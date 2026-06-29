-- =============================================================================
-- PARTICIPAÇÃO NA FASE DE GRUPOS — flag por usuário (PRODUÇÃO)
-- Rodar no Supabase SQL Editor. Espelha knockout_access.sql (knockout_unlocked).
--
-- Indica que o usuário PARTICIPA do bolão da fase de grupos (assim como
-- `profiles.knockout_unlocked` indica participação no mata-mata). A visão por
-- fases (Grupos/Mista/Mata-Mata) só faz sentido para quem está assinalado na
-- fase: telas/estatísticas de grupos ficam INATIVAS para quem não participou.
-- =============================================================================

-- 1) COLUNA — participação na fase de grupos (não reaproveita profiles.paid).
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS groups_unlocked    boolean NOT NULL DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS groups_unlocked_at timestamptz;

-- 2) BACKFILL inicial — quem JÁ pontuou na fase de grupos participou dela.
--    Critério: >= 5 pontos somados em bets (fase de grupos). Os demais são
--    usuários recentes (só mata-mata) e ficam com groups_unlocked = false.
UPDATE profiles p
   SET groups_unlocked    = true,
       groups_unlocked_at = now()
 WHERE p.groups_unlocked = false
   AND (SELECT COALESCE(SUM(b.points), 0) FROM bets b WHERE b.user_id = p.id) >= 5;

-- 3) RPC p/ o admin listar quem está com a fase de grupos liberada (espelha
--    get_knockout_unlocked_ids). O toggle é UPDATE direto em profiles (admin já
--    tem RLS de update), não precisa de setter dedicado.
CREATE OR REPLACE FUNCTION get_groups_unlocked_ids()
RETURNS SETOF uuid
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY SELECT id FROM profiles WHERE groups_unlocked = true;
END;
$$;
GRANT EXECUTE ON FUNCTION get_groups_unlocked_ids() TO authenticated;
