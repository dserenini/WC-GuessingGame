-- =============================================================================
-- BOLÃO MATA-MATA — regras v4 (ADITIVO, idempotente). Rode no SQL editor da PROD.
--   1) Pontuação reforçada na Semifinal e Final: cravada=5 / resultado=3
--      (demais fases seguem 3/1; disputa de 3º NÃO entra no reforço).
--   2) Palpite de CAMPEÃO: 1 por usuário, fecha no início do mata-mata; acertar
--      o campeão (advancing_team_id da FINAL) dá +3 pts no ranking do mata-mata.
--   3) Prazo de aposta do mata-mata passa de 1h → 30 min antes do jogo.
--   4) Rankings do mata-mata somam o bônus de campeão; nova view de "cravadas".
--   NÃO dropa ko_match/ko_bet (preserva apostas já existentes). Pode rodar de novo.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1) CONFIG — pontos por fase + bônus de campeão (preserva `enabled`)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO app_config (key, value)
VALUES ('knockout', jsonb_build_object(
  'enabled',        false,
  'points',         jsonb_build_object('exact', 3, 'direction', 1),
  'points_finals',  jsonb_build_object('exact', 5, 'direction', 3),
  'champion_bonus', 3
))
ON CONFLICT (key) DO UPDATE SET value =
      app_config.value
   || jsonb_build_object('points',         jsonb_build_object('exact', 3, 'direction', 1))
   || jsonb_build_object('points_finals',  jsonb_build_object('exact', 5, 'direction', 3))
   || jsonb_build_object('champion_bonus', 3);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2) TABELA — palpite de campeão (1 por usuário)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ko_champion_pick (
  user_id    uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  team_id    uuid NOT NULL REFERENCES teams(id),
  points     int  NOT NULL DEFAULT 0,        -- 0; vira champion_bonus após a final se acertou
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_ko_champion_pick_team ON ko_champion_pick(team_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3) PRAZO do palpite de campeão — fecha no INÍCIO do 1º jogo do mata-mata
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION ko_champion_deadline()
RETURNS trigger LANGUAGE plpgsql
SET search_path = public, pg_temp AS $$
DECLARE first_ko timestamptz;
BEGIN
  IF is_admin() THEN RETURN NEW; END IF;
  -- Update de SISTEMA (pontuação): não muda o time escolhido → libera.
  IF TG_OP = 'UPDATE' AND NEW.team_id = OLD.team_id THEN
    RETURN NEW;
  END IF;
  SELECT min(match_date) INTO first_ko FROM ko_match WHERE match_date IS NOT NULL;
  IF first_ko IS NOT NULL AND now() >= first_ko THEN
    RAISE EXCEPTION 'Palpite de campeão encerrado (fecha no início do mata-mata).';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ko_champion_deadline ON ko_champion_pick;
CREATE TRIGGER trg_ko_champion_deadline
  BEFORE INSERT OR UPDATE ON ko_champion_pick
  FOR EACH ROW EXECUTE FUNCTION ko_champion_deadline();

-- ─────────────────────────────────────────────────────────────────────────────
-- 4) PONTUAÇÃO — 5/3 na semi/final, 3/1 nas demais; + bônus de campeão na final
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
-- (trigger trg_score_ko_match já existe e segue ligado a esta função.)

-- ─────────────────────────────────────────────────────────────────────────────
-- 5) PRAZO da aposta de placar — 30 min antes (era 1h)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION ko_bet_deadline()
RETURNS trigger LANGUAGE plpgsql
SET search_path = public, pg_temp AS $$
DECLARE m ko_match%ROWTYPE;
BEGIN
  IF is_admin() THEN RETURN NEW; END IF;
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
-- (trigger trg_ko_bet_deadline já existe e segue ligado a esta função.)

-- ─────────────────────────────────────────────────────────────────────────────
-- 6) RLS + GRANTS do palpite de campeão (espelha ko_bet: gate por inscrição)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE ko_champion_pick ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS kcp_read  ON ko_champion_pick;
DROP POLICY IF EXISTS kcp_ins   ON ko_champion_pick;
DROP POLICY IF EXISTS kcp_upd   ON ko_champion_pick;
DROP POLICY IF EXISTS kcp_admin ON ko_champion_pick;

-- Lê o próprio sempre; dos outros só depois que o mata-mata começou (revela
-- a distribuição de palpites de campeão nas estatísticas).
CREATE POLICY kcp_read ON ko_champion_pick FOR SELECT USING (
  user_id = auth.uid()
  OR EXISTS (SELECT 1 FROM ko_match m WHERE m.match_date IS NOT NULL AND now() >= m.match_date)
);
CREATE POLICY kcp_ins ON ko_champion_pick FOR INSERT WITH CHECK (
  user_id = auth.uid()
  AND (is_admin()
       OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.knockout_unlocked = true))
);
CREATE POLICY kcp_upd ON ko_champion_pick FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid()
    AND (is_admin()
         OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.knockout_unlocked = true))
  );
CREATE POLICY kcp_admin ON ko_champion_pick FOR ALL USING (is_admin()) WITH CHECK (is_admin());

GRANT SELECT, INSERT, UPDATE, DELETE ON ko_champion_pick TO authenticated;
GRANT SELECT ON ko_champion_pick TO anon;

-- ─────────────────────────────────────────────────────────────────────────────
-- 7) VIEWS DE RANKING — somam o bônus de campeão (subconsulta escalar p/ não
--    multiplicar pelas linhas de ko_bet). Mantém o filtro de inscritos pagos.
-- ─────────────────────────────────────────────────────────────────────────────
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
    AND p.knockout_unlocked = true
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
  WHERE p.knockout_unlocked = true
  GROUP BY lm.league_id, l.name, p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- Ranking de CRAVADAS do mata-mata (total_points = nº de placares cravados).
-- Mesmo shape de user_rankings p/ reusar o card de ranking estatístico.
CREATE OR REPLACE VIEW ko_exact_score_rankings AS
  SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
         COALESCE(sum(CASE WHEN b.exact THEN 1 ELSE 0 END), 0) AS total_points,
         count(b.id) AS total_bets,
         rank() OVER (ORDER BY COALESCE(sum(CASE WHEN b.exact THEN 1 ELSE 0 END), 0) DESC) AS rank
  FROM profiles p
  LEFT JOIN ko_bet b ON b.user_id = p.id
  WHERE p.participate_in_ranking = true
    AND p.knockout_unlocked = true
  GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

GRANT SELECT ON ko_user_rankings, ko_league_rankings, ko_exact_score_rankings TO anon, authenticated;
