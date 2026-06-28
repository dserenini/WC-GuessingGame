-- =============================================================================
-- ANÁLISE: impacto das trocas de palpite (Super Palpite) no placar dos usuários
-- =============================================================================
--
-- Pergunta: quando o usuário trocou um palpite depois do prazo (Super Palpite),
-- ele GANHOU ou PERDEU pontos com a troca?
--
-- Como funciona:
--  - O app salva apostas via upsert, então a tabela `bets` só tem o placar FINAL.
--  - Mas o trigger `audit_bets` grava TODA alteração em `audit_log`
--    (old_data = placar anterior, new_data = placar novo, changed_at = quando).
--  - Prazo global do Super Palpite: 2026-06-11 17:30:00+00 UTC (= 11/06 14:30 GMT-3,
--    valor informado/confirmado; NÃO bate com super_palpite.sql do repo, que está
--    desatualizado). Toda alteração de PLACAR depois disso é uma troca via Super Palpite.
--
-- Definições usadas:
--  - palpite ORIGINAL  = old_data da PRIMEIRA troca pós-prazo do jogo
--                        (= placar que estava travado no prazo, antes do 1º Super Palpite)
--  - palpite FINAL     = estado atual em `bets` (resultado líquido de todas as trocas)
--  - pontos            = regra do sistema: 3 (placar exato) / 1 (acertou o resultado) / 0
--
-- Observações:
--  - Só conta jogos JÁ FINALIZADOS (status='finished'), senão não há resultado real.
--  - INSERTs novos após o prazo (quem só palpitou depois) são ignorados:
--    não havia palpite anterior para comparar.
--  - Cobre apenas a competição principal (`bets`). O Mata-Mata usa outra tabela
--    (ko_bet) com regra própria e NÃO entra nesta análise.
--  - Rode logado como ADMIN (RLS de audit_log exige is_admin()).
-- =============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOCO BASE (reutilizado pelas 3 consultas abaixo).
-- Cada consulta repete o WITH porque CTEs não cruzam statements no SQL Editor.
-- ─────────────────────────────────────────────────────────────────────────────


-- =============================================================================
-- CONSULTA 1 — RESUMO POR USUÁRIO + TOTAL GERAL (use esta para a visão principal)
-- =============================================================================
WITH params AS (
  SELECT TIMESTAMPTZ '2026-06-11 17:30:00+00' AS deadline
),
super_changes AS (  -- toda troca REAL de placar após o prazo
  SELECT
    (a.new_data->>'user_id')::uuid       AS user_id,
    (a.new_data->>'match_id')::uuid      AS match_id,
    (a.old_data->>'home_score_bet')::int AS old_home,
    (a.old_data->>'away_score_bet')::int AS old_away,
    a.changed_at,
    ROW_NUMBER() OVER (
      PARTITION BY a.new_data->>'user_id', a.new_data->>'match_id'
      ORDER BY a.changed_at ASC
    ) AS rn
  FROM audit_log a CROSS JOIN params p
  WHERE a.table_name = 'bets'
    AND a.operation  = 'UPDATE'
    AND a.changed_at > p.deadline
    AND ( a.old_data->>'home_score_bet' IS DISTINCT FROM a.new_data->>'home_score_bet'
       OR a.old_data->>'away_score_bet' IS DISTINCT FROM a.new_data->>'away_score_bet' )
),
original_bet AS (  -- placar travado no prazo = old_data da 1ª troca
  SELECT user_id, match_id, old_home, old_away
  FROM super_changes
  WHERE rn = 1
),
scored AS (
  SELECT
    o.user_id,
    o.match_id,
    -- pontos do palpite ORIGINAL (se NÃO tivesse trocado)
    CASE
      WHEN o.old_home = m.home_score AND o.old_away = m.away_score THEN 3
      WHEN o.old_home > o.old_away AND m.home_score > m.away_score THEN 1
      WHEN o.old_home < o.old_away AND m.home_score < m.away_score THEN 1
      WHEN o.old_home = o.old_away AND m.home_score = m.away_score THEN 1
      ELSE 0
    END AS orig_points,
    -- pontos do palpite FINAL (depois da troca)
    CASE
      WHEN b.home_score_bet = m.home_score AND b.away_score_bet = m.away_score THEN 3
      WHEN b.home_score_bet > b.away_score_bet AND m.home_score > m.away_score THEN 1
      WHEN b.home_score_bet < b.away_score_bet AND m.home_score < m.away_score THEN 1
      WHEN b.home_score_bet = b.away_score_bet AND m.home_score = m.away_score THEN 1
      ELSE 0
    END AS final_points
  FROM original_bet o
  JOIN bets    b ON b.user_id = o.user_id AND b.match_id = o.match_id
  JOIN matches m ON m.id = o.match_id
  WHERE m.status = 'finished' AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
)
SELECT
  COALESCE(pr.username, '➤➤ TOTAL GERAL') AS usuario,
  COUNT(*)                                        AS jogos_trocados,
  SUM(s.orig_points)                              AS pts_se_nao_trocasse,
  SUM(s.final_points)                             AS pts_com_a_troca,
  SUM(s.final_points - s.orig_points)             AS saldo,  -- + ganhou / - perdeu
  SUM((s.final_points > s.orig_points)::int)      AS trocas_que_ganharam,
  SUM((s.final_points < s.orig_points)::int)      AS trocas_que_perderam,
  SUM((s.final_points = s.orig_points)::int)      AS trocas_neutras
