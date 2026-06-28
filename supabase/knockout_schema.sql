-- =============================================================================
-- BOLÃO MATA-MATA — schema simplificado (v3)
--   Só PLACAR por jogo. Pontuação = fase de grupos: 3 (cravado) / 1 (direção) / 0.
--   SEM bônus, "quem avança" ou seleção única.
--   ko_match mantém advancing_team_id (vem do RESULTADO real, não de palpite) só
--   para desenhar/animar o bracket. NÃO toca em nada da fase de grupos.
--   Pré-lançamento: recria os ko_* do zero a cada run (sem dados reais em prod).
-- =============================================================================

DROP VIEW     IF EXISTS v_ko_ranking;
DROP VIEW     IF EXISTS ko_user_rankings;
DROP VIEW     IF EXISTS ko_league_rankings;
DROP VIEW     IF EXISTS ko_exact_score_rankings;
DROP TABLE    IF EXISTS ko_bet            CASCADE;
DROP TABLE    IF EXISTS ko_champion_pick  CASCADE;
DROP TABLE    IF EXISTS ko_bracket_pick   CASCADE;
DROP TABLE    IF EXISTS ko_team_pick      CASCADE;
DROP TABLE    IF EXISTS ko_match          CASCADE;
-- funções de versões anteriores (bônus/seleção) — removidas
DROP FUNCTION IF EXISTS ko_recompute_bracket_bonus();
DROP FUNCTION IF EXISTS ko_bracket_locked();
DROP FUNCTION IF EXISTS ko_bracket_pick_guard();
DROP FUNCTION IF EXISTS ko_score_team_picks();
DROP FUNCTION IF EXISTS ko_score_bracket_picks();
DROP FUNCTION IF EXISTS ko_team_reached(uuid, text);
DROP FUNCTION IF EXISTS ko_bracket_deadline();

-- ─────────────────────────────────────────────────────────────────────────────
-- 1) CONFIG (flag + pontos) — tunável sem rebuild
-- ─────────────────────────────────────────────────────────────────────────────
-- Pontos por fase: 3/1 nas fases iniciais; 5/3 na Semifinal e Final. Bônus de
-- campeão (palpite único do campeão da Copa) = +3.
INSERT INTO app_config (key, value)
VALUES ('knockout', jsonb_build_object(
  'enabled', false,
  'points',         jsonb_build_object('exact', 3, 'direction', 1),
  'points_finals',  jsonb_build_object('exact', 5, 'direction', 3),
  'champion_bonus', 3
))
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

CREATE OR REPLACE FUNCTION ko_cfg()
RETURNS jsonb LANGUAGE sql STABLE AS $$
  SELECT value FROM app_config WHERE key = 'knockout';
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2) TABELAS
-- ─────────────────────────────────────────────────────────────────────────────

-- 2.1 Jogos do mata-mata + árvore do chaveamento (auto-referência src_match)
CREATE TABLE ko_match (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  round              text NOT NULL CHECK (round IN ('16avos','oitavas','quartas','semis','final','3lugar')),
  slot               int  NOT NULL,
  home_team_id       uuid REFERENCES teams(id),
  away_team_id       uuid REFERENCES teams(id),
  home_src_match     uuid REFERENCES ko_match(id),
  away_src_match     uuid REFERENCES ko_match(id),
  match_date         timestamptz,
  home_score         int,                       -- placar do TEMPO REGULAR (90'); prorrogação/pênaltis NÃO contam aqui
  away_score         int,
  home_pens          int,                       -- pênaltis (informativo)
  away_pens          int,
  advancing_team_id  uuid REFERENCES teams(id), -- quem avança (resultado real; resolve empate via prorrog./pênaltis)
  status             text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','live','finished')),
  api_fixture_id     bigint,
  created_at         timestamptz NOT NULL DEFAULT now(),
  UNIQUE (round, slot)
);
CREATE INDEX ix_ko_match_round ON ko_match(round);

-- 2.2 Aposta de placar (1 por usuário/jogo) — pontuação igual à fase de grupos
CREATE TABLE ko_bet (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  ko_match_id     uuid NOT NULL REFERENCES ko_match(id) ON DELETE CASCADE,
  home_score_bet  int  NOT NULL,
  away_score_bet  int  NOT NULL,
  points          int  NOT NULL DEFAULT 0,
  exact           boolean NOT NULL DEFAULT false,   -- p/ desempate
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, ko_match_id)
);
CREATE INDEX ix_ko_bet_match ON ko_bet(ko_match_id);
CREATE INDEX ix_ko_bet_user  ON ko_bet(user_id);

