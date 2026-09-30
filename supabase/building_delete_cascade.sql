-- ================================================================
-- Cascade deletes for buildings -> rooms
-- ================================================================
-- Run once in the Supabase SQL editor (Dashboard > SQL Editor > New query).
--
-- Why: rooms.building_id was created without an ON DELETE action, so
-- removing a building that still had rooms was rejected with
--     update or delete on table "buildings" violates foreign key
--     constraint "rooms_building_id_fkey" on table rooms
--
-- This rewrites every foreign key in the public schema that points at
-- `buildings` or `rooms`, so one delete flows down the whole chain:
--   buildings -> rooms  : cascade   (the rooms belong to the building)
--   rooms -> faculty    : set null  (faculty records are kept, link cleared)
--   rooms -> qr_codes   : cascade   (a QR code only describes its room)
--
-- The app does the same cleanup in Dart (CampusRepository.deleteBuilding /
-- deleteRoom), so this script mainly keeps the database consistent for
-- anything that talks to Postgres directly. Safe to run more than once.

do $$
declare
  fk     record;
  cols   text;
  action text;
begin
  for fk in
    select con.conname                    as constraint_name,
           child.relname                  as child_table,
           child.oid                      as child_oid,
           con.confrelid::regclass::text  as parent_table,
           con.conkey
      from pg_constraint con
      join pg_class child on child.oid = con.conrelid
      join pg_namespace n  on n.oid = child.relnamespace
     where con.contype = 'f'
       and n.nspname = 'public'
       and con.confrelid in ('public.buildings'::regclass,
                             'public.rooms'::regclass)
  loop
    if array_length(fk.conkey, 1) <> 1 then
      raise notice 'skipped multi-column foreign key public.% (%)',
        fk.child_table, fk.constraint_name;
      continue;
    end if;

    select string_agg(a.attname, ', ' order by key_order.ord)
      into cols
      from unnest(fk.conkey) with ordinality as key_order(attnum, ord)
      join pg_attribute a
        on a.attrelid = fk.child_oid
       and a.attnum = key_order.attnum;

    action := case when fk.child_table = 'faculty'
                   then 'set null'
                   else 'cascade' end;

    execute format('alter table public.%I drop constraint %I',
                   fk.child_table, fk.constraint_name);
    execute format(
      'alter table public.%I add constraint %I foreign key (%s) references %s (id) on delete %s',
      fk.child_table, fk.constraint_name, cols, fk.parent_table, action);

    raise notice 'public.%: % -> % (id) on delete %',
      fk.child_table, fk.constraint_name, fk.parent_table, action;
  end loop;
end $$;
