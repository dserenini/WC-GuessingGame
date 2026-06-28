-- =============================================================================
-- MATA-MATA — PREENCHER OS 8 TERCEIROS COLOCADOS NOS 16-AVOS
--   Rode SÓ depois que a fase de grupos acabar e você souber:
--     (1) os 8 melhores 3ºs (quais grupos avançam) e
--     (2) a alocação oficial da FIFA (qual 3º vai pra qual jogo).
--
--   COMO USAR: preencha apenas o NOME do time em cada linha do passo 1.
--   O grupo é derivado de teams.group_letter — você NÃO digita o grupo.
--
--   TRAVAS À PROVA DE ERRO (qualquer falha aborta tudo, nada é gravado):
--     • nome em branco            -> erro
--     • nome não existe em teams  -> erro (pega erro de grafia)
--     • grupo do time fora do slot -> erro (pega jogo trocado)
--     • dois 3ºs do mesmo grupo   -> erro (cada grupo só dá 1 terceiro)
--     • time repetido em 2 jogos  -> erro
--
--   LIMITE: as travas garantem que o grupo é PERMITIDO naquele slot, mas NÃO
--   substituem a tabela de alocação da FIFA — para a combinação específica dos
--   8 grupos classificados, consulte o anexo oficial p/ saber o mapeamento exato.
-- =============================================================================
BEGIN;

-- ───────────────────────────────────────────────────────────────────────────
-- PASSO 1: PREENCHA o nome exato (= teams.name) do 3º de cada confronto.
--          O comentário ao lado mostra os grupos permitidos naquele slot.
-- ───────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE _thirds (match_no int PRIMARY KEY, team_name text) ON COMMIT DROP;
INSERT INTO _thirds (match_no, team_name) VALUES
  (74, ''),   -- 3º A/B/C/D/F   (adversário do 1º E)
  (77, ''),   -- 3º C/D/F/G/H   (adversário do 1º I)
  (79, ''),   -- 3º C/E/F/H/I   (adversário do 1º A)
  (80, ''),   -- 3º E/H/I/J/K   (adversário do 1º L)
  (81, ''),   -- 3º B/E/F/I/J   (adversário do 1º D)
  (82, ''),   -- 3º A/E/H/I/J   (adversário do 1º G)
  (85, ''),   -- 3º E/F/G/I/J   (adversário do 1º B)
  (87, '');   -- 3º D/E/I/J/L   (adversário do 1º K)

-- ───────────────────────────────────────────────────────────────────────────
-- PASSO 2: VALIDAÇÕES (não mexer)
-- ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v        record;
  v_id     uuid;
  v_grp    char(1);
  v_allow  text;
BEGIN
  IF (SELECT count(*) FROM _thirds) <> 8 THEN
    RAISE EXCEPTION 'Esperado 8 confrontos, encontrei %.', (SELECT count(*) FROM _thirds);
  END IF;

  IF EXISTS (SELECT 1 FROM _thirds WHERE COALESCE(btrim(team_name),'') = '') THEN
    RAISE EXCEPTION 'Há confronto(s) sem nome preenchido. Preencha os 8.';
  END IF;

  FOR v IN SELECT * FROM _thirds ORDER BY match_no LOOP
    SELECT id, group_letter INTO v_id, v_grp FROM teams WHERE name = btrim(v.team_name);
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'Jogo %: time "%" não existe em teams.name (confira a grafia exata).',
        v.match_no, v.team_name;
    END IF;

    SELECT away_slot_label INTO v_allow FROM ko_match WHERE match_no = v.match_no AND round = '16avos';
    IF v_allow IS NULL THEN
      RAISE EXCEPTION 'Jogo % não é um slot de 16-avos válido.', v.match_no;
    END IF;
    IF position(v_grp IN v_allow) = 0 THEN
      RAISE EXCEPTION 'Jogo %: "%" é do grupo %, que NÃO está no slot "%".',
        v.match_no, v.team_name, v_grp, v_allow;
    END IF;
  END LOOP;

  IF EXISTS (
    SELECT 1 FROM _thirds t JOIN teams te ON te.name = btrim(t.team_name)
    GROUP BY te.group_letter HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION 'Dois confrontos receberam 3ºs do MESMO grupo. Cada grupo fornece só um.';
  END IF;

  IF EXISTS (SELECT 1 FROM _thirds GROUP BY btrim(team_name) HAVING count(*) > 1) THEN
    RAISE EXCEPTION 'O mesmo time foi colocado em dois confrontos.';
  END IF;
END $$;

-- ───────────────────────────────────────────────────────────────────────────
-- PASSO 3: GRAVA (o 3º é sempre o visitante = away_team_id nos 8 slots)
-- ───────────────────────────────────────────────────────────────────────────
UPDATE ko_match m
   SET away_team_id = te.id
  FROM _thirds t
  JOIN teams te ON te.name = btrim(t.team_name)
 WHERE m.match_no = t.match_no AND m.round = '16avos';

-- ───────────────────────────────────────────────────────────────────────────
-- PASSO 4: CONFIRA antes do COMMIT (deve listar os 8, sem nada vazio)
-- ───────────────────────────────────────────────────────────────────────────
SELECT m.match_no, m.home_slot_label, m.away_slot_label,
       te.name AS terceiro, te.group_letter AS grupo
  FROM ko_match m
  JOIN _thirds t ON t.match_no = m.match_no
  JOIN teams te  ON te.name = btrim(t.team_name)
 ORDER BY m.match_no;

-- Se o resultado acima estiver certo:   COMMIT;
-- Se algo estiver errado:               ROLLBACK;
COMMIT;
