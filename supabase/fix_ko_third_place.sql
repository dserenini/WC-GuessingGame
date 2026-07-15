-- =============================================================================
-- FIX: disputa de 3º lugar deve receber os PERDEDORES das semis (não o vencedor).
-- Bug: propagateKnockout (Edge Function sync-scores) mandava o advancing
-- (vencedor) para TODOS os destinos, inclusive o 3lugar — a Espanha (vencedora
-- da semi 1) apareceu no 3º lugar além da final.
--
-- ORDEM IMPORTA:
--   1º) Deploy da Edge Function corrigida (supabase functions deploy sync-scores)
--       — senão o cron re-preenche o time errado em até 3 min.
--   2º) Rodar este SQL na PROD (SQL editor).
--
-- Idempotente: recalcula os dois lados do 3lugar a partir das semis finalizadas;
-- semi ainda não decidida → lado volta a NULL (mostra "Perd. Jogo X" no app).
-- =============================================================================

UPDATE ko_match t SET
  home_team_id = (
    SELECT CASE WHEN s.advancing_team_id = s.home_team_id
                THEN s.away_team_id ELSE s.home_team_id END
    FROM ko_match s
    WHERE s.id = t.home_src_match
      AND s.status = 'finished' AND s.advancing_team_id IS NOT NULL
  ),
  away_team_id = (
    SELECT CASE WHEN s.advancing_team_id = s.home_team_id
                THEN s.away_team_id ELSE s.home_team_id END
    FROM ko_match s
    WHERE s.id = t.away_src_match
      AND s.status = 'finished' AND s.advancing_team_id IS NOT NULL
  )
WHERE t.round = '3lugar';

-- ── Conferência 1: 3º lugar deve mostrar o PERDEDOR da(s) semi(s) decidida(s) ──
SELECT t.round, t.slot,
       h.name AS home, a.name AS away,
       t.home_slot_label, t.away_slot_label
FROM ko_match t
LEFT JOIN teams h ON h.id = t.home_team_id
LEFT JOIN teams a ON a.id = t.away_team_id
WHERE t.round IN ('3lugar', 'final');

-- ── Conferência 2: pontuação do 3º lugar é 3/1 (fora do reforço 5/3) ──────────
-- A função deve conter: is_finals := NEW.round IN ('semis','final')
-- ('3lugar' NÃO está na lista → usa points 3/1). Confirme no corpo abaixo:
SELECT pg_get_functiondef('score_ko_match'::regproc);
