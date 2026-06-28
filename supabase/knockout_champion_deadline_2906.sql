-- =============================================================================
-- MATA-MATA — fixar o PRAZO do palpite de CAMPEÃO
--   Antes: dinâmico = início do 1º jogo do mata-mata (min(match_date)).
--   Agora: FIXO em 29/06/2026 12:00 (GMT-3) = 15:00 UTC, a pedido.
--   Mantém a mesma trigger (CREATE OR REPLACE só troca o corpo da função).
--   Espelha a constante kKoChampionPickDeadline no app (gating do botão).
-- Rodar no SQL Editor da produção.
-- =============================================================================
CREATE OR REPLACE FUNCTION ko_champion_deadline()
RETURNS trigger LANGUAGE plpgsql
SET search_path = public, pg_temp AS $$
DECLARE
  -- 29/06/2026 12:00 GMT-3 = 15:00 UTC
  CHAMPION_DEADLINE timestamptz := '2026-06-29 15:00:00+00';
BEGIN
  IF is_admin() THEN RETURN NEW; END IF;
  -- Update de sistema (pontuação) que não troca o time → libera.
  IF TG_OP = 'UPDATE' AND NEW.team_id = OLD.team_id THEN
    RETURN NEW;
  END IF;
  IF now() >= CHAMPION_DEADLINE THEN
    RAISE EXCEPTION 'Palpite de campeão encerrado (fecha 29/06 às 12h, horário de Brasília).';
  END IF;
  RETURN NEW;
END;
$$;

-- Conferência: deve listar a nova data limite no corpo da função.
-- SELECT pg_get_functiondef('ko_champion_deadline'::regproc);
