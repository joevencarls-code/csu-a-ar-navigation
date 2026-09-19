-- ============================================================
--  CSU-A Kiosk: Offices admin fix (single, safe, re-runnable)
--  Run ONCE in the Supabase SQL editor.
--  Safe: only ADDS the missing image_url column and the RLS
--  write policies the app needs. Nothing is truncated or dropped.
--
--  Fixes for IMS Super Admin + HRO Admin:
--    * Edit an office    (UPDATE needs the policy + image_url)
--    * Delete an office  (DELETE needs the policy)
--    * Approve HRO changes (the super admin's approval writes
--      directly to offices, which also needs these policies)
--    * Show office photos on the kiosk (image_url column)
-- ============================================================

-- 1. Column the app reads/writes but the table was missing.
alter table public.offices add column if not exists image_url text;

-- 2. RLS: enable (idempotent) + public read + authenticated writes.
alter table public.offices enable row level security;

drop policy if exists "Public read access" on public.offices;
create policy "Public read access"
  on public.offices for select using (true);

drop policy if exists "Authenticated insert access" on public.offices;
create policy "Authenticated insert access"
  on public.offices for insert
  with check (auth.role() = 'authenticated');

drop policy if exists "Authenticated update access" on public.offices;
create policy "Authenticated update access"
  on public.offices for update
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

drop policy if exists "Authenticated delete access" on public.offices;
create policy "Authenticated delete access"
  on public.offices for delete
  using (auth.role() = 'authenticated');