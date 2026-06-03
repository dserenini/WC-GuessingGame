-- 1. Adicionar colunas em profiles
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS full_name TEXT,
ADD COLUMN IF NOT EXISTS display_preference TEXT DEFAULT 'username' CHECK (display_preference IN ('username', 'full_name'));

-- 2. Adicionar restrição UNIQUE ao username
-- ATENÇÃO: Só rode isso DEPOIS de deletar/renomear os usuários duplicados manualmente!
ALTER TABLE public.profiles 
ADD CONSTRAINT profiles_username_key UNIQUE (username);

-- 3. Atualizar a View de Rankings Globais
DROP VIEW IF EXISTS public.user_rankings;
CREATE OR REPLACE VIEW public.user_rankings
WITH (security_invoker = on) AS
SELECT
  p.id        AS user_id,
  p.username,
  p.full_name,
  p.display_preference,
  p.avatar_url,
  COALESCE(SUM(b.points), 0) AS total_points,
  COUNT(b.id) AS total_bets,
  RANK() OVER (ORDER BY COALESCE(SUM(b.points), 0) DESC) AS rank
FROM profiles p
LEFT JOIN bets b ON b.user_id = p.id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- 4. Atualizar a View de Rankings de Ligas
DROP VIEW IF EXISTS public.league_rankings;
CREATE OR REPLACE VIEW public.league_rankings
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
  RANK() OVER (PARTITION BY lm.league_id ORDER BY COALESCE(SUM(b.points), 0) DESC) AS rank
FROM league_members lm
JOIN leagues l ON l.id = lm.league_id
JOIN profiles p ON p.id = lm.user_id
LEFT JOIN bets b ON b.user_id = lm.user_id
GROUP BY lm.league_id, l.name, p.id, p.username, p.full_name, p.display_preference, p.avatar_url;