-- 2.3 Palpite de CAMPEÃO (1 por usuário) — quem leva a Copa. Fecha no início do
--     mata-mata; acertar dá bônus (champion_bonus) no ranking.
CREATE TABLE ko_champion_pick (
  user_id    uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  team_id    uuid NOT NULL REFERENCES teams(id),
  points     int  NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_ko_champion_pick_team ON ko_champion_pick(team_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3) PONTUAÇÃO — 5/3 na Semi/Final, 3/1 nas demais; + bônus de campeão na final
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION score_ko_match()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp AS $$
DECLARE
  cfg           jsonb   := ko_cfg();
  is_finals     boolean := NEW.round IN ('semis','final');
  pts           jsonb   := CASE WHEN is_finals THEN cfg->'points_finals' ELSE cfg->'points' END;
  v_exact       int     := COALESCE((pts->>'exact')::int,     CASE WHEN is_finals THEN 5 ELSE 3 END);
  v_dir         int     := COALESCE((pts->>'direction')::int, CASE WHEN is_finals THEN 3 ELSE 1 END);
  v_champ_bonus int     := COALESCE((cfg->>'champion_bonus')::int, 3);
BEGIN
  IF NEW.status = 'finished' AND NEW.home_score IS NOT NULL AND NEW.away_score IS NOT NULL THEN
    UPDATE ko_bet b SET
      exact = (b.home_score_bet = NEW.home_score AND b.away_score_bet = NEW.away_score),
      points = CASE
        WHEN b.home_score_bet = NEW.home_score AND b.away_score_bet = NEW.away_score THEN v_exact
        WHEN (b.home_score_bet > b.away_score_bet AND NEW.home_score > NEW.away_score)
          OR (b.home_score_bet < b.away_score_bet AND NEW.home_score < NEW.away_score)
          OR (b.home_score_bet = b.away_score_bet AND NEW.home_score = NEW.away_score) THEN v_dir
        ELSE 0 END,
      updated_at = now()
    WHERE b.ko_match_id = NEW.id;
  END IF;

  -- Bônus de campeão: quando a FINAL termina com o vencedor definido.
  IF NEW.round = 'final' AND NEW.status = 'finished' AND NEW.advancing_team_id IS NOT NULL THEN
    UPDATE ko_champion_pick cp SET
      points     = CASE WHEN cp.team_id = NEW.advancing_team_id THEN v_champ_bonus ELSE 0 END,
      updated_at = now();
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_score_ko_match ON ko_match;
CREATE TRIGGER trg_score_ko_match
  AFTER INSERT OR UPDATE ON ko_match
  FOR EACH ROW EXECUTE FUNCTION score_ko_match();

-- ─────────────────────────────────────────────────────────────────────────────
-- 4) PRAZO (30 min antes; precisa dos 2 times definidos) — bypass admin
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION ko_bet_deadline()
RETURNS trigger LANGUAGE plpgsql
SET search_path = public, pg_temp AS $$
DECLARE m ko_match%ROWTYPE;
BEGIN
  IF is_admin() THEN RETURN NEW; END IF;
  -- Update de SISTEMA (pontuação): não altera o placar apostado → libera mesmo
  -- após o prazo (senão o trigger de scoring travaria ao finalizar o jogo).
  IF TG_OP = 'UPDATE'
     AND NEW.home_score_bet = OLD.home_score_bet
     AND NEW.away_score_bet = OLD.away_score_bet THEN
    RETURN NEW;
  END IF;
  SELECT * INTO m FROM ko_match WHERE id = NEW.ko_match_id;
  IF m.home_team_id IS NULL OR m.away_team_id IS NULL THEN
    RAISE EXCEPTION 'Confronto ainda não definido para este jogo.';
  END IF;
  IF now() > m.match_date - interval '30 minutes' THEN
    RAISE EXCEPTION 'Apostas encerradas (até 30 min antes do jogo).';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ko_bet_deadline ON ko_bet;
CREATE TRIGGER trg_ko_bet_deadline
  BEFORE INSERT OR UPDATE ON ko_bet
  FOR EACH ROW EXECUTE FUNCTION ko_bet_deadline();

-- 4.1 PRAZO do palpite de campeão — fecha no INÍCIO do 1º jogo do mata-mata.
CREATE OR REPLACE FUNCTION ko_champion_deadline()
RETURNS trigger LANGUAGE plpgsql
SET search_path = public, pg_temp AS $$
DECLARE
  -- Prazo FIXO: 29/06/2026 12:00 GMT-3 = 15:00 UTC (antes era min(match_date)).
  -- Espelha kKoChampionPickDeadline no app. Ver knockout_champion_deadline_2906.sql.
  CHAMPION_DEADLINE timestamptz := '2026-06-29 15:00:00+00';
BEGIN
  IF is_admin() THEN RETURN NEW; END IF;
  IF TG_OP = 'UPDATE' AND NEW.team_id = OLD.team_id THEN
    RETURN NEW;
  END IF;
  IF now() >= CHAMPION_DEADLINE THEN
    RAISE EXCEPTION 'Palpite de campeão encerrado (fecha 29/06 às 12h, horário de Brasília).';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ko_champion_deadline ON ko_champion_pick;
