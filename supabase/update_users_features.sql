-- 1. Adicionar coluna de telefone
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone TEXT;

-- 2. Recriar a trigger com a nova data (11/06/2026 14:30 GMT-3 = 17:30 UTC)
CREATE OR REPLACE FUNCTION check_bet_deadline()
RETURNS TRIGGER AS $$
DECLARE
  v_match_date TIMESTAMPTZ;
  v_match_status TEXT;
  v_used INT;
  -- Data Limite Global atualizada para: 11 de Junho 2026, 17:30 UTC
  GLOBAL_DEADLINE TIMESTAMPTZ := '2026-06-11 17:30:00+00'; 
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

-- 3. Criar a View/RPC para admins visualizarem todos os usuários com email
CREATE OR REPLACE FUNCTION get_admin_users()
RETURNS TABLE (
  id UUID,
  username TEXT,
  full_name TEXT,
  email TEXT,
  phone TEXT,
  paid BOOLEAN
) AS $$
BEGIN
  -- Verifica se o usuário autenticado é admin
  IF NOT EXISTS (SELECT 1 FROM admins WHERE user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Acesso negado: Somente administradores podem ver a lista completa de usuários.';
  END IF;

  RETURN QUERY
  SELECT 
    p.id,
    p.username,
    p.full_name,
    u.email::TEXT,
    p.phone,
    p.paid
  FROM profiles p
  JOIN auth.users u ON p.id = u.id
  ORDER BY p.username ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
