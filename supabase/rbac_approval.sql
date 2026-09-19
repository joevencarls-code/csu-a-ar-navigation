-- ============================================================
--  CSU-A Kiosk: RBAC + Approval Queue setup
--  Run this in the Supabase SQL editor, then:
--    1. Replace the three emails below with the real admin accounts
--       (or insert them later via the kiosk's admin panel / SQL).
--    2. Create Supabase Auth users for the HRO and Infra emails with
--       the passwords you want them to use at login.
-- ============================================================

-- ---- 1. Admin roles --------------------------------------------------
create table if not exists public.admin_roles (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  role text not null
    check (role in ('ims_super_admin', 'hro_admin', 'infra_admin')),
  full_name text,
  created_at timestamptz not null default now()
);

alter table public.admin_roles enable row level security;

-- Only the kiosk admin clients touch this table; any authenticated
-- admin can read its own role assignment.
create policy "admin_roles_select_authenticated"
  on public.admin_roles for select to authenticated using (true);

create policy "admin_roles_insert_authenticated"
  on public.admin_roles for insert to authenticated with check (true);

create policy "admin_roles_update_authenticated"
  on public.admin_roles for update to authenticated using (true);

-- ---- 2. Pending change queue -----------------------------------------
create table if not exists public.pending_changes (
  id uuid primary key default gen_random_uuid(),
  submitted_by text not null,
  role text not null,
  module text not null,
  table_name text not null,
  operation text not null
    check (operation in ('create', 'update', 'delete')),
  record_id integer,
  data jsonb,
  before_data jsonb,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  submitted_at timestamptz not null default now(),
  reviewed_by text,
  reviewed_at timestamptz
);

alter table public.pending_changes enable row level security;

create policy "pending_changes_select_authenticated"
  on public.pending_changes for select to authenticated using (true);

create policy "pending_changes_insert_authenticated"
  on public.pending_changes for insert to authenticated with check (true);

create policy "pending_changes_update_authenticated"
  on public.pending_changes for update to authenticated using (true);

-- ---- 3. Seed the three admin roles (REPLACE THE EMAILS) --------------
-- Run the IMS Super Admin email for the existing account. Create the
-- other two accounts in Authentication > Users first (or after).
insert into public.admin_roles (email, role, full_name) values
  ('ims.superadmin@kiosk.com', 'ims_super_admin', 'IMS Super Admin'),
  ('hro.admin@kiosk.com',     'hro_admin',        'HRO Admin'),
  ('infra.admin@kiosk.com',   'infra_admin',      'Infra Admin')
on conflict (email) do nothing;

-- ============================================================
--  OPTIONAL DB-LEVEL ENFORCEMENT (recommended for production)
-- ------------------------------------------------------------
--  The app enforces roles and the approval flow in client code,
--  which matches how the kiosk app already works. To also stop
--  a non-super admin from writing straight to live tables at the
--  database level, replace the generic `authenticated` write
--  policies on each managed table with a policy that only allows
--  the IMS Super Admin to write.
--
--  Example for the buildings table (repeat for rooms, qr_codes,
--  faculty, leadership, colleges, offices, and any other admin
--  table you manage):
--
--  drop policy if exists "buildings_insert_authenticated" on public.buildings;
--  drop policy if exists "buildings_update_authenticated" on public.buildings;
--  drop policy if exists "buildings_delete_authenticated" on public.buildings;
--
--  create policy "buildings_super_admin_write"
--    on public.buildings for insert to authenticated
--    with check (exists (
--      select 1 from public.admin_roles
--      where email = coalesce(auth.jwt()->>'email', '')
--        and role = 'ims_super_admin'
--    ));
--
--  create policy "buildings_super_admin_update"
--    on public.buildings for update to authenticated
--    using (exists (
--      select 1 from public.admin_roles
--      where email = coalesce(auth.jwt()->>'email', '')
--        and role = 'ims_super_admin'
--    ));
--
--  create policy "buildings_super_admin_delete"
--    on public.buildings for delete to authenticated
--    using (exists (
--      select 1 from public.admin_roles
--      where email = coalesce(auth.jwt()->>'email', '')
--        and role = 'ims_super_admin'
--    ));
-- ============================================================