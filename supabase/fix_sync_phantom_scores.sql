-- =============================================================================
-- FIX — sync live gravou placares fantasmas e pontuou em placar transitório
--
-- Sintomas:
--  1) Jogos FUTUROS aparecendo com placar (ex.: 0-1) e status 'scheduled'.
--  2) Pontos errados: palpite de empate recebeu +1 num jogo que terminou em
--     vitória (o trigger pontuou num instante em que a fonte marcou 'finished'
--     com placar transitório, e os pontos ficaram gravados).
--
-- Causa: a Edge Function sync-scores, em modo 'live', confiou na fonte gratuita
-- worldcup26.ir, que reporta placar de placeholder para jogos futuros e flapa
-- status. (Correção definitiva já aplicada no código da função — redeploy.)
--
-- Rode os passos abaixo no SQL Editor da PRODUÇÃO, como ADMIN.
-- =============================================================================

-- ─────────────────────────────────────────────
-- PASSO 0 (EMERGÊNCIA): parar o sync de escrever
-- ─────────────────────────────────────────────
UPDATE app_config
   SET value = '{"mode":"shadow"}'::jsonb, updated_at = NOW()
 WHERE key = 'sync_mode';

-- ─────────────────────────────────────────────
-- PASSO 1 (DIAGNÓSTICO): o que o sync fez no USA x Paraguai
--   Procure por linhas com src_status='finished' e um placar de empate / errado:
--   é a "pegadinha" que pontuou os palpites de empate.
-- ─────────────────────────────────────────────
SELECT ran_at, mode, home_team, away_team,
       src_home_score, src_away_score, src_status,
       src_raw_finished, src_time_elapsed, applied
FROM api_sync_runs
WHERE home_team IN ('Estados Unidos', 'Paraguai')
   OR away_team IN ('Estados Unidos', 'Paraguai')
ORDER BY ran_at DESC
LIMIT 40;

-- ─────────────────────────────────────────────
-- PASSO 2 (DIAGNÓSTICO): jogos com placar fantasma (scheduled mas com placar)
-- ─────────────────────────────────────────────
SELECT h.name AS mandante, a.name AS visitante,
       m.home_score, m.away_score, m.status, m.match_date
FROM matches m
JOIN teams h ON h.id = m.home_team_id
JOIN teams a ON a.id = m.away_team_id
WHERE m.status = 'scheduled'
  AND (m.home_score IS NOT NULL OR m.away_score IS NOT NULL)
ORDER BY m.match_date;

-- ─────────────────────────────────────────────
-- PASSO 3 (REPARO A): limpar placares fantasmas dos jogos não iniciados
-- ─────────────────────────────────────────────
UPDATE matches
   SET home_score = NULL, away_score = NULL
 WHERE status = 'scheduled'
   AND (home_score IS NOT NULL OR away_score IS NOT NULL);

-- ─────────────────────────────────────────────
-- PASSO 3b (REPARO): zerar pontos de apostas cujo jogo NÃO está finalizado.
--   A fonte "encerrou" jogos futuros prematuramente e o trigger pontuou essas
--   apostas; como esses jogos voltaram para 'scheduled', os pontos ficaram
--   pendurados e inflam o ranking. Invariante: só jogo 'finished' tem pontos.
--   Quando o jogo realmente acontecer, o trigger recalcula normalmente.
-- ─────────────────────────────────────────────
UPDATE bets b
   SET points = 0, updated_at = NOW()
  FROM matches m
 WHERE b.match_id = m.id
   AND m.status <> 'finished'
   AND b.points <> 0;

-- ─────────────────────────────────────────────
-- PASSO 4 (CONFERÊNCIA): o placar REAL gravado nos jogos finalizados está certo?
--   Antes de recalcular pontos, garanta que home_score/away_score batem com o
--   resultado oficial. Corrija manualmente os que estiverem errados:
--     UPDATE matches SET home_score = 4, away_score = 1
--       WHERE id = '<uuid-do-usa-x-paraguai>';
-- ─────────────────────────────────────────────
SELECT m.id, h.name AS mandante, a.name AS visitante,
       m.home_score, m.away_score, m.status, m.match_date
FROM matches m
JOIN teams h ON h.id = m.home_team_id
JOIN teams a ON a.id = m.away_team_id
WHERE m.status = 'finished'
ORDER BY m.match_date DESC;

-- ─────────────────────────────────────────────
-- PASSO 5 (REPARO B): recalcular os pontos de TODOS os jogos finalizados
--   a partir do placar (já conferido) gravado em matches.
--   O UPDATE "no-op" de status re-dispara o trigger calculate_bet_points, que
--   reescreve bets.points pela regra correta (empate em jogo de vitória -> 0).
--   Idempotente: pode rodar quantas vezes quiser.
-- ─────────────────────────────────────────────
UPDATE matches
   SET status = status
 WHERE status = 'finished'
   AND home_score IS NOT NULL
   AND away_score IS NOT NULL;

-- ─────────────────────────────────────────────
-- PASSO 6 (VERIFICAÇÃO): confirmar que empate não pontua em jogo de vitória
-- ─────────────────────────────────────────────
SELECT b.home_score_bet, b.away_score_bet, b.points,
       m.home_score AS real_home, m.away_score AS real_away
FROM bets b
JOIN matches m ON m.id = b.match_id
JOIN teams h ON h.id = m.home_team_id
JOIN teams a ON a.id = m.away_team_id
WHERE h.name = 'Estados Unidos' AND a.name = 'Paraguai'
ORDER BY b.points DESC;

-- =============================================================================
-- DEPOIS de redeployar a Edge Function corrigida e validar em shadow, religue:
--   UPDATE app_config SET value='{"mode":"live"}'::jsonb, updated_at=NOW()
--    WHERE key='sync_mode';
-- =============================================================================
