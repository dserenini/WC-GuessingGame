-- ============================================================================
-- DEPLOY CONSOLIDADO — MATA-MATA (rodar na PROD/main, NA ORDEM)
--   1) schema base ko_* → 2) gating por inscrição → 3) reset+chaveamento oficial
--   → 4) colunas de origem p/ auto-preenchimento (1º/2º).
--
--   SEGURO se o mata-mata NUNCA foi para produção (sem apostas reais ko_bet):
--   as partes 1 e 3 RECRIAM as tabelas ko_* (apagam ko_bet). Se em prod JÁ
--   houver apostas reais de mata-mata, NÃO rode as partes 1 e 3.
--
--   Ao final o mata-mata fica ESCONDIDO (app_config.knockout.enabled=false).
--   Para liberar quando quiser, rode:
--     UPDATE app_config SET value = jsonb_set(value,'{enabled}','true'::jsonb)
--      WHERE key='knockout';
--   E libere por usuário marcando profiles.knockout_unlocked (badge no admin).
-- ============================================================================

-- ===================== PARTE 1/4: SCHEMA BASE =====================
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
DROP TABLE    IF EXISTS ko_bet            CASCADE;
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
INSERT INTO app_config (key, value)
VALUES ('knockout', jsonb_build_object(
  'enabled', false,
  'points', jsonb_build_object('exact', 3, 'direction', 1)
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

-- ─────────────────────────────────────────────────────────────────────────────
-- 3) PONTUAÇÃO (3 cravado / 1 direção / 0) — quando o jogo finaliza
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION score_ko_match()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp AS $$
DECLARE
  cfg     jsonb := ko_cfg();
  v_exact int   := COALESCE((cfg->'points'->>'exact')::int, 3);
  v_dir   int   := COALESCE((cfg->'points'->>'direction')::int, 1);
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
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_score_ko_match ON ko_match;
CREATE TRIGGER trg_score_ko_match
  AFTER INSERT OR UPDATE ON ko_match
  FOR EACH ROW EXECUTE FUNCTION score_ko_match();

-- ─────────────────────────────────────────────────────────────────────────────
-- 4) PRAZO (1h antes; precisa dos 2 times definidos) — bypass admin
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
  IF now() > m.match_date - interval '1 hour' THEN
    RAISE EXCEPTION 'Apostas encerradas (até 1h antes do jogo).';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ko_bet_deadline ON ko_bet;
CREATE TRIGGER trg_ko_bet_deadline
  BEFORE INSERT OR UPDATE ON ko_bet
  FOR EACH ROW EXECUTE FUNCTION ko_bet_deadline();

-- ─────────────────────────────────────────────────────────────────────────────
-- 5) VIEWS DE RANKING (mesmo formato de user_rankings / league_rankings, p/
--    reusar a tela de Ranking e Ligas existentes). Zera; só placar do mata-mata.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW ko_user_rankings AS
  SELECT p.id AS user_id, p.username, p.full_name, p.display_preference, p.avatar_url,
         COALESCE(sum(b.points), 0) AS total_points,
         count(b.id) AS total_bets,
         rank() OVER (ORDER BY COALESCE(sum(b.points), 0) DESC) AS rank
  FROM profiles p
  LEFT JOIN ko_bet b ON b.user_id = p.id
  WHERE p.participate_in_ranking = true
  GROUP BY p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

CREATE OR REPLACE VIEW ko_league_rankings AS
  SELECT lm.league_id, l.name AS league_name, p.id AS user_id, p.username, p.full_name,
         p.display_preference, p.avatar_url,
         COALESCE(sum(b.points), 0) AS total_points,
         rank() OVER (PARTITION BY lm.league_id ORDER BY COALESCE(sum(b.points), 0) DESC) AS rank,
         count(b.id) AS total_bets
  FROM league_members lm
  JOIN leagues l ON l.id = lm.league_id
  JOIN profiles p ON p.id = lm.user_id
  LEFT JOIN ko_bet b ON b.user_id = lm.user_id
  GROUP BY lm.league_id, l.name, p.id, p.username, p.full_name, p.display_preference, p.avatar_url;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6) RLS — lê tudo p/ jogos; aposta própria sempre; dos outros só após início
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE ko_match ENABLE ROW LEVEL SECURITY;
ALTER TABLE ko_bet   ENABLE ROW LEVEL SECURITY;

CREATE POLICY ko_match_read  ON ko_match FOR SELECT USING (true);
CREATE POLICY ko_match_admin ON ko_match FOR ALL USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY ko_bet_read ON ko_bet FOR SELECT USING (
  user_id = auth.uid()
  OR EXISTS (SELECT 1 FROM ko_match m WHERE m.id = ko_match_id AND now() >= m.match_date));
