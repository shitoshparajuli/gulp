-- Open up cross-user reads so the home feed can show activity from people you follow,
-- and so suggested-users lists can render. Follows table gets self-managed write policies.

-- Profiles: every authenticated user can read every profile (username, display_name, avatar_url).
drop policy if exists "Authenticated can read all profiles" on public.profiles;
create policy "Authenticated can read all profiles"
on public.profiles
for select
to authenticated
using (true);

-- Ratings: every authenticated user can read every non-deleted rating.
drop policy if exists "Authenticated can read all ratings" on public.ratings;
create policy "Authenticated can read all ratings"
on public.ratings
for select
to authenticated
using (deleted_at is null);

-- Dishes are shared across users; everyone can read.
drop policy if exists "Authenticated can read all dishes" on public.dishes;
create policy "Authenticated can read all dishes"
on public.dishes
for select
to authenticated
using (true);

-- Restaurants are shared across users; everyone can read.
drop policy if exists "Authenticated can read all restaurants" on public.restaurants;
create policy "Authenticated can read all restaurants"
on public.restaurants
for select
to authenticated
using (true);

-- Follows: enable RLS (harmless if already on) and define read/write policies.
alter table public.follows enable row level security;

drop policy if exists "Authenticated can read all follows" on public.follows;
create policy "Authenticated can read all follows"
on public.follows
for select
to authenticated
using (true);

drop policy if exists "Users can follow others" on public.follows;
create policy "Users can follow others"
on public.follows
for insert
to authenticated
with check (follower_id = auth.uid());

drop policy if exists "Users can unfollow" on public.follows;
create policy "Users can unfollow"
on public.follows
for delete
to authenticated
using (follower_id = auth.uid());
