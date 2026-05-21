-- 1. Adicionar a coluna de contagem na tabela de perfis
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS super_palpites_used INT NOT NULL DEFAULT 0;

-- 2. Criar a função que verifica os limites
CREATE OR REPLACE FUNCTION check_bet_deadline()
RETURNS TRIGGER AS $$
DECLARE
  v_match_date TIMESTAMPTZ;
  v_match_status TEXT;
  v_used INT;
  -- Data Limite Global: 10 de Junho 2026, 23:59 GMT-3 = 11 de Junho 2026, 02:59 UTC
  GLOBAL_DEADLINE TIMESTAMPTZ := '2026-06-11 02:59:00+00'; 
BEGIN
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
     -- Se for update e o placar não mudou, ignorar (ex: sync repetido)
     IF TG_OP = 'UPDATE' AND OLD.home_score_bet = NEW.home_score_bet AND OLD.away_score_bet = NEW.away_score_bet THEN
       RETURN NEW;
     END IF;

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

-- 3. Aplicar o Trigger na tabela de apostas
DROP TRIGGER IF EXISTS enforce_bet_rules ON bets;
CREATE TRIGGER enforce_bet_rules
BEFORE INSERT OR UPDATE ON bets
FOR EACH ROW EXECUTE PROCEDURE check_bet_deadline();
