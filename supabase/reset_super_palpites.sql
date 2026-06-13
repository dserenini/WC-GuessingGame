-- Reset do contador de Super Palpites de TODOS os usuários.
--
-- Contexto: o trigger check_bet_deadline contava 2 Super Palpites por alteração
-- de placar (o upsert INSERT ... ON CONFLICT DO UPDATE disparava tanto o
-- BEFORE INSERT quanto o BEFORE UPDATE). Após corrigir o trigger
-- (ver super_palpite.sql), zeramos o saldo de todos para tirar a contagem em
-- dobro acumulada.
--
-- Rodar manualmente no SQL Editor do Supabase de produção.

UPDATE profiles
SET super_palpites_used = 0
WHERE super_palpites_used <> 0;
