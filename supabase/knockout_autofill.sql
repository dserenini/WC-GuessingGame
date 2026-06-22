-- =============================================================================
-- MATA-MATA — fonte estruturada de cada slot dos 16-avos (p/ auto-preenchimento)
--   Diz, por jogo, qual GRUPO + POSIÇÃO alimenta cada lado (casa/visitante):
--     kind: 'winner' (1º) | 'runnerup' (2º) | 'third' (3º — set de grupos)
--     group: letra do grupo (winner/runnerup) ou o conjunto (third, ex.: 'ABCDF')
--   A Edge Function sync-scores usa isso p/ preencher home_team_id/away_team_id
--   quando a posição estiver MATEMATICAMENTE definida (rigoroso FIFA).
--   Os 3ºs ficam só como rótulo por ora (dependem do Anexo de alocação da FIFA).
--   Aditivo e idempotente. Rode após knockout_reset_bracket.sql.
-- =============================================================================

ALTER TABLE ko_match ADD COLUMN IF NOT EXISTS home_src_kind  text;
ALTER TABLE ko_match ADD COLUMN IF NOT EXISTS home_src_group text;
ALTER TABLE ko_match ADD COLUMN IF NOT EXISTS away_src_kind  text;
ALTER TABLE ko_match ADD COLUMN IF NOT EXISTS away_src_group text;

UPDATE ko_match m SET
  home_src_kind = v.hk, home_src_group = v.hg,
  away_src_kind = v.ak, away_src_group = v.ag
FROM (VALUES
  (73,'runnerup','A','runnerup','B'),
  (74,'winner',  'E','third',   'ABCDF'),
  (75,'winner',  'F','runnerup','C'),
  (76,'winner',  'C','runnerup','F'),
  (77,'winner',  'I','third',   'CDFGH'),
  (78,'runnerup','E','runnerup','I'),
  (79,'winner',  'A','third',   'CEFHI'),
  (80,'winner',  'L','third',   'EHIJK'),
  (81,'winner',  'D','third',   'BEFIJ'),
  (82,'winner',  'G','third',   'AEHIJ'),
  (83,'runnerup','K','runnerup','L'),
  (84,'winner',  'H','runnerup','J'),
  (85,'winner',  'B','third',   'EFGIJ'),
  (86,'winner',  'J','runnerup','H'),
  (87,'winner',  'K','third',   'DEIJL'),
  (88,'runnerup','D','runnerup','G')
) AS v(mno, hk, hg, ak, ag)
WHERE m.match_no = v.mno;
