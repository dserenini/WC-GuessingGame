-- =============================================================================
-- COPA 2026 — Supabase Schema
-- Run this entire file in the Supabase SQL Editor.
-- =============================================================================

-- ─────────────────────────────────────────────
-- EXTENSIONS
-- ─────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────────
-- PROFILES
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username    TEXT NOT NULL DEFAULT '',
  avatar_url  TEXT,
  locale      TEXT NOT NULL DEFAULT 'pt',
  max_goals   INT  NOT NULL DEFAULT 5,
  super_palpites_used INT NOT NULL DEFAULT 0,
  participate_in_ranking BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read all profiles"
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Auto-create profile on sign-up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Lookup email by username (for login by username)
CREATE OR REPLACE FUNCTION public.get_email_by_username(p_username TEXT)
RETURNS TEXT AS $$
DECLARE
  v_email TEXT;
BEGIN
  SELECT u.email INTO v_email
    FROM auth.users u
    JOIN public.profiles p ON p.id = u.id
   WHERE LOWER(p.username) = LOWER(p_username)
   LIMIT 1;
  RETURN v_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─────────────────────────────────────────────
-- ADMINS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admins (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Only admins can read admins table"
  ON admins FOR SELECT USING (
    auth.uid() IN (SELECT user_id FROM admins)
  );

-- Helper function to check admin status
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM admins WHERE user_id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─────────────────────────────────────────────
-- TEAMS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS teams (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL UNIQUE,
  flag_url     TEXT,
  group_letter CHAR(1) NOT NULL CHECK (group_letter IN ('A','B','C','D','E','F','G','H','I','J','K','L')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE teams ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read teams"
  ON teams FOR SELECT USING (true);

CREATE POLICY "Only admins can modify teams"
  ON teams FOR ALL USING (is_admin());

-- ─────────────────────────────────────────────
-- MATCHES
-- ─────────────────────────────────────────────
CREATE TYPE match_status AS ENUM ('scheduled', 'live', 'finished');

CREATE TABLE IF NOT EXISTS matches (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_letter  CHAR(1) NOT NULL,
  home_team_id  UUID NOT NULL REFERENCES teams(id),
  away_team_id  UUID NOT NULL REFERENCES teams(id),
  match_date    TIMESTAMPTZ,
  home_score    INT,
  away_score    INT,
  status        match_status NOT NULL DEFAULT 'scheduled',
  api_match_id  TEXT,  -- external API identifier for future integration
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read matches"
  ON matches FOR SELECT USING (true);

CREATE POLICY "Only admins can modify matches"
  ON matches FOR ALL USING (is_admin());

-- ─────────────────────────────────────────────
-- BETS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bets (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  match_id        UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  home_score_bet  INT NOT NULL DEFAULT 0,
  away_score_bet  INT NOT NULL DEFAULT 0,
  points          INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, match_id)
);

ALTER TABLE bets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read all bets"
  ON bets FOR SELECT USING (true);

CREATE POLICY "Users can manage their own bets"
  ON bets FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own bets"
  ON bets FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all bets"
  ON bets FOR ALL USING (is_admin());

-- ─────────────────────────────────────────────
-- AUTO-SCORING TRIGGER
-- Recalculates points for all bets when a match is marked "finished"
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION calculate_bet_points()
RETURNS TRIGGER AS $$
DECLARE
  real_home INT := NEW.home_score;
  real_away INT := NEW.away_score;
BEGIN
  -- Only run when match transitions to "finished" with valid scores
  IF NEW.status = 'finished' AND real_home IS NOT NULL AND real_away IS NOT NULL THEN
    UPDATE bets
    SET points = CASE
      -- Exact score: 3 points
      WHEN home_score_bet = real_home AND away_score_bet = real_away THEN 3
      -- Correct result (win/draw direction): 1 point
      WHEN (home_score_bet > away_score_bet AND real_home > real_away) THEN 1  -- home win
      WHEN (home_score_bet < away_score_bet AND real_home < real_away) THEN 1  -- away win
      WHEN (home_score_bet = away_score_bet AND real_home = real_away) THEN 1  -- draw
      ELSE 0
    END,
    updated_at = NOW()
    WHERE match_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_match_finished ON matches;
CREATE TRIGGER on_match_finished
  AFTER UPDATE ON matches
  FOR EACH ROW
  WHEN (NEW.status = 'finished')
  EXECUTE PROCEDURE calculate_bet_points();

-- ─────────────────────────────────────────────
-- LEAGUES
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS leagues (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  invite_code TEXT NOT NULL UNIQUE DEFAULT UPPER(SUBSTRING(gen_random_uuid()::TEXT FROM 1 FOR 6)),
  owner_id    UUID NOT NULL REFERENCES auth.users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE leagues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read leagues"
  ON leagues FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create leagues"
  ON leagues FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update their leagues"
  ON leagues FOR UPDATE USING (auth.uid() = owner_id);

-- ─────────────────────────────────────────────
-- LEAGUE MEMBERS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS league_members (
  league_id   UUID NOT NULL REFERENCES leagues(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (league_id, user_id)
);

ALTER TABLE league_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read league members"
  ON league_members FOR SELECT USING (true);

CREATE POLICY "Users can join leagues"
  ON league_members FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave leagues"
  ON league_members FOR DELETE USING (auth.uid() = user_id);

-- ─────────────────────────────────────────────
-- RANKING VIEW
-- Aggregates total points per user across all bets
-- ─────────────────────────────────────────────
CREATE OR REPLACE VIEW user_rankings
WITH (security_invoker = on) AS
SELECT
  p.id        AS user_id,
  p.username,
  p.avatar_url,
  COALESCE(SUM(b.points), 0) AS total_points,
  COUNT(b.id) AS total_bets,
  RANK() OVER (ORDER BY COALESCE(SUM(b.points), 0) DESC) AS rank
FROM profiles p
LEFT JOIN bets b ON b.user_id = p.id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.avatar_url;

-- ─────────────────────────────────────────────
-- LEAGUE RANKING VIEW
-- ─────────────────────────────────────────────
CREATE OR REPLACE VIEW league_rankings
WITH (security_invoker = on) AS
SELECT
  lm.league_id,
  l.name        AS league_name,
  p.id          AS user_id,
  p.username,
  p.avatar_url,
  COALESCE(SUM(b.points), 0) AS total_points,
  RANK() OVER (PARTITION BY lm.league_id ORDER BY COALESCE(SUM(b.points), 0) DESC) AS rank
FROM league_members lm
JOIN leagues l ON l.id = lm.league_id
JOIN profiles p ON p.id = lm.user_id
LEFT JOIN bets b ON b.user_id = lm.user_id
GROUP BY lm.league_id, l.name, p.id, p.username, p.avatar_url;

-- ─────────────────────────────────────────────
-- ENABLE REALTIME
-- ─────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE bets;
ALTER PUBLICATION supabase_realtime ADD TABLE matches;

-- =============================================================================
-- AUDIT & RECOVERY SYSTEM
-- =============================================================================

-- ─────────────────────────────────────────────
-- AUDIT LOG TABLE
-- Tracks every INSERT, UPDATE, DELETE on critical tables
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_log (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  table_name  TEXT        NOT NULL,
  record_id   TEXT        NOT NULL,
  operation   TEXT        NOT NULL CHECK (operation IN ('INSERT','UPDATE','DELETE')),
  old_data    JSONB,
  new_data    JSONB,
  changed_by  UUID,
  changed_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast lookups by table and record
CREATE INDEX IF NOT EXISTS idx_audit_log_table_record
  ON audit_log (table_name, record_id);

-- Index for time-based queries (e.g. "what changed in the last hour?")
CREATE INDEX IF NOT EXISTS idx_audit_log_changed_at
  ON audit_log (changed_at DESC);

ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- Only admins can read audit logs
CREATE POLICY "Only admins can read audit_log"
  ON audit_log FOR SELECT USING (is_admin());

-- Only the system (triggers) can insert — no direct user inserts
CREATE POLICY "System can insert audit_log"
  ON audit_log FOR INSERT WITH CHECK (true);

-- ─────────────────────────────────────────────
-- GENERIC AUDIT TRIGGER FUNCTION
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audit_log (table_name, record_id, operation, old_data, new_data, changed_by)
    VALUES (TG_TABLE_NAME, NEW.id::TEXT, 'INSERT', NULL, to_jsonb(NEW), auth.uid());
    RETURN NEW;

  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_log (table_name, record_id, operation, old_data, new_data, changed_by)
    VALUES (TG_TABLE_NAME, NEW.id::TEXT, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), auth.uid());
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO audit_log (table_name, record_id, operation, old_data, new_data, changed_by)
    VALUES (TG_TABLE_NAME, OLD.id::TEXT, 'DELETE', to_jsonb(OLD), NULL, auth.uid());
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─────────────────────────────────────────────
-- ATTACH AUDIT TRIGGERS TO CRITICAL TABLES
-- ─────────────────────────────────────────────

-- Audit all changes to matches (scores, status)
DROP TRIGGER IF EXISTS audit_matches ON matches;
CREATE TRIGGER audit_matches
  AFTER INSERT OR UPDATE OR DELETE ON matches
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Audit all changes to bets (scores, points)
DROP TRIGGER IF EXISTS audit_bets ON bets;
CREATE TRIGGER audit_bets
  AFTER INSERT OR UPDATE OR DELETE ON bets
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- ─────────────────────────────────────────────
-- ROLLBACK MATCH SCORING
-- Resets a match and all its bets to pre-scoring state.
-- Usage:  SELECT * FROM rollback_match_scoring('match-uuid-here');
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION rollback_match_scoring(p_match_id UUID)
RETURNS TABLE (
  match_reset   BOOLEAN,
  bets_affected BIGINT,
  old_home      INT,
  old_away      INT,
  old_status    TEXT
) AS $$
DECLARE
  v_home   INT;
  v_away   INT;
  v_status TEXT;
  v_count  BIGINT;
BEGIN
  -- Only admins can rollback
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Apenas administradores podem executar rollback.';
  END IF;

  -- Capture current match state before reset
  SELECT m.home_score, m.away_score, m.status::TEXT
    INTO v_home, v_away, v_status
    FROM matches m
   WHERE m.id = p_match_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Partida % não encontrada.', p_match_id;
  END IF;

  -- Reset all bet points for this match
  UPDATE bets
     SET points = 0,
         updated_at = NOW()
   WHERE match_id = p_match_id;

  GET DIAGNOSTICS v_count = ROW_COUNT;

  -- Reset match to scheduled state (clear scores)
  UPDATE matches
     SET home_score = NULL,
         away_score = NULL,
         status = 'scheduled'
   WHERE id = p_match_id;

  -- Return summary of what was rolled back
  RETURN QUERY SELECT
    TRUE          AS match_reset,
    v_count       AS bets_affected,
    v_home        AS old_home,
    v_away        AS old_away,
    v_status      AS old_status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─────────────────────────────────────────────
-- ENFORCE BET RULES (SUPER PALPITE & DEADLINES)
-- ─────────────────────────────────────────────
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

DROP TRIGGER IF EXISTS enforce_bet_rules ON bets;
CREATE TRIGGER enforce_bet_rules
BEFORE INSERT OR UPDATE ON bets
FOR EACH ROW EXECUTE PROCEDURE check_bet_deadline();

-- ─────────────────────────────────────────────
-- CHECK EMAIL EXISTS RPC
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.check_email_exists(p_email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users WHERE email = p_email
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
