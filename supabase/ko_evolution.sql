-- ═════════════════════════════════════════════════════════════════════════════
-- EVOLUÇÃO DE POSIÇÃO (Mata-Mata) — RODAR EM PRODUÇÃO
-- ═════════════════════════════════════════════════════════════════════════════
--
-- Cole TUDO no SQL Editor do Supabase de produção e execute. É IDEMPOTENTE
-- (CREATE OR REPLACE) — rodar de novo não causa dano.
--
-- Espelho de group_evolution.sql, porém sobre ko_bet + ko_match. Cria DUAS views
-- para a tela "Resultados Mata-Mata" → aba "Evolução" (gráfico de linha):
--   • ko_user_game_evolution → snapshot ao fim de cada JOGO finalizado (73..104).
--   • ko_user_day_evolution  → snapshot ao fim de cada DIA com jogo finalizado.
--
-- JOGO: usa ko_match.match_no (73..104, coluna int — sem regex, ao contrário das
-- views de grupos que derivam do api_match_id textual).
--
-- FILTRO: participantes que aparecem no ranking (participate_in_ranking) E pagaram
-- o mata-mata (knockout_unlocked) — mesma regra de ko_user_rankings
-- (knockout_access.sql).
--
-- BÔNUS DE CAMPEÃO: ko_champion_pick.points (3 p/ quem cravou) entra no acumulado
-- SÓ a partir do snapshot da FINAL, e apenas quando a final está finished com
-- vencedor. Assim o ÚLTIMO snapshot bate exatamente com ko_user_rankings.total_points.
-- ─────────────────────────────────────────────────────────────────────────────


-- ── 1) EVOLUÇÃO POR JOGO ──────────────────────────────────────────────────────
CREATE OR REPLACE VIEW ko_user_game_evolution
WITH (security_invoker = on) AS
WITH game_points AS (
  -- pontos que cada usuário fez em cada jogo do mata-mata
  SELECT
    b.user_id,
    m.match_no AS game_no,
    SUM(b.points) AS pts
  FROM ko_bet b
  JOIN ko_match m ON m.id = b.ko_match_id
  WHERE m.match_no BETWEEN 73 AND 104
  GROUP BY b.user_id, m.match_no
),
finished_games AS (
  -- nº dos jogos JÁ finalizados (cada um vira um snapshot no eixo X)
  SELECT m.match_no AS game_no
  FROM ko_match m
  WHERE m.status = 'finished'
    AND m.match_no BETWEEN 73 AND 104
),
champ AS (
  -- nº da final SE já decidida (senão NULL → bônus nunca soma). Guarda contra
  -- final não finalizada: o bônus só aparece quando há campeã.
  SELECT m.match_no AS final_no
  FROM ko_match m
  WHERE m.round = 'final'
    AND m.status = 'finished'
    AND m.advancing_team_id IS NOT NULL
  LIMIT 1
),
cum AS (
  -- para cada (usuário × jogo finalizado): pontos acumulados + bônus de campeão
  -- a partir do snapshot da final.
  SELECT
    p.id AS user_id,
    fg.game_no,
    COALESCE(SUM(gp.pts) FILTER (WHERE gp.game_no <= fg.game_no), 0)
      + CASE
          WHEN (SELECT final_no FROM champ) IS NOT NULL
           AND fg.game_no >= (SELECT final_no FROM champ)
          THEN COALESCE((SELECT cp.points FROM ko_champion_pick cp WHERE cp.user_id = p.id), 0)
          ELSE 0
        END AS cum_points
  FROM profiles p
  CROSS JOIN finished_games fg
  LEFT JOIN game_points gp ON gp.user_id = p.id
  WHERE p.participate_in_ranking = true
    AND p.knockout_unlocked = true
  GROUP BY p.id, fg.game_no
)
SELECT
  user_id,
  game_no,
  cum_points,
  RANK() OVER (PARTITION BY game_no ORDER BY cum_points DESC) AS rank
FROM cum;


-- ── 2) EVOLUÇÃO POR DIA ───────────────────────────────────────────────────────
CREATE OR REPLACE VIEW ko_user_day_evolution
WITH (security_invoker = on) AS
WITH day_points AS (
  SELECT
    b.user_id,
    (m.match_date AT TIME ZONE 'America/Sao_Paulo')::date AS match_day,
    SUM(b.points) AS pts
  FROM ko_bet b
  JOIN ko_match m ON m.id = b.ko_match_id
  WHERE m.match_no BETWEEN 73 AND 104
  GROUP BY b.user_id, (m.match_date AT TIME ZONE 'America/Sao_Paulo')::date
),
finished_days AS (
  SELECT DISTINCT (m.match_date AT TIME ZONE 'America/Sao_Paulo')::date AS match_day
  FROM ko_match m
  WHERE m.status = 'finished'
    AND m.match_no BETWEEN 73 AND 104
),
champ AS (
  -- dia da final SE já decidida (senão NULL → bônus nunca soma).
  SELECT (m.match_date AT TIME ZONE 'America/Sao_Paulo')::date AS final_day
  FROM ko_match m
  WHERE m.round = 'final'
    AND m.status = 'finished'
    AND m.advancing_team_id IS NOT NULL
  LIMIT 1
),
cum AS (
  SELECT
    p.id AS user_id,
    fd.match_day,
    COALESCE(SUM(dp.pts) FILTER (WHERE dp.match_day <= fd.match_day), 0)
      + CASE
          WHEN (SELECT final_day FROM champ) IS NOT NULL
           AND fd.match_day >= (SELECT final_day FROM champ)
          THEN COALESCE((SELECT cp.points FROM ko_champion_pick cp WHERE cp.user_id = p.id), 0)
          ELSE 0
        END AS cum_points
  FROM profiles p
  CROSS JOIN finished_days fd
  LEFT JOIN day_points dp ON dp.user_id = p.id
  WHERE p.participate_in_ranking = true
    AND p.knockout_unlocked = true
  GROUP BY p.id, fd.match_day
)
SELECT
  user_id,
  match_day,
  cum_points,
  RANK() OVER (PARTITION BY match_day ORDER BY cum_points DESC) AS rank
FROM cum;


GRANT SELECT ON ko_user_game_evolution, ko_user_day_evolution TO anon, authenticated;


-- ═════════════════════════════════════════════════════════════════════════════
-- VERIFICAÇÃO (opcional):
--   SELECT game_no, count(*) FROM ko_user_game_evolution GROUP BY game_no ORDER BY game_no;
--   -- cada game_no finalizado lista o nº de participantes do mata-mata.
--   SELECT game_no, cum_points, rank FROM ko_user_game_evolution
--     WHERE user_id = '<seu uuid>' ORDER BY game_no;
--   -- cum_points monotônico; o ÚLTIMO game_no deve bater com ko_user_rankings:
--   SELECT e.cum_points AS evol_final, r.total_points AS ranking
--   FROM ko_user_game_evolution e
--   JOIN ko_user_rankings r ON r.user_id = e.user_id
--   WHERE e.game_no = (SELECT max(game_no) FROM ko_user_game_evolution)
--   ORDER BY r.rank;   -- evol_final == ranking p/ todos.
-- ═════════════════════════════════════════════════════════════════════════════