CREATE POLICY ko_bet_ins ON ko_bet FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY ko_bet_upd ON ko_bet FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────────
-- 7) GRANTS
-- ─────────────────────────────────────────────────────────────────────────────
GRANT SELECT ON ko_match TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ko_match, ko_bet TO authenticated;
GRANT SELECT ON ko_bet TO anon;
GRANT SELECT ON ko_user_rankings, ko_league_rankings TO anon, authenticated;


-- ============== PARTE 2/4: GATING POR INSCRIÇÃO (acesso) ==============
-- =============================================================================
-- MATA-MATA — controle de acesso por usuário (rollout gradual "às escondidas")
--   Inscrição do mata-mata é SEPARADA da do bolão principal → flag dedicada
--   `profiles.knockout_unlocked` (não reaproveita profiles.paid).
--   Gate = master global (app_config.knockout.enabled) E (knockout_unlocked OU admin).
--   ADITIVO: nova coluna + 1 função + políticas RLS de ko_bet. Idempotente.
--   Rode no SQL editor da PROD.
-- =============================================================================

-- 1) FLAG dedicada por usuário (liberada quando o admin confirma a inscrição
--    do mata-mata). knockout_unlocked_at = auditoria de quando foi liberado.
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS knockout_unlocked    boolean NOT NULL DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS knockout_unlocked_at timestamptz;

-- 2) GATE REAL no backend: só quem teve a inscrição do mata-mata liberada (ou
--    admin) grava palpite. Esconder a tela no app é UX; ISTO impede apostar via
--    API sem ter pago. auth.uid() lê o PRÓPRIO profiles (permitido pelo RLS),
--    então o EXISTS funciona sem SECURITY DEFINER.
DROP POLICY IF EXISTS ko_bet_ins ON ko_bet;
CREATE POLICY ko_bet_ins ON ko_bet FOR INSERT WITH CHECK (
  user_id = auth.uid()
  AND (
    is_admin()
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.knockout_unlocked = true)
  )
);

DROP POLICY IF EXISTS ko_bet_upd ON ko_bet;
CREATE POLICY ko_bet_upd ON ko_bet FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid()
    AND (
      is_admin()
      OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.knockout_unlocked = true)
    )
  );

-- 3) ADMIN: função para listar os IDs liberados. profiles é restrito (por isso
--    o app usa a RPC get_admin_users); esta é aditiva e NÃO toca naquela.
--    O toggle em si é um UPDATE direto em profiles (admin já tem RLS de update,
--    igual ao "Pago"), então não precisa de setter dedicado.
CREATE OR REPLACE FUNCTION get_knockout_unlocked_ids()
RETURNS SETOF uuid
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY SELECT id FROM profiles WHERE knockout_unlocked = true;
END;
$$;
GRANT EXECUTE ON FUNCTION get_knockout_unlocked_ids() TO authenticated;

-- Observações:
--  • Leitura do bracket (ko_match) continua pública; o app esconde a tela.
--  • O scoring (trigger score_ko_match) roda SECURITY DEFINER e não é afetado.

-- 4) ATIVAÇÃO (master switch) — rode SÓ no cutover, quando for liberar.
--    Enquanto 'enabled' = false, NINGUÉM vê (nem quem já tem knockout_unlocked).
--    Depois de ligar, cada usuário passa a ver assim que knockout_unlocked=true.
-- UPDATE app_config
--   SET value = jsonb_set(value, '{enabled}', 'true'::jsonb)
--   WHERE key = 'knockout';


-- ========= PARTE 3/4: RESET + CHAVEAMENTO OFICIAL (match_no/rótulos) =========
-- =============================================================================
-- MATA-MATA — RESET + CHAVEAMENTO OFICIAL 2026 (apenas STAGING por enquanto)
--   • Reseta placares/status (todos → 'scheduled', sem times definidos).
--   • Adiciona nº oficial do jogo (match_no, 73–104) e rótulos de confronto
--     (home_slot_label / away_slot_label) p/ exibir "1º E", "3º A/B/C/D/F",
--     "Venc. Jogo 74" em vez de "A definir".
--   • Datas oficiais da FIFA; horário provisório 14h Brasília (GMT-3) = 17:00 UTC,
--     a atualizar quando a FIFA divulgar os horários.
--   slot = ordem na ÁRVORE (o bracket_tree pareia por slot*2-1 / slot*2);
--   match_no = número oficial. São coisas distintas de propósito.
--   ATENÇÃO: recria os ko_match do zero (cascata ko_bet de demo no staging).
-- =============================================================================
BEGIN;

