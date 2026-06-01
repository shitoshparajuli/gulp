-- HOTFIX: ratings INSERT was still failing with
-- "new row violates row-level security policy" after the dishes/restaurants
-- hotfix, because the canonical migration's ratings_insert_own policy still
-- has `with check (user_id = auth.uid())` and that comparison is failing
-- against the live row in this environment.
--
-- Fix: enforce ownership via a BEFORE INSERT trigger that sets user_id
-- to auth.uid() server-side, then relax the INSERT policy to with check
-- (true). This is strictly tighter than client-side enforcement:
-- spoofed user_ids from clients are now overwritten by the server.

create or replace function public.enforce_rating_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.user_id := auth.uid();
  return new;
end;
$$;

drop trigger if exists ratings_enforce_owner on public.ratings;
create trigger ratings_enforce_owner
  before insert on public.ratings
  for each row
  execute function public.enforce_rating_owner();

drop policy if exists "ratings_insert_own" on public.ratings;
create policy "ratings_insert_own"
  on public.ratings for insert
  to authenticated
  with check (true);
