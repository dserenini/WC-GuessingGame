-- =============================================================================
-- MATA-MATA — RESET + CHAVEAMENTO OFICIAL 2026 (apenas STAGING por enquanto)
--   • Reseta placares/status (todos → 'scheduled', sem times definidos).
--   • Adiciona nº oficial do jogo (match_no, 73–104) e rótulos de confronto
--     (home_slot_label / away_slot_label) p/ exibir "1º E", "3º A/B/C/D/F",
--     "Venc. Jogo 74" em vez de "A definir".
--   • Datas oficiais da FIFA; horário provisório 14h Brasília (GMT-3) = 17:00 UTC,
--     a atualizar quando a FIFA divulgar os horários.
--   slot = ordem na ÁRVORE (o bracket_tree pareia por slot*2-1 / slot*2);
--   match_no = número oficial. São coisas distintas de propósito.
--   ATENÇÃO: recria os ko_match do zero (cascata ko_bet de demo no staging).
-- =============================================================================
BEGIN;

ALTER TABLE ko_match ADD COLUMN IF NOT EXISTS match_no        int;
ALTER TABLE ko_match ADD COLUMN IF NOT EXISTS home_slot_label text;
ALTER TABLE ko_match ADD COLUMN IF NOT EXISTS away_slot_label text;

DELETE FROM ko_match;  -- staging: cascata ko_bet (dados de demonstração)

-- 16-avos (Round of 32): slot = posição na árvore; match_no = nº oficial FIFA.
INSERT INTO ko_match (round, slot, match_no, home_slot_label, away_slot_label, match_date, status) VALUES
 ('16avos', 1, 74,'1º E','3º A/B/C/D/F','2026-06-29 17:00:00+00','scheduled'),
 ('16avos', 2, 77,'1º I','3º C/D/F/G/H','2026-06-30 17:00:00+00','scheduled'),
 ('16avos', 3, 73,'2º A','2º B',        '2026-06-28 17:00:00+00','scheduled'),
 ('16avos', 4, 75,'1º F','2º C',        '2026-06-29 17:00:00+00','scheduled'),
 ('16avos', 5, 83,'2º K','2º L',        '2026-07-02 17:00:00+00','scheduled'),
 ('16avos', 6, 84,'1º H','2º J',        '2026-07-02 17:00:00+00','scheduled'),
 ('16avos', 7, 81,'1º D','3º B/E/F/I/J','2026-07-01 17:00:00+00','scheduled'),
 ('16avos', 8, 82,'1º G','3º A/E/H/I/J','2026-07-01 17:00:00+00','scheduled'),
 ('16avos', 9, 76,'1º C','2º F',        '2026-06-29 17:00:00+00','scheduled'),
 ('16avos',10, 78,'2º E','2º I',        '2026-06-30 17:00:00+00','scheduled'),
 ('16avos',11, 79,'1º A','3º C/E/F/H/I','2026-06-30 17:00:00+00','scheduled'),
 ('16avos',12, 80,'1º L','3º E/H/I/J/K','2026-07-01 17:00:00+00','scheduled'),
 ('16avos',13, 86,'1º J','2º H',        '2026-07-03 17:00:00+00','scheduled'),
 ('16avos',14, 88,'2º D','2º G',        '2026-07-03 17:00:00+00','scheduled'),
 ('16avos',15, 85,'1º B','3º E/F/G/I/J','2026-07-02 17:00:00+00','scheduled'),
 ('16avos',16, 87,'1º K','3º D/E/I/J/L','2026-07-03 17:00:00+00','scheduled');

-- Demais fases (datas oficiais; rótulos derivados do nº do jogo de origem abaixo).
INSERT INTO ko_match (round, slot, match_no, match_date, status) VALUES
 ('oitavas',1, 89,'2026-07-04 17:00:00+00','scheduled'),
 ('oitavas',2, 90,'2026-07-04 17:00:00+00','scheduled'),
 ('oitavas',3, 93,'2026-07-06 17:00:00+00','scheduled'),
 ('oitavas',4, 94,'2026-07-06 17:00:00+00','scheduled'),
 ('oitavas',5, 91,'2026-07-05 17:00:00+00','scheduled'),
 ('oitavas',6, 92,'2026-07-05 17:00:00+00','scheduled'),
 ('oitavas',7, 95,'2026-07-07 17:00:00+00','scheduled'),
 ('oitavas',8, 96,'2026-07-07 17:00:00+00','scheduled'),
 ('quartas',1, 97,'2026-07-09 17:00:00+00','scheduled'),
 ('quartas',2, 98,'2026-07-10 17:00:00+00','scheduled'),
 ('quartas',3, 99,'2026-07-11 17:00:00+00','scheduled'),
 ('quartas',4,100,'2026-07-11 17:00:00+00','scheduled'),
 ('semis',  1,101,'2026-07-14 17:00:00+00','scheduled'),
 ('semis',  2,102,'2026-07-15 17:00:00+00','scheduled'),
 ('3lugar', 1,103,'2026-07-18 17:00:00+00','scheduled'),
 ('final',  1,104,'2026-07-19 17:00:00+00','scheduled');

-- Liga a árvore (src_match) por aritmética de slot.
UPDATE ko_match o SET
  home_src_match = (SELECT id FROM ko_match WHERE round='16avos'  AND slot=o.slot*2-1),
  away_src_match = (SELECT id FROM ko_match WHERE round='16avos'  AND slot=o.slot*2)
WHERE o.round='oitavas';
UPDATE ko_match q SET
  home_src_match = (SELECT id FROM ko_match WHERE round='oitavas' AND slot=q.slot*2-1),
  away_src_match = (SELECT id FROM ko_match WHERE round='oitavas' AND slot=q.slot*2)
WHERE q.round='quartas';
UPDATE ko_match s SET
  home_src_match = (SELECT id FROM ko_match WHERE round='quartas' AND slot=s.slot*2-1),
  away_src_match = (SELECT id FROM ko_match WHERE round='quartas' AND slot=s.slot*2)
WHERE s.round='semis';
UPDATE ko_match f SET
  home_src_match = (SELECT id FROM ko_match WHERE round='semis' AND slot=1),
  away_src_match = (SELECT id FROM ko_match WHERE round='semis' AND slot=2)
WHERE f.round='final';
UPDATE ko_match t SET
  home_src_match = (SELECT id FROM ko_match WHERE round='semis' AND slot=1),
  away_src_match = (SELECT id FROM ko_match WHERE round='semis' AND slot=2)
WHERE t.round='3lugar';

-- Rótulos das fases eliminatórias a partir do nº do jogo de origem.
UPDATE ko_match m SET
  home_slot_label = 'Venc. Jogo ' || (SELECT match_no FROM ko_match s WHERE s.id = m.home_src_match),
  away_slot_label = 'Venc. Jogo ' || (SELECT match_no FROM ko_match s WHERE s.id = m.away_src_match)
WHERE m.round IN ('oitavas','quartas','semis','final');

UPDATE ko_match m SET
  home_slot_label = 'Perd. Jogo ' || (SELECT match_no FROM ko_match s WHERE s.id = m.home_src_match),
  away_slot_label = 'Perd. Jogo ' || (SELECT match_no FROM ko_match s WHERE s.id = m.away_src_match)
WHERE m.round='3lugar';

COMMIT;

-- Conferência rápida (opcional):
-- SELECT round, slot, match_no, home_slot_label, away_slot_label, match_date
--   FROM ko_match ORDER BY match_no;
