-- =============================================================================
-- FIX — permitir encerrar partidas (conflito entre triggers)
--
-- Bug: ao marcar um jogo como 'finished', calculate_bet_points() faz UPDATE em
-- bets.points, o que dispara check_bet_deadline(), cuja 1ª regra rejeita
-- qualquer alteração de aposta de partida não-'scheduled' → exceção → o encerrar
-- falha. Idem para rollback_match_scoring().
--
-- Correção: updates que NÃO mudam o placar do palpite são internos do sistema
-- (pontuação/rollback) e devem passar direto, antes das regras de aposta.
--
-- Rode uma vez no SQL Editor da produção. O trigger continua ligado.
-- =============================================================================

CREATE OR REPLACE FUNCTION check_bet_deadline()
RETURNS TRIGGER AS $$
DECLARE
  v_match_date TIMESTAMPTZ;
  v_match_status TEXT;
  v_used INT;
  -- Data Limite Global: 11 de Junho 2026, 14:30 GMT-3 = 11 de Junho 2026, 17:30 UTC
  GLOBAL_DEADLINE TIMESTAMPTZ := '2026-06-11 17:30:00+00';
BEGIN
  -- 0. Bypass: updates que não mudam o placar do palpite são internos do
  --    sistema (recálculo de pontos ao encerrar, rollback). Não podem ser
  --    bloqueados pelas regras abaixo — senão encerrar um jogo falha.
  IF TG_OP = 'UPDATE'
     AND OLD.home_score_bet = NEW.home_score_bet
     AND OLD.away_score_bet = NEW.away_score_bet THEN
    RETURN NEW;
  END IF;

  -- 1. Obter informações da partida
  SELECT match_date, status::TEXT INTO v_match_date, v_match_status
  FROM matches WHERE id = NEW.match_id;

  -- 2. Regra básica: Partidas em andamento ou finalizadas não podem ser alteradas
  IF v_match_status != 'scheduled' THEN
     RAISE EXCEPTION 'Não é possível alterar apostas de partidas em andamento ou finalizadas.';
  END IF;

  -- 3. Regra de 1 hora antes do jogo
  IF v_match_date <= NOW() + INTERVAL '1 hour' THEN
     RAISE EXCEPTION 'O tempo limite para alterar a aposta desta partida expirou (menos de 1 hora para o início).';
  END IF;

  -- 4. Regra da Data Limite Global (Super Palpite)
  IF NOW() > GLOBAL_DEADLINE THEN
     -- Verificar saldo do usuário
     SELECT super_palpites_used INTO v_used FROM profiles WHERE id = NEW.user_id;

     IF v_used >= 10 THEN
        RAISE EXCEPTION 'Você já atingiu o limite de 10 Super Palpites.';
     END IF;

     -- Incrementar o uso do Super Palpite
     UPDATE profiles SET super_palpites_used = super_palpites_used + 1 WHERE id = NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
