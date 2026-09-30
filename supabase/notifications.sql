-- ============================================================
--  CSU-A Kiosk: Admin notifications
--  Run this in the Supabase SQL editor (after rbac_approval.sql).
--
--  When the IMS Super Admin approves or rejects a pending change,
--  the app inserts a row here for the admin who submitted it.
--  HRO and Infra admins see an unread badge in the admin header.
-- ============================================================
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_email text not null,
  type text not null
    check (type in ('approved', 'rejected')),
  title text not null,
  message text not null,
  module text not null,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

-- Anyone can create a notification from the admin clients; the app
-- always keys it to the intended recipient's email.
create policy "notifications_insert_authenticated"
  on public.notifications for insert to authenticated with check (true);

-- A user can only read and mark-read their own notifications.
create policy "notifications_select_own"
  on public.notifications for select to authenticated
  using (user_email = coalesce(auth.jwt()->>'email', ''));

create policy "notifications_update_own"
  on public.notifications for update to authenticated
  using (user_email = coalesce(auth.jwt()->>'email', ''));

-- A user can delete their own notifications (per-item or clear all).
create policy "notifications_delete_own"
  on public.notifications for delete to authenticated
  using (user_email = coalesce(auth.jwt()->>'email', ''));

create index if not exists notifications_user_email_idx
  on public.notifications (user_email, read);