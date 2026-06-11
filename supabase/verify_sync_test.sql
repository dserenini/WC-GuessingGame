-- =============================================================================
-- VERIFICAÇÃO do teste do sincronizador (modo shadow) — rode APÓS o jogo
--
-- Objetivo: confirmar que a Edge Function (1) casou o jogo certo, (2) capturou o
-- placar/encerramento corretamente. Compare o que o shadow registrou com o
-- resultado REAL que você lançou manualmente no admin.
-- =============================================================================

-- 1) O que o sincronizador (shadow) leu para o jogo do México (mais recente no topo):
SELECT ran_at, group_letter, home_team, away_team,
       src_home_score, src_away_score, src_status, src_time_elapsed
FROM api_sync_runs
WHERE home_team = 'México' OR away_team = 'México'
ORDER BY ran_at DESC
LIMIT 10;

-- 2) Resultado REAL lançado por você (admin) para os jogos do México no grupo A:
SELECT h.name AS mandante, a.name AS visitante,
       m.home_score, m.away_score, m.status, m.match_date
FROM matches m
JOIN teams h ON h.id = m.home_team_id
JOIN teams a ON a.id = m.away_team_id
WHERE m.group_letter = 'A' AND (h.name = 'México' OR a.name = 'México')
ORDER BY m.match_date;

-- ✅ TESTE OK se, no jogo já encerrado, o placar/orientação da consulta (1)
--    bater com a consulta (2) e src_status = 'finished'.

-- 3) Panorama geral de tudo que o shadow capturou hoje (ao vivo/encerrado):
SELECT ran_at, group_letter, home_team, away_team,
       src_home_score, src_away_score, src_status
FROM api_sync_runs
WHERE mode = 'shadow'
ORDER BY ran_at DESC
LIMIT 50;
