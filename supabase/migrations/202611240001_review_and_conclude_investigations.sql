-- SYN-21: review the full investigation before planning the action.
drop trigger if exists action_plans_mark_occurrence_action_planned
  on public.action_plans;

alter table public.action_plans
  alter column status set default 'draft';
alter table public.action_plans
  drop constraint if exists action_plans_status_check;
alter table public.action_plans
  add constraint action_plans_status_check
  check (status in ('draft', 'planned'));

alter table public.five_why_investigations
  add column if not exists finalized_at timestamptz;

-- Preserve the lock state of investigations concluded by the previous flow.
update public.five_why_investigations as investigation
set finalized_at = coalesce(plan.created_at, now())
from public.action_plans as plan
where plan.investigation_id = investigation.id
  and plan.status = 'planned'
  and investigation.finalized_at is null;

grant update (
  probable_cause,
  action,
  responsible,
  due_date,
  expected_result,
  indicator
) on table public.action_plans to authenticated;

drop policy if exists "action_plans_update_own_draft"
  on public.action_plans;
create policy "action_plans_update_own_draft"
on public.action_plans for update to authenticated
using (
  (select auth.uid()) = user_id and
  status = 'draft'
)
with check (
  (select auth.uid()) = user_id and
  status = 'draft' and
  due_date >= (now() at time zone 'America/Sao_Paulo')::date
);

-- Context and answers stay editable during review, but never after conclusion.
drop policy if exists "occurrences_update_own_open" on public.occurrences;
create policy "occurrences_update_own_open"
on public.occurrences for update to authenticated
using (
  (select auth.uid()) = user_id and
  status in ('registered', 'investigating')
)
with check (
  (select auth.uid()) = user_id and
  status in ('registered', 'investigating')
);

drop policy if exists "five_why_update_own_draft"
  on public.five_why_investigations;
create policy "five_why_update_own_open_investigation"
on public.five_why_investigations for update to authenticated
using (
  (select auth.uid()) = user_id and
  finalized_at is null
)
with check (
  (select auth.uid()) = user_id and
  finalized_at is null
);

create or replace function public.conclude_investigation(
  p_occurrence_id uuid
)
returns setof public.action_plans
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_plan public.action_plans%rowtype;
  v_investigation public.five_why_investigations%rowtype;
  v_occurrence_status text;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select *
  into v_plan
  from public.action_plans
  where occurrence_id = p_occurrence_id
    and user_id = v_user_id
  for update;

  if not found then
    raise exception 'Action plan not found' using errcode = '22023';
  end if;

  if v_plan.status = 'planned' then
    return next v_plan;
    return;
  end if;

  select status
  into v_occurrence_status
  from public.occurrences
  where id = p_occurrence_id
    and user_id = v_user_id
  for update;

  if not found or v_occurrence_status <> 'investigating' then
    raise exception 'Occurrence is not open for conclusion'
      using errcode = '22023';
  end if;

  select *
  into v_investigation
    from public.five_why_investigations
    where id = v_plan.investigation_id
      and occurrence_id = p_occurrence_id
      and user_id = v_user_id
    for update;

  if not found
    or v_investigation.status <> 'completed'
    or v_investigation.finalized_at is not null
    or v_investigation.answer_1 is null
    or v_investigation.answer_2 is null
    or v_investigation.answer_3 is null
    or v_investigation.answer_4 is null
    or v_investigation.answer_5 is null
  then
    raise exception 'Five Whys investigation is incomplete'
      using errcode = '22023';
  end if;

  update public.five_why_investigations
  set finalized_at = now()
  where id = v_investigation.id
    and finalized_at is null;

  if not found then
    raise exception 'Investigation was concurrently concluded'
      using errcode = '40001';
  end if;

  if char_length(trim(v_plan.probable_cause)) < 2
    or char_length(trim(v_plan.action)) < 2
    or char_length(trim(v_plan.responsible)) < 2
    or char_length(trim(v_plan.expected_result)) < 2
    or char_length(trim(v_plan.indicator)) < 2
    or v_plan.due_date < (now() at time zone 'America/Sao_Paulo')::date
  then
    raise exception 'Action plan is incomplete or expired'
      using errcode = '22023';
  end if;

  update public.action_plans
  set status = 'planned'
  where id = v_plan.id
    and status = 'draft'
  returning * into v_plan;

  update public.occurrences
  set status = 'action_planned'
  where id = p_occurrence_id
    and user_id = v_user_id
    and status = 'investigating';

  if not found then
    raise exception 'Occurrence could not be concluded'
      using errcode = '40001';
  end if;

  return next v_plan;
end;
$$;

revoke all on function public.conclude_investigation(uuid) from public, anon;
grant execute on function public.conclude_investigation(uuid) to authenticated;
