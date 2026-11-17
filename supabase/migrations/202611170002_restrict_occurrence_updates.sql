-- SYN-18: clients may only edit the context of open occurrences.
revoke update on public.occurrences from authenticated;
grant update (context) on public.occurrences to authenticated;
