-- ═════════════════════════════════════════════════════════════════════════════
-- FINALIZAR A FINAL DA COPA (Campeã) — RODAR EM PRODUÇÃO
-- ═════════════════════════════════════════════════════════════════════════════
--
-- PROBLEMA: ao finalizar a FINAL (round='final', slot=1, match_no=104) pelo Admin,
-- o UPDATE em ko_match dá erro. O código do repo é null-safe para a final:
--   • a propagação de vencedores vive na Edge Function propagateKnockout
--     (supabase/functions/sync-scores/index.ts) e a final NÃO é src_match de
--     ninguém, então nunca tenta escrever "o próximo jogo";
--   • o trigger de PONTUAÇÃO score_ko_match (knockout_schema.sql) trata a final
--     e o bônus de campeão sem erro.
-- Logo, o erro é quase certamente DRIFT DE PRODUÇÃO: um trigger de propagação que
-- existe SÓ no banco de prod (não no repo) e assume que sempre há um jogo destino.
--
-- ESTE SCRIPT: (A) diagnostica, (B) conserta (condicional ao que A revelar),
-- (C) finaliza a final, (D) verifica o bônus de campeão. Rode PARTE A primeiro,
-- leia o resultado, e só então aplique a PARTE B adequada.
-- ─────────────────────────────────────────────────────────────────────────────


-- ══ PARTE A — DIAGNÓSTICO (somente leitura) ══════════════════════════════════
-- A1) Todos os triggers de ko_match (procure por qualquer trigger de propagação
--     ALÉM de trg_score_ko_match e trg_ko_bet_deadline).
SELECT t.tgname, pg_get_triggerdef(t.oid) AS def
FROM pg_trigger t
WHERE t.tgrelid = 'public.ko_match'::regclass
  AND NOT t.tgisinternal
ORDER BY t.tgname;

-- A2) Corpo das funções por trás desses triggers.
SELECT DISTINCT p.proname, pg_get_functiondef(p.oid) AS def
FROM pg_trigger t
JOIN pg_proc p ON p.oid = t.tgfoid
WHERE t.tgrelid = 'public.ko_match'::regclass
  AND NOT t.tgisinternal
ORDER BY p.proname;

-- A3) Corpo da função de pontuação (confirmar se bate com o repo).
SELECT pg_get_functiondef('score_ko_match'::regproc) AS score_ko_match_def;

-- A4) Reproduzir o erro COM SEGURANÇA (rollback no fim) e capturar o texto exato.
--     Ajuste <H> e <A> para o placar real da final.
-- BEGIN;
--   UPDATE ko_match
--   SET home_score = <H>, away_score = <A>, status = 'finished',
--       advancing_team_id = (SELECT id FROM teams WHERE name = 'Espanha')
--   WHERE round = 'final' AND slot = 1;   -- match_no = 104
-- ROLLBACK;   -- >>> anote a mensagem de erro antes de conserta <<<


-- ══ PARTE B — FIX (aplique a variante que a PARTE A indicar) ══════════════════
--
-- VARIANTE B1 (mais provável): existe um trigger de propagação prod-only cuja
-- função computa "o próximo jogo" e falha na final. Reescreva a função para
-- propagar via os PONTEIROS DE ORIGEM do destino (home_src_match/away_src_match),
-- de modo que a final (que não é origem de ninguém) simplesmente atualize 0 linhas.
-- Troque <nome_da_funcao> pelo nome real visto em A2 e mantenha os atributos
-- (LANGUAGE / SECURITY DEFINER / SET search_path) idênticos aos de prod.
--
-- CREATE OR REPLACE FUNCTION <nome_da_funcao>()
-- RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
-- SET search_path = public, pg_temp AS $$
-- BEGIN
--   IF NEW.status = 'finished' AND NEW.advancing_team_id IS NOT NULL THEN
--     -- Vencedor entra no(s) jogo(s) cujo src aponta para ESTE jogo. Para a
--     -- FINAL não há nenhum → 0 linhas, sem erro. O 3º lugar recebe o PERDEDOR
--     -- (ver supabase/fix_ko_third_place.sql) — se a função de prod já cuidava
--     -- disso, preserve essa lógica no bloco correspondente.
--     UPDATE ko_match dest
--        SET home_team_id = NEW.advancing_team_id
--      WHERE dest.home_src_match = NEW.id AND dest.round <> '3lugar';
--     UPDATE ko_match dest
--        SET away_team_id = NEW.advancing_team_id
--      WHERE dest.away_src_match = NEW.id AND dest.round <> '3lugar';
--   END IF;
--   RETURN NEW;
-- END;
-- $$;
--
-- VARIANTE B1-alt (mínima): apenas envolver o corpo atual da função de prod num
-- guard, sem reescrever a lógica:
--   IF EXISTS (SELECT 1 FROM ko_match d
--              WHERE d.home_src_match = NEW.id OR d.away_src_match = NEW.id) THEN
--     <corpo original de propagação>
--   END IF;
--
-- VARIANTE B2 (se A3 mostrar score_ko_match divergente do repo e for ELE que
-- falha): reaplicar o corpo canônico do repo (supabase/knockout_schema.sql,
-- função score_ko_match) via CREATE OR REPLACE FUNCTION.


-- ══ PARTE C — FINALIZAR A FINAL ══════════════════════════════════════════════
-- Após aplicar a PARTE B, finalize (por aqui OU pelo diálogo do Admin — ambos
-- disparam trg_score_ko_match, que pontua os palpites 5/3 e grava o bônus de
-- campeão em ko_champion_pick). Ajuste <H> e <A>.
--
-- UPDATE ko_match
-- SET home_score = <H>, away_score = <A>, status = 'finished',
--     advancing_team_id = (SELECT id FROM teams WHERE name = 'Espanha')
-- WHERE round = 'final' AND slot = 1;


-- ══ PARTE D — VERIFICAÇÃO ════════════════════════════════════════════════════
-- D1) Estado da final (deve mostrar status=finished e campea=Espanha).
SELECT m.round, m.match_no, m.home_score, m.away_score, m.status,
       t.name AS campea
FROM ko_match m
LEFT JOIN teams t ON t.id = m.advancing_team_id
WHERE m.round = 'final';

-- D2) Palpites da final pontuados só com 5 / 3 / 0.
SELECT points, count(*)
FROM ko_bet
WHERE ko_match_id = (SELECT id FROM ko_match WHERE round = 'final' AND slot = 1)
GROUP BY points
ORDER BY points DESC;

-- D3) Bônus de campeão: 3 apenas para quem cravou a Espanha, 0 para o resto.
SELECT t.name AS palpite, cp.points, count(*)
FROM ko_champion_pick cp
JOIN teams t ON t.id = cp.team_id
GROUP BY t.name, cp.points
ORDER BY cp.points DESC, t.name;

-- D4) Ranking geral do KO com o bônus embutido (confira um usuário que cravou
--     Espanha: total_points deve ser soma dos ko_bet.points + 3).
SELECT * FROM ko_user_rankings ORDER BY rank LIMIT 10;
-- ═════════════════════════════════════════════════════════════════════════════