ALTER TABLE ko_match ADD COLUMN IF NOT EXISTS match_no        int;
ALTER TABLE ko_match ADD COLUMN IF NOT EXISTS home_slot_label text;
ALTER TABLE ko_match ADD COLUMN IF NOT EXISTS away_slot_label text;

DELETE FROM ko_match;  -- staging: cascata ko_bet (dados de demonstração)

-- 16-avos (Round of 32): slot = posição na árvore; match_no = nº oficial FIFA.
INSERT INTO ko_match (round, slot, match_no, home_slot_label, away_slot_label, match_date, status) VALUES
 ('16avos', 1, 74,'1º E','3º A/B/C/D/F','2026-06-29 17:00:00+00','scheduled'),
 ('16avos', 2, 77,'1º I','3º C/D/F/G/H','2026-06-30 17:00:00+00','scheduled'),
 ('16avos', 3, 73,'2º A','2º B',        '2026-06-28 17:00:00+00','scheduled'),
 ('16avos', 4, 75,'1º F','2º C',        '2026-06-29 17:00:00+00','scheduled'),
 ('16avos', 5, 83,'2º K','2º L',        '2026-07-02 17:00:00+00','scheduled'),
 ('16avos', 6, 84,'1º H','2º J',        '2026-07-02 17:00:00+00','scheduled'),
 ('16avos', 7, 81,'1º D','3º B/E/F/I/J','2026-07-01 17:00:00+00','scheduled'),
 ('16avos', 8, 82,'1º G','3º A/E/H/I/J','2026-07-01 17:00:00+00','scheduled'),
 ('16avos', 9, 76,'1º C','2º F',        '2026-06-29 17:00:00+00','scheduled'),
 ('16avos',10, 78,'2º E','2º I',        '2026-06-30 17:00:00+00','scheduled'),
 ('16avos',11, 79,'1º A','3º C/E/F/H/I','2026-06-30 17:00:00+00','scheduled'),
 ('16avos',12, 80,'1º L','3º E/H/I/J/K','2026-07-01 17:00:00+00','scheduled'),
 ('16avos',13, 86,'1º J','2º H',        '2026-07-03 17:00:00+00','scheduled'),
 ('16avos',14, 88,'2º D','2º G',        '2026-07-03 17:00:00+00','scheduled'),
 ('16avos',15, 85,'1º B','3º E/F/G/I/J','2026-07-02 17:00:00+00','scheduled'),
 ('16avos',16, 87,'1º K','3º D/E/I/J/L','2026-07-03 17:00:00+00','scheduled');

-- Demais fases (datas oficiais; rótulos derivados do nº do jogo de origem abaixo).
INSERT INTO ko_match (round, slot, match_no, match_date, status) VALUES
 ('oitavas',1, 89,'2026-07-04 17:00:00+00','scheduled'),
 ('oitavas',2, 90,'2026-07-04 17:00:00+00','scheduled'),
 ('oitavas',3, 93,'2026-07-06 17:00:00+00','scheduled'),
 ('oitavas',4, 94,'2026-07-06 17:00:00+00','scheduled'),
 ('oitavas',5, 91,'2026-07-05 17:00:00+00','scheduled'),
 ('oitavas',6, 92,'2026-07-05 17:00:00+00','scheduled'),
 ('oitavas',7, 95,'2026-07-07 17:00:00+00','scheduled'),
 ('oitavas',8, 96,'2026-07-07 17:00:00+00','scheduled'),
 ('quartas',1, 97,'2026-07-09 17:00:00+00','scheduled'),
 ('quartas',2, 98,'2026-07-10 17:00:00+00','scheduled'),
 ('quartas',3, 99,'2026-07-11 17:00:00+00','scheduled'),
 ('quartas',4,100,'2026-07-11 17:00:00+00','scheduled'),
 ('semis',  1,101,'2026-07-14 17:00:00+00','scheduled'),
 ('semis',  2,102,'2026-07-15 17:00:00+00','scheduled'),
 ('3lugar', 1,103,'2026-07-18 17:00:00+00','scheduled'),
 ('final',  1,104,'2026-07-19 17:00:00+00','scheduled');

-- Liga a árvore (src_match) por aritmética de slot.
UPDATE ko_match o SET
  home_src_match = (SELECT id FROM ko_match WHERE round='16avos'  AND slot=o.slot*2-1),
  away_src_match = (SELECT id FROM ko_match WHERE round='16avos'  AND slot=o.slot*2)
