-- ═════════════════════════════════════════════════════════════════════════════
-- DESEMPATE NO RANKING (Geral + Ligas) — RODAR EM PRODUÇÃO
-- ═════════════════════════════════════════════════════════════════════════════
--
-- Cole TUDO no SQL Editor do Supabase de produção e execute. É IDEMPOTENTE
-- (CREATE OR REPLACE) — rodar de novo não causa dano.
--
-- O QUE MUDA: o RANK() das views user_rankings e league_rankings passa a
-- desempatar por critérios, nesta ordem. Só dividem a MESMA posição quando os
-- TRÊS critérios são idênticos.
--   1) total de pontos (desc)               — critério principal (já existia)
--   2) vitórias em PLACAR EXATO (desc)       — nº de palpites com points = 3
--   3) pontos nos jogos do BRASIL (desc)     — soma dos pontos onde Brasil joga
--
-- Os joins matches/teams existem só para o critério 3. Como bet→match e
-- match→team são N:1 (cada palpite tem 1 jogo; cada jogo tem 1 mandante e 1
-- visitante), NÃO há multiplicação de linhas: total_points (SUM) e total_bets
-- (COUNT) continuam idênticos ao de antes.
--
-- IMPORTANTE: CREATE OR REPLACE VIEW exige as MESMAS colunas (nome/ordem/tipo)
-- da view atual. As colunas de saída aqui são idênticas às de hoje — só muda o
-- ORDER BY do RANK() e os joins internos. Se der erro de "cannot change name /
-- cannot drop columns", a view de prod divergiu do repo: rode antes
--   SELECT pg_get_viewdef('user_rankings'::regclass, true);
--   SELECT pg_get_viewdef('league_rankings'::regclass, true);
-- e me mande o resultado.
-- ─────────────────────────────────────────────────────────────────────────────


-- ── 1) RANKING GERAL ─────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW user_rankings
WITH (security_invoker = on) AS
SELECT
  p.id        AS user_id,
  p.username,
  p.full_name,
  p.display_preference,
  p.avatar_url,
  COALESCE(SUM(b.points), 0) AS total_points,
  COUNT(b.id) AS total_bets,
  RANK() OVER (
    ORDER BY
      COALESCE(SUM(b.points), 0) DESC,
      COUNT(*) FILTER (WHERE b.points = 3) DESC,
      COALESCE(SUM(b.points) FILTER (WHERE th.name = 'Brasil' OR ta.name = 'Brasil'), 0) DESC
  ) AS rank
FROM profiles p
LEFT JOIN bets b    ON b.user_id = p.id
LEFT JOIN matches m ON m.id = b.match_id
LEFT JOIN teams th  ON th.id = m.home_team_id
LEFT JOIN teams ta  ON ta.id = m.away_team_id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;


-- ── 2) RANKING DE LIGAS ──────────────────────────────────────────────────────
CREATE OR REPLACE VIEW league_rankings
WITH (security_invoker = on) AS
SELECT
  lm.league_id,
  l.name        AS league_name,
  p.id          AS user_id,
  p.username,
  p.full_name,
  p.display_preference,
  p.avatar_url,
  COALESCE(SUM(b.points), 0) AS total_points,
  RANK() OVER (
    PARTITION BY lm.league_id
    ORDER BY
      COALESCE(SUM(b.points), 0) DESC,
      COUNT(*) FILTER (WHERE b.points = 3) DESC,
      COALESCE(SUM(b.points) FILTER (WHERE th.name = 'Brasil' OR ta.name = 'Brasil'), 0) DESC
  ) AS rank,
  COUNT(b.id) AS total_bets
FROM league_members lm
JOIN leagues l ON l.id = lm.league_id
JOIN profiles p ON p.id = lm.user_id
LEFT JOIN bets b    ON b.user_id = lm.user_id
LEFT JOIN matches m ON m.id = b.match_id
LEFT JOIN teams th  ON th.id = m.home_team_id
LEFT JOIN teams ta  ON ta.id = m.away_team_id
GROUP BY lm.league_id, l.name, p.id, p.username, p.full_name, p.display_preference, p.avatar_url;


-- ═════════════════════════════════════════════════════════════════════════════
-- VERIFICAÇÃO (opcional) — confira que o ORDER BY do RANK() tem os 3 critérios:
--   SELECT pg_get_viewdef('user_rankings'::regclass, true);
--   SELECT pg_get_viewdef('league_rankings'::regclass, true);
-- ═════════════════════════════════════════════════════════════════════════════
