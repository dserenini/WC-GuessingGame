-- ==========================================
-- SCRIPT DE NOTIFICAÇÕES PARA SUPABASE
-- ==========================================

-- 1. Criação da tabela
create table public.notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  message text not null,
  is_read boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Habilitar RLS
alter table public.notifications enable row level security;

-- 3. Políticas de Segurança (RLS)
create policy "Users can view their own notifications." on public.notifications
  for select using (auth.uid() = user_id);

create policy "Users can update their own notifications." on public.notifications
  for update using (auth.uid() = user_id);

create policy "Users can delete their own notifications." on public.notifications
  for delete using (auth.uid() = user_id);

-- 4. Função RPC para envio em massa pelo Administrador
-- Suporta dois filtros: 'all' (Todos os usuários) ou 'missing_bets' (Usuários com apostas incompletas)
create or replace function admin_send_notification(p_title text, p_message text, p_filter text)
returns void as $$
declare
  v_total_matches integer;
begin
  if p_filter = 'all' then
    insert into public.notifications (user_id, title, message)
    select id, p_title, p_message from auth.users;
    
  elsif p_filter = 'missing_bets' then
    select count(*) into v_total_matches from public.matches;
    
    insert into public.notifications (user_id, title, message)
    select u.id, p_title, p_message 
    from auth.users u
    where (select count(*) from public.bets b where b.user_id = u.id) < v_total_matches;
  end if;
end;
$$ language plpgsql security definer;
