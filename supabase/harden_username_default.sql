-- ─────────────────────────────────────────────────────────────────────────────
-- HARDENING: elimina o landmine DEFAULT '' + CHECK (username <> '')
--
-- Contexto: a coluna profiles.username é NOT NULL, DEFAULT '' e CHECK (<> '').
-- O upsert do PostgREST é INSERT ... ON CONFLICT (id) DO UPDATE, e o Postgres
-- valida NOT NULL/CHECK no tuple do INSERT (que nasce com o DEFAULT '') ANTES
-- de detectar o conflito de id e cair no UPDATE. Logo, QUALQUER upsert/insert
-- que omita `username` estoura 23514 (username_not_empty) — mesmo quando a
-- linha já existe com um username válido. (Foi o que prendia usuários no
-- onboarding; o app já foi corrigido para sempre enviar username, mas o
-- default em si continua sendo uma armadilha para qualquer código futuro.)
--
-- Correção: troca o DEFAULT '' por um valor GERADO, único e não-vazio. Assim,
-- um INSERT (ou o INSERT especulativo do upsert) sem username recebe um
-- username válido automaticamente:
--   * passa no CHECK (username <> '') e na UNIQUE (valor aleatório);
--   * no caso de upsert, o conflito de id é então detectado e o UPDATE
--     preserva o username real — o gerado é descartado.
-- O CHECK e o NOT NULL são MANTIDOS de propósito (queremos username não-vazio
-- para login-por-username e exibição no ranking).
--
-- O trigger handle_new_user define username explicitamente (prefixo do e-mail),
-- então cadastros reais NÃO usam este default — ele é só uma rede de segurança.
--
-- gen_random_uuid() é nativo no Postgres do Supabase (pgcrypto/core).
--
-- RODAR UMA VEZ na produção. Idempotente (ALTER ... SET DEFAULT é declarativo).
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.profiles
  ALTER COLUMN username
  SET DEFAULT ('user_' || replace(gen_random_uuid()::text, '-', ''));

-- Verificação: o column_default deve mostrar a expressão acima, não ''::text.
-- SELECT column_default
--   FROM information_schema.columns
--  WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'username';

-- Teste rápido (opcional, NÃO comitar dados de teste):
--   Um upsert que omita username numa linha existente deve atualizar sem erro.
--   INSERT INTO public.profiles (id, full_name)
--   VALUES ('<id-existente>', 'Teste') ON CONFLICT (id) DO UPDATE SET full_name = excluded.full_name;
