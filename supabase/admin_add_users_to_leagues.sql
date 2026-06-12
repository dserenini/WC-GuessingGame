-- ─────────────────────────────────────────────
-- ADMIN: adicionar usuários a ligas em massa
-- ─────────────────────────────────────────────
-- Insere o produto cartesiano (cada usuário selecionado em cada liga
-- selecionada), ignorando vínculos que já existam.
--
-- Necessária porque a policy de league_members só permite que o próprio
-- usuário se insira (INSERT WITH CHECK auth.uid() = user_id). Para um admin
-- adicionar terceiros, usamos SECURITY DEFINER + checagem de admin, no mesmo
-- padrão de get_admin_users() / admin_send_notification().
--
-- Rodar no SQL Editor do Supabase (produção).
CREATE OR REPLACE FUNCTION admin_add_users_to_leagues(
  p_user_ids   UUID[],
  p_league_ids UUID[]
) RETURNS INTEGER AS $$
DECLARE
  v_inserted INTEGER;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM admins WHERE user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Acesso negado: somente administradores podem adicionar usuários a ligas.';
  END IF;

  WITH ins AS (
    INSERT INTO league_members (league_id, user_id)
    SELECT lid, uid
    FROM unnest(p_league_ids) AS lid
    CROSS JOIN unnest(p_user_ids) AS uid
    ON CONFLICT (league_id, user_id) DO NOTHING
    RETURNING 1
  )
  SELECT COUNT(*) INTO v_inserted FROM ins;

  RETURN v_inserted;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
