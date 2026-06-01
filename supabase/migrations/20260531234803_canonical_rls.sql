-- ============================================================
-- Canonical RLS policies for the public schema.
-- This migration is the SOURCE OF TRUTH. Do not edit policies
-- in the Supabase dashboard — make a new migration instead.
--
-- Strategy: drop every existing policy on these tables, then
-- recreate the canonical set. Runs inside a single transaction
-- so there is no unprotected window.
-- ============================================================

-- Ensure RLS is enabled on every public-facing table.
alter table public.profiles    enable row level security;
alter table public.restaurants enable row level security;
alter table public.dishes      enable row level security;
alter table public.ratings     enable row level security;
alter table public.follows     enable row level security;

-- Wipe every existing policy on the tables we control.
do $$
declare
  pol record;
begin
  for pol in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename in ('profiles', 'restaurants', 'dishes', 'ratings', 'follows')
  loop
    execute format('drop policy %I on %I.%I',
                   pol.policyname, pol.schemaname, pol.tablename);
  end loop;
end $$;

-- ============================================================
-- profiles
--   - Anyone authenticated can read any profile (powers feed/social).
--   - A user can only insert/update their own row (id = auth.uid()).
--   - Profile rows are normally inserted by the handle_new_user
--     trigger (security definer), which bypasses RLS. The INSERT
--     policy below covers manual recreation if needed.
-- ============================================================

create policy "profiles_select_all"
  on public.profiles for select
  to authenticated
  using (true);

create policy "profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check (id = auth.uid());

create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- ============================================================
-- restaurants
--   - Shared resource. Anyone authenticated can read.
--   - Anyone authenticated can insert (added_by must equal them).
--   - No UPDATE/DELETE — restaurants are immutable once added.
-- ============================================================

create policy "restaurants_select_all"
  on public.restaurants for select
  to authenticated
  using (true);

create policy "restaurants_insert_authenticated"
  on public.restaurants for insert
  to authenticated
  with check (added_by = auth.uid());

-- ============================================================
-- dishes
--   - Shared resource. Anyone authenticated can read.
--   - Anyone authenticated can insert (added_by must equal them).
--   - No UPDATE/DELETE — dishes are immutable once added.
-- ============================================================

create policy "dishes_select_all"
  on public.dishes for select
  to authenticated
  using (true);

create policy "dishes_insert_authenticated"
  on public.dishes for insert
  to authenticated
  with check (added_by = auth.uid());

-- ============================================================
-- ratings
--   - User-owned, soft-deletable.
--   - SELECT: anyone authenticated can read non-deleted ratings.
--   - INSERT: must own the row (user_id = auth.uid()).
--   - UPDATE: must own the row, AND cannot change ownership.
--   - DELETE: must own the row (used only for hard cleanups; the
--     app soft-deletes via UPDATE deleted_at).
-- ============================================================

create policy "ratings_select_active"
  on public.ratings for select
  to authenticated
  using (deleted_at is null);

create policy "ratings_insert_own"
  on public.ratings for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "ratings_update_own"
  on public.ratings for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "ratings_delete_own"
  on public.ratings for delete
  to authenticated
  using (user_id = auth.uid());

-- ============================================================
-- follows
--   - SELECT: anyone authenticated can read all follow edges.
--   - INSERT: must be the follower (follower_id = auth.uid()).
--   - DELETE: must be the follower (follower_id = auth.uid()).
-- ============================================================

create policy "follows_select_all"
  on public.follows for select
  to authenticated
  using (true);

create policy "follows_insert_self"
  on public.follows for insert
  to authenticated
  with check (follower_id = auth.uid());

create policy "follows_delete_self"
  on public.follows for delete
  to authenticated
  using (follower_id = auth.uid());
