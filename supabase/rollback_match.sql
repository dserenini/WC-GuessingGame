-- =============================================================================
-- 🚨 ROLLBACK DE PARTIDA — Script de Emergência
-- =============================================================================
-- Use este script no Supabase SQL Editor quando um placar for registrado
-- incorretamente e os pontos das apostas precisarem ser recalculados.
--
-- IMPORTANTE: Você precisa estar logado como ADMIN para executar.
-- =============================================================================

-- ─────────────────────────────────────────────
-- PASSO 1: Encontrar o ID da partida com problema
-- ─────────────────────────────────────────────
-- Liste as partidas finalizadas recentemente:
SELECT
  m.id,
  m.api_match_id,
  t1.name AS mandante,
  t2.name AS visitante,
  m.home_score,
  m.away_score,
  m.status,
  m.match_date
FROM matches m
JOIN teams t1 ON t1.id = m.home_team_id
JOIN teams t2 ON t2.id = m.away_team_id
WHERE m.status = 'finished'
ORDER BY m.match_date DESC
LIMIT 10;

-- ─────────────────────────────────────────────
-- PASSO 2: Executar o rollback
-- ─────────────────────────────────────────────
-- Substitua 'MATCH_ID_AQUI' pelo UUID da partida:

-- SELECT * FROM rollback_match_scoring('MATCH_ID_AQUI');

-- Exemplo:
-- SELECT * FROM rollback_match_scoring('a1b2c3d4-e5f6-7890-abcd-ef1234567890');
--
-- Retorno esperado:
-- match_reset | bets_affected | old_home | old_away | old_status
-- true        | 42            | 2        | 1        | finished

-- ─────────────────────────────────────────────
-- PASSO 3: Verificar o audit log
-- ─────────────────────────────────────────────
-- Veja o que foi alterado pelo rollback:
SELECT
  table_name,
  record_id,
  operation,
  old_data,
  new_data,
  changed_at
FROM audit_log
WHERE changed_at > NOW() - INTERVAL '1 hour'
ORDER BY changed_at DESC;

-- ─────────────────────────────────────────────
-- PASSO 4: Reprocessar com o placar correto
-- ─────────────────────────────────────────────
-- Após o rollback, o match volta para status 'scheduled'.
-- Basta enviar o placar correto via CSV/Admin Panel
-- e o trigger calculate_bet_points() recalculará os pontos.

-- Ou manualmente:
-- UPDATE matches
--   SET home_score = X, away_score = Y, status = 'finished'
--   WHERE id = 'MATCH_ID_AQUI';

-- ─────────────────────────────────────────────
-- CONSULTAS ÚTEIS DE AUDITORIA
-- ─────────────────────────────────────────────

-- Ver todas as alterações de uma partida específica:
-- SELECT * FROM audit_log
--   WHERE table_name = 'matches' AND record_id = 'MATCH_ID_AQUI'
--   ORDER BY changed_at DESC;

-- Ver todas as alterações de apostas de uma partida:
-- SELECT * FROM audit_log
--   WHERE table_name = 'bets'
--     AND new_data->>'match_id' = 'MATCH_ID_AQUI'
--   ORDER BY changed_at DESC;

-- Ver quem fez alterações hoje:
-- SELECT changed_by, table_name, operation, COUNT(*)
--   FROM audit_log
--   WHERE changed_at > CURRENT_DATE
--   GROUP BY changed_by, table_name, operation
--   ORDER BY COUNT(*) DESC;
