-- =============================================================================
-- SETUP do sincronizador automático do MATA-MATA (Edge Function sync-scores)
--
-- SEGREGADO da fase de grupos de propósito:
--   * log próprio          -> ko_api_sync_runs   (FK p/ ko_match, não p/ matches)
--   * flag de modo própria -> app_config.ko_sync_mode  ('shadow' | 'live')
-- Assim você valida e liga/desliga o KO SEM tocar no sync_mode dos grupos.
--
-- Rode uma vez no SQL Editor da produção. Começa em 'shadow' (não escreve em
-- ko_match; só registra em ko_api_sync_runs o que FARIA).
--
-- Para LIGAR a sincronização automática do mata-mata de verdade:
--   UPDATE app_config SET value = '{"mode":"live"}'::jsonb, updated_at = NOW()
--    WHERE key = 'ko_sync_mode';
-- Para voltar ao teste:
--   UPDATE app_config SET value = '{"mode":"shadow"}'::jsonb, updated_at = NOW()
--    WHERE key = 'ko_sync_mode';
-- =============================================================================

-- 1) Log do sincronizador do mata-mata ------------------------------------
--    Espelha api_sync_runs, mas: referencia ko_match (não matches), guarda o
--    'round', os pênaltis informados pela fonte (se houver) e um 'note' para
--    explicar por que um jogo NÃO foi aplicado (ex.: empate sem vencedor).
CREATE TABLE IF NOT EXISTS ko_api_sync_runs (
  id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ran_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  mode             TEXT NOT NULL,                 -- 'shadow' | 'live'
  source_game_id   TEXT,                          -- id do jogo na fonte
  ko_match_id      UUID REFERENCES ko_match(id) ON DELETE SET NULL,
  round            TEXT,                          -- 16avos | oitavas | quartas | semis | final | 3lugar
  home_team        TEXT,
  away_team        TEXT,
  src_home_score   INT,                           -- placar orientado p/ NOSSO mandante
  src_away_score   INT,
  src_home_pens    INT,                           -- pênaltis (informativo; a fonte hoje NÃO traz)
  src_away_pens    INT,
  src_status       TEXT,                          -- scheduled | live | finished
  src_raw_finished TEXT,                          -- valor cru da fonte
  src_time_elapsed TEXT,                          -- valor cru da fonte
  applied          BOOLEAN NOT NULL DEFAULT FALSE,-- escreveu em ko_match?
  note             TEXT                           -- motivo de não aplicar / revisão manual
);

CREATE INDEX IF NOT EXISTS idx_ko_api_sync_runs_ran_at ON ko_api_sync_runs (ran_at DESC);

ALTER TABLE ko_api_sync_runs ENABLE ROW LEVEL SECURITY;

-- Leitura só para admins. Inserts vêm da Edge Function (service_role, ignora RLS).
DROP POLICY IF EXISTS "Only admins read ko_api_sync_runs" ON ko_api_sync_runs;
CREATE POLICY "Only admins read ko_api_sync_runs"
  ON ko_api_sync_runs FOR SELECT USING (is_admin());

-- 2) Flag de modo do sincronizador do MATA-MATA (própria, separada) --------
INSERT INTO app_config (key, value)
VALUES ('ko_sync_mode', '{"mode":"shadow"}'::jsonb)
ON CONFLICT (key) DO NOTHING;
