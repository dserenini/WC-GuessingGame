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
  username    TEXT NOT NULL UNIQUE DEFAULT '',
  full_name   TEXT,
  display_preference TEXT DEFAULT 'username' CHECK (display_preference IN ('username', 'full_name')),
  avatar_url  TEXT,
  locale      TEXT NOT NULL DEFAULT 'pt',
  max_goals   INT  NOT NULL DEFAULT 5,
  super_palpites_used INT NOT NULL DEFAULT 0,
  participate_in_ranking BOOLEAN NOT NULL DEFAULT true,
  paid        BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read all profiles"
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can update profiles"
  ON profiles FOR UPDATE USING (is_admin());

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
-- APP CONFIG
-- Server-driven key/value settings read by the app. Readable by everyone,
-- writable only by admins. See supabase/app_config.sql for usage notes.
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS app_config (
  key        TEXT PRIMARY KEY,
  value      JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read app_config"
  ON app_config FOR SELECT USING (true);

CREATE POLICY "Only admins can modify app_config"
  ON app_config FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- Reveal config for the Visitor Profile feature:
--   mode = 'global' | 'per_game_tail', protected_tail_count = trailing matches protected
INSERT INTO app_config (key, value)
VALUES ('reveal', '{"mode": "global", "protected_tail_count": 10}'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- Modo do sincronizador automático de placares (Edge Function sync-scores):
--   'shadow' = só registra em api_sync_runs (não escreve em matches)
--   'live'   = escreve placar/status em matches
INSERT INTO app_config (key, value)
VALUES ('sync_mode', '{"mode":"shadow"}'::jsonb)
ON CONFLICT (key) DO NOTHING;

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
  api_match_id  TEXT,    -- sequência interna 1..72 (seed/planilha; ordenação + sync manual)
  api_fixture_id BIGINT, -- fixture.id da API-Football (sync automático via Edge Function)
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Cada fixture da API mapeia para no máximo uma partida (vários NULL permitidos).
CREATE UNIQUE INDEX IF NOT EXISTS uniq_matches_api_fixture_id
  ON matches (api_fixture_id)
  WHERE api_fixture_id IS NOT NULL;

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
  p.full_name,
  p.display_preference,
  p.avatar_url,
  COALESCE(SUM(b.points), 0) AS total_points,
  RANK() OVER (PARTITION BY lm.league_id ORDER BY COALESCE(SUM(b.points), 0) DESC) AS rank,
  COUNT(b.id) AS total_bets
FROM league_members lm
JOIN leagues l ON l.id = lm.league_id
JOIN profiles p ON p.id = lm.user_id
LEFT JOIN bets b ON b.user_id = lm.user_id
GROUP BY lm.league_id, l.name, p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- ─────────────────────────────────────────────
-- ADVANCED STATS — RANKING VIEWS (família A)
-- Todas seguem o shape de user_rankings (user_id, username, full_name,
-- display_preference, avatar_url, total_points, total_bets, rank) para que o
-- frontend reuse RankingEntry/applyDenseRank sem código novo. A coluna
-- total_points carrega SEMPRE o valor da métrica de cada ranking.
-- Só expõem agregados (contagens/somatórios) — nenhum palpite individual vaza.
-- Futuro: espelhar cada uma com variante por liga (PARTITION BY league_id +
-- JOIN league_members), como em league_rankings.
-- ─────────────────────────────────────────────

-- 1) Rei do Placar Exato — quem mais cravou (points = 3)
CREATE OR REPLACE VIEW exact_score_rankings WITH (security_invoker = on) AS
SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
  COUNT(*) FILTER (WHERE b.points = 3)                              AS total_points,
  COUNT(b.id)                                                      AS total_bets,
  RANK() OVER (ORDER BY COUNT(*) FILTER (WHERE b.points = 3) DESC) AS rank
FROM profiles p LEFT JOIN bets b ON b.user_id = p.id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- 2) Pé-quente do Brasil — pontos somados nos jogos do Brasil
CREATE OR REPLACE VIEW brazil_points_rankings WITH (security_invoker = on) AS
SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
  COALESCE(SUM(b.points) FILTER (WHERE th.name = 'Brasil' OR ta.name = 'Brasil'), 0) AS total_points,
  COUNT(b.id)  FILTER (WHERE th.name = 'Brasil' OR ta.name = 'Brasil')               AS total_bets,
  RANK() OVER (ORDER BY COALESCE(SUM(b.points) FILTER (WHERE th.name = 'Brasil' OR ta.name = 'Brasil'), 0) DESC) AS rank
