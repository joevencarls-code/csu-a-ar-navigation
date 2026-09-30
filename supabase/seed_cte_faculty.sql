-- Assigns the 11 CTE faculty photos (assets/CTE/*.jpg) to the faculty
-- records under the College of Teacher Education.
--
-- The image files are slugs of the faculty name:
--   arlene_talosa        -> Arlene Talosa              (existing row, id 164)
--   jocelyn_dabbay       -> Jocelyn K. Dabbay           (inserted)
--   kelhveen_carino      -> Kelhveen Jezrill Cariño     (existing row, id 156)
--   ma_angelita_rabanal  -> Ma. Angelita S. Rabanal     (inserted)
--   marisa_lacambra      -> Marisa B. Lacambra          (existing row, id 159)
--   marivic_agbisit      -> Marivic A. Agbisit          (inserted)
--   mark_tamanu          -> Mark John M. Tamanu         (existing row, id 165)
--   minerva_galabay      -> Minerva M. Galabay          (existing row, id 157)
--   nargloric_utanesh    -> Nargloric C. Utanes         (existing row, id 166)
--   shailanie_rivera     -> Shailanie V. Rivera         (existing row, id 162)
--   rolly_acidera        -> Rolly A. Acidera            (inserted, Dean)
--
-- Safe to re-run: rows are matched on first name + last name so middle
-- initials and the Cariño/Carino spelling never create a duplicate. Only
-- image_url, college_id and a still-empty position are written. When no
-- row matches the photo the faculty member is inserted instead, so the
-- picture still appears on the kiosk.
--
-- Run this in the Supabase SQL Editor after seed_campus_data.sql has run
-- once. Positions come from the directory convention: everyone is a
-- "Regular Faculty" except the college dean.

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
  where c.abbrev ilike '%CTE%'
     or c.name ilike '%Teacher Education%'
  limit 1;

  if v_college_id is null then
    raise notice 'CTE college not found; run seed_campus_data.sql first.';
    return;
  end if;

  for rec in select * from (values
    ('arlene',    array['talosa'],           'Arlene D. Talosa',           'Regular Faculty', 'assets/CTE/arlene_talosa.jpg'),
    ('jocelyn',   array['dabbay'],           'Jocelyn K. Dabbay',          'Regular Faculty', 'assets/CTE/jocelyn_dabbay.jpg'),
    ('kelhveen',  array['cariño','carino'],  'Kelhveen Jezrill S. Carino', 'Regular Faculty', 'assets/CTE/kelhveen_carino.jpg'),
    ('ma',        array['rabanal'],          'Ma. Angelita S. Rabanal',    'Regular Faculty', 'assets/CTE/ma_angelita_rabanal.jpg'),
    ('marisa',    array['lacambra'],         'Marisa B. Lacambra',         'Regular Faculty', 'assets/CTE/marisa_lacambra.jpg'),
    ('marivic',   array['agbisit'],          'Marivic A. Agbisit',         'Regular Faculty', 'assets/CTE/marivic_agbisit.jpg'),
    ('mark',      array['tamanu'],           'Mark John M. Tamanu',        'Regular Faculty', 'assets/CTE/mark_tamanu.jpg'),
    ('minerva',   array['galabay'],          'Minerva M. Galabay',         'Regular Faculty', 'assets/CTE/minerva_galabay.jpg'),
    ('nargloric', array['utanes'],           'Nargloric C. Utanes',        'Regular Faculty', 'assets/CTE/nargloric_utanesh.jpg'),
    ('shailanie', array['rivera'],           'Shailanie V. Rivera',        'Regular Faculty', 'assets/CTE/shailanie_rivera.jpg'),
    ('rolly',     array['acidera'],          'Rolly A. Acidera',           'Dean',            'assets/CTE/rolly_acidera.jpg')
  ) as t(match_first, match_last, fullname, position, image_url) loop

    update public.faculty f
       set image_url  = rec.image_url,
           college_id = v_college_id,
           position   = coalesce(f.position, rec.position)
     where lower(regexp_replace(split_part(trim(f.fullname), ' ', 1),
                                '[^[:alnum:]]', '', 'g')) = rec.match_first
       and lower(regexp_replace(split_part(trim(f.fullname), ' ', -1),
                                '[^[:alnum:]]', '', 'g')) = any (rec.match_last)
       and (f.college_id is null or f.college_id = v_college_id);

    if not found then
      insert into public.faculty (fullname, position, image_url, college_id)
      values (rec.fullname, rec.position, rec.image_url, v_college_id);
    end if;
  end loop;
end $$;
