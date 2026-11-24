-- SYN-22: track action execution, observed outcomes, and chronological notes.
alter table public.action_plans
  add constraint action_plans_id_occurrence_user_key
  unique (id, occurrence_id, user_id);

create table public.action_follow_ups (
  id uuid primary key default gen_random_uuid(),
  action_plan_id uuid not null unique,
  occurrence_id uuid not null unique,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  status text not null default 'not_started'
    check (status in ('not_started', 'in_progress', 'completed', 'cancelled')),
  observed_result text
    check (
      observed_result is null or
      char_length(trim(observed_result)) between 2 and 4000
    ),
  outcome text
    check (outcome is null or outcome in ('worked', 'partially_worked', 'did_not_work')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint action_follow_ups_plan_owner_fkey
    foreign key (action_plan_id, occurrence_id, user_id)
    references public.action_plans(id, occurrence_id, user_id)
    on delete cascade,
  constraint action_follow_ups_completion_result_check check (
    (
      status = 'completed' and
      observed_result is not null and
      outcome is not null
    ) or (
      status <> 'completed' and
      outcome is null
    )
  ),
  constraint action_follow_ups_id_user_key unique (id, user_id)
);

alter table public.action_follow_ups enable row level security;

revoke all on table public.action_follow_ups from anon, authenticated;
grant select on table public.action_follow_ups to authenticated;
grant insert (action_plan_id, occurrence_id)
  on table public.action_follow_ups to authenticated;
grant update (status, observed_result, outcome)
  on table public.action_follow_ups to authenticated;

create index action_follow_ups_user_id_idx
  on public.action_follow_ups (user_id);

create policy "action_follow_ups_select_own"
on public.action_follow_ups for select to authenticated
using ((select auth.uid()) = user_id);

create policy "action_follow_ups_insert_own_planned_action"
on public.action_follow_ups for insert to authenticated
with check (
  (select auth.uid()) = user_id and
  status = 'not_started' and
  observed_result is null and
  outcome is null and
  exists (
    select 1
    from public.action_plans
    where action_plans.id = action_follow_ups.action_plan_id
      and action_plans.occurrence_id = action_follow_ups.occurrence_id
      and action_plans.user_id = (select auth.uid())
      and action_plans.status = 'planned'
  )
);

create policy "action_follow_ups_update_own_planned_action"
on public.action_follow_ups for update to authenticated
using (
  (select auth.uid()) = user_id and
  exists (
    select 1
    from public.action_plans
    where action_plans.id = action_follow_ups.action_plan_id
      and action_plans.occurrence_id = action_follow_ups.occurrence_id
      and action_plans.user_id = (select auth.uid())
      and action_plans.status = 'planned'
  )
)
with check (
  (select auth.uid()) = user_id and
  exists (
    select 1
    from public.action_plans
    where action_plans.id = action_follow_ups.action_plan_id
      and action_plans.occurrence_id = action_follow_ups.occurrence_id
      and action_plans.user_id = (select auth.uid())
      and action_plans.status = 'planned'
  )
);

drop trigger if exists action_follow_ups_set_updated_at
  on public.action_follow_ups;
create trigger action_follow_ups_set_updated_at
  before update on public.action_follow_ups
  for each row execute procedure private.set_updated_at();

create table public.action_follow_up_notes (
  id uuid primary key default gen_random_uuid(),
  follow_up_id uuid not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  note text not null check (char_length(trim(note)) between 2 and 4000),
  created_at timestamptz not null default now(),
  constraint action_follow_up_notes_owner_fkey
    foreign key (follow_up_id, user_id)
    references public.action_follow_ups(id, user_id)
    on delete cascade
);

alter table public.action_follow_up_notes enable row level security;

revoke all on table public.action_follow_up_notes from anon, authenticated;
grant select on table public.action_follow_up_notes to authenticated;
grant insert (follow_up_id, note)
  on table public.action_follow_up_notes to authenticated;

create index action_follow_up_notes_user_id_idx
  on public.action_follow_up_notes (user_id);
create index action_follow_up_notes_timeline_idx
  on public.action_follow_up_notes (follow_up_id, created_at);

create policy "action_follow_up_notes_select_own"
on public.action_follow_up_notes for select to authenticated
using ((select auth.uid()) = user_id);

create policy "action_follow_up_notes_insert_own_follow_up"
on public.action_follow_up_notes for insert to authenticated
with check (
  (select auth.uid()) = user_id and
  exists (
    select 1
    from public.action_follow_ups
    where action_follow_ups.id = action_follow_up_notes.follow_up_id
      and action_follow_ups.user_id = (select auth.uid())
  )
);
