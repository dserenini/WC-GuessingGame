-- =============================================================================
-- COPA 2026 — Seed Data
-- Run AFTER schema.sql
-- =============================================================================

-- ─────────────────────────────────────────────
-- TEAMS (48 teams, 12 groups of 4)
-- ─────────────────────────────────────────────
INSERT INTO teams (name, flag_url, group_letter) VALUES
-- Group A
('Mexico',       'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Flag_of_Mexico.svg/320px-Flag_of_Mexico.svg.png',          'A'),
('South Africa', 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/af/Flag_of_South_Africa.svg/320px-Flag_of_South_Africa.svg.png','A'),
('South Korea',  'https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/Flag_of_South_Korea.svg/320px-Flag_of_South_Korea.svg.png', 'A'),
('Czechia',      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Flag_of_the_Czech_Republic.svg/320px-Flag_of_the_Czech_Republic.svg.png','A'),
-- Group B
('Canada',                'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Flag_of_Canada_%28Pantone%29.svg/320px-Flag_of_Canada_%28Pantone%29.svg.png','B'),
('Switzerland',           'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Flag_of_Switzerland.svg/240px-Flag_of_Switzerland.svg.png','B'),
('Qatar',                 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/Flag_of_Qatar.svg/320px-Flag_of_Qatar.svg.png',      'B'),
('Bosnia and Herzegovina','https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/Flag_of_Bosnia_and_Herzegovina.svg/320px-Flag_of_Bosnia_and_Herzegovina.svg.png','B'),
-- Group C
('Brazil',   'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Flag_of_Brazil.svg/320px-Flag_of_Brazil.svg.png',               'C'),
('Morocco',  'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Flag_of_Morocco.svg/320px-Flag_of_Morocco.svg.png',              'C'),
('Haiti',    'https://upload.wikimedia.org/wikipedia/commons/thumb/5/56/Flag_of_Haiti.svg/320px-Flag_of_Haiti.svg.png',                  'C'),
('Scotland', 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Flag_of_Scotland.svg/320px-Flag_of_Scotland.svg.png',            'C'),
-- Group D
('United States','https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Flag_of_the_United_States.svg/320px-Flag_of_the_United_States.svg.png','D'),
('Paraguay',     'https://upload.wikimedia.org/wikipedia/commons/thumb/2/27/Flag_of_Paraguay.svg/320px-Flag_of_Paraguay.svg.png',        'D'),
('Australia',    'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Flag_of_Australia.svg/320px-Flag_of_Australia.svg.png',      'D'),
('Türkiye',      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b4/Flag_of_Turkey.svg/320px-Flag_of_Turkey.svg.png',            'D'),
-- Group E
('Germany',     'https://upload.wikimedia.org/wikipedia/commons/thumb/b/ba/Flag_of_Germany.svg/320px-Flag_of_Germany.svg.png',           'E'),
('Curaçao',     'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/Flag_of_Cura%C3%A7ao.svg/320px-Flag_of_Cura%C3%A7ao.svg.png','E'),
('Ivory Coast', 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Flag_of_C%C3%B4te_d%27Ivoire.svg/320px-Flag_of_C%C3%B4te_d%27Ivoire.svg.png','E'),
('Ecuador',     'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Flag_of_Ecuador.svg/320px-Flag_of_Ecuador.svg.png',           'E'),
-- Group F
('Netherlands','https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/Flag_of_the_Netherlands.svg/320px-Flag_of_the_Netherlands.svg.png','F'),
('Japan',      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/Flag_of_Japan.svg/320px-Flag_of_Japan.svg.png',                'F'),
('Sweden',     'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Flag_of_Sweden.svg/320px-Flag_of_Sweden.svg.png',              'F'),
('Tunisia',    'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Flag_of_Tunisia.svg/320px-Flag_of_Tunisia.svg.png',            'F'),
-- Group G
('Belgium',     'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/Flag_of_Belgium.svg/320px-Flag_of_Belgium.svg.png',           'G'),
('Egypt',       'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Flag_of_Egypt.svg/320px-Flag_of_Egypt.svg.png',               'G'),
('IR Iran',     'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Flag_of_Iran.svg/320px-Flag_of_Iran.svg.png',                 'G'),
('New Zealand', 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Flag_of_New_Zealand.svg/320px-Flag_of_New_Zealand.svg.png',   'G'),
-- Group H
('Spain',        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Flag_of_Spain.svg/320px-Flag_of_Spain.svg.png',              'H'),
('Cabo Verde',   'https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Flag_of_Cape_Verde.svg/320px-Flag_of_Cape_Verde.svg.png',    'H'),
('Saudi Arabia', 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0d/Flag_of_Saudi_Arabia.svg/320px-Flag_of_Saudi_Arabia.svg.png','H'),
('Uruguay',      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Flag_of_Uruguay.svg/320px-Flag_of_Uruguay.svg.png',          'H'),
-- Group I
('France',  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Flag_of_France.svg/320px-Flag_of_France.svg.png',                'I'),
('Senegal', 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fd/Flag_of_Senegal.svg/320px-Flag_of_Senegal.svg.png',              'I'),
('Iraq',    'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Flag_of_Iraq.svg/320px-Flag_of_Iraq.svg.png',                    'I'),
('Norway',  'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Flag_of_Norway.svg/320px-Flag_of_Norway.svg.png',               'I'),
-- Group J
('Argentina','https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Flag_of_Argentina.svg/320px-Flag_of_Argentina.svg.png',         'J'),
('Algeria',  'https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/Flag_of_Algeria.svg/320px-Flag_of_Algeria.svg.png',             'J'),
('Austria',  'https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/Flag_of_Austria.svg/320px-Flag_of_Austria.svg.png',             'J'),
('Jordan',   'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c0/Flag_of_Jordan.svg/320px-Flag_of_Jordan.svg.png',              'J'),
-- Group K
('Portugal',   'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Flag_of_Portugal.svg/320px-Flag_of_Portugal.svg.png',         'K'),
('DR Congo',   'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Flag_of_the_Democratic_Republic_of_the_Congo.svg/320px-Flag_of_the_Democratic_Republic_of_the_Congo.svg.png','K'),
('Uzbekistan', 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Flag_of_Uzbekistan.svg/320px-Flag_of_Uzbekistan.svg.png',     'K'),
('Colombia',   'https://upload.wikimedia.org/wikipedia/commons/thumb/2/21/Flag_of_Colombia.svg/320px-Flag_of_Colombia.svg.png',         'K'),
-- Group L
('England','https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/Flag_of_England.svg/320px-Flag_of_England.svg.png',               'L'),
('Croatia','https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Flag_of_Croatia.svg/320px-Flag_of_Croatia.svg.png',               'L'),
('Ghana',  'https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Flag_of_Ghana.svg/320px-Flag_of_Ghana.svg.png',                   'L'),
('Panama', 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Flag_of_Panama.svg/320px-Flag_of_Panama.svg.png',                 'L');

-- ─────────────────────────────────────────────
-- MATCHES (6 per group = 72 total)
-- Dates are approximate — update when official schedule is confirmed.
-- Each group plays a round-robin: pairs (0v1),(0v2),(0v3),(1v2),(1v3),(2v3)
-- ─────────────────────────────────────────────

-- Helper: Insert all 6 matches for a group using a DO block
DO $$
DECLARE
  t RECORD;
  t0 UUID; t1 UUID; t2 UUID; t3 UUID;
  grp CHAR;
BEGIN
  FOR grp IN SELECT UNNEST(ARRAY['A','B','C','D','E','F','G','H','I','J','K','L'])
  LOOP
    -- Get the 4 team IDs for this group in insertion order
    SELECT id INTO t0 FROM teams WHERE group_letter = grp ORDER BY name LIMIT 1 OFFSET 0;
    SELECT id INTO t1 FROM teams WHERE group_letter = grp ORDER BY name LIMIT 1 OFFSET 1;
    SELECT id INTO t2 FROM teams WHERE group_letter = grp ORDER BY name LIMIT 1 OFFSET 2;
    SELECT id INTO t3 FROM teams WHERE group_letter = grp ORDER BY name LIMIT 1 OFFSET 3;

    -- 6 matchups per group
    INSERT INTO matches (group_letter, home_team_id, away_team_id)
    VALUES
      (grp, t0, t1),
      (grp, t0, t2),
      (grp, t0, t3),
      (grp, t1, t2),
      (grp, t1, t3),
      (grp, t2, t3);
  END LOOP;
END;
$$;

-- ─────────────────────────────────────────────
-- ADMINS (Create Auth Users & Admin references)
-- ─────────────────────────────────────────────
-- 1. Delete previous attempts (if any)
DELETE FROM auth.users WHERE email IN ('admin1@bolao.com', 'admin2@bolao.com', 'admin3@bolao.com');
DELETE FROM admins WHERE user_id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');

-- 2. Create Auth Users (Password for all: CHANGE_ME_ON_SETUP)
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, 
    recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, 
    updated_at, confirmation_token, email_change, email_change_token_new, recovery_token
) VALUES
('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin1@bolao.com', crypt('CHANGE_ME_ON_SETUP', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
('22222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin2@bolao.com', crypt('CHANGE_ME_ON_SETUP', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
('33333333-3333-3333-3333-333333333333', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin3@bolao.com', crypt('CHANGE_ME_ON_SETUP', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

-- 2. Grant them Admin role in our custom table
INSERT INTO admins (user_id) VALUES
  ('11111111-1111-1111-1111-111111111111'),
  ('22222222-2222-2222-2222-222222222222'),
  ('33333333-3333-3333-3333-333333333333');

-- ─────────────────────────────────────────────
-- POPULATE API MATCH IDs
-- Assigns a sequential api_match_id to each match
-- ─────────────────────────────────────────────
WITH numbered_matches AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY match_date, group_letter) as seq_id
  FROM matches
)
UPDATE matches
SET api_match_id = numbered_matches.seq_id::TEXT
FROM numbered_matches
WHERE matches.id = numbered_matches.id;

