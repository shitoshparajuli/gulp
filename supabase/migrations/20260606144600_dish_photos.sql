-- ============================================================
-- dish_photos: a growing collection of every photo uploaded for
-- a dish. Each photo a user attaches to their rating is mirrored
-- here so we accumulate a per-dish image DB (a gallery) over time,
-- independent of any single rating's lifecycle.
--
-- Population is automatic: a security-definer trigger on ratings
-- inserts a row here whenever a rating gains/changes a photo. The
-- client never writes to this table directly (mirrors how
-- enforce_rating_owner keeps rating ownership server-side).
-- ============================================================

create table if not exists public.dish_photos (
  id         uuid primary key default gen_random_uuid(),
  dish_id    uuid not null references public.dishes(id)  on delete cascade,
  rating_id  uuid          references public.ratings(id) on delete set null,
  user_id    uuid not null references auth.users(id)     on delete cascade,
  photo_path text not null unique,
  created_at timestamptz not null default now()
);

create index if not exists dish_photos_dish_id_created_idx
  on public.dish_photos (dish_id, created_at desc);

-- ============================================================
-- RLS
--   - SELECT: anyone authenticated can read (powers galleries).
--   - No client INSERT/UPDATE/DELETE policies: rows are written
--     only by the security-definer trigger below, which bypasses
--     RLS. Cascades from dishes/ratings/users handle cleanup.
-- ============================================================

alter table public.dish_photos enable row level security;

drop policy if exists "dish_photos_select_all" on public.dish_photos;
create policy "dish_photos_select_all"
  on public.dish_photos for select
  to authenticated
  using (true);

-- ============================================================
-- Mirror a rating's photo into dish_photos.
-- Fires when a photo is first attached (INSERT) or swapped for a
-- new one (UPDATE where photo_path changed). Editing score/notes,
-- or soft-deleting, leaves photo_path unchanged and is skipped.
-- Old photos are kept on purpose — that's the point of the DB.
-- on conflict (photo_path) guards against re-firing on the same
-- image (photo_path is a globally-unique uploaded filename).
-- ============================================================

create or replace function public.sync_dish_photo()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.photo_path is not null
     and (tg_op = 'INSERT' or new.photo_path is distinct from old.photo_path) then
    insert into public.dish_photos (dish_id, rating_id, user_id, photo_path)
    values (new.dish_id, new.id, new.user_id, new.photo_path)
    on conflict (photo_path) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists ratings_sync_dish_photo on public.ratings;
create trigger ratings_sync_dish_photo
  after insert or update on public.ratings
  for each row
  execute function public.sync_dish_photo();

-- ============================================================
-- Backfill: seed dish_photos from ratings that already carry a
-- photo. One row per photo_path; existing rows win.
-- ============================================================

insert into public.dish_photos (dish_id, rating_id, user_id, photo_path, created_at)
select r.dish_id, r.id, r.user_id, r.photo_path, r.created_at
from public.ratings r
where r.photo_path is not null
on conflict (photo_path) do nothing;
