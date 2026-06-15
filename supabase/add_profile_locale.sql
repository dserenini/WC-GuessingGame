-- ─────────────────────────────────────────────────────────────────────────────
-- Onboarding único e vinculado à conta
-- ─────────────────────────────────────────────────────────────────────────────
-- Antes, o "já escolheu idioma" ficava só no aparelho (localStorage), então o
-- usuário era perguntado de novo em todo celular/navegador novo. Passamos a
-- guardar o idioma no próprio perfil, para o onboarding (idioma + nome +
-- telefone) ser pedido UMA vez e seguir a conta em qualquer dispositivo.
--
-- O onboarding (idioma + nome + telefone) é pedido enquanto NOME ou TELEFONE
-- estiverem vazios. O idioma NÃO bloqueia: para usuários antigos (que já têm
-- nome+telefone), o app grava sozinho o idioma local atual deles nesta coluna
-- (backfill silencioso), preservando a escolha e passando a vinculá-la à conta.
--
-- Rode UMA vez no SQL Editor da produção ANTES de publicar a versão nova (o app
-- passa a fazer SELECT da coluna locale; sem a coluna, o SELECT falha).

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS locale text;
