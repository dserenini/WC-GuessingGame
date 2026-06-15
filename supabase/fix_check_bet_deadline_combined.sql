-- =============================================================================
-- FIX — check_bet_deadline() combinando os dois ajustes que precisam coexistir:
--
--   (A) Bypass de updates internos do sistema (de fix_finish_scoring.sql):
--       calculate_bet_points()/rollback_match_scoring() fazem UPDATE em
--       bets.points ao encerrar/reverter um jogo. Isso dispara este trigger.
--       Como o jogo já não é 'scheduled', a regra de status barrava o update
--       e o encerramento/pontuação FALHAVA. Updates que NÃO mudam o placar do
--       palpite são internos e passam direto.
--
--   (B) Fix do double-count no Super Palpite (de super_palpite.sql):
--       o app salva via upsert (INSERT ... ON CONFLICT DO UPDATE). Quando a
--       aposta já existe, o Postgres dispara o BEFORE INSERT e, ao detectar o
--       conflito, também o BEFORE UPDATE — contando 2 Super Palpites por
--       alteração. No ramo INSERT, se já existe aposta, saímos sem contar e
--       deixamos o caminho do UPDATE contar uma única vez.
--
-- Contexto: ao aplicar (B) em prod isoladamente, a versão regrediu (A), porque
-- (B) foi escrito sobre a versão anterior da função. Esta versão une os dois.
--
-- ⚠️ GLOBAL_DEADLINE: confira o valor REAL em produção antes de aplicar
--    (SELECT pg_get_functiondef('check_bet_deadline'::regproc);) e mantenha-o.
--
-- Rode uma vez no SQL Editor da produção. O trigger continua ligado.
-- =============================================================================

CREATE OR REPLACE FUNCTION check_bet_deadline()
RETURNS TRIGGER AS $$
DECLARE
  v_match_date TIMESTAMPTZ;
  v_match_status TEXT;
  v_used INT;
  GLOBAL_DEADLINE TIMESTAMPTZ := '2026-06-11 17:30:00+00';
BEGIN
  -- 0. BYPASS de updates internos do sistema (pontuação/rollback): não mudam o
  --    placar do palpite. Sem isto, encerrar/pontuar um jogo falha.
  IF TG_OP = 'UPDATE'
     AND OLD.home_score_bet = NEW.home_score_bet
     AND OLD.away_score_bet = NEW.away_score_bet THEN
    RETURN NEW;
  END IF;

  -- 1. Info da partida
  SELECT match_date, status::TEXT INTO v_match_date, v_match_status
  FROM matches WHERE id = NEW.match_id;

  -- 2. Partidas em andamento ou finalizadas não podem ser alteradas
  IF v_match_status != 'scheduled' THEN
     RAISE EXCEPTION 'Não é possível alterar apostas de partidas em andamento ou finalizadas.';
  END IF;

  -- 3. Regra de 1 hora antes do jogo
  IF v_match_date <= NOW() + INTERVAL '1 hour' THEN
     RAISE EXCEPTION 'O tempo limite para alterar a aposta desta partida expirou (menos de 1 hora para o início).';
  END IF;

  -- 4. Data Limite Global (Super Palpite)
  IF NOW() > GLOBAL_DEADLINE THEN
     -- O app salva via upsert. No upsert, o BEFORE INSERT dispara mesmo quando a
     -- linha já existe; em seguida dispara o BEFORE UPDATE. Sem o tratamento
     -- abaixo, uma alteração contaria 2 Super Palpites.
     IF TG_OP = 'INSERT' THEN
       IF EXISTS (SELECT 1 FROM bets WHERE user_id = NEW.user_id AND match_id = NEW.match_id) THEN
         RETURN NEW;  -- vira UPDATE pelo ON CONFLICT; o UPDATE é quem conta
       END IF;
       -- senão, é aposta nova após o deadline → conta abaixo
     END IF;
     -- (o caso UPDATE com placar inalterado já saiu no bypass 0 acima)

     SELECT super_palpites_used INTO v_used FROM profiles WHERE id = NEW.user_id;
     IF v_used >= 10 THEN
        RAISE EXCEPTION 'Você já atingiu o limite de 10 Super Palpites.';
     END IF;
     UPDATE profiles SET super_palpites_used = super_palpites_used + 1 WHERE id = NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
