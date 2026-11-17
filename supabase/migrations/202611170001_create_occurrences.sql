create table if not exists public.occurrences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 2 and 180),
  project text not null check (char_length(trim(project)) between 2 and 120),
  occurred_on date not null,
  context text not null check (char_length(trim(context)) between 2 and 4000),
  impact text not null check (char_length(trim(impact)) between 2 and 4000),
  status text not null default 'registered' check (status in ('registered', 'investigating', 'action_planned', 'completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.occurrences enable row level security;

revoke all on table public.occurrences from anon;
revoke all on table public.occurrences from authenticated;
grant select, insert, update on table public.occurrences to authenticated;

create index if not exists occurrences_user_id_created_at_idx
  on public.occurrences (user_id, created_at desc);

create policy "occurrences_select_own"
on public.occurrences for select to authenticated
using ((select auth.uid()) = user_id);

create policy "occurrences_insert_own"
on public.occurrences for insert to authenticated
with check ((select auth.uid()) = user_id and status = 'registered');

create policy "occurrences_update_own_open"
on public.occurrences for update to authenticated
using ((select auth.uid()) = user_id and status <> 'completed')
with check ((select auth.uid()) = user_id);

drop trigger if exists occurrences_set_updated_at on public.occurrences;
create trigger occurrences_set_updated_at
  before update on public.occurrences
  for each row execute procedure private.set_updated_at();
