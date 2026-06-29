-- =============================================================================
-- REVELAÇÃO DOS PALPITES DO MATA-MATA — antecipa de "no kickoff" p/ "30 min
-- antes" (PRODUÇÃO). Rodar no Supabase SQL Editor.
--
-- O prazo do palpite de KO é 30 min antes do jogo (ko_bet_deadline). A partir
-- desse momento o jogo está "fechado" (não dá mais para mudar a aposta), então
-- os palpites alheios podem ser revelados sem risco de cópia. A política antiga
-- só revelava a partir do horário do jogo (now() >= match_date); aqui passamos
-- para now() >= match_date - 30 min, batendo com o fechamento da aposta.
--
-- Telas que dependem disso: perfil visitante do KO e "ver apostas" do KO
-- (mostram só jogos finalizados/ao vivo/fechados-há-30min).
-- =============================================================================

DROP POLICY IF EXISTS ko_bet_read ON ko_bet;
CREATE POLICY ko_bet_read ON ko_bet FOR SELECT USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM ko_match m
    WHERE m.id = ko_match_id
      AND m.match_date IS NOT NULL
      AND now() >= m.match_date - interval '30 minutes'
  )
);
