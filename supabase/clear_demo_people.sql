-- ============================================================
-- REMOVE DEMO / SEED PEOPLE FROM THE DATABASE
-- Run ONCE in the Supabase SQL Editor.
--
-- This clears ONLY the old pre-seeded names:
--   * college_faculty  -> obsolete demo faculty lists (app no longer uses it)
--   * leadership       -> seeded CEO / deans shown under "Heads & Faculty"
--
-- Your real `faculty` table (Admin > Faculty) is NOT touched.
-- You add faculty yourself from the admin panel afterwards.
-- ============================================================

truncate table public.college_faculty restart identity;

delete from public.leadership;