FROM profiles p
LEFT JOIN bets b    ON b.user_id = p.id
LEFT JOIN matches m ON m.id = b.match_id
LEFT JOIN teams th  ON th.id = m.home_team_id
LEFT JOIN teams ta  ON ta.id = m.away_team_id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- 3) Quase lá — errou o placar exato por 1 gol (cravou perto, não levou os 3)
CREATE OR REPLACE VIEW near_miss_rankings WITH (security_invoker = on) AS
SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
  COUNT(*) FILTER (
    WHERE m.status = 'finished' AND b.points < 3
      AND ABS(b.home_score_bet - m.home_score) + ABS(b.away_score_bet - m.away_score) = 1
  ) AS total_points,
  COUNT(b.id) AS total_bets,
  RANK() OVER (ORDER BY COUNT(*) FILTER (
    WHERE m.status = 'finished' AND b.points < 3
      AND ABS(b.home_score_bet - m.home_score) + ABS(b.away_score_bet - m.away_score) = 1) DESC) AS rank
FROM profiles p
LEFT JOIN bets b    ON b.user_id = p.id
LEFT JOIN matches m ON m.id = b.match_id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- 4) Tacada do Dia — maior pontuação de um usuário num único dia (fuso SP)
CREATE OR REPLACE VIEW daily_top_rankings WITH (security_invoker = on) AS
WITH daily AS (
  SELECT b.user_id,
         (m.match_date AT TIME ZONE 'America/Sao_Paulo')::date AS match_day,
         SUM(b.points) AS day_points
  FROM bets b JOIN matches m ON m.id = b.match_id
  WHERE m.status = 'finished'
  GROUP BY b.user_id, (m.match_date AT TIME ZONE 'America/Sao_Paulo')::date
)
SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
  COALESCE(MAX(d.day_points), 0) AS total_points,
  COUNT(d.match_day)             AS total_bets,
  RANK() OVER (ORDER BY COALESCE(MAX(d.day_points), 0) DESC) AS rank
FROM profiles p LEFT JOIN daily d ON d.user_id = p.id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- 5) Mais Regular — pontuou no maior número de jogos finalizados (consistência)
CREATE OR REPLACE VIEW regularity_rankings WITH (security_invoker = on) AS
SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
  COUNT(*)    FILTER (WHERE m.status = 'finished' AND b.points > 0) AS total_points,
  COUNT(b.id) FILTER (WHERE m.status = 'finished')                 AS total_bets,
  RANK() OVER (ORDER BY COUNT(*) FILTER (WHERE m.status = 'finished' AND b.points > 0) DESC) AS rank
FROM profiles p
LEFT JOIN bets b    ON b.user_id = p.id
LEFT JOIN matches m ON m.id = b.match_id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- 6) Os Corajosos — palpites ousados: >= 5 gols de diferença OU >= 7 gols somados
CREATE OR REPLACE VIEW boldness_rankings WITH (security_invoker = on) AS
SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
  COUNT(*) FILTER (WHERE (ABS(b.home_score_bet - b.away_score_bet) >= 5 OR (b.home_score_bet + b.away_score_bet) >= 7)) AS total_points,
  COUNT(b.id)                                                        AS total_bets,
  RANK() OVER (ORDER BY COUNT(*) FILTER (WHERE (ABS(b.home_score_bet - b.away_score_bet) >= 5 OR (b.home_score_bet + b.away_score_bet) >= 7)) DESC) AS rank
