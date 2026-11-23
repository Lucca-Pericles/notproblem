-- SYN-20: probable cause and one concrete action plan per occurrence.
alter table public.five_why_investigations
  add constraint five_why_investigations_id_occurrence_id_key
  unique (id, occurrence_id);

create table public.action_plans (
  id uuid primary key default gen_random_uuid(),
  occurrence_id uuid not null unique references public.occurrences(id) on delete cascade,
  investigation_id uuid not null unique,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  probable_cause text not null check (char_length(trim(probable_cause)) between 2 and 4000),
  action text not null check (char_length(trim(action)) between 2 and 4000),
  responsible text not null check (char_length(trim(responsible)) between 2 and 120),
  due_date date not null,
  expected_result text not null check (char_length(trim(expected_result)) between 2 and 4000),
  indicator text not null check (char_length(trim(indicator)) between 2 and 500),
  status text not null default 'planned' check (status = 'planned'),
  created_at timestamptz not null default now(),
  constraint action_plans_investigation_occurrence_fkey
    foreign key (investigation_id, occurrence_id)
    references public.five_why_investigations(id, occurrence_id)
    on delete cascade
);

alter table public.action_plans enable row level security;

revoke all on table public.action_plans from anon, authenticated;
grant select on table public.action_plans to authenticated;
grant insert (
  occurrence_id,
  investigation_id,
  probable_cause,
  action,
  responsible,
  due_date,
  expected_result,
  indicator
) on table public.action_plans to authenticated;

create index action_plans_user_id_idx on public.action_plans (user_id);

create policy "action_plans_select_own"
on public.action_plans for select to authenticated
using ((select auth.uid()) = user_id);

create policy "action_plans_insert_own_completed_investigation"
on public.action_plans for insert to authenticated
with check (
  (select auth.uid()) = user_id and
  due_date >= (now() at time zone 'America/Sao_Paulo')::date and
  exists (
    select 1 from public.occurrences
    where occurrences.id = action_plans.occurrence_id
      and occurrences.user_id = (select auth.uid())
      and occurrences.status = 'investigating'
  ) and
  exists (
    select 1 from public.five_why_investigations
    where five_why_investigations.id = action_plans.investigation_id
      and five_why_investigations.occurrence_id = action_plans.occurrence_id
      and five_why_investigations.user_id = (select auth.uid())
      and five_why_investigations.status = 'completed'
  )
);

create or replace function private.mark_occurrence_action_planned()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.occurrences
  set status = 'action_planned'
  where id = new.occurrence_id
    and user_id = new.user_id
    and status = 'investigating';
  return new;
end;
$$;

revoke all on function private.mark_occurrence_action_planned() from public;

create trigger action_plans_mark_occurrence_action_planned
  after insert on public.action_plans
  for each row execute procedure private.mark_occurrence_action_planned();
