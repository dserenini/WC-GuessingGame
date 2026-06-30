-- ═════════════════════════════════════════════════════════════════════════════
-- EVOLUÇÃO DE POSIÇÃO (Fase de Grupos) — RODAR EM PRODUÇÃO
-- ═════════════════════════════════════════════════════════════════════════════
--
-- Cole TUDO no SQL Editor do Supabase de produção e execute. É IDEMPOTENTE
-- (CREATE OR REPLACE) — rodar de novo não causa dano.
--
-- O QUE FAZ: cria DUAS views que entregam o RANKING ACUMULADO de cada usuário ao
-- longo do tempo, para a tela "Resultados" → aba "Evolução" (gráfico de linha):
--   • user_game_evolution → um snapshot ao fim de cada JOGO finalizado (1..72).
--   • user_day_evolution  → um snapshot ao fim de cada DIA com jogo finalizado.
--
-- Cada linha = (user, x, pontos acumulados, posição naquele instante). O app
-- plota a posição (rank) no eixo Y invertido (1 no topo) e o jogo#/dia no X.
--
-- JOGO/RODADA: derivado do api_match_id sequencial (1..72 = fase de grupos),
-- mesma regra de round_rankings.sql. O regex '^[0-9]+$' protege contra
-- api_match_id não-numérico/nulo (mata-mata) e o BETWEEN 1 AND 72 restringe à
-- fase de grupos.
--
-- ACUMULADO: como `points` só é gravado pelo trigger quando o jogo finaliza
-- (default 0), somar os pontos dos jogos com game_no <= snapshot já ignora
-- naturalmente os jogos não finalizados.
--
-- DESEMPATE: o RANK() aqui ordena SÓ por pontos acumulados (sem os critérios
-- extras de placar exato/Brasil do user_rankings). É suficiente para a posição no
-- gráfico; a escolha dos "vizinhos ±2" no app usa o user_rankings (autoritativo).
-- ─────────────────────────────────────────────────────────────────────────────


-- ── 1) EVOLUÇÃO POR JOGO ──────────────────────────────────────────────────────
CREATE OR REPLACE VIEW user_game_evolution
WITH (security_invoker = on) AS
WITH game_points AS (
  -- pontos que cada usuário fez em cada jogo da fase de grupos
  SELECT
    b.user_id,
    (m.api_match_id)::int AS game_no,
    SUM(b.points)         AS pts
  FROM bets b
  JOIN matches m ON m.id = b.match_id
  WHERE m.api_match_id ~ '^[0-9]+$'
    AND (m.api_match_id)::int BETWEEN 1 AND 72
  GROUP BY b.user_id, (m.api_match_id)::int
),
finished_games AS (
  -- nº dos jogos JÁ finalizados (cada um vira um snapshot no eixo X)
  SELECT (m.api_match_id)::int AS game_no
  FROM matches m
  WHERE m.status = 'finished'
    AND m.api_match_id ~ '^[0-9]+$'
    AND (m.api_match_id)::int BETWEEN 1 AND 72
),
cum AS (
  -- para cada (usuário × jogo finalizado): pontos acumulados até aquele jogo
  SELECT
    p.id AS user_id,
    fg.game_no,
    COALESCE(SUM(gp.pts) FILTER (WHERE gp.game_no <= fg.game_no), 0) AS cum_points
  FROM profiles p
  CROSS JOIN finished_games fg
  LEFT JOIN game_points gp ON gp.user_id = p.id
  WHERE p.participate_in_ranking = true
  GROUP BY p.id, fg.game_no
)
SELECT
  user_id,
  game_no,
  cum_points,
  RANK() OVER (PARTITION BY game_no ORDER BY cum_points DESC) AS rank
FROM cum;


-- ── 2) EVOLUÇÃO POR DIA ───────────────────────────────────────────────────────
CREATE OR REPLACE VIEW user_day_evolution
WITH (security_invoker = on) AS
WITH day_points AS (
  -- pontos que cada usuário fez em cada DIA (fuso de Brasília), só jogos de grupos
  SELECT
    b.user_id,
    (m.match_date AT TIME ZONE 'America/Sao_Paulo')::date AS match_day,
    SUM(b.points)                                          AS pts
  FROM bets b
  JOIN matches m ON m.id = b.match_id
  WHERE m.api_match_id ~ '^[0-9]+$'
    AND (m.api_match_id)::int BETWEEN 1 AND 72
  GROUP BY b.user_id, (m.match_date AT TIME ZONE 'America/Sao_Paulo')::date
),
finished_days AS (
  -- dias que têm ao menos um jogo finalizado (cada um vira um snapshot no X)
  SELECT DISTINCT (m.match_date AT TIME ZONE 'America/Sao_Paulo')::date AS match_day
  FROM matches m
  WHERE m.status = 'finished'
    AND m.api_match_id ~ '^[0-9]+$'
    AND (m.api_match_id)::int BETWEEN 1 AND 72
),
cum AS (
  SELECT
    p.id AS user_id,
    fd.match_day,
    COALESCE(SUM(dp.pts) FILTER (WHERE dp.match_day <= fd.match_day), 0) AS cum_points
  FROM profiles p
  CROSS JOIN finished_days fd
  LEFT JOIN day_points dp ON dp.user_id = p.id
  WHERE p.participate_in_ranking = true
  GROUP BY p.id, fd.match_day
)
SELECT
  user_id,
  match_day,
  cum_points,
  RANK() OVER (PARTITION BY match_day ORDER BY cum_points DESC) AS rank
FROM cum;


-- ═════════════════════════════════════════════════════════════════════════════
-- VERIFICAÇÃO (opcional):
--   SELECT game_no, count(*) FROM user_game_evolution GROUP BY game_no ORDER BY game_no;
--   -- cada game_no finalizado deve listar o nº total de participantes.
--   SELECT game_no, cum_points, rank FROM user_game_evolution
--     WHERE user_id = '<seu uuid>' ORDER BY game_no;
--   -- cum_points deve ser monotônico (não decresce); rank entre 1 e N.
--   SELECT match_day, count(*) FROM user_day_evolution GROUP BY match_day ORDER BY match_day;
-- ═════════════════════════════════════════════════════════════════════════════