FROM profiles p
LEFT JOIN bets b ON b.user_id = p.id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- 7) Do Contra que Acertou — cravou (points=3) um placar que < 20% do bolão apostou
CREATE OR REPLACE VIEW contrarian_rankings WITH (security_invoker = on) AS
WITH match_total AS (
  SELECT match_id, COUNT(*) AS n_bets FROM bets GROUP BY match_id
),
score_pop AS (
  SELECT match_id, home_score_bet, away_score_bet, COUNT(*) AS n_same
  FROM bets GROUP BY match_id, home_score_bet, away_score_bet
),
contrarian AS (
  SELECT b.user_id
  FROM bets b
  JOIN matches m     ON m.id = b.match_id AND m.status = 'finished'
  JOIN match_total mt ON mt.match_id = b.match_id
  JOIN score_pop sp   ON sp.match_id = b.match_id
                     AND sp.home_score_bet = b.home_score_bet
                     AND sp.away_score_bet = b.away_score_bet
  WHERE b.points = 3
    AND mt.n_bets > 0
    AND sp.n_same::numeric / mt.n_bets < 0.20
)
SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
  COUNT(c.user_id) AS total_points,
  COUNT(c.user_id) AS total_bets,
  RANK() OVER (ORDER BY COUNT(c.user_id) DESC) AS rank
FROM profiles p
LEFT JOIN contrarian c ON c.user_id = p.id
WHERE p.participate_in_ranking = true
GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- Detalhe do "Do Contra que Acertou": (user_id, match_id) das cravadas raras.
-- Usado ao tocar num jogador para mostrar apenas esses jogos. Mesmo critério do
-- contrarian_rankings; só expõe IDs de jogo (sem placares), respeita RLS.
CREATE OR REPLACE VIEW contrarian_matches WITH (security_invoker = on) AS
WITH match_total AS (
  SELECT match_id, COUNT(*) AS n_bets FROM bets GROUP BY match_id
),
score_pop AS (
  SELECT match_id, home_score_bet, away_score_bet, COUNT(*) AS n_same
  FROM bets GROUP BY match_id, home_score_bet, away_score_bet
)
SELECT b.user_id, b.match_id
FROM bets b
JOIN matches m      ON m.id = b.match_id AND m.status = 'finished'
JOIN match_total mt ON mt.match_id = b.match_id
JOIN score_pop sp   ON sp.match_id = b.match_id
                   AND sp.home_score_bet = b.home_score_bet
                   AND sp.away_score_bet = b.away_score_bet
WHERE b.points = 3
  AND mt.n_bets > 0
  AND sp.n_same::numeric / mt.n_bets < 0.20;

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
  -- Data Limite Global: 11 de Junho 2026, 14:30 GMT-3 = 11 de Junho 2026, 17:30 UTC
  -- (alinhado com kBetDeadline em lib/core/constants.dart)
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
  --    (ERRCODE mapeado no app: lib/shared/utils/error_messages.dart)
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
     -- Verificar saldo do usuário
     SELECT super_palpites_used INTO v_used FROM profiles WHERE id = NEW.user_id;

     IF v_used >= 10 THEN
        RAISE EXCEPTION 'Você já atingiu o limite de 10 Super Palpites.'
          USING ERRCODE = 'P0012';
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

-- ─────────────────────────────────────────────
-- API SYNC LOG (Edge Function sync-scores)
-- Registra o que o sincronizador automático fez (modo 'live') ou faria
-- (modo 'shadow'). Ver supabase/setup_api_sync.sql.
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS api_sync_runs (
  id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ran_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  mode             TEXT NOT NULL,
  source_game_id   TEXT,
  match_id         UUID REFERENCES matches(id) ON DELETE SET NULL,
  group_letter     TEXT,
  home_team        TEXT,
  away_team        TEXT,
  src_home_score   INT,
  src_away_score   INT,
  src_status       TEXT,
  src_raw_finished TEXT,
  src_time_elapsed TEXT,
  applied          BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_api_sync_runs_ran_at ON api_sync_runs (ran_at DESC);

ALTER TABLE api_sync_runs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Only admins read api_sync_runs" ON api_sync_runs;
CREATE POLICY "Only admins read api_sync_runs"
  ON api_sync_runs FOR SELECT USING (is_admin());
