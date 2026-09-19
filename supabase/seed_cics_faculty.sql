-- Assigns the 10 CICS faculty photos (assets/faculty/*.png) to the matching
-- faculty records under the College of Information and Computing Sciences.
--
-- The image files are named after the faculty's first name:
--   araa   -> Aarah Francescha C. Cabalbag
--   billy  -> Billy S. Javier
--   ced    -> Cedric Sales
--   cora   -> Corazon T. Talamayan
--   io     -> Iolani A. Silvestre
--   james  -> James Karl A. Agpalza
--   jesty  -> Jesty S. Agoto
--   leo    -> Leo P. Paliuanan
--   marie  -> Marie Khadija Xynefida P. Ontiveros
--   stella -> Estela L. Dirain
--
-- Safe to re-run: existing rows are matched case-insensitively by fullname and
-- only their image_url, position, and college are updated. If a row does not
-- exist yet it is inserted so the photo still appears on the kiosk.
--
-- Run this in the Supabase SQL Editor after seed_campus_data.sql /
-- faculty_college_link.sql have run once.

-- Make sure the columns the faculty table needs are present.
alter table public.faculty
  add column if not exists image_url text;
alter table public.faculty
  add column if not exists college_id integer
  references public.colleges (id) on delete set null;

do $$
declare
  v_college_id int;
  rec record;
begin
  select c.id into v_college_id
  from public.colleges c
  where c.name ilike '%Information and Computing%'
     or c.abbrev ilike '%CICS%'
  limit 1;

  if v_college_id is null then
    raise notice 'CICS college not found; run seed_campus_data.sql first.';
    return;
  end if;

  for rec in select * from (values
    ('Aarah Francescha C. Cabalbag', 'Part-Time Faculty',    'assets/faculty/araa.png'),
    ('Billy S. Javier',             'Professor III',         'assets/faculty/billy.png'),
    ('Cedric Sales',                null,                    'assets/faculty/ced.png'),
    ('Corazon T. Talamayan',        'Associate Professor IV','assets/faculty/cora.png'),
    ('Iolani A. Silvestre',         'Part-Time Faculty',     'assets/faculty/io.png'),
    ('James Karl A. Agpalza',       'Instructor III',        'assets/faculty/james.png'),
    ('Jesty S. Agoto',              'Assistant Professor I', 'assets/faculty/jesty.png'),
    ('Leo P. Paliuanan',            'Assistant Professor I', 'assets/faculty/leo.png'),
    ('Marie Khadija Xynefida P. Ontiveros', 'Assistant Professor I', 'assets/faculty/marie.png'),
    ('Estela L. Dirain',            'Associate Professor III','assets/faculty/stella.png')
  ) as t(fullname, position, image_url) loop

    update public.faculty f
    set image_url = rec.image_url,
        position = coalesce(rec.position, f.position),
        college_id = v_college_id
    where lower(f.fullname) = lower(rec.fullname);

    if not found then
      insert into public.faculty (fullname, position, image_url, college_id)
      values (rec.fullname, rec.position, rec.image_url, v_college_id);
    end if;
  end loop;
end $$;