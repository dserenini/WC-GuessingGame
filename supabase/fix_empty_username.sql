-- ─────────────────────────────────────────────────────────────────────────────
-- FIX: perfis com username vazio quebram o onboarding
--
-- Sintoma: ao "Completar Perfil", o upsert em `profiles` falhava com
--   new row for relation "profiles" violates check constraint "username_not_empty" (23514)
--
-- Causa: a coluna `username` tem NOT NULL + CHECK (username_not_empty). Mesmo
-- num UPDATE (que é o que o upsert vira quando a linha já existe), o Postgres
-- revalida a CHECK na linha INTEIRA. Perfis criados fora do trigger
-- handle_new_user (ou anteriores à constraint) ficaram com username = '' e,
-- portanto, qualquer gravação nessa linha era recusada.
--
-- Este script faz o backfill das linhas com username vazio usando a MESMA
-- convenção do trigger handle_new_user: o prefixo do e-mail. Em caso de colisão
-- com a UNIQUE, anexa um sufixo curto do id para garantir unicidade.
--
-- RODAR UMA VEZ na produção. Idempotente (só toca linhas com username vazio).
-- ─────────────────────────────────────────────────────────────────────────────

WITH candidatos AS (
  SELECT
    p.id,
    -- base = prefixo do e-mail; fallback p/ user_<8 chars do id se faltar e-mail
    COALESCE(NULLIF(SPLIT_PART(u.email, '@', 1), ''), 'user_' || LEFT(p.id::text, 8)) AS base
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id
  WHERE COALESCE(TRIM(p.username), '') = ''
)
UPDATE public.profiles p
SET username = CASE
  -- se a base já está livre, usa direto; senão, garante unicidade com sufixo do id
  WHEN NOT EXISTS (
    SELECT 1 FROM public.profiles x
    WHERE LOWER(x.username) = LOWER(c.base) AND x.id <> p.id
  ) THEN c.base
  ELSE c.base || '_' || LEFT(p.id::text, 4)
END
FROM candidatos c
WHERE p.id = c.id;

-- Verificação: deve retornar 0 linhas.
-- SELECT id, username FROM public.profiles WHERE COALESCE(TRIM(username), '') = '';
