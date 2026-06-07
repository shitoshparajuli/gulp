-- Soft-delete was silently failing the same way INSERT did before
-- 20260601000153_hotfix_rating_insert.sql: the ratings_update_own policy
-- still gates on `user_id = auth.uid()`, and an UPDATE that trips it either
-- raises an RLS error or matches zero rows. The app swallowed both, so
-- "delete rating" looked like a no-op.
--
-- Fix (mirrors the INSERT hotfix's server-side-enforcement strategy):
-- a SECURITY DEFINER function that bypasses RLS but still enforces ownership
-- in its WHERE clause via auth.uid(). Returns the number of rows it
-- soft-deleted so the client can tell success from a no-op.

create or replace function public.soft_delete_ratings(p_ids uuid[])
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  affected integer;
begin
  update public.ratings
     set deleted_at = now()
   where id = any(p_ids)
     and user_id = auth.uid()
     and deleted_at is null;

  get diagnostics affected = row_count;
  return affected;
end;
$$;

-- Only authenticated users may call it; never anon/public.
revoke all on function public.soft_delete_ratings(uuid[]) from public;
grant execute on function public.soft_delete_ratings(uuid[]) to authenticated;