CREATE TRIGGER trg_ko_champion_deadline
  BEFORE INSERT OR UPDATE ON ko_champion_pick
  FOR EACH ROW EXECUTE FUNCTION ko_champion_deadline();

-- ─────────────────────────────────────────────────────────────────────────────
-- 5) VIEWS DE RANKING (mesmo formato de user_rankings / league_rankings, p/
--    reusar a tela de Ranking e Ligas existentes). Zera; só placar do mata-mata.
-- ─────────────────────────────────────────────────────────────────────────────
-- total_points = pontos das apostas de placar + bônus de campeão (subconsulta
-- escalar p/ não multiplicar pelas linhas de ko_bet).
CREATE OR REPLACE VIEW ko_user_rankings AS
  SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
         COALESCE(sum(b.points), 0)
           + COALESCE((SELECT cp.points FROM ko_champion_pick cp WHERE cp.user_id = p.id), 0)
             AS total_points,
         count(b.id) AS total_bets,
         rank() OVER (ORDER BY
           COALESCE(sum(b.points), 0)
             + COALESCE((SELECT cp.points FROM ko_champion_pick cp WHERE cp.user_id = p.id), 0)
           DESC) AS rank
  FROM profiles p
  LEFT JOIN ko_bet b ON b.user_id = p.id
  WHERE p.participate_in_ranking = true
  GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

CREATE OR REPLACE VIEW ko_league_rankings AS
  SELECT lm.league_id, l.name AS league_name, p.id AS user_id, p.username, p.full_name,
         p.display_preference, p.avatar_url,
         COALESCE(sum(b.points), 0)
           + COALESCE((SELECT cp.points FROM ko_champion_pick cp WHERE cp.user_id = p.id), 0)
             AS total_points,
         rank() OVER (PARTITION BY lm.league_id ORDER BY
           COALESCE(sum(b.points), 0)
             + COALESCE((SELECT cp.points FROM ko_champion_pick cp WHERE cp.user_id = p.id), 0)
           DESC) AS rank,
         count(b.id) AS total_bets
  FROM league_members lm
  JOIN leagues l ON l.id = lm.league_id
  JOIN profiles p ON p.id = lm.user_id
  LEFT JOIN ko_bet b ON b.user_id = lm.user_id
  GROUP BY lm.league_id, l.name, p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- Ranking de CRAVADAS do mata-mata (total_points = nº de placares cravados).
CREATE OR REPLACE VIEW ko_exact_score_rankings AS
  SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
         COALESCE(sum(CASE WHEN b.exact THEN 1 ELSE 0 END), 0) AS total_points,
         count(b.id) AS total_bets,
         rank() OVER (ORDER BY COALESCE(sum(CASE WHEN b.exact THEN 1 ELSE 0 END), 0) DESC) AS rank
  FROM profiles p
  LEFT JOIN ko_bet b ON b.user_id = p.id
  WHERE p.participate_in_ranking = true
  GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6) RLS — lê tudo p/ jogos; aposta própria sempre; dos outros só após início
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE ko_match         ENABLE ROW LEVEL SECURITY;
ALTER TABLE ko_bet           ENABLE ROW LEVEL SECURITY;
ALTER TABLE ko_champion_pick ENABLE ROW LEVEL SECURITY;

CREATE POLICY ko_match_read  ON ko_match FOR SELECT USING (true);
CREATE POLICY ko_match_admin ON ko_match FOR ALL USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY ko_bet_read ON ko_bet FOR SELECT USING (
  user_id = auth.uid()
  OR EXISTS (SELECT 1 FROM ko_match m WHERE m.id = ko_match_id AND now() >= m.match_date));
CREATE POLICY ko_bet_ins ON ko_bet FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY ko_bet_upd ON ko_bet FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Palpite de campeão: lê o próprio sempre; dos outros só após o mata-mata começar
-- (revela a distribuição nas estatísticas). NOTA: o gate de inscrição paga
-- (knockout_unlocked) é aplicado em knockout_access.sql, igual ao ko_bet.
CREATE POLICY kcp_read ON ko_champion_pick FOR SELECT USING (
  user_id = auth.uid()
  OR EXISTS (SELECT 1 FROM ko_match m WHERE m.match_date IS NOT NULL AND now() >= m.match_date));
CREATE POLICY kcp_ins ON ko_champion_pick FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY kcp_upd ON ko_champion_pick FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────────
-- 7) GRANTS
-- ─────────────────────────────────────────────────────────────────────────────
GRANT SELECT ON ko_match TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ko_match, ko_bet, ko_champion_pick TO authenticated;
GRANT SELECT ON ko_bet, ko_champion_pick TO anon;
GRANT SELECT ON ko_user_rankings, ko_league_rankings, ko_exact_score_rankings TO anon, authenticated;
