-- ============================================================
-- FIXES FOR ADMIN ERRORS
-- Run this ONCE in the Supabase SQL Editor (Dashboard > SQL Editor).
-- It fixes both:
--   1. Admin > Faculty  -> saving fails ("column college_id does not exist")
--   2. Admin > Kiosk Settings -> "Error Loading Settings"
--      (the kiosk_settings table was missing from the database)
-- ============================================================

-- 1) Link faculty members to their college
alter table public.faculty
  add column if not exists college_id integer
  references public.colleges (id) on delete set null;

-- 2) Create the missing kiosk_settings table
create table if not exists public.kiosk_settings (
  id integer primary key generated always as identity,
  welcome_message text,
  campus_hours text,
  emergency_number text,
  theme_color text,
  font_size text default 'medium',
  screen_timeout integer default 300,
  welcome_animation boolean default true,
  show_map_on_start boolean default true,
  enable_search boolean default true,
  enable_directory boolean default true,
  enable_campus_info boolean default true
);

alter table public.kiosk_settings enable row level security;

drop policy if exists "Public read access" on public.kiosk_settings;
create policy "Public read access" on public.kiosk_settings
  for select using (true);

drop policy if exists "Authenticated manage access" on public.kiosk_settings;
create policy "Authenticated manage access" on public.kiosk_settings
  for all to authenticated
  using (true)
  with check (true);
