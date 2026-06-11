-- =============================================================================
-- FIX — códigos de erro estáveis em check_bet_deadline()
--
-- Objetivo: as regras de negócio passam a lançar SQLSTATEs próprios, para que o
-- app mostre a mensagem ao usuário traduzida (pt/en/it), em vez do texto fixo em
-- português do trigger. O texto do RAISE vira apenas log/fallback.
--
--   P0010 → partida em andamento ou finalizada (palpite bloqueado)
--   P0011 → menos de 1 hora para o início do jogo
--   P0012 → limite de 10 Super Palpites atingido
--
-- Mapeamento no app: lib/shared/utils/error_messages.dart
--
-- Mantém o bypass do fix_finish_scoring.sql (updates internos de pontuação/
-- rollback não podem ser bloqueados). A LÓGICA é idêntica à que já roda em
-- produção — só foram adicionados os ERRCODE.
--
-- Rode uma vez no SQL Editor da produção. O trigger continua ligado.
-- =============================================================================

CREATE OR REPLACE FUNCTION check_bet_deadline()
RETURNS TRIGGER AS $$
DECLARE
  v_match_date   TIMESTAMPTZ;
  v_match_status TEXT;
  v_used         INT;
  -- Data Limite Global: 11 de Junho 2026, 14:30 GMT-3 = 11 de Junho 2026, 17:30 UTC
  GLOBAL_DEADLINE TIMESTAMPTZ := '2026-06-11 17:30:00+00';
BEGIN
  -- 0. Bypass: updates que não mudam o placar do palpite são internos do
  --    sistema (recálculo de pontos ao encerrar, rollback). Passam direto.
  IF TG_OP = 'UPDATE'
     AND OLD.home_score_bet = NEW.home_score_bet
     AND OLD.away_score_bet = NEW.away_score_bet THEN
    RETURN NEW;
  END IF;

  -- 1. Obter informações da partida
  SELECT match_date, status::TEXT INTO v_match_date, v_match_status
  FROM matches WHERE id = NEW.match_id;

  -- 2. Partidas em andamento ou finalizadas não podem ser alteradas
  IF v_match_status != 'scheduled' THEN
     RAISE EXCEPTION 'Não é possível alterar apostas de partidas em andamento ou finalizadas.'
       USING ERRCODE = 'P0010';
  END IF;

  -- 3. Regra de 1 hora antes do jogo
  IF v_match_date <= NOW() + INTERVAL '1 hour' THEN
     RAISE EXCEPTION 'O tempo limite para alterar a aposta desta partida expirou (menos de 1 hora para o início).'
       USING ERRCODE = 'P0011';
  END IF;

  -- 4. Regra da Data Limite Global (Super Palpite)
  IF NOW() > GLOBAL_DEADLINE THEN
     SELECT super_palpites_used INTO v_used FROM profiles WHERE id = NEW.user_id;

     IF v_used >= 10 THEN
        RAISE EXCEPTION 'Você já atingiu o limite de 10 Super Palpites.'
          USING ERRCODE = 'P0012';
     END IF;

     UPDATE profiles SET super_palpites_used = super_palpites_used + 1 WHERE id = NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
