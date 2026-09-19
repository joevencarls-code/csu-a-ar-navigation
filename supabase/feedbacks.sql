-- ============================================================
--  CSU-A Kiosk: AR navigation feedback (stars + optional message)
--  Run this once in the Supabase SQL editor.
--
--  The AR navigation web app (ar_navigation.html) POSTs a row here
--  whenever a visitor finishes a trip and rates how helpful the
--  AR navigation was. The IMS Super Admin can read all rows from
--  the Supabase Table Editor / dashboard.
-- ============================================================
create table if not exists public.feedbacks (
  id            uuid primary key default gen_random_uuid(),
  building_key  text not null,
  building_name text not null,
  rating        smallint not null check (rating between 1 and 5),
  message       text,
  gps_lat       double precision,
  gps_lng       double precision,
  gps_acc       real,
  device        text,
  created_at    timestamptz not null default now()
);

alter table public.feedbacks enable row level security;

-- Anyone (anonymous AR visitors) can submit feedback.
create policy "feedbacks_public_insert"
  on public.feedbacks for insert
  with check (true);

-- Authenticated admins can read all feedback.
create policy "feedbacks_admin_select"
  on public.feedbacks for select
  to authenticated using (true);

create index if not exists idx_feedbacks_building on public.feedbacks (building_key);
create index if not exists idx_feedbacks_created   on public.feedbacks (created_at desc);