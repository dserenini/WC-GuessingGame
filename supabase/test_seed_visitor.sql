-- =============================================================================
-- TEST SEED — Visitor Profile feature (LOCAL ENVIRONMENT ONLY)
--
-- ⚠️  DO NOT RUN IN PRODUCTION. This creates a fake user, rewrites match dates
--     and statuses, and bulk-inserts bets to exercise every card state.
--
-- Prereqs: schema.sql + seed.sql + app_config.sql already applied locally.
-- After running, log in as admin1@bolao.com / CHANGE_ME_ON_SETUP (the "viewer"), set
-- kDebugForceReveal = true in lib/core/constants.dart, open the Ranking and
-- tap "Beto Visitante" to see the comparison screen.
-- =============================================================================

-- ─────────────────────────────────────────────
-- 1. Create user B ("Beto Visitante")
-- ─────────────────────────────────────────────
DELETE FROM auth.users WHERE email = 'userb@bolao.com';

INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at,
    updated_at, confirmation_token, email_change, email_change_token_new, recovery_token
) VALUES (
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'userb@bolao.com', crypt('test123', gen_salt('bf')),
  now(), now(), now(), '{"provider":"email","providers":["email"]}',
  '{"username":"beto"}', now(), now(), '', '', '', ''
);

-- handle_new_user() auto-creates the profile; enrich it for a nicer display.
UPDATE profiles
   SET full_name = 'Beto Visitante',
       display_preference = 'full_name',
       participate_in_ranking = true
 WHERE id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

-- ─────────────────────────────────────────────
-- 2. Spread match kickoff times so reveal/tail/time chips are meaningful.
--    api_match_id 1..72 → match_date from ~40h ago to ~32h ahead (distinct).
--    Reset everything to 'scheduled' first; statuses are set in step 4.
-- ─────────────────────────────────────────────
UPDATE matches m
   SET match_date = NOW() - INTERVAL '40 hours' + ((m.api_match_id)::int * INTERVAL '1 hour'),
       status = 'scheduled',
       home_score = NULL,
       away_score = NULL
 WHERE m.api_match_id ~ '^[0-9]+$';

-- ─────────────────────────────────────────────
-- 3. Bulk-insert bets for B and for admin1 (the viewer) across ALL matches.
--    Disable the deadline/super-palpite trigger so seeding isn't blocked.
-- ─────────────────────────────────────────────
ALTER TABLE bets DISABLE TRIGGER enforce_bet_rules;

-- B's bets
INSERT INTO bets (user_id, match_id, home_score_bet, away_score_bet)
SELECT 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', m.id,
       ((m.api_match_id)::int % 4),
       (((m.api_match_id)::int + 1) % 3)
FROM matches m
WHERE m.api_match_id ~ '^[0-9]+$'
ON CONFLICT (user_id, match_id) DO UPDATE
  SET home_score_bet = EXCLUDED.home_score_bet,
      away_score_bet = EXCLUDED.away_score_bet;

-- admin1's bets (so the viewer is "complete" and the faded "You" line shows)
INSERT INTO bets (user_id, match_id, home_score_bet, away_score_bet)
SELECT '11111111-1111-1111-1111-111111111111', m.id,
       (((m.api_match_id)::int + 2) % 4),
       ((m.api_match_id)::int % 3)
FROM matches m
WHERE m.api_match_id ~ '^[0-9]+$'
ON CONFLICT (user_id, match_id) DO UPDATE
  SET home_score_bet = EXCLUDED.home_score_bet,
      away_score_bet = EXCLUDED.away_score_bet;

ALTER TABLE bets ENABLE TRIGGER enforce_bet_rules;

-- ─────────────────────────────────────────────
-- 4. Force a few match states so all card states are visible.
--    Setting a match 'finished' fires the scoring trigger (computes points).
-- ─────────────────────────────────────────────
-- FINISHED (past) — exercises green/amber/gray badges
UPDATE matches SET home_score = 3, away_score = 1, status = 'finished' WHERE api_match_id = '1';
UPDATE matches SET home_score = 0, away_score = 0, status = 'finished' WHERE api_match_id = '2';
UPDATE matches SET home_score = 2, away_score = 2, status = 'finished' WHERE api_match_id = '5';

-- LIVE (now) — exercises the "AO VIVO" pill and the "parcial" points
UPDATE matches
   SET match_date = NOW() - INTERVAL '30 minutes', home_score = 1, away_score = 0, status = 'live'
 WHERE api_match_id = '40';

-- The remaining future matches stay 'scheduled' (the "antes do jogo" state),
-- and the last 10 chronological matches form the protected tail for testing
-- mode = 'per_game_tail'.

-- ─────────────────────────────────────────────
-- 5. (Optional) Switch reveal mode to per-game-tail to test the lock:
--   UPDATE app_config
--      SET value = '{"mode":"per_game_tail","protected_tail_count":10}'::jsonb,
--          updated_at = NOW()
--    WHERE key = 'reveal';
-- =============================================================================
