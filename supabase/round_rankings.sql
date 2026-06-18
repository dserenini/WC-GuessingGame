-- ═════════════════════════════════════════════════════════════════════════════
-- RANKING GERAL POR RODADA — RODAR EM PRODUÇÃO
-- ═════════════════════════════════════════════════════════════════════════════
--
-- Cole TUDO no SQL Editor do Supabase de produção e execute. É IDEMPOTENTE
-- (CREATE OR REPLACE) — rodar de novo não causa dano.
--
-- O QUE FAZ: cria a view user_round_rankings, que entrega o ranking geral
-- separado por RODADA da fase de grupos (1, 2, 3). O app filtra por `round`
-- (.eq('round', n)) e reusa o mesmo RankingEntry. A opção "Geral" no app
-- continua usando a view user_rankings (todos os jogos).
--
-- RODADA: derivada do api_match_id sequencial (1-24 = R1, 25-48 = R2,
-- 49-72 = R3) — MESMA regra já usada no filtro de apostas (betRoundOf):
--   round = ((api_match_id - 1) / 24) + 1
-- O regex '^[0-9]+$' protege contra api_match_id não-numérico/nulo (ex.: jogos
-- de mata-mata), e o BETWEEN 1 AND 72 restringe à fase de grupos.
--
-- DESEMPATE: os mesmos 3 critérios do user_rankings, porém ESCOPADOS à rodada
-- (pontos da rodada → placares exatos na rodada → pontos do Brasil na rodada).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW user_round_rankings
WITH (security_invoker = on) AS
WITH bet_rounds AS (
  SELECT
    b.user_id,
    b.id     AS bet_id,
    b.points,
    ((m.api_match_id)::int - 1) / 24 + 1        AS round,
    (th.name = 'Brasil' OR ta.name = 'Brasil')  AS is_brazil
  FROM bets b
  JOIN matches m     ON m.id = b.match_id
  LEFT JOIN teams th ON th.id = m.home_team_id
  LEFT JOIN teams ta ON ta.id = m.away_team_id
  WHERE m.api_match_id ~ '^[0-9]+$'
    AND (m.api_match_id)::int BETWEEN 1 AND 72
),
rounds AS (SELECT generate_series(1, 3) AS round)
SELECT
  p.id AS user_id,
  p.username,
  p.full_name,
  p.display_preference,
  p.avatar_url,
  r.round,
  COALESCE(SUM(br.points), 0) AS total_points,
  COUNT(br.bet_id)            AS total_bets,
  RANK() OVER (
    PARTITION BY r.round
    ORDER BY
      COALESCE(SUM(br.points), 0) DESC,
      COUNT(*) FILTER (WHERE br.points = 3) DESC,
      COALESCE(SUM(br.points) FILTER (WHERE br.is_brazil), 0) DESC
  ) AS rank
FROM profiles p
CROSS JOIN rounds r
LEFT JOIN bet_rounds br ON br.user_id = p.id AND br.round = r.round
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url, r.round;

-- ═════════════════════════════════════════════════════════════════════════════
-- VERIFICAÇÃO (opcional):
--   SELECT round, count(*) FROM user_round_rankings GROUP BY round ORDER BY round;
--   -- deve listar rodadas 1, 2, 3, cada uma com o nº total de participantes.
--   SELECT username, round, total_points, total_bets, rank
--     FROM user_round_rankings WHERE round = 1 ORDER BY rank LIMIT 10;
-- ═════════════════════════════════════════════════════════════════════════════
