-- Fix handle_new_user trigger:
-- 1. Username is now just the email prefix (no UUID suffix) for cleaner handles.
--    Falls back to prefix_first4uuid only on a unique_violation (two users with
--    the same email prefix from different domains).
-- 2. Captures avatar_url from OAuth metadata (e.g. Google profile picture).
-- 3. Adds outer EXCEPTION handler so unexpected failures log a WARNING instead
--    of silently leaving the user without a profile.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  BEGIN
    INSERT INTO public.profiles (id, username, display_name, avatar_url)
    VALUES (
      NEW.id,
      split_part(NEW.email, '@', 1),
      COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
      NEW.raw_user_meta_data->>'avatar_url'
    );
  EXCEPTION WHEN unique_violation THEN
    INSERT INTO public.profiles (id, username, display_name, avatar_url)
    VALUES (
      NEW.id,
      split_part(NEW.email, '@', 1) || '_' || left(NEW.id::text, 4),
      COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
      NEW.raw_user_meta_data->>'avatar_url'
    );
  END;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'handle_new_user failed for user %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;

-- Backfill existing profiles to drop the _XXXX suffix.
UPDATE public.profiles p
SET username = split_part(u.email, '@', 1)
FROM auth.users u
WHERE p.id = u.id;
