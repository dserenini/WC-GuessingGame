-- =============================================================================
-- FASE DO BOLÃO — fonte única de verdade da "fase atual" do torneio (PRODUÇÃO)
-- Rodar no Supabase SQL Editor. Depende de app_config + is_admin() (app_config.sql).
--
-- O app lê `app_config.phase` (= {"phase": "groups"|"mixed"|"knockout"}) via
-- tournamentPhaseProvider (lib/shared/providers/phase_provider.dart) e segrega a
-- visibilidade:
--   groups   → só Fase de Grupos. Mata-Mata escondido para todos.
--   mixed    → ambos visíveis (grupos + mata-mata).
--   knockout → só Mata-Mata. Dados de grupos escondidos para todos.
--
-- A fase SUBSTITUI a antiga flag global `app_config.knockout.enabled`: agora o
-- liga/desliga global do mata-mata é a própria fase (mixed/knockout = ligado).
-- O gate por usuário (inscrição paga, profiles.knockout_unlocked) permanece
-- ortogonal e continua valendo nas fases mixed/knockout.
-- =============================================================================

-- Semeia a fase inicial. Ajuste o valor conforme o estado atual da prod:
--   • 'groups'   antes do mata-mata começar (esconde o KO);
--   • 'mixed'    quando o mata-mata abrir (recomendado durante TODO o KO, pois
--                mantém grupos + KO visíveis ao mesmo tempo);
--   • 'knockout' só ao final, para "aposentar" o bolão de grupos.
INSERT INTO app_config (key, value)
VALUES ('phase', '{"phase": "groups"}'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- ─────────────────────────────────────────────
-- TROCAR A FASE NO MEIO DO TORNEIO (sem rebuild) — também dá p/ fazer pelo
-- seletor no Painel Admin (aba "Fase", com duplo check). Via SQL:
-- ─────────────────────────────────────────────
--   Abrir o mata-mata (grupos + KO visíveis):
--     UPDATE app_config SET value = '{"phase":"mixed"}'::jsonb, updated_at = NOW()
--      WHERE key = 'phase';
--
--   Fase final (só mata-mata; esconde os grupos):
--     UPDATE app_config SET value = '{"phase":"knockout"}'::jsonb, updated_at = NOW()
--      WHERE key = 'phase';
--
--   Voltar para a fase de grupos:
--     UPDATE app_config SET value = '{"phase":"groups"}'::jsonb, updated_at = NOW()
--      WHERE key = 'phase';

-- A antiga chave `app_config.knockout` (enabled) deixa de ser lida pelo app.
-- Pode ser mantida (ignorada) ou removida:
--   DELETE FROM app_config WHERE key = 'knockout';
