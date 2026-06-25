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

-- 4) RANKINGS DO MATA-MATA só contam participantes PAGOS (knockout_unlocked).
--    Recria as views de knockout_schema.sql agora que a coluna existe (a coluna
--    é criada acima, na PARTE 2; por isso o filtro entra aqui, não no schema).
--    • ko_user_rankings (geral): exige "aparecer no ranking" (participate_in_
--      ranking) E "mata-mata pago" (knockout_unlocked).
--    • ko_league_rankings (liga): exige knockout_unlocked; segue a convenção da
--      league_rankings regular de NÃO filtrar participate_in_ranking.
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

GRANT SELECT ON ko_exact_score_rankings TO anon, authenticated;

-- 4.1) GATE de inscrição no PALPITE DE CAMPEÃO (espelha ko_bet): só admin ou
--      quem teve a inscrição do mata-mata liberada grava o palpite de campeão.
DROP POLICY IF EXISTS kcp_ins ON ko_champion_pick;
CREATE POLICY kcp_ins ON ko_champion_pick FOR INSERT WITH CHECK (
  user_id = auth.uid()
  AND (
    is_admin()
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.knockout_unlocked = true)
  )
);

DROP POLICY IF EXISTS kcp_upd ON ko_champion_pick;
CREATE POLICY kcp_upd ON ko_champion_pick FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid()
    AND (
      is_admin()
      OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.knockout_unlocked = true)
    )
  );

-- Observações:
--  • Leitura do bracket (ko_match) continua pública; o app esconde a tela.
--  • O scoring (trigger score_ko_match) roda SECURITY DEFINER e não é afetado.

-- 5) ATIVAÇÃO (master switch) — rode SÓ no cutover, quando for liberar.
--    Enquanto 'enabled' = false, NINGUÉM vê (nem quem já tem knockout_unlocked).
--    Depois de ligar, cada usuário passa a ver assim que knockout_unlocked=true.
-- UPDATE app_config
--   SET value = jsonb_set(value, '{enabled}', 'true'::jsonb)
--   WHERE key = 'knockout';
