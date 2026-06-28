-- =============================================================================
-- MATA-MATA — PREENCHER OS 16 CONFRONTOS DA 2ª FASE (Round of 32) + HORÁRIOS
--   Substitui/dispensa o knockout_fill_thirds.sql: aqui entram os DOIS times de
--   cada um dos 16 jogos (não só os 3ºs) + os horários oficiais de TODAS as fases.
--
--   NOMES: teams.name na PRODUÇÃO está em PORTUGUÊS (grafia exata conferida na
--   base). Por isso o mapa abaixo usa os nomes em PT-BR como gravados em teams.
--
--   HORÁRIOS: digitados no fuso de Brasília (GMT-3, sufixo -03); o Postgres
--   converte e guarda em UTC. Não precisa converter na mão.
--
--   SLOT = posição na ÁRVORE (o bracket pareia slot*2-1 / slot*2). É a ordem da
--   lista "Chaveamento - Segunda fase": slot 1 = Alemanha×Paraguai, ... slot 16 =
--   Colômbia×Gana. NÃO confundir com match_no (nº oficial FIFA), que já está certo.
--
--   SEGURANÇA: roda em transação com validações que ABORTAM tudo se:
--     • um nome não existir em teams.name (pega erro de grafia/idioma);
--     • o grupo do time não bater com o rótulo do slot (pega jogo trocado);
--     • houver time repetido entre os 16 confrontos.
--   Nada é gravado até o COMMIT no fim.
-- =============================================================================
BEGIN;

-- ───────────────────────────────────────────────────────────────────────────
-- 1) 16-AVOS: confronto (mandante × visitante) + horário (BRT) por slot
-- ───────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE _r32 (slot int PRIMARY KEY, home_name text, away_name text, kickoff timestamptz)
  ON COMMIT DROP;
INSERT INTO _r32 (slot, home_name, away_name, kickoff) VALUES
  ( 1, 'Alemanha',       'Paraguai',              '2026-06-29 17:30:00-03'),  -- 1ºE x 3º(A/B/C/D/F)
  ( 2, 'França',         'Suécia',                '2026-06-30 18:00:00-03'),  -- 1ºI x 3º(C/D/F/G/H)
  ( 3, 'África do Sul',  'Canadá',                '2026-06-28 16:00:00-03'),  -- 2ºA x 2ºB
  ( 4, 'Holanda',        'Marrocos',              '2026-06-29 22:00:00-03'),  -- 1ºF x 2ºC
  ( 5, 'Portugal',       'Croácia',               '2026-07-02 20:00:00-03'),  -- 2ºK x 2ºL
  ( 6, 'Espanha',        'Áustria',               '2026-07-02 16:00:00-03'),  -- 1ºH x 2ºJ
  ( 7, 'Estados Unidos', 'Bósnia e Herzegovina',  '2026-07-01 21:00:00-03'),  -- 1ºD x 3º(B/E/F/I/J)
  ( 8, 'Bélgica',        'Senegal',               '2026-07-01 17:00:00-03'),  -- 1ºG x 3º(A/E/H/I/J)
  ( 9, 'Brasil',         'Japão',                 '2026-06-29 14:00:00-03'),  -- 1ºC x 2ºF
  (10, 'Costa do Marfim','Noruega',               '2026-06-30 14:00:00-03'),  -- 2ºE x 2ºI
  (11, 'México',         'Equador',               '2026-06-30 22:00:00-03'),  -- 1ºA x 3º(C/E/F/H/I)
  (12, 'Inglaterra',     'RD Congo',              '2026-07-01 13:00:00-03'),  -- 1ºL x 3º(E/H/I/J/K)
  (13, 'Argentina',      'Cabo Verde',            '2026-07-03 19:00:00-03'),  -- 1ºJ x 2ºH
  (14, 'Austrália',      'Egito',                 '2026-07-03 15:00:00-03'),  -- 2ºD x 2ºG
  (15, 'Suíça',          'Argélia',               '2026-07-03 00:00:00-03'),  -- 1ºB x 3º(E/F/G/I/J)
  (16, 'Colômbia',       'Gana',                  '2026-07-03 22:30:00-03');  -- 1ºK x 3º(D/E/I/J/L)

-- ───────────────────────────────────────────────────────────────────────────
-- 2) VALIDAÇÕES (não mexer) — qualquer falha aborta a transação inteira
-- ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  r      record;
  v_hid  uuid; v_hg char(1);
  v_aid  uuid; v_ag char(1);
  lab_h  text; lab_a text;
