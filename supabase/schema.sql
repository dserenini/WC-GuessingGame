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
CREATE OR REPLACE VIEW user_rankings AS
SELECT
  p.id        AS user_id,
  p.username,
  p.avatar_url,
  COALESCE(SUM(b.points), 0) AS total_points,
  COUNT(b.id) AS total_bets,
  RANK() OVER (ORDER BY COALESCE(SUM(b.points), 0) DESC) AS rank
FROM profiles p
LEFT JOIN bets b ON b.user_id = p.id
GROUP BY p.id, p.username, p.avatar_url;

-- ─────────────────────────────────────────────
-- LEAGUE RANKING VIEW
-- ─────────────────────────────────────────────
CREATE OR REPLACE VIEW league_rankings AS
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
