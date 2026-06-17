-- =============================================================================
-- BRACKET DE EXEMPLO — APENAS STAGING. NÃO RODAR EM PRODUÇÃO.
--   Cria os 32 jogos do mata-mata 2026 (16avos→final + 3º lugar) com a árvore
--   do chaveamento ligada, p/ desenvolver/visualizar a UI. Times reais (já temos
--   48), datas no futuro (apostas abertas). Idempotente: limpa e recria.
-- =============================================================================

DELETE FROM ko_match;  -- casc;ata ko_bet / ko_bracket_pick (sem dados reais no staging)

-- 16avos: 16 jogos, 32 primeiras seleções (por nome), em pares
WITH t AS (SELECT id, row_number() OVER (ORDER BY name) rn FROM teams)
INSERT INTO ko_match (round, slot, home_team_id, away_team_id, match_date, status)
SELECT '16avos', g,
       (SELECT id FROM t WHERE rn = g*2 - 1),
       (SELECT id FROM t WHERE rn = g*2),
       now() + interval '2 days' + (g * interval '4 hours'),
       'scheduled'
FROM generate_series(1,16) g;

-- Rodadas seguintes: confrontos a definir (times nulos), datas escalonadas
INSERT INTO ko_match (round, slot, match_date, status)
SELECT 'oitavas', g, now() + interval '7 days'  + (g * interval '4 hours'), 'scheduled' FROM generate_series(1,8) g;
INSERT INTO ko_match (round, slot, match_date, status)
SELECT 'quartas', g, now() + interval '11 days' + (g * interval '6 hours'), 'scheduled' FROM generate_series(1,4) g;
INSERT INTO ko_match (round, slot, match_date, status)
SELECT 'semis', g, now() + interval '14 days' + (g * interval '24 hours'), 'scheduled' FROM generate_series(1,2) g;
INSERT INTO ko_match (round, slot, match_date, status) VALUES
  ('3lugar', 1, now() + interval '17 days', 'scheduled'),
  ('final',  1, now() + interval '18 days', 'scheduled');

-- Liga a árvore: cada jogo recebe os vencedores dos dois jogos anteriores
UPDATE ko_match o SET
  home_src_match = (SELECT id FROM ko_match WHERE round='16avos' AND slot = o.slot*2 - 1),
  away_src_match = (SELECT id FROM ko_match WHERE round='16avos' AND slot = o.slot*2)
WHERE o.round = 'oitavas';

UPDATE ko_match q SET
  home_src_match = (SELECT id FROM ko_match WHERE round='oitavas' AND slot = q.slot*2 - 1),
  away_src_match = (SELECT id FROM ko_match WHERE round='oitavas' AND slot = q.slot*2)
WHERE q.round = 'quartas';

UPDATE ko_match s SET
  home_src_match = (SELECT id FROM ko_match WHERE round='quartas' AND slot = s.slot*2 - 1),
  away_src_match = (SELECT id FROM ko_match WHERE round='quartas' AND slot = s.slot*2)
WHERE s.round = 'semis';

UPDATE ko_match f SET
  home_src_match = (SELECT id FROM ko_match WHERE round='semis' AND slot=1),
  away_src_match = (SELECT id FROM ko_match WHERE round='semis' AND slot=2)
WHERE f.round = 'final' AND f.slot = 1;

-- Liga o app: mostra o mata-mata no staging
UPDATE app_config SET value = jsonb_set(value, '{enabled}', 'true'), updated_at = now()
WHERE key = 'knockout';

-- ─────────────────────────────────────────────────────────────────────────────
-- (DEMO) Simula resultados: 16avos→quartas "jogados", semis com classificados,
-- pra ver o bracket preenchido e a animação de progressão.
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE ko_match SET
  home_score = CASE WHEN slot % 4 = 0 THEN 0 ELSE 2 END,
  away_score = 1, status = 'finished',
  advancing_team_id = CASE WHEN slot % 4 = 0 THEN away_team_id ELSE home_team_id END
WHERE round = '16avos';

UPDATE ko_match o SET
  home_team_id = (SELECT advancing_team_id FROM ko_match WHERE round='16avos' AND slot=o.slot*2-1),
  away_team_id = (SELECT advancing_team_id FROM ko_match WHERE round='16avos' AND slot=o.slot*2)
WHERE o.round = 'oitavas';
UPDATE ko_match SET
  home_score = CASE WHEN slot % 3 = 0 THEN 1 ELSE 3 END,
  away_score = CASE WHEN slot % 3 = 0 THEN 2 ELSE 1 END, status='finished',
  advancing_team_id = CASE WHEN slot % 3 = 0 THEN away_team_id ELSE home_team_id END
WHERE round = 'oitavas';

UPDATE ko_match q SET
  home_team_id = (SELECT advancing_team_id FROM ko_match WHERE round='oitavas' AND slot=q.slot*2-1),
  away_team_id = (SELECT advancing_team_id FROM ko_match WHERE round='oitavas' AND slot=q.slot*2)
WHERE q.round = 'quartas';
UPDATE ko_match SET home_score=2, away_score=0, status='finished', advancing_team_id=home_team_id
WHERE round='quartas';

UPDATE ko_match s SET
  home_team_id = (SELECT advancing_team_id FROM ko_match WHERE round='quartas' AND slot=s.slot*2-1),
  away_team_id = (SELECT advancing_team_id FROM ko_match WHERE round='quartas' AND slot=s.slot*2)
WHERE s.round = 'semis';

-- ─────────────────────────────────────────────────────────────────────────────
-- (DEMO) Apostas de 15 usuários nos jogos com times definidos, com acertos
-- variados (cravado / direção / erro), pra popular o RANKING do mata-mata.
-- ─────────────────────────────────────────────────────────────────────────────
WITH u AS (
  SELECT id, row_number() OVER (ORDER BY (username = 'dserenini') DESC, username) AS rn
  FROM profiles
  WHERE participate_in_ranking = true
  LIMIT 15
)
INSERT INTO ko_bet (user_id, ko_match_id, home_score_bet, away_score_bet)
SELECT u.id, m.id,
  CASE WHEN m.home_score IS NULL THEN 1
       WHEN (u.rn % 3) = 0 THEN m.home_score       -- cravado (3)
       WHEN (u.rn % 3) = 1 THEN m.home_score + 1   -- mesma direção (1)
       ELSE m.away_score END,                      -- invertido (0)
  CASE WHEN m.away_score IS NULL THEN 0
       WHEN (u.rn % 3) = 0 THEN m.away_score
       WHEN (u.rn % 3) = 1 THEN m.away_score + 1
       ELSE m.home_score END
FROM u
CROSS JOIN ko_match m
WHERE m.home_team_id IS NOT NULL
  AND m.round IN ('16avos','oitavas','quartas','semis')
ON CONFLICT (user_id, ko_match_id) DO NOTHING;

-- Recalcula a pontuação dos palpites nos jogos já encerrados (dispara o trigger).
UPDATE ko_match SET status = 'finished' WHERE status = 'finished';
