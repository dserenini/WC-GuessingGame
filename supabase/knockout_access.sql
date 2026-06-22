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
