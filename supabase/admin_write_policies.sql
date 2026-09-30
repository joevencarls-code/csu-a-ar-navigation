-- Allow logged-in admins (Supabase Auth "authenticated" role) to create,
-- edit, and delete buildings/rooms/qr_codes/faculty/leadership/offices/
-- colleges/services/faqs from the in-app admin CRUD screens, while keeping
-- read access public for the kiosk itself.
-- Run once in the Supabase SQL Editor (safe to re-run).

do $$
declare
  tables text[] := array['buildings', 'rooms', 'qr_codes', 'faculty', 'leadership', 'offices', 'colleges', 'services', 'faqs'];
  t text;
begin
  foreach t in array tables loop
    execute format('alter table %I enable row level security', t);

    execute format('drop policy if exists "Public read access" on %I', t);
    execute format(
      'create policy "Public read access" on %I for select using (true)', t
    );

    execute format('drop policy if exists "Authenticated insert access" on %I', t);
    execute format(
      'create policy "Authenticated insert access" on %I for insert with check (auth.role() = ''authenticated'')',
      t
    );

    execute format('drop policy if exists "Authenticated update access" on %I', t);
    execute format(
      'create policy "Authenticated update access" on %I for update using (auth.role() = ''authenticated'') with check (auth.role() = ''authenticated'')',
      t
    );

    execute format('drop policy if exists "Authenticated delete access" on %I', t);
    execute format(
      'create policy "Authenticated delete access" on %I for delete using (auth.role() = ''authenticated'')',
      t
    );
  end loop;
end $$;
