-- =============================================================================
-- ADD api_fixture_id — mapeamento para a sincronização automática via API
--
-- Por quê: `api_match_id` é a nossa sequência 1..72 (seed/planilha) e NÃO pode
-- ser repurposada — é usada para ordenar os jogos e pela sync manual da planilha.
-- O `fixture.id` da API-Football é um número grande e próprio dela. Guardamos ele
-- numa coluna separada, `api_fixture_id`, que a Edge Function usa para casar cada
-- fixture com a nossa partida.
--
-- Aditivo e seguro: não altera dados existentes. Rode uma vez no SQL Editor.
-- O backfill (preencher api_fixture_id nos 72 jogos) é um passo SEPARADO e
-- validado, feito depois que a chave/league id existirem (ver playbook).
-- =============================================================================

ALTER TABLE matches
  ADD COLUMN IF NOT EXISTS api_fixture_id BIGINT;

-- Cada fixture da API mapeia para no máximo uma partida nossa.
-- Índice parcial: permite vários NULL (jogos ainda não mapeados).
CREATE UNIQUE INDEX IF NOT EXISTS uniq_matches_api_fixture_id
  ON matches (api_fixture_id)
  WHERE api_fixture_id IS NOT NULL;
