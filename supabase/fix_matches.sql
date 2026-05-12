-- =============================================================================
-- FIX: Recriar matches com confrontos reais, datas e IDs cronologicos
-- Rodar no SQL Editor do Supabase
-- =============================================================================

-- 1) Limpar bets existentes (dependem de match_id)
DELETE FROM bets;

-- 2) Limpar matches existentes
DELETE FROM matches;

-- 3) Inserir matches com confrontos reais e datas corretas
DO $$
DECLARE
  h_id UUID;
  a_id UUID;
BEGIN
  -- Jogo 1: Grupo A - México vs África do Sul
  SELECT id INTO h_id FROM teams WHERE name = 'México';
  SELECT id INTO a_id FROM teams WHERE name = 'África do Sul';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('A', h_id, a_id, '2026-06-11 19:00:00+00', '1');

  -- Jogo 2: Grupo A - Coreia do Sul vs Rep. Tcheca
  SELECT id INTO h_id FROM teams WHERE name = 'Coreia do Sul';
  SELECT id INTO a_id FROM teams WHERE name = 'Rep. Tcheca';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('A', h_id, a_id, '2026-06-12 02:00:00+00', '2');

  -- Jogo 3: Grupo B - Canadá vs Bósnia e Herzegovina
  SELECT id INTO h_id FROM teams WHERE name = 'Canadá';
  SELECT id INTO a_id FROM teams WHERE name = 'Bósnia e Herzegovina';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('B', h_id, a_id, '2026-06-12 19:00:00+00', '3');

  -- Jogo 4: Grupo D - Estados Unidos vs Paraguai
  SELECT id INTO h_id FROM teams WHERE name = 'Estados Unidos';
  SELECT id INTO a_id FROM teams WHERE name = 'Paraguai';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('D', h_id, a_id, '2026-06-13 01:00:00+00', '4');

  -- Jogo 5: Grupo B - Catar vs Suíça
  SELECT id INTO h_id FROM teams WHERE name = 'Catar';
  SELECT id INTO a_id FROM teams WHERE name = 'Suíça';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('B', h_id, a_id, '2026-06-13 19:00:00+00', '5');

  -- Jogo 6: Grupo C - Brasil vs Marrocos
  SELECT id INTO h_id FROM teams WHERE name = 'Brasil';
  SELECT id INTO a_id FROM teams WHERE name = 'Marrocos';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('C', h_id, a_id, '2026-06-13 22:00:00+00', '6');

  -- Jogo 7: Grupo C - Haiti vs Escócia
  SELECT id INTO h_id FROM teams WHERE name = 'Haiti';
  SELECT id INTO a_id FROM teams WHERE name = 'Escócia';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('C', h_id, a_id, '2026-06-14 01:00:00+00', '7');

  -- Jogo 8: Grupo D - Austrália vs Turquia
  SELECT id INTO h_id FROM teams WHERE name = 'Austrália';
  SELECT id INTO a_id FROM teams WHERE name = 'Turquia';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('D', h_id, a_id, '2026-06-14 04:00:00+00', '8');

  -- Jogo 9: Grupo E - Alemanha vs Curaçao
  SELECT id INTO h_id FROM teams WHERE name = 'Alemanha';
  SELECT id INTO a_id FROM teams WHERE name = 'Curaçao';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('E', h_id, a_id, '2026-06-14 17:00:00+00', '9');

  -- Jogo 10: Grupo F - Holanda vs Japão
  SELECT id INTO h_id FROM teams WHERE name = 'Holanda';
  SELECT id INTO a_id FROM teams WHERE name = 'Japão';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('F', h_id, a_id, '2026-06-14 20:00:00+00', '10');

  -- Jogo 11: Grupo E - Costa do Marfim vs Equador
  SELECT id INTO h_id FROM teams WHERE name = 'Costa do Marfim';
  SELECT id INTO a_id FROM teams WHERE name = 'Equador';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('E', h_id, a_id, '2026-06-14 23:00:00+00', '11');

  -- Jogo 12: Grupo F - Suécia vs Tunísia
  SELECT id INTO h_id FROM teams WHERE name = 'Suécia';
  SELECT id INTO a_id FROM teams WHERE name = 'Tunísia';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('F', h_id, a_id, '2026-06-15 02:00:00+00', '12');

  -- Jogo 13: Grupo H - Espanha vs Cabo Verde
  SELECT id INTO h_id FROM teams WHERE name = 'Espanha';
  SELECT id INTO a_id FROM teams WHERE name = 'Cabo Verde';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('H', h_id, a_id, '2026-06-15 16:00:00+00', '13');

  -- Jogo 14: Grupo G - Bélgica vs Egito
  SELECT id INTO h_id FROM teams WHERE name = 'Bélgica';
  SELECT id INTO a_id FROM teams WHERE name = 'Egito';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('G', h_id, a_id, '2026-06-15 19:00:00+00', '14');

  -- Jogo 15: Grupo H - Arábia Saudita vs Uruguai
  SELECT id INTO h_id FROM teams WHERE name = 'Arábia Saudita';
  SELECT id INTO a_id FROM teams WHERE name = 'Uruguai';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('H', h_id, a_id, '2026-06-15 22:00:00+00', '15');

  -- Jogo 16: Grupo G - Irã vs Nova Zelândia
  SELECT id INTO h_id FROM teams WHERE name = 'Irã';
  SELECT id INTO a_id FROM teams WHERE name = 'Nova Zelândia';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('G', h_id, a_id, '2026-06-16 01:00:00+00', '16');

  -- Jogo 17: Grupo I - França vs Senegal
  SELECT id INTO h_id FROM teams WHERE name = 'França';
  SELECT id INTO a_id FROM teams WHERE name = 'Senegal';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('I', h_id, a_id, '2026-06-16 19:00:00+00', '17');

  -- Jogo 18: Grupo I - Iraque vs Noruega
  SELECT id INTO h_id FROM teams WHERE name = 'Iraque';
  SELECT id INTO a_id FROM teams WHERE name = 'Noruega';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('I', h_id, a_id, '2026-06-16 22:00:00+00', '18');

  -- Jogo 19: Grupo J - Argentina vs Argélia
  SELECT id INTO h_id FROM teams WHERE name = 'Argentina';
  SELECT id INTO a_id FROM teams WHERE name = 'Argélia';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('J', h_id, a_id, '2026-06-17 01:00:00+00', '19');

  -- Jogo 20: Grupo J - Áustria vs Jordânia
  SELECT id INTO h_id FROM teams WHERE name = 'Áustria';
  SELECT id INTO a_id FROM teams WHERE name = 'Jordânia';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('J', h_id, a_id, '2026-06-17 04:00:00+00', '20');

  -- Jogo 21: Grupo K - Portugal vs RD Congo
  SELECT id INTO h_id FROM teams WHERE name = 'Portugal';
  SELECT id INTO a_id FROM teams WHERE name = 'RD Congo';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('K', h_id, a_id, '2026-06-17 17:00:00+00', '21');

  -- Jogo 22: Grupo L - Inglaterra vs Croácia
  SELECT id INTO h_id FROM teams WHERE name = 'Inglaterra';
  SELECT id INTO a_id FROM teams WHERE name = 'Croácia';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('L', h_id, a_id, '2026-06-17 20:00:00+00', '22');

  -- Jogo 23: Grupo L - Gana vs Panamá
  SELECT id INTO h_id FROM teams WHERE name = 'Gana';
  SELECT id INTO a_id FROM teams WHERE name = 'Panamá';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('L', h_id, a_id, '2026-06-17 23:00:00+00', '23');

  -- Jogo 24: Grupo K - Uzbequistão vs Colômbia
  SELECT id INTO h_id FROM teams WHERE name = 'Uzbequistão';
  SELECT id INTO a_id FROM teams WHERE name = 'Colômbia';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('K', h_id, a_id, '2026-06-18 02:00:00+00', '24');

  -- Jogo 25: Grupo A - Rep. Tcheca vs África do Sul
  SELECT id INTO h_id FROM teams WHERE name = 'Rep. Tcheca';
  SELECT id INTO a_id FROM teams WHERE name = 'África do Sul';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('A', h_id, a_id, '2026-06-18 16:00:00+00', '25');

  -- Jogo 26: Grupo B - Suíça vs Bósnia e Herzegovina
  SELECT id INTO h_id FROM teams WHERE name = 'Suíça';
  SELECT id INTO a_id FROM teams WHERE name = 'Bósnia e Herzegovina';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('B', h_id, a_id, '2026-06-18 19:00:00+00', '26');

  -- Jogo 27: Grupo B - Canadá vs Catar
  SELECT id INTO h_id FROM teams WHERE name = 'Canadá';
  SELECT id INTO a_id FROM teams WHERE name = 'Catar';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('B', h_id, a_id, '2026-06-18 22:00:00+00', '27');

  -- Jogo 28: Grupo A - México vs Coreia do Sul
  SELECT id INTO h_id FROM teams WHERE name = 'México';
  SELECT id INTO a_id FROM teams WHERE name = 'Coreia do Sul';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('A', h_id, a_id, '2026-06-19 01:00:00+00', '28');

  -- Jogo 29: Grupo D - Estados Unidos vs Austrália
  SELECT id INTO h_id FROM teams WHERE name = 'Estados Unidos';
  SELECT id INTO a_id FROM teams WHERE name = 'Austrália';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('D', h_id, a_id, '2026-06-19 19:00:00+00', '29');

  -- Jogo 30: Grupo C - Escócia vs Marrocos
  SELECT id INTO h_id FROM teams WHERE name = 'Escócia';
  SELECT id INTO a_id FROM teams WHERE name = 'Marrocos';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('C', h_id, a_id, '2026-06-19 22:00:00+00', '30');

  -- Jogo 31: Grupo C - Brasil vs Haiti
  SELECT id INTO h_id FROM teams WHERE name = 'Brasil';
  SELECT id INTO a_id FROM teams WHERE name = 'Haiti';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('C', h_id, a_id, '2026-06-20 00:30:00+00', '31');

  -- Jogo 32: Grupo D - Turquia vs Paraguai
  SELECT id INTO h_id FROM teams WHERE name = 'Turquia';
  SELECT id INTO a_id FROM teams WHERE name = 'Paraguai';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('D', h_id, a_id, '2026-06-20 03:30:00+00', '32');

  -- Jogo 33: Grupo E - Alemanha vs Costa do Marfim
  SELECT id INTO h_id FROM teams WHERE name = 'Alemanha';
  SELECT id INTO a_id FROM teams WHERE name = 'Costa do Marfim';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('E', h_id, a_id, '2026-06-20 17:00:00+00', '33');

  -- Jogo 34: Grupo F - Holanda vs Suécia
  SELECT id INTO h_id FROM teams WHERE name = 'Holanda';
  SELECT id INTO a_id FROM teams WHERE name = 'Suécia';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('F', h_id, a_id, '2026-06-20 20:00:00+00', '34');

  -- Jogo 35: Grupo E - Equador vs Curaçao
  SELECT id INTO h_id FROM teams WHERE name = 'Equador';
  SELECT id INTO a_id FROM teams WHERE name = 'Curaçao';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('E', h_id, a_id, '2026-06-21 00:00:00+00', '35');

  -- Jogo 36: Grupo F - Tunísia vs Japão
  SELECT id INTO h_id FROM teams WHERE name = 'Tunísia';
  SELECT id INTO a_id FROM teams WHERE name = 'Japão';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('F', h_id, a_id, '2026-06-21 04:00:00+00', '36');

  -- Jogo 37: Grupo H - Espanha vs Arábia Saudita
  SELECT id INTO h_id FROM teams WHERE name = 'Espanha';
  SELECT id INTO a_id FROM teams WHERE name = 'Arábia Saudita';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('H', h_id, a_id, '2026-06-21 16:00:00+00', '37');

  -- Jogo 38: Grupo G - Bélgica vs Irã
  SELECT id INTO h_id FROM teams WHERE name = 'Bélgica';
  SELECT id INTO a_id FROM teams WHERE name = 'Irã';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('G', h_id, a_id, '2026-06-21 19:00:00+00', '38');

  -- Jogo 39: Grupo H - Uruguai vs Cabo Verde
  SELECT id INTO h_id FROM teams WHERE name = 'Uruguai';
  SELECT id INTO a_id FROM teams WHERE name = 'Cabo Verde';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('H', h_id, a_id, '2026-06-21 22:00:00+00', '39');

  -- Jogo 40: Grupo G - Nova Zelândia vs Egito
  SELECT id INTO h_id FROM teams WHERE name = 'Nova Zelândia';
  SELECT id INTO a_id FROM teams WHERE name = 'Egito';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('G', h_id, a_id, '2026-06-22 01:00:00+00', '40');

  -- Jogo 41: Grupo I - França vs Iraque
  SELECT id INTO h_id FROM teams WHERE name = 'França';
  SELECT id INTO a_id FROM teams WHERE name = 'Iraque';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('I', h_id, a_id, '2026-06-22 19:00:00+00', '41');

  -- Jogo 42: Grupo I - Noruega vs Senegal
  SELECT id INTO h_id FROM teams WHERE name = 'Noruega';
  SELECT id INTO a_id FROM teams WHERE name = 'Senegal';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('I', h_id, a_id, '2026-06-22 22:00:00+00', '42');

  -- Jogo 43: Grupo J - Argentina vs Áustria
  SELECT id INTO h_id FROM teams WHERE name = 'Argentina';
  SELECT id INTO a_id FROM teams WHERE name = 'Áustria';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('J', h_id, a_id, '2026-06-23 01:00:00+00', '43');

  -- Jogo 44: Grupo J - Jordânia vs Argélia
  SELECT id INTO h_id FROM teams WHERE name = 'Jordânia';
  SELECT id INTO a_id FROM teams WHERE name = 'Argélia';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('J', h_id, a_id, '2026-06-23 04:00:00+00', '44');

  -- Jogo 45: Grupo K - Portugal vs Uzbequistão
  SELECT id INTO h_id FROM teams WHERE name = 'Portugal';
  SELECT id INTO a_id FROM teams WHERE name = 'Uzbequistão';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('K', h_id, a_id, '2026-06-23 16:00:00+00', '45');

  -- Jogo 46: Grupo L - Inglaterra vs Gana
  SELECT id INTO h_id FROM teams WHERE name = 'Inglaterra';
  SELECT id INTO a_id FROM teams WHERE name = 'Gana';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('L', h_id, a_id, '2026-06-23 19:00:00+00', '46');

  -- Jogo 47: Grupo L - Panamá vs Croácia
  SELECT id INTO h_id FROM teams WHERE name = 'Panamá';
  SELECT id INTO a_id FROM teams WHERE name = 'Croácia';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('L', h_id, a_id, '2026-06-23 22:00:00+00', '47');

  -- Jogo 48: Grupo K - Colômbia vs RD Congo
  SELECT id INTO h_id FROM teams WHERE name = 'Colômbia';
  SELECT id INTO a_id FROM teams WHERE name = 'RD Congo';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('K', h_id, a_id, '2026-06-24 01:00:00+00', '48');

  -- Jogo 49: Grupo B - Suíça vs Canadá
  SELECT id INTO h_id FROM teams WHERE name = 'Suíça';
  SELECT id INTO a_id FROM teams WHERE name = 'Canadá';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('B', h_id, a_id, '2026-06-24 19:00:00+00', '49');

  -- Jogo 50: Grupo B - Bósnia e Herzegovina vs Catar
  SELECT id INTO h_id FROM teams WHERE name = 'Bósnia e Herzegovina';
  SELECT id INTO a_id FROM teams WHERE name = 'Catar';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('B', h_id, a_id, '2026-06-24 19:00:00+00', '50');

  -- Jogo 51: Grupo C - Escócia vs Brasil
  SELECT id INTO h_id FROM teams WHERE name = 'Escócia';
  SELECT id INTO a_id FROM teams WHERE name = 'Brasil';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('C', h_id, a_id, '2026-06-24 22:00:00+00', '51');

  -- Jogo 52: Grupo C - Marrocos vs Haiti
  SELECT id INTO h_id FROM teams WHERE name = 'Marrocos';
  SELECT id INTO a_id FROM teams WHERE name = 'Haiti';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('C', h_id, a_id, '2026-06-24 22:00:00+00', '52');

  -- Jogo 53: Grupo A - Rep. Tcheca vs México
  SELECT id INTO h_id FROM teams WHERE name = 'Rep. Tcheca';
  SELECT id INTO a_id FROM teams WHERE name = 'México';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('A', h_id, a_id, '2026-06-25 01:00:00+00', '53');

  -- Jogo 54: Grupo A - África do Sul vs Coreia do Sul
  SELECT id INTO h_id FROM teams WHERE name = 'África do Sul';
  SELECT id INTO a_id FROM teams WHERE name = 'Coreia do Sul';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('A', h_id, a_id, '2026-06-25 01:00:00+00', '54');

  -- Jogo 55: Grupo E - Equador vs Alemanha
  SELECT id INTO h_id FROM teams WHERE name = 'Equador';
  SELECT id INTO a_id FROM teams WHERE name = 'Alemanha';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('E', h_id, a_id, '2026-06-25 16:00:00+00', '55');

  -- Jogo 56: Grupo E - Curaçao vs Costa do Marfim
  SELECT id INTO h_id FROM teams WHERE name = 'Curaçao';
  SELECT id INTO a_id FROM teams WHERE name = 'Costa do Marfim';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('E', h_id, a_id, '2026-06-25 16:00:00+00', '56');

  -- Jogo 57: Grupo F - Japão vs Suécia
  SELECT id INTO h_id FROM teams WHERE name = 'Japão';
  SELECT id INTO a_id FROM teams WHERE name = 'Suécia';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('F', h_id, a_id, '2026-06-25 19:00:00+00', '57');

  -- Jogo 58: Grupo F - Tunísia vs Holanda
  SELECT id INTO h_id FROM teams WHERE name = 'Tunísia';
  SELECT id INTO a_id FROM teams WHERE name = 'Holanda';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('F', h_id, a_id, '2026-06-25 19:00:00+00', '58');

  -- Jogo 59: Grupo D - Austrália vs Paraguai
  SELECT id INTO h_id FROM teams WHERE name = 'Austrália';
  SELECT id INTO a_id FROM teams WHERE name = 'Paraguai';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('D', h_id, a_id, '2026-06-25 22:00:00+00', '59');

  -- Jogo 60: Grupo D - Estados Unidos vs Turquia
  SELECT id INTO h_id FROM teams WHERE name = 'Estados Unidos';
  SELECT id INTO a_id FROM teams WHERE name = 'Turquia';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('D', h_id, a_id, '2026-06-25 22:00:00+00', '60');

  -- Jogo 61: Grupo G - Nova Zelândia vs Bélgica
  SELECT id INTO h_id FROM teams WHERE name = 'Nova Zelândia';
  SELECT id INTO a_id FROM teams WHERE name = 'Bélgica';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('G', h_id, a_id, '2026-06-26 16:00:00+00', '61');

  -- Jogo 62: Grupo G - Egito vs Irã
  SELECT id INTO h_id FROM teams WHERE name = 'Egito';
  SELECT id INTO a_id FROM teams WHERE name = 'Irã';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('G', h_id, a_id, '2026-06-26 16:00:00+00', '62');

  -- Jogo 63: Grupo I - Noruega vs França
  SELECT id INTO h_id FROM teams WHERE name = 'Noruega';
  SELECT id INTO a_id FROM teams WHERE name = 'França';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('I', h_id, a_id, '2026-06-26 19:00:00+00', '63');

  -- Jogo 64: Grupo I - Senegal vs Iraque
  SELECT id INTO h_id FROM teams WHERE name = 'Senegal';
  SELECT id INTO a_id FROM teams WHERE name = 'Iraque';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('I', h_id, a_id, '2026-06-26 19:00:00+00', '64');

  -- Jogo 65: Grupo H - Cabo Verde vs Arábia Saudita
  SELECT id INTO h_id FROM teams WHERE name = 'Cabo Verde';
  SELECT id INTO a_id FROM teams WHERE name = 'Arábia Saudita';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('H', h_id, a_id, '2026-06-27 00:00:00+00', '65');

  -- Jogo 66: Grupo H - Uruguai vs Espanha
  SELECT id INTO h_id FROM teams WHERE name = 'Uruguai';
  SELECT id INTO a_id FROM teams WHERE name = 'Espanha';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('H', h_id, a_id, '2026-06-27 00:00:00+00', '66');

  -- Jogo 67: Grupo J - Áustria vs Argélia
  SELECT id INTO h_id FROM teams WHERE name = 'Áustria';
  SELECT id INTO a_id FROM teams WHERE name = 'Argélia';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('J', h_id, a_id, '2026-06-27 04:00:00+00', '67');

  -- Jogo 68: Grupo J - Jordânia vs Argentina
  SELECT id INTO h_id FROM teams WHERE name = 'Jordânia';
  SELECT id INTO a_id FROM teams WHERE name = 'Argentina';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('J', h_id, a_id, '2026-06-27 04:00:00+00', '68');

  -- Jogo 69: Grupo L - Panamá vs Inglaterra
  SELECT id INTO h_id FROM teams WHERE name = 'Panamá';
  SELECT id INTO a_id FROM teams WHERE name = 'Inglaterra';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('L', h_id, a_id, '2026-06-27 19:00:00+00', '69');

  -- Jogo 70: Grupo L - Croácia vs Gana
  SELECT id INTO h_id FROM teams WHERE name = 'Croácia';
  SELECT id INTO a_id FROM teams WHERE name = 'Gana';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('L', h_id, a_id, '2026-06-27 19:00:00+00', '70');

  -- Jogo 71: Grupo K - RD Congo vs Uzbequistão
  SELECT id INTO h_id FROM teams WHERE name = 'RD Congo';
  SELECT id INTO a_id FROM teams WHERE name = 'Uzbequistão';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('K', h_id, a_id, '2026-06-27 22:00:00+00', '71');

  -- Jogo 72: Grupo K - Colômbia vs Portugal
  SELECT id INTO h_id FROM teams WHERE name = 'Colômbia';
  SELECT id INTO a_id FROM teams WHERE name = 'Portugal';
  INSERT INTO matches (group_letter, home_team_id, away_team_id, match_date, api_match_id)
  VALUES ('K', h_id, a_id, '2026-06-27 22:00:00+00', '72');

END;
$$;

-- 4) Verificacao
SELECT m.api_match_id::int as jogo, m.group_letter as grupo,
       h.name as time_casa, a.name as time_visitante,
       m.match_date
FROM matches m
JOIN teams h ON h.id = m.home_team_id
JOIN teams a ON a.id = m.away_team_id
ORDER BY m.api_match_id::int;