FROM scored s
LEFT JOIN profiles pr ON pr.id = s.user_id
GROUP BY ROLLUP (pr.username)
ORDER BY (pr.username IS NULL), saldo DESC;


-- =============================================================================
-- CONSULTA 2 — DETALHE POR JOGO (auditar casos específicos, ex: #15, #48)
-- =============================================================================
WITH params AS (
  SELECT TIMESTAMPTZ '2026-06-11 17:30:00+00' AS deadline
),
super_changes AS (
  SELECT
    (a.new_data->>'user_id')::uuid       AS user_id,
    (a.new_data->>'match_id')::uuid      AS match_id,
    (a.old_data->>'home_score_bet')::int AS old_home,
    (a.old_data->>'away_score_bet')::int AS old_away,
    a.changed_at,
    ROW_NUMBER() OVER (
      PARTITION BY a.new_data->>'user_id', a.new_data->>'match_id'
      ORDER BY a.changed_at ASC
    ) AS rn
  FROM audit_log a CROSS JOIN params p
  WHERE a.table_name = 'bets'
    AND a.operation  = 'UPDATE'
    AND a.changed_at > p.deadline
    AND ( a.old_data->>'home_score_bet' IS DISTINCT FROM a.new_data->>'home_score_bet'
       OR a.old_data->>'away_score_bet' IS DISTINCT FROM a.new_data->>'away_score_bet' )
),
original_bet AS (
  SELECT user_id, match_id, old_home, old_away
  FROM super_changes WHERE rn = 1
)
SELECT
  pr.username                                              AS usuario,
  m.api_match_id                                           AS jogo,        -- nº 1..72
  ht.name || ' x ' || at.name                              AS confronto,
  o.old_home || '-' || o.old_away                          AS palpite_original,
  b.home_score_bet || '-' || b.away_score_bet              AS palpite_final,
  m.home_score || '-' || m.away_score                      AS resultado_real,
  CASE
    WHEN o.old_home = m.home_score AND o.old_away = m.away_score THEN 3
    WHEN o.old_home > o.old_away AND m.home_score > m.away_score THEN 1
    WHEN o.old_home < o.old_away AND m.home_score < m.away_score THEN 1
    WHEN o.old_home = o.old_away AND m.home_score = m.away_score THEN 1
    ELSE 0
  END                                                      AS pts_original,
  b.points                                                 AS pts_final,
  b.points - (CASE
    WHEN o.old_home = m.home_score AND o.old_away = m.away_score THEN 3
    WHEN o.old_home > o.old_away AND m.home_score > m.away_score THEN 1
    WHEN o.old_home < o.old_away AND m.home_score < m.away_score THEN 1
    WHEN o.old_home = o.old_away AND m.home_score = m.away_score THEN 1
    ELSE 0
  END)                                                     AS saldo
FROM original_bet o
JOIN bets    b  ON b.user_id = o.user_id AND b.match_id = o.match_id
JOIN matches m  ON m.id = o.match_id
JOIN teams   ht ON ht.id = m.home_team_id
JOIN teams   at ON at.id = m.away_team_id
JOIN profiles pr ON pr.id = o.user_id
WHERE m.status = 'finished' AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
ORDER BY pr.username, m.api_match_id;


-- =============================================================================
-- CONSULTA 3 — RESUMO POR JOGO (quais partidas a galera mais ganhou/perdeu trocando)
-- =============================================================================
WITH params AS (
  SELECT TIMESTAMPTZ '2026-06-11 17:30:00+00' AS deadline
),
super_changes AS (
  SELECT
    (a.new_data->>'user_id')::uuid       AS user_id,
    (a.new_data->>'match_id')::uuid      AS match_id,
    (a.old_data->>'home_score_bet')::int AS old_home,
    (a.old_data->>'away_score_bet')::int AS old_away,
    a.changed_at,
    ROW_NUMBER() OVER (
      PARTITION BY a.new_data->>'user_id', a.new_data->>'match_id'
      ORDER BY a.changed_at ASC
    ) AS rn
  FROM audit_log a CROSS JOIN params p
  WHERE a.table_name = 'bets'
    AND a.operation  = 'UPDATE'
    AND a.changed_at > p.deadline
    AND ( a.old_data->>'home_score_bet' IS DISTINCT FROM a.new_data->>'home_score_bet'
       OR a.old_data->>'away_score_bet' IS DISTINCT FROM a.new_data->>'away_score_bet' )
),
original_bet AS (
  SELECT user_id, match_id, old_home, old_away
  FROM super_changes WHERE rn = 1
),
scored AS (
  SELECT
    o.match_id,
    CASE
      WHEN o.old_home = m.home_score AND o.old_away = m.away_score THEN 3
      WHEN o.old_home > o.old_away AND m.home_score > m.away_score THEN 1
      WHEN o.old_home < o.old_away AND m.home_score < m.away_score THEN 1
      WHEN o.old_home = o.old_away AND m.home_score = m.away_score THEN 1
      ELSE 0
    END AS orig_points,
    b.points AS final_points
  FROM original_bet o
  JOIN bets    b ON b.user_id = o.user_id AND b.match_id = o.match_id
  JOIN matches m ON m.id = o.match_id
  WHERE m.status = 'finished' AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
)
SELECT
  m.api_match_id                                AS jogo,
  ht.name || ' x ' || at.name                   AS confronto,
  m.home_score || '-' || m.away_score           AS resultado_real,
  COUNT(*)                                       AS qtd_trocas,
  SUM(s.final_points - s.orig_points)            AS saldo_total,  -- + galera ganhou / - perdeu
  SUM((s.final_points > s.orig_points)::int)     AS ganharam,
  SUM((s.final_points < s.orig_points)::int)     AS perderam
FROM scored s
JOIN matches m  ON m.id = s.match_id
JOIN teams   ht ON ht.id = m.home_team_id
JOIN teams   at ON at.id = m.away_team_id
GROUP BY m.api_match_id, ht.name, at.name, m.home_score, m.away_score
ORDER BY saldo_total DESC;


-- =============================================================================
-- CONSULTA 4 — MESMA VISÃO DA CONSULTA 1, PARA UM USUÁRIO ESPECÍFICO
-- >>> EDITE o nome do usuário na linha "target_user" abaixo. <<<
-- (use o username exato; a busca é case-insensitive via ILIKE)
-- =============================================================================
WITH params AS (
  SELECT
    TIMESTAMPTZ '2026-06-11 17:30:00+00' AS deadline,
    'NOME_DO_USUARIO'                    AS target_user   -- <<< TROQUE AQUI
),
super_changes AS (
  SELECT
    (a.new_data->>'user_id')::uuid       AS user_id,
    (a.new_data->>'match_id')::uuid      AS match_id,
    (a.old_data->>'home_score_bet')::int AS old_home,
    (a.old_data->>'away_score_bet')::int AS old_away,
    a.changed_at,
    ROW_NUMBER() OVER (
      PARTITION BY a.new_data->>'user_id', a.new_data->>'match_id'
      ORDER BY a.changed_at ASC
    ) AS rn
  FROM audit_log a CROSS JOIN params p
  WHERE a.table_name = 'bets'
    AND a.operation  = 'UPDATE'
    AND a.changed_at > p.deadline
    AND ( a.old_data->>'home_score_bet' IS DISTINCT FROM a.new_data->>'home_score_bet'
       OR a.old_data->>'away_score_bet' IS DISTINCT FROM a.new_data->>'away_score_bet' )
),
original_bet AS (
  SELECT user_id, match_id, old_home, old_away
  FROM super_changes WHERE rn = 1
),
scored AS (
  SELECT
    o.user_id,
    CASE
      WHEN o.old_home = m.home_score AND o.old_away = m.away_score THEN 3
      WHEN o.old_home > o.old_away AND m.home_score > m.away_score THEN 1
      WHEN o.old_home < o.old_away AND m.home_score < m.away_score THEN 1
      WHEN o.old_home = o.old_away AND m.home_score = m.away_score THEN 1
      ELSE 0
    END AS orig_points,
    b.points AS final_points
  FROM original_bet o
  JOIN bets    b ON b.user_id = o.user_id AND b.match_id = o.match_id
  JOIN matches m ON m.id = o.match_id
  WHERE m.status = 'finished' AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
)
SELECT
  pr.username                                AS usuario,
  COUNT(*)                                   AS jogos_trocados,
  SUM(s.orig_points)                         AS pts_se_nao_trocasse,
  SUM(s.final_points)                        AS pts_com_a_troca,
  SUM(s.final_points - s.orig_points)        AS saldo,
  SUM((s.final_points > s.orig_points)::int) AS trocas_que_ganharam,
  SUM((s.final_points < s.orig_points)::int) AS trocas_que_perderam,
  SUM((s.final_points = s.orig_points)::int) AS trocas_neutras
FROM scored s
JOIN profiles pr ON pr.id = s.user_id
CROSS JOIN params p
WHERE pr.username ILIKE p.target_user
GROUP BY pr.username
ORDER BY pr.username;


-- =============================================================================
-- CONSULTA 5 — MESMA VISÃO DA CONSULTA 1, RESTRITA AOS MEMBROS DE UMA LIGA
-- >>> EDITE o nome da liga na linha "target_league" abaixo. <<<
-- (busca case-insensitive; aceita parte do nome via ILIKE com %)
-- Retorna uma linha por usuário da liga + linha "➤➤ TOTAL DA LIGA".
-- =============================================================================
WITH params AS (
  SELECT
    TIMESTAMPTZ '2026-06-11 17:30:00+00' AS deadline,
    'NOME_DA_LIGA'                       AS target_league  -- <<< TROQUE AQUI
),
league_users AS (  -- usuários membros da(s) liga(s) que casam com o nome
  SELECT DISTINCT lm.user_id
  FROM league_members lm
  JOIN leagues l ON l.id = lm.league_id
  CROSS JOIN params p
  WHERE l.name ILIKE p.target_league
),
super_changes AS (
  SELECT
    (a.new_data->>'user_id')::uuid       AS user_id,
    (a.new_data->>'match_id')::uuid      AS match_id,
    (a.old_data->>'home_score_bet')::int AS old_home,
    (a.old_data->>'away_score_bet')::int AS old_away,
    a.changed_at,
    ROW_NUMBER() OVER (
      PARTITION BY a.new_data->>'user_id', a.new_data->>'match_id'
      ORDER BY a.changed_at ASC
    ) AS rn
  FROM audit_log a CROSS JOIN params p
  WHERE a.table_name = 'bets'
    AND a.operation  = 'UPDATE'
    AND a.changed_at > p.deadline
    AND ( a.old_data->>'home_score_bet' IS DISTINCT FROM a.new_data->>'home_score_bet'
       OR a.old_data->>'away_score_bet' IS DISTINCT FROM a.new_data->>'away_score_bet' )
),
original_bet AS (
  SELECT user_id, match_id, old_home, old_away
  FROM super_changes WHERE rn = 1
),
scored AS (
  SELECT
    o.user_id,
    CASE
      WHEN o.old_home = m.home_score AND o.old_away = m.away_score THEN 3
      WHEN o.old_home > o.old_away AND m.home_score > m.away_score THEN 1
      WHEN o.old_home < o.old_away AND m.home_score < m.away_score THEN 1
      WHEN o.old_home = o.old_away AND m.home_score = m.away_score THEN 1
      ELSE 0
    END AS orig_points,
    b.points AS final_points
  FROM original_bet o
  JOIN bets    b ON b.user_id = o.user_id AND b.match_id = o.match_id
  JOIN matches m ON m.id = o.match_id
  WHERE m.status = 'finished' AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
)
SELECT
  COALESCE(pr.username, '➤➤ TOTAL DA LIGA') AS usuario,
  COUNT(*)                                   AS jogos_trocados,
  SUM(s.orig_points)                         AS pts_se_nao_trocasse,
  SUM(s.final_points)                        AS pts_com_a_troca,
  SUM(s.final_points - s.orig_points)        AS saldo,
  SUM((s.final_points > s.orig_points)::int) AS trocas_que_ganharam,
  SUM((s.final_points < s.orig_points)::int) AS trocas_que_perderam,
  SUM((s.final_points = s.orig_points)::int) AS trocas_neutras
FROM scored s
JOIN league_users lu ON lu.user_id = s.user_id   -- só membros da liga
LEFT JOIN profiles pr ON pr.id = s.user_id
GROUP BY ROLLUP (pr.username)
ORDER BY (pr.username IS NULL), saldo DESC;


-- =============================================================================
-- CONSULTA 6 — HISTÓRICO DE TODAS AS TROCAS DE UM USUÁRIO (uma linha por troca)
-- >>> EDITE o nome do usuário na linha "target_user" abaixo. <<<
--
-- Mostra CADA evento de troca (não colapsa por jogo). Útil para entender por que
-- "jogos_trocados" (jogos distintos) é menor que o nº de Super Palpites usados:
-- um jogo trocado 2x conta como 2 Super Palpites, mas 1 jogo na Consulta 4.
-- Agrupado por jogo e em ordem cronológica dentro de cada jogo.
-- =============================================================================
WITH params AS (
  SELECT
    TIMESTAMPTZ '2026-06-11 17:30:00+00' AS deadline,
    'NOME_DO_USUARIO'                    AS target_user   -- <<< TROQUE AQUI
)
SELECT
  m.api_match_id                                          AS jogo,         -- nº 1..72
  ht.name || ' x ' || at.name                             AS confronto,
  (a.old_data->>'home_score_bet') || '-' ||
    (a.old_data->>'away_score_bet')                       AS placar_antigo,
  (a.new_data->>'home_score_bet') || '-' ||
    (a.new_data->>'away_score_bet')                       AS placar_novo,
  (a.changed_at AT TIME ZONE 'America/Sao_Paulo')         AS data_brasilia,
  CASE
    WHEN m.status = 'finished' AND m.home_score IS NOT NULL
      THEN m.home_score || '-' || m.away_score
    ELSE '— (não finalizado)'
  END                                                     AS resultado_real
FROM audit_log a
CROSS JOIN params p
JOIN profiles pr ON pr.id = (a.new_data->>'user_id')::uuid
JOIN matches  m  ON m.id  = (a.new_data->>'match_id')::uuid
JOIN teams    ht ON ht.id = m.home_team_id
JOIN teams    at ON at.id = m.away_team_id
WHERE a.table_name = 'bets'
  AND a.operation  = 'UPDATE'
  AND a.changed_at > p.deadline
  AND ( a.old_data->>'home_score_bet' IS DISTINCT FROM a.new_data->>'home_score_bet'
     OR a.old_data->>'away_score_bet' IS DISTINCT FROM a.new_data->>'away_score_bet' )
  AND pr.username ILIKE p.target_user
ORDER BY m.api_match_id, a.changed_at;


-- =============================================================================
-- CONSULTA 7 — CONFERÊNCIA: palpites criados/alterados APÓS o prazo do jogo
--
-- Prazo individual de cada jogo = match_date - 1 hora (regra do trigger,
-- super_palpite.sql:34). Em tese o trigger bloqueia isso para usuários comuns;
-- então o que aparecer aqui são anomalias a investigar: ajuste manual/admin,
-- override, ou alguma falha na regra.
--
-- Inclui:
--   - UPDATE em que o PLACAR mudou depois do prazo (ignora updates só de pontos,
--     que são a pontuação automática do sistema e legitimamente vêm após o jogo);
--   - INSERT de aposta nova feita depois do prazo.
-- `alterado_por` mostra quem fez (NULL = sistema/trigger, sem auth.uid()).
-- Não filtra usuário: é uma varredura geral. Ordenado por jogo e data.
-- =============================================================================
SELECT
  pr.username                                              AS usuario,
  m.api_match_id                                           AS jogo,
  ht.name || ' x ' || at.name                              AS confronto,
  a.operation                                              AS operacao,
  COALESCE((a.old_data->>'home_score_bet') || '-' ||
           (a.old_data->>'away_score_bet'), '(nova)')      AS placar_antigo,
  (a.new_data->>'home_score_bet') || '-' ||
    (a.new_data->>'away_score_bet')                        AS placar_novo,
  (m.match_date AT TIME ZONE 'America/Sao_Paulo')          AS inicio_jogo_brt,
  ((m.match_date - INTERVAL '1 hour') AT TIME ZONE 'America/Sao_Paulo')
                                                           AS prazo_limite_brt,
  (a.changed_at AT TIME ZONE 'America/Sao_Paulo')          AS data_alteracao_brt,
  -- quão depois do prazo a alteração aconteceu
  (a.changed_at - (m.match_date - INTERVAL '1 hour'))      AS atraso,
  cb.username                                              AS alterado_por
FROM audit_log a
JOIN matches  m  ON m.id  = (a.new_data->>'match_id')::uuid
JOIN teams    ht ON ht.id = m.home_team_id
JOIN teams    at ON at.id = m.away_team_id
JOIN profiles pr ON pr.id = (a.new_data->>'user_id')::uuid
LEFT JOIN profiles cb ON cb.id = a.changed_by
WHERE a.table_name = 'bets'
  AND a.operation IN ('INSERT', 'UPDATE')
  AND m.match_date IS NOT NULL
  AND a.changed_at > (m.match_date - INTERVAL '1 hour')   -- depois do prazo do jogo
  AND (
        a.operation = 'INSERT'
     OR ( a.old_data->>'home_score_bet' IS DISTINCT FROM a.new_data->>'home_score_bet'
       OR a.old_data->>'away_score_bet' IS DISTINCT FROM a.new_data->>'away_score_bet' )
      )
ORDER BY m.api_match_id, a.changed_at;
