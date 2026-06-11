-- =============================================================================
-- FIX — contagem de apostas no ranking das LIGAS PRIVADAS
--
-- A view league_rankings não calculava total_bets, então o app sempre mostrava
-- "0 apostas" para todos os membros de uma liga. Esta versão adiciona
-- COUNT(b.id) AS total_bets.
--
-- Obs.: total_bets é a ÚLTIMA coluna de propósito — CREATE OR REPLACE VIEW só
-- permite acrescentar colunas no fim (não inserir no meio). O app lê por nome,
-- então a ordem não importa.
--
-- Rode uma vez no SQL Editor da produção.
-- =============================================================================

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
  RANK() OVER (PARTITION BY lm.league_id ORDER BY COALESCE(SUM(b.points), 0) DESC) AS rank,
  COUNT(b.id) AS total_bets
FROM league_members lm
JOIN leagues l ON l.id = lm.league_id
JOIN profiles p ON p.id = lm.user_id
LEFT JOIN bets b ON b.user_id = lm.user_id
GROUP BY lm.league_id, l.name, p.id, p.username, p.full_name, p.display_preference, p.avatar_url;
