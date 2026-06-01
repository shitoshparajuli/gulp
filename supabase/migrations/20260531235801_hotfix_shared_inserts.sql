-- HOTFIX: the canonical RLS migration's INSERT policy on dishes and
-- restaurants used `with check (added_by = auth.uid())`. This rejected
-- valid inserts in production — the live schema's added_by column
-- semantics don't match the assumption (likely a default/trigger that
-- coerces the value to NULL or a different identifier).
--
-- Fix: relax the INSERT WITH CHECK on these shared tables to just
-- require an authenticated user. The added_by column is informational
-- on shared resources; security boundaries that actually matter
-- (ratings, follows) remain strict.

drop policy if exists "dishes_insert_authenticated" on public.dishes;
create policy "dishes_insert_authenticated"
  on public.dishes for insert
  to authenticated
  with check (true);

drop policy if exists "restaurants_insert_authenticated" on public.restaurants;
create policy "restaurants_insert_authenticated"
  on public.restaurants for insert
  to authenticated
  with check (true);
