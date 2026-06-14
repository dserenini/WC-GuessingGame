-- ═════════════════════════════════════════════════════════════════════════════
-- MIGRAÇÃO CONSOLIDADA — RODAR UMA VEZ EM PRODUÇÃO JUNTO COM O PUSH GERAL
-- ═════════════════════════════════════════════════════════════════════════════
--
-- Cole TUDO no SQL Editor do Supabase de produção e execute uma única vez, ao
-- publicar a build que mescla as branches claude/*.
--
-- É IDEMPOTENTE: a coluna usa ADD COLUMN IF NOT EXISTS e as views usam
-- CREATE OR REPLACE. Rodar de novo não causa dano.
--
-- ORDEM IMPORTA: a Parte 1 (coluna locale) precisa existir ANTES de o app novo
-- subir, senão o SELECT da coluna locale quebra o app. Por isso vem primeiro.
--
-- FORA DESTE ARQUIVO (de propósito — já aplicado em prod em sessões anteriores):
--   • check_bet_deadline versão combinada (bypass + anti-dupla)  → fix_check_bet_deadline_combined.sql
--   • admin_add_users_to_leagues RPC                              → admin_add_users_to_leagues.sql
--   • reset de Super Palpites (zerar saldo dobrado)               → reset_super_palpites.sql (one-time)
-- Se tiver dúvida se algum desses já rodou, confirme com pg_get_functiondef /
-- pg_get_viewdef antes — NÃO re-rode o reset_super_palpites (não é idempotente).
--
-- ─────────────────────────────────────────────────────────────────────────────


-- ═════════════════════════════════════════════════════════════════════════════
-- PARTE 1 — ONBOARDING ÚNICO (origem: claude/focused-hopper-80bda6)
-- ═════════════════════════════════════════════════════════════════════════════
-- O "já escolheu idioma" deixava de ficar só no aparelho (localStorage) e passa
-- a ser gravado no perfil, para o onboarding (idioma + nome + telefone) ser
-- pedido UMA vez e seguir a conta em qualquer dispositivo.
-- RODAR ANTES DE PUBLICAR: o app novo faz SELECT da coluna locale.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS locale text;


-- ═════════════════════════════════════════════════════════════════════════════
-- PARTE 2 — ESTATÍSTICAS AVANÇADAS / RANKINGS (origem: claude/wonderful-aryabhata-7df850)
-- ═════════════════════════════════════════════════════════════════════════════
-- Todas seguem o shape de user_rankings (user_id, username, full_name,
-- display_preference, avatar_url, total_points, total_bets, rank) para que o
-- frontend reuse RankingEntry/applyDenseRank sem código novo. A coluna
-- total_points carrega SEMPRE o valor da métrica de cada ranking.
-- Só expõem agregados (contagens/somatórios) — nenhum palpite individual vaza.
-- Futuro: espelhar cada uma com variante por liga (PARTITION BY league_id +
-- JOIN league_members), como em league_rankings.
-- ─────────────────────────────────────────────

-- 1) Rei do Placar Exato — quem mais cravou (points = 3)
CREATE OR REPLACE VIEW exact_score_rankings WITH (security_invoker = on) AS
SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
  COUNT(*) FILTER (WHERE b.points = 3)                              AS total_points,
  COUNT(b.id)                                                      AS total_bets,
  RANK() OVER (ORDER BY COUNT(*) FILTER (WHERE b.points = 3) DESC) AS rank
FROM profiles p LEFT JOIN bets b ON b.user_id = p.id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- 2) Pé-quente do Brasil — pontos somados nos jogos do Brasil
CREATE OR REPLACE VIEW brazil_points_rankings WITH (security_invoker = on) AS
SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
  COALESCE(SUM(b.points) FILTER (WHERE th.name = 'Brasil' OR ta.name = 'Brasil'), 0) AS total_points,
  COUNT(b.id)  FILTER (WHERE th.name = 'Brasil' OR ta.name = 'Brasil')               AS total_bets,
  RANK() OVER (ORDER BY COALESCE(SUM(b.points) FILTER (WHERE th.name = 'Brasil' OR ta.name = 'Brasil'), 0) DESC) AS rank
FROM profiles p
LEFT JOIN bets b    ON b.user_id = p.id
LEFT JOIN matches m ON m.id = b.match_id
LEFT JOIN teams th  ON th.id = m.home_team_id
LEFT JOIN teams ta  ON ta.id = m.away_team_id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- 3) Quase lá — errou o placar exato por 1 gol (cravou perto, não levou os 3)
CREATE OR REPLACE VIEW near_miss_rankings WITH (security_invoker = on) AS
SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
  COUNT(*) FILTER (
    WHERE m.status = 'finished' AND b.points < 3
      AND ABS(b.home_score_bet - m.home_score) + ABS(b.away_score_bet - m.away_score) = 1
  ) AS total_points,
  COUNT(b.id) AS total_bets,
  RANK() OVER (ORDER BY COUNT(*) FILTER (
    WHERE m.status = 'finished' AND b.points < 3
      AND ABS(b.home_score_bet - m.home_score) + ABS(b.away_score_bet - m.away_score) = 1) DESC) AS rank
FROM profiles p
LEFT JOIN bets b    ON b.user_id = p.id
LEFT JOIN matches m ON m.id = b.match_id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- 4) Tacada do Dia — maior pontuação de um usuário num único dia (fuso SP)
CREATE OR REPLACE VIEW daily_top_rankings WITH (security_invoker = on) AS
WITH daily AS (
  SELECT b.user_id,
         (m.match_date AT TIME ZONE 'America/Sao_Paulo')::date AS match_day,
         SUM(b.points) AS day_points
  FROM bets b JOIN matches m ON m.id = b.match_id
  WHERE m.status = 'finished'
  GROUP BY b.user_id, (m.match_date AT TIME ZONE 'America/Sao_Paulo')::date
)
SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
  COALESCE(MAX(d.day_points), 0) AS total_points,
  COUNT(d.match_day)             AS total_bets,
  RANK() OVER (ORDER BY COALESCE(MAX(d.day_points), 0) DESC) AS rank
FROM profiles p LEFT JOIN daily d ON d.user_id = p.id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- 5) Mais Regular — pontuou no maior número de jogos finalizados (consistência)
CREATE OR REPLACE VIEW regularity_rankings WITH (security_invoker = on) AS
SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
  COUNT(*)    FILTER (WHERE m.status = 'finished' AND b.points > 0) AS total_points,
  COUNT(b.id) FILTER (WHERE m.status = 'finished')                 AS total_bets,
  RANK() OVER (ORDER BY COUNT(*) FILTER (WHERE m.status = 'finished' AND b.points > 0) DESC) AS rank
FROM profiles p
LEFT JOIN bets b    ON b.user_id = p.id
LEFT JOIN matches m ON m.id = b.match_id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- 6) Os Corajosos — palpites ousados: >= 5 gols de diferença OU >= 7 gols somados
CREATE OR REPLACE VIEW boldness_rankings WITH (security_invoker = on) AS
SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
  COUNT(*) FILTER (WHERE (ABS(b.home_score_bet - b.away_score_bet) >= 5 OR (b.home_score_bet + b.away_score_bet) >= 7)) AS total_points,
  COUNT(b.id)                                                        AS total_bets,
  RANK() OVER (ORDER BY COUNT(*) FILTER (WHERE (ABS(b.home_score_bet - b.away_score_bet) >= 5 OR (b.home_score_bet + b.away_score_bet) >= 7)) DESC) AS rank
FROM profiles p
LEFT JOIN bets b ON b.user_id = p.id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- 7) Do Contra que Acertou — cravou (points=3) um placar que < 20% do bolão apostou
CREATE OR REPLACE VIEW contrarian_rankings WITH (security_invoker = on) AS
WITH match_total AS (
  SELECT match_id, COUNT(*) AS n_bets FROM bets GROUP BY match_id
),
score_pop AS (
  SELECT match_id, home_score_bet, away_score_bet, COUNT(*) AS n_same
  FROM bets GROUP BY match_id, home_score_bet, away_score_bet
),
contrarian AS (
  SELECT b.user_id
  FROM bets b
  JOIN matches m     ON m.id = b.match_id AND m.status = 'finished'
  JOIN match_total mt ON mt.match_id = b.match_id
  JOIN score_pop sp   ON sp.match_id = b.match_id
                     AND sp.home_score_bet = b.home_score_bet
                     AND sp.away_score_bet = b.away_score_bet
  WHERE b.points = 3
    AND mt.n_bets > 0
    AND sp.n_same::numeric / mt.n_bets < 0.20
)
SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
  COUNT(c.user_id) AS total_points,
  COUNT(c.user_id) AS total_bets,
  RANK() OVER (ORDER BY COUNT(c.user_id) DESC) AS rank
FROM profiles p
LEFT JOIN contrarian c ON c.user_id = p.id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- Detalhe do "Do Contra que Acertou": (user_id, match_id) das cravadas raras.
-- Usado ao tocar num jogador para mostrar apenas esses jogos. Mesmo critério do
-- contrarian_rankings; só expõe IDs de jogo (sem placares), respeita RLS.
CREATE OR REPLACE VIEW contrarian_matches WITH (security_invoker = on) AS
WITH match_total AS (
  SELECT match_id, COUNT(*) AS n_bets FROM bets GROUP BY match_id
),
score_pop AS (
  SELECT match_id, home_score_bet, away_score_bet, COUNT(*) AS n_same
  FROM bets GROUP BY match_id, home_score_bet, away_score_bet
)
SELECT b.user_id, b.match_id
FROM bets b
JOIN matches m      ON m.id = b.match_id AND m.status = 'finished'
JOIN match_total mt ON mt.match_id = b.match_id
JOIN score_pop sp   ON sp.match_id = b.match_id
                   AND sp.home_score_bet = b.home_score_bet
                   AND sp.away_score_bet = b.away_score_bet
WHERE b.points = 3
  AND mt.n_bets > 0
  AND sp.n_same::numeric / mt.n_bets < 0.20;

-- ═════════════════════════════════════════════════════════════════════════════
-- FIM. Após rodar, confirme rapidamente (opcional):
--   SELECT 1 FROM information_schema.columns
--     WHERE table_name='profiles' AND column_name='locale';
--   SELECT count(*) FROM information_schema.views
--     WHERE table_name IN ('exact_score_rankings','brazil_points_rankings',
--       'near_miss_rankings','daily_top_rankings','regularity_rankings',
--       'boldness_rankings','contrarian_rankings','contrarian_matches');  -- deve dar 8
-- ═════════════════════════════════════════════════════════════════════════════
