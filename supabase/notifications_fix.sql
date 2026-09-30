-- ============================================================
--  CSU-A Kiosk: Admin notifications (safe, re-runnable)
--  Run once in the Supabase SQL editor (run AFTER rbac_approval.sql).
--
--  HRO and Infra admins receive a notification every time the IMS
--  Super Admin approves or rejects one of their submitted changes.
--  The notification bell in the admin header shows an unread badge.
--
--  If you previously ran notifications.sql you can still re-run this;
--  everything is IF NOT EXISTS / drop-if-exists + recreate so it is
--  safe to execute repeatedly.
-- ============================================================

-- ---- 1. notifications table ------------------------------------
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

-- Any authenticated admin client can create a notification; the app
-- always keys it to the intended recipient's email.
drop policy if exists "notifications_insert_authenticated"
  on public.notifications;
create policy "notifications_insert_authenticated"
  on public.notifications for insert to authenticated with check (true);

-- A user can only read their own notifications.
drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
  on public.notifications for select to authenticated
  using (user_email = coalesce(auth.jwt()->>'email', ''));

-- A user can only mark their own notifications as read.
drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
  on public.notifications for update to authenticated
  using (user_email = coalesce(auth.jwt()->>'email', ''));

-- Delete policy so a user can clear their own history (the app does
-- not currently call DELETE, but keep the policy complete).
drop policy if exists "notifications_delete_own" on public.notifications;
create policy "notifications_delete_own"
  on public.notifications for delete to authenticated
  using (user_email = coalesce(auth.jwt()->>'email', ''));

create index if not exists notifications_user_email_idx
  on public.notifications (user_email, read);