BEGIN
  IF (SELECT count(*) FROM _r32) <> 16 THEN
    RAISE EXCEPTION 'Esperado 16 confrontos, encontrei %.', (SELECT count(*) FROM _r32);
  END IF;

  FOR r IN SELECT * FROM _r32 ORDER BY slot LOOP
    SELECT id, group_letter INTO v_hid, v_hg FROM teams WHERE name = r.home_name;
    SELECT id, group_letter INTO v_aid, v_ag FROM teams WHERE name = r.away_name;
    IF v_hid IS NULL THEN
      RAISE EXCEPTION 'slot %: mandante "%" não existe em teams.name (confira a grafia/idioma).', r.slot, r.home_name;
    END IF;
    IF v_aid IS NULL THEN
      RAISE EXCEPTION 'slot %: visitante "%" não existe em teams.name (confira a grafia/idioma).', r.slot, r.away_name;
    END IF;

    SELECT home_slot_label, away_slot_label INTO lab_h, lab_a
      FROM ko_match WHERE round = '16avos' AND slot = r.slot;
    IF lab_h IS NULL THEN
      RAISE EXCEPTION 'slot % não existe nos 16-avos do ko_match.', r.slot;
    END IF;
    -- O grupo do time tem de estar contido no rótulo do slot (ex.: "3º B/E/F/I/J").
    IF position(v_hg IN lab_h) = 0 THEN
      RAISE EXCEPTION 'slot %: mandante "%" (grupo %) não bate com o rótulo "%".', r.slot, r.home_name, v_hg, lab_h;
    END IF;
    IF position(v_ag IN lab_a) = 0 THEN
      RAISE EXCEPTION 'slot %: visitante "%" (grupo %) não bate com o rótulo "%".', r.slot, r.away_name, v_ag, lab_a;
    END IF;
  END LOOP;

  -- 32 times distintos (sem repetição entre os 16 jogos)
  IF (SELECT count(DISTINCT n) FROM (
        SELECT home_name AS n FROM _r32 UNION ALL SELECT away_name FROM _r32) s) <> 32 THEN
    RAISE EXCEPTION 'Há time repetido entre os 16 confrontos.';
  END IF;
END $$;

-- ───────────────────────────────────────────────────────────────────────────
-- 3) GRAVA times + horário nos 16-avos
-- ───────────────────────────────────────────────────────────────────────────
UPDATE ko_match k
   SET home_team_id = th.id,
       away_team_id = ta.id,
       match_date   = r.kickoff
  FROM _r32 r
  JOIN teams th ON th.name = r.home_name
  JOIN teams ta ON ta.name = r.away_name
 WHERE k.round = '16avos' AND k.slot = r.slot;

-- ───────────────────────────────────────────────────────────────────────────
-- 4) HORÁRIOS OFICIAIS das demais fases (a árvore/confrontos já estão ligados e
--    foram conferidos: oitavas pareiam slots 1-2,3-4,…; quartas 1-2,3-4; etc.)
-- ───────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE _later (round text, slot int, kickoff timestamptz, PRIMARY KEY (round, slot))
  ON COMMIT DROP;
INSERT INTO _later (round, slot, kickoff) VALUES
  ('oitavas', 1, '2026-07-04 18:00:00-03'),  -- Venc.AlemanhaxParaguai  x Venc.FrançaxSuécia
  ('oitavas', 2, '2026-07-04 14:00:00-03'),  -- Venc.ÁfricaSulxCanadá    x Venc.HolandaxMarrocos
  ('oitavas', 3, '2026-07-06 16:00:00-03'),  -- Venc.PortugalxCroácia    x Venc.EspanhaxÁustria
  ('oitavas', 4, '2026-07-06 21:00:00-03'),  -- Venc.EUAxBósnia          x Venc.BélgicaxSenegal
  ('oitavas', 5, '2026-07-05 17:00:00-03'),  -- Venc.BrasilxJapão        x Venc.CostaMarfimxNoruega
  ('oitavas', 6, '2026-07-05 21:00:00-03'),  -- Venc.MéxicoxEquador      x Venc.InglaterraxRDCongo
  ('oitavas', 7, '2026-07-07 13:00:00-03'),  -- Venc.ArgentinaxCaboVerde x Venc.AustráliaxEgito
  ('oitavas', 8, '2026-07-07 17:00:00-03'),  -- Venc.SuíçaxArgélia       x Venc.ColômbiaxGana
  ('quartas', 1, '2026-07-09 17:00:00-03'),  -- Oitavas 1 x Oitavas 2
  ('quartas', 2, '2026-07-10 16:00:00-03'),  -- Oitavas 3 x Oitavas 4
  ('quartas', 3, '2026-07-11 18:00:00-03'),  -- Oitavas 5 x Oitavas 6
  ('quartas', 4, '2026-07-11 22:00:00-03'),  -- Oitavas 7 x Oitavas 8
  ('semis',   1, '2026-07-14 16:00:00-03'),  -- Quartas 1 x Quartas 2
  ('semis',   2, '2026-07-15 16:00:00-03'),  -- Quartas 3 x Quartas 4
  ('3lugar',  1, '2026-07-18 18:00:00-03'),  -- Perd. Semi 1 x Perd. Semi 2
  ('final',   1, '2026-07-19 16:00:00-03');  -- Semi 1 x Semi 2

UPDATE ko_match k
   SET match_date = l.kickoff
  FROM _later l
 WHERE k.round = l.round AND k.slot = l.slot;

-- ───────────────────────────────────────────────────────────────────────────
-- 5) CONFERÊNCIA (deve listar os 32 jogos em ordem cronológica; nos 16-avos com
--    os times reais, nas fases seguintes com o rótulo "Venc. Jogo N").
-- ───────────────────────────────────────────────────────────────────────────
SELECT
  k.round,
  k.slot,
  k.match_no                                          AS jogo_fifa,
  COALESCE(th.name, k.home_slot_label)                AS mandante,
  COALESCE(ta.name, k.away_slot_label)                AS visitante,
  to_char(k.match_date AT TIME ZONE 'America/Sao_Paulo', 'DD/MM Dy HH24:MI') AS inicio_brt,
  k.match_date                                        AS inicio_utc
FROM ko_match k
LEFT JOIN teams th ON th.id = k.home_team_id
LEFT JOIN teams ta ON ta.id = k.away_team_id
ORDER BY k.match_date, k.match_no;

-- Se a conferência acima estiver certa, mantenha o COMMIT.
-- Para apenas pré-visualizar sem gravar, troque COMMIT por ROLLBACK e rode de novo.
COMMIT;