WHERE o.round='oitavas';
UPDATE ko_match q SET
  home_src_match = (SELECT id FROM ko_match WHERE round='oitavas' AND slot=q.slot*2-1),
  away_src_match = (SELECT id FROM ko_match WHERE round='oitavas' AND slot=q.slot*2)
WHERE q.round='quartas';
UPDATE ko_match s SET
  home_src_match = (SELECT id FROM ko_match WHERE round='quartas' AND slot=s.slot*2-1),
  away_src_match = (SELECT id FROM ko_match WHERE round='quartas' AND slot=s.slot*2)
WHERE s.round='semis';
UPDATE ko_match f SET
  home_src_match = (SELECT id FROM ko_match WHERE round='semis' AND slot=1),
  away_src_match = (SELECT id FROM ko_match WHERE round='semis' AND slot=2)
WHERE f.round='final';
UPDATE ko_match t SET
  home_src_match = (SELECT id FROM ko_match WHERE round='semis' AND slot=1),
  away_src_match = (SELECT id FROM ko_match WHERE round='semis' AND slot=2)
WHERE t.round='3lugar';

-- Rótulos das fases eliminatórias a partir do nº do jogo de origem.
UPDATE ko_match m SET
  home_slot_label = 'Venc. Jogo ' || (SELECT match_no FROM ko_match s WHERE s.id = m.home_src_match),
  away_slot_label = 'Venc. Jogo ' || (SELECT match_no FROM ko_match s WHERE s.id = m.away_src_match)
WHERE m.round IN ('oitavas','quartas','semis','final');

UPDATE ko_match m SET
  home_slot_label = 'Perd. Jogo ' || (SELECT match_no FROM ko_match s WHERE s.id = m.home_src_match),
  away_slot_label = 'Perd. Jogo ' || (SELECT match_no FROM ko_match s WHERE s.id = m.away_src_match)
WHERE m.round='3lugar';

COMMIT;

-- Conferência rápida (opcional):
-- SELECT round, slot, match_no, home_slot_label, away_slot_label, match_date
--   FROM ko_match ORDER BY match_no;


-- ===== PARTE 4/4: COLUNAS DE ORIGEM P/ AUTO-PREENCHIMENTO 1º/2º =====
-- =============================================================================
-- MATA-MATA — fonte estruturada de cada slot dos 16-avos (p/ auto-preenchimento)
--   Diz, por jogo, qual GRUPO + POSIÇÃO alimenta cada lado (casa/visitante):
--     kind: 'winner' (1º) | 'runnerup' (2º) | 'third' (3º — set de grupos)
--     group: letra do grupo (winner/runnerup) ou o conjunto (third, ex.: 'ABCDF')
--   A Edge Function sync-scores usa isso p/ preencher home_team_id/away_team_id
--   quando a posição estiver MATEMATICAMENTE definida (rigoroso FIFA).
--   Os 3ºs ficam só como rótulo por ora (dependem do Anexo de alocação da FIFA).
--   Aditivo e idempotente. Rode após knockout_reset_bracket.sql.
-- =============================================================================

ALTER TABLE ko_match ADD COLUMN IF NOT EXISTS home_src_kind  text;
ALTER TABLE ko_match ADD COLUMN IF NOT EXISTS home_src_group text;
ALTER TABLE ko_match ADD COLUMN IF NOT EXISTS away_src_kind  text;
ALTER TABLE ko_match ADD COLUMN IF NOT EXISTS away_src_group text;

UPDATE ko_match m SET
  home_src_kind = v.hk, home_src_group = v.hg,
  away_src_kind = v.ak, away_src_group = v.ag
FROM (VALUES
  (73,'runnerup','A','runnerup','B'),
  (74,'winner',  'E','third',   'ABCDF'),
  (75,'winner',  'F','runnerup','C'),
  (76,'winner',  'C','runnerup','F'),
  (77,'winner',  'I','third',   'CDFGH'),
  (78,'runnerup','E','runnerup','I'),
  (79,'winner',  'A','third',   'CEFHI'),
  (80,'winner',  'L','third',   'EHIJK'),
  (81,'winner',  'D','third',   'BEFIJ'),
  (82,'winner',  'G','third',   'AEHIJ'),
  (83,'runnerup','K','runnerup','L'),
  (84,'winner',  'H','runnerup','J'),
  (85,'winner',  'B','third',   'EFGIJ'),
  (86,'winner',  'J','runnerup','H'),
  (87,'winner',  'K','third',   'DEIJL'),
  (88,'runnerup','D','runnerup','G')
) AS v(mno, hk, hg, ak, ag)
WHERE m.match_no = v.mno;
