-- =============================================================================
-- SETUP do sincronizador automático (Edge Function sync-scores)
--
-- Rode uma vez no SQL Editor da produção. Cria:
--   1) api_sync_runs  -> log do que o sincronizador fez/faria (shadow e live)
--   2) app_config.sync_mode = 'shadow'  -> começa em teste (não escreve em matches)
--
-- Depois, para LIGAR a sincronização automática de verdade:
--   UPDATE app_config SET value = '{"mode":"live"}'::jsonb, updated_at = NOW()
--    WHERE key = 'sync_mode';
-- Para voltar ao teste:
--   UPDATE app_config SET value = '{"mode":"shadow"}'::jsonb, updated_at = NOW()
--    WHERE key = 'sync_mode';
-- =============================================================================

-- 1) Log do sincronizador --------------------------------------------------
CREATE TABLE IF NOT EXISTS api_sync_runs (
  id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ran_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  mode             TEXT NOT NULL,                 -- 'shadow' | 'live'
  source_game_id   TEXT,                          -- id do jogo na fonte
  match_id         UUID REFERENCES matches(id) ON DELETE SET NULL,
  group_letter     TEXT,
  home_team        TEXT,
  away_team        TEXT,
  src_home_score   INT,
  src_away_score   INT,
  src_status       TEXT,                          -- scheduled | live | finished
  src_raw_finished TEXT,                          -- valor cru da fonte
  src_time_elapsed TEXT,                          -- valor cru da fonte
  applied          BOOLEAN NOT NULL DEFAULT FALSE -- escreveu em matches?
);

CREATE INDEX IF NOT EXISTS idx_api_sync_runs_ran_at ON api_sync_runs (ran_at DESC);

ALTER TABLE api_sync_runs ENABLE ROW LEVEL SECURITY;

-- Leitura só para admins. Inserts vêm da Edge Function (service_role, ignora RLS).
DROP POLICY IF EXISTS "Only admins read api_sync_runs" ON api_sync_runs;
CREATE POLICY "Only admins read api_sync_runs"
  ON api_sync_runs FOR SELECT USING (is_admin());

-- 2) Flag de modo do sincronizador ----------------------------------------
INSERT INTO app_config (key, value)
VALUES ('sync_mode', '{"mode":"shadow"}'::jsonb)
ON CONFLICT (key) DO NOTHING;
