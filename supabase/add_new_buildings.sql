-- ================================================================
-- NEW BUILDINGS / ROUTES ADDED TO THE KIOSK DIRECTORY
-- ================================================================
-- Run this in the Supabase SQL editor (Dashboard > SQL Editor > New query).
-- It is safe to run more than once: every insert is keyed on the building
-- name, so re-running only refreshes the description/location/offices/dean
-- text of buildings that already exist.
--
-- These six match buildings that are already on the campus map
-- (lib/data/campus_routes_data.dart):
--   CHM Building ........... College of Hospitality Management
--   Cafeteria .............. Canteen / Food Court
--   Business Center ........ CBEA Building
--   Science Laboratories ... Science Laboratories
--   Workshop Building ...... Workshop Building
--   Dormitory .............. Lecturer's Dormitory

-- `on conflict (name)` below needs a unique index on the name column.
create unique index if not exists buildings_name_key on buildings (name);

insert into buildings (name, description, location, offices, dean) values
($$CHM Building$$,
 $$Houses the College of Hospitality Management with training kitchens, mock hotel rooms, and food service laboratories.$$,
 $$Central area, near the Canteen$$,
 $$Dean's Office, Training Kitchen, Mock Hotel, Culinary Laboratory$$,
 $$Rexcel Blanes Braceros, Ph.D.$$),
($$Cafeteria$$,
 $$The main campus cafeteria serving meals, snacks, and drinks for students, faculty, staff, and visitors.$$,
 $$Central area$$,
 $$Food stalls, Seating area, Washing area$$,
 $$null$$),
($$Business Center$$,
 $$Home of the College of Business, Entrepreneurship and Accountancy. Contains business, accounting, and entrepreneurship classrooms and offices.$$,
 $$Western side$$,
 $$Dean's Office, Accounting Lab, Business Laboratory$$,
 $$Senador V. Dela Cruz, MBA$$),
($$Science Laboratories$$,
 $$Holds the science laboratories used for chemistry, biology, and other laboratory subjects.$$,
 $$East side, near the CBEA Building$$,
 $$Science Laboratory, Preparation Room, Equipment Storage$$,
 $$null$$),
($$Workshop Building$$,
 $$Workshops and laboratory bays for practical training, fabrication, and maintenance work.$$,
 $$Central area$$,
 $$Workshop Bay, Tool Storage, Machine Shop$$,
 $$null$$),
($$Dormitory$$,
 $$Housing for faculty and staff, with rooms and shared facilities for residents.$$,
 $$Southern section$$,
 $$Rooms, Common Area, Laundry Area$$,
 $$null$$)
on conflict (name) do update set
  description = excluded.description,
  location = excluded.location,
  offices = excluded.offices,
  dean = excluded.dean;

-- Optional: point these buildings at waypoints you already added on the map
-- so wayfinding routes can be built to them. Fill in the room/waypoint ids
-- for your database, then run this block once.
--
-- update buildings set location = 'Northern section' where name = 'CHM Building';
