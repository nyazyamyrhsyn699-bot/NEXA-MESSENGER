create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text,
  avatar_url text,
  bio text default '',
  created_at timestamptz default now()
);

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  type text not null default 'private'
    check (type in ('private','group','channel')),
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

create table if not exists public.chat_members (
  chat_id uuid references public.chats(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  role text default 'member',
  joined_at timestamptz default now(),
  primary key(chat_id,user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid references public.chats(id) on delete cascade,
  sender_id uuid references auth.users(id),
  content text not null default '',
  message_type text default 'text',
  created_at timestamptz default now(),
  edited_at timestamptz,
  deleted_at timestamptz
);

create table if not exists public.user_blocks (
  blocker_id uuid references auth.users(id) on delete cascade,
  blocked_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  primary key(blocker_id,blocked_id)
);

create table if not exists public.message_reports (
  id uuid primary key default gen_random_uuid(),
  message_id uuid references public.messages(id) on delete cascade,
  reporter_id uuid references auth.users(id),
  reason text not null,
  status text default 'pending',
  created_at timestamptz default now()
);

create table if not exists public.moderation_logs (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references auth.users(id),
  target_user_id uuid references auth.users(id),
  action text not null,
  reason text,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;
alter table public.chats enable row level security;
alter table public.chat_members enable row level security;
alter table public.messages enable row level security;
alter table public.user_blocks enable row level security;
alter table public.message_reports enable row level security;
alter table public.moderation_logs enable row level security;

drop policy if exists profile_read on public.profiles;
create policy profile_read on public.profiles
for select to authenticated using (true);

drop policy if exists profile_insert on public.profiles;
create policy profile_insert on public.profiles
for insert to authenticated with check (id = auth.uid());

drop policy if exists profile_update on public.profiles;
create policy profile_update on public.profiles
for update to authenticated using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists chat_member_read on public.chat_members;
create policy chat_member_read on public.chat_members
for select to authenticated
using (user_id = auth.uid());

drop policy if exists chat_read on public.chats;
create policy chat_read on public.chats
for select to authenticated
using (
  exists (
    select 1 from public.chat_members m
    where m.chat_id = id and m.user_id = auth.uid()
  )
);

drop policy if exists chat_create on public.chats;
create policy chat_create on public.chats
for insert to authenticated
with check (created_by = auth.uid());

drop policy if exists member_add_self on public.chat_members;
create policy member_add_self on public.chat_members
for insert to authenticated
with check (
  user_id = auth.uid()
  and exists (
    select 1 from public.chats c
    where c.id = chat_id and c.created_by = auth.uid()
  )
);

drop policy if exists message_read_member on public.messages;
create policy message_read_member on public.messages
for select to authenticated
using (
  exists (
    select 1 from public.chat_members m
    where m.chat_id = messages.chat_id
      and m.user_id = auth.uid()
  )
);

drop policy if exists message_send_member on public.messages;
create policy message_send_member on public.messages
for insert to authenticated
with check (
  sender_id = auth.uid()
  and exists (
    select 1 from public.chat_members m
    where m.chat_id = messages.chat_id
      and m.user_id = auth.uid()
  )
);

drop policy if exists message_edit_own on public.messages;
create policy message_edit_own on public.messages
for update to authenticated
using (sender_id = auth.uid())
with check (sender_id = auth.uid());

drop policy if exists block_manage on public.user_blocks;
create policy block_manage on public.user_blocks
for all to authenticated
using (blocker_id = auth.uid())
with check (blocker_id = auth.uid());

drop policy if exists report_create on public.message_reports;
create policy report_create on public.message_reports
for insert to authenticated
with check (reporter_id = auth.uid());

drop policy if exists report_read_own on public.message_reports;
create policy report_read_own on public.message_reports
for select to authenticated
using (reporter_id = auth.uid());

drop policy if exists moderation_admin_only on public.moderation_logs;
create policy moderation_admin_only on public.moderation_logs
for select to authenticated
using ((auth.jwt()->'app_metadata'->>'role') = 'admin');

create or replace function public.nexa_suspend_user(
  target uuid,
  reason_text text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (auth.jwt()->'app_metadata'->>'role') <> 'admin' then
    raise exception 'Admin access required';
  end if;

  insert into public.moderation_logs
    (admin_id,target_user_id,action,reason)
  values
    (auth.uid(),target,'suspend',reason_text);

  update auth.users
  set banned_until = now() + interval '100 years'
  where id = target;
end;
$$;

revoke all on function public.nexa_suspend_user(uuid,text) from public;
grant execute on function public.nexa_suspend_user(uuid,text) to authenticated;

do $$
begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null;
when undefined_object then null;
end $$;
