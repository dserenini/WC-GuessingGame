-- =============================================================================
-- APP CONFIG — server-driven settings read by the app (PRODUCTION)
-- Run this in the Supabase SQL Editor. Requires is_admin() (from schema.sql).
-- =============================================================================

-- Generic key/value config table. The app reads rows by `key`.
CREATE TABLE IF NOT EXISTS app_config (
  key        TEXT PRIMARY KEY,
  value      JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

-- Everyone can read config (needed by the client). Only admins may change it.
DROP POLICY IF EXISTS "Anyone can read app_config" ON app_config;
CREATE POLICY "Anyone can read app_config"
  ON app_config FOR SELECT USING (true);

DROP POLICY IF EXISTS "Only admins can modify app_config" ON app_config;
CREATE POLICY "Only admins can modify app_config"
  ON app_config FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- ─────────────────────────────────────────────
-- REVEAL CONFIG (Visitor Profile feature)
--   mode:
--     'global'        → after the betting deadline, all bets are visible
--     'per_game_tail' → the last N matches (chronological) reveal per-game,
--                       only once each one kicks off; the rest follow 'global'
--   protected_tail_count: how many trailing matches are protected (default 10)
-- ─────────────────────────────────────────────
INSERT INTO app_config (key, value)
VALUES ('reveal', '{"mode": "global", "protected_tail_count": 10}'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- ─────────────────────────────────────────────
-- HOW TO CHANGE IT MID-TOURNAMENT (no app rebuild needed)
-- ─────────────────────────────────────────────
-- Protect the last 10 matches (e.g. for the final stretch):
--   UPDATE app_config
--      SET value = '{"mode":"per_game_tail","protected_tail_count":10}'::jsonb,
--          updated_at = NOW()
--    WHERE key = 'reveal';
--
-- Change only the protected count to 15:
--   UPDATE app_config
--      SET value = jsonb_set(value, '{protected_tail_count}', '15'),
--          updated_at = NOW()
--    WHERE key = 'reveal';
--
-- Back to global (reveal everything after the deadline):
--   UPDATE app_config
--      SET value = '{"mode":"global","protected_tail_count":10}'::jsonb,
--          updated_at = NOW()
--    WHERE key = 'reveal';
