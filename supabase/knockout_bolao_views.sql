-- =============================================================================
-- BOLÃO MATA-MATA — views da modalidade "Bolão" das Estatísticas Avançadas.
--   Agregam os palpites de placar (ko_bet) de TODOS os participantes (as views
--   rodam com os privilégios do dono, então passam por cima do RLS de ko_bet,
--   igual às views score_popularity / match_predictability da fase de grupos).
--   ADITIVO e idempotente. Rode no SQL editor da PROD.
-- =============================================================================

-- Distribuição de placares apostados no mata-mata (quantas vezes cada placar foi
-- apostado, no agregado). Mesmo shape de score_popularity.
CREATE OR REPLACE VIEW ko_score_popularity AS
  SELECT home_score_bet, away_score_bet, count(*) AS n
  FROM ko_bet
  GROUP BY home_score_bet, away_score_bet;

-- Previsibilidade por jogo FINALIZADO do mata-mata: quantos cravaram o placar e
-- quantos apostaram no total. Mesmo shape de match_predictability.
CREATE OR REPLACE VIEW ko_match_predictability AS
  SELECT b.ko_match_id AS match_id,
         count(*) FILTER (WHERE b.exact) AS exact_count,
         count(*)                        AS total_bets
  FROM ko_bet b
  JOIN ko_match m ON m.id = b.ko_match_id
  WHERE m.status = 'finished'
  GROUP BY b.ko_match_id;

GRANT SELECT ON ko_score_popularity, ko_match_predictability TO anon, authenticated;
