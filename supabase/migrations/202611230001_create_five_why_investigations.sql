-- SYN-19: guided and resumable 5 Whys investigations.
create table if not exists public.five_why_investigations (
  id uuid primary key default gen_random_uuid(),
  occurrence_id uuid not null unique references public.occurrences(id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  answer_1 text check (answer_1 is null or char_length(trim(answer_1)) between 2 and 4000),
  answer_2 text check (answer_2 is null or char_length(trim(answer_2)) between 2 and 4000),
  answer_3 text check (answer_3 is null or char_length(trim(answer_3)) between 2 and 4000),
  answer_4 text check (answer_4 is null or char_length(trim(answer_4)) between 2 and 4000),
  answer_5 text check (answer_5 is null or char_length(trim(answer_5)) between 2 and 4000),
  status text not null default 'draft' check (status in ('draft', 'completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint five_why_answers_in_sequence check (
    (answer_2 is null or answer_1 is not null) and
    (answer_3 is null or answer_2 is not null) and
    (answer_4 is null or answer_3 is not null) and
    (answer_5 is null or answer_4 is not null)
  ),
  constraint five_why_completed_has_all_answers check (
    status <> 'completed' or
    (answer_1 is not null and answer_2 is not null and answer_3 is not null and
     answer_4 is not null and answer_5 is not null)
  )
);

alter table public.five_why_investigations enable row level security;

revoke all on table public.five_why_investigations from anon, authenticated;
grant select, insert on table public.five_why_investigations to authenticated;
grant update (answer_1, answer_2, answer_3, answer_4, answer_5, status)
  on table public.five_why_investigations to authenticated;

create index if not exists five_why_investigations_user_id_idx
  on public.five_why_investigations (user_id);

create policy "five_why_select_own"
on public.five_why_investigations for select to authenticated
using ((select auth.uid()) = user_id);

create policy "five_why_insert_own_occurrence"
on public.five_why_investigations for insert to authenticated
with check (
  (select auth.uid()) = user_id and
  exists (
    select 1 from public.occurrences
    where occurrences.id = occurrence_id
      and occurrences.user_id = (select auth.uid())
  )
);

create policy "five_why_update_own_draft"
on public.five_why_investigations for update to authenticated
using ((select auth.uid()) = user_id and status = 'draft')
with check ((select auth.uid()) = user_id);

-- SYN-18 allows context edits only while the analysis is still open.
drop policy if exists "occurrences_update_own_open" on public.occurrences;
create policy "occurrences_update_own_open"
on public.occurrences for update to authenticated
using (
  (select auth.uid()) = user_id and
  status <> 'completed' and
  not exists (
    select 1 from public.five_why_investigations
    where occurrence_id = occurrences.id and status = 'completed'
  )
)
with check (
  (select auth.uid()) = user_id and
  status <> 'completed' and
  not exists (
    select 1 from public.five_why_investigations
    where occurrence_id = occurrences.id and status = 'completed'
  )
);

create or replace function private.mark_occurrence_investigating()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.occurrences
  set status = 'investigating'
  where id = new.occurrence_id
    and user_id = new.user_id
    and status = 'registered';
  return new;
end;
$$;

revoke all on function private.mark_occurrence_investigating() from public;

drop trigger if exists five_why_mark_occurrence_investigating
  on public.five_why_investigations;
create trigger five_why_mark_occurrence_investigating
  after insert on public.five_why_investigations
  for each row execute procedure private.mark_occurrence_investigating();

drop trigger if exists five_why_set_updated_at on public.five_why_investigations;
create trigger five_why_set_updated_at
  before update on public.five_why_investigations
  for each row execute procedure private.set_updated_at();
