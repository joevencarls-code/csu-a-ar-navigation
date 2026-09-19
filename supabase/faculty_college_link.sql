-- Links each faculty member to their college so that faculty added in
-- Admin > Faculty automatically appear in the kiosk's Campus Info
-- "Heads & Faculty" section.
--
-- Run this once in the Supabase SQL Editor.

alter table public.faculty
  add column if not exists college_id integer
  references public.colleges (id) on delete set null;
