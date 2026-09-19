-- CSU-A Kiosk: migrate lib/data/campus_data.dart content into Supabase.
-- Run this once in the Supabase SQL Editor (Project -> SQL Editor -> New query).
-- Safe to re-run: tables are created IF NOT EXISTS and seed rows are cleared before insert.

-- ============================================================
-- Schema
-- ============================================================

create table if not exists campus_info (
  id bigint generated always as identity primary key,
  campus_name text not null,
  address text,
  phone text,
  email text,
  website text,
  executive_officer text,
  total_colleges integer,
  total_programs integer,
  total_faculty integer
);

create table if not exists colleges (
  id bigint generated always as identity primary key,
  name text not null,
  abbrev text,
  dean text,
  programs text,
  location text,
  description text
);

create table if not exists offices (
  id bigint generated always as identity primary key,
  name text not null,
  abbreviation text,
  location text,
  head text,
  purpose text,
  contact text,
  image_url text
);

alter table offices add column if not exists image_url text;

create table if not exists services (
  id bigint generated always as identity primary key,
  name text not null,
  description text
);

create table if not exists faqs (
  id bigint generated always as identity primary key,
  question text not null,
  answer text
);

create table if not exists leadership (
  id bigint generated always as identity primary key,
  name text not null,
  position text,
  department text,
  image_path text,
  initials text
);

create table if not exists college_faculty (
  id bigint generated always as identity primary key,
  college text not null,
  faculty text
);

-- The existing `buildings` table (used for wayfinding) only had
-- name/description/image_url. Add the general-info fields campus_data.dart
-- used to carry.
alter table buildings add column if not exists location text;
alter table buildings add column if not exists offices text;
alter table buildings add column if not exists dean text;

-- Needed so the seed insert below can upsert by name instead of duplicating
-- rows on re-run (buildings has no natural unique key otherwise).
create unique index if not exists buildings_name_key on buildings (name);

-- ============================================================
-- RLS: make these readable by the app's anon key, same as the
-- existing buildings/rooms/faculty/etc. tables.
-- ============================================================

alter table campus_info enable row level security;
alter table colleges enable row level security;
alter table offices enable row level security;
alter table services enable row level security;
alter table faqs enable row level security;
alter table leadership enable row level security;
alter table college_faculty enable row level security;

drop policy if exists "Public read access" on campus_info;
create policy "Public read access" on campus_info for select using (true);

drop policy if exists "Public read access" on colleges;
create policy "Public read access" on colleges for select using (true);

drop policy if exists "Public read access" on offices;
create policy "Public read access" on offices for select using (true);

drop policy if exists "Public read access" on services;
create policy "Public read access" on services for select using (true);

drop policy if exists "Public read access" on faqs;
create policy "Public read access" on faqs for select using (true);

drop policy if exists "Public read access" on leadership;
create policy "Public read access" on leadership for select using (true);

drop policy if exists "Public read access" on college_faculty;
create policy "Public read access" on college_faculty for select using (true);

-- ============================================================
-- Seed data (clears existing rows in these tables first)
-- ============================================================

truncate table campus_info restart identity;
truncate table colleges restart identity;
truncate table offices restart identity;
truncate table services restart identity;
truncate table faqs restart identity;
truncate table leadership restart identity;
truncate table college_faculty restart identity;

insert into campus_info
  (campus_name, address, phone, email, website, executive_officer, total_colleges, total_programs, total_faculty)
values (
  $$Cagayan State University - Aparri Campus$$,
  $$Barangay Maura, Aparri, Cagayan 3515$$,
  $$(+63 78) 888-2751 / 822-8399$$,
  $$ceocsuaparri@csu.edu.ph$$,
  $$https://aparri.csu.edu.ph$$,
  $$Dr. Policarpio L. Mabborang$$,
  8, 18, 136
);

insert into colleges (name, abbrev, dean, programs, location, description) values
($$College of Information and Computing Sciences$$, $$CICS$$, $$Julieta B. Babas, DIT$$,
 $$Bachelor of Science in Computer Science, Bachelor of Science in Information Technology$$,
 $$Eastern side of campus$$,
 $$Offers programs in computer science and information technology, Equipped with science laboratories and computer facilities.$$),
($$College of Hospitality Management$$, $$CHM$$, $$Rexcel Blanes Braceros, Ph.D.$$,
 $$Bachelor of Science in Hospitality Management$$,
 $$Central area of campus$$,
 $$Trains students in hotel and restaurant management, tourism, and hospitality services.$$),
($$College of Fisheries and Aquatic Sciences$$, $$CFAS$$, $$Quirino G. Pascua, Ph.D.$$,
 $$Bachelor of Science in Fisheries, Bachelor of Science in Aquaculture$$,
 $$Near the coastal area of campus$$,
 $$Focuses on fisheries management, aquaculture technology, and marine resource conservation. One of the flagship programs of CSU Aparri given its coastal location.$$),
($$College of Industrial Technology$$, $$CIT$$, $$Margarito B. Ballad, Ph.D.$$,
 $$Bachelor of Industrial Technology with specializations in Automotive, Electrical, Electronics, Mechanical, and Civil Technology$$,
 $$Western side of campus$$,
 $$Provides technical and vocational education with hands-on training in various industrial technology fields.$$),
($$College of Criminal Justice Education$$, $$CCJE$$, $$Daryl Don P. Taguba, Ph.D.$$,
 $$Bachelor of Science in Criminology$$,
 $$Northern section of campus$$,
 $$Prepares students for careers in law enforcement, criminal investigation, and the justice system.$$),
($$College of Business Entrepreneurship and Accountancy$$, $$CBEA$$, $$Senador V. Dela Cruz, MBA$$,
 $$Bachelor of Science in Accountancy, Bachelor of Science in Business Administration, Bachelor of Science in Entrepreneurship$$,
 $$Central area of campus$$,
 $$Develops future business leaders, accountants, and entrepreneurs with strong academic foundations.$$),
($$College of Teacher Education$$, $$CTE$$, $$Rolly S. Acidera, Ph.D.$$,
 $$Bachelor of Elementary Education, Bachelor of Secondary Education major in English, Mathematics, Science, and Social Studies$$,
 $$Northern section of campus$$,
 $$Trains future educators and teachers with comprehensive pedagogical skills and teaching methodologies.$$),
($$Graduate School$$, $$GS$$, $$Mark John M. Tamanu, Ph.D.$$,
 $$Master's and Doctoral programs in Education, Public Administration, Business Administration, and Information Technology$$,
 $$Administration Building, upper floor$$,
 $$Offers advanced academic programs for professionals seeking master's and doctoral degrees.$$);

insert into offices (name, abbreviation, location, head, purpose, contact) values
($$Office of the Campus Executive Officer$$, $$CEO$$, $$Administration Building$$, $$Dr. Policarpio L. Mabborang$$, null, $$(+63 78) 888-2751$$),
($$Office of the Registrar$$, $$Registrar$$, $$Administration Building$$, null, $$Handles enrollment, records, credentials, and academic documents.$$, null),
($$Finance Office$$, $$Finance$$, $$Administration Building$$, null, $$Manages budget, disbursements, and financial transactions.$$, null),
($$Human Resource and Development Office$$, $$HRDO$$, $$Administration Building$$, null, $$Manages personnel records, hiring, and employee welfare.$$, null),
($$Planning and Management Office$$, $$PMO$$, $$Administration Building$$, null, $$Handles campus development plans and institutional planning.$$, null),
($$Guidance and Counseling Office$$, $$GCO$$, $$Administration Building$$, null, $$Provides academic, personal, and career guidance to students.$$, null),
($$Student Affairs and Services$$, $$SAS$$, $$Administration Building$$, null, $$Oversees student organizations, activities, and welfare services.$$, null),
($$Extension Services Office$$, $$ESO$$, $$Administration Building$$, null, $$Coordinates community extension and outreach programs.$$, null),
($$Research and Development Office$$, $$RDO$$, $$Administration Building$$, null, $$Supports faculty and student research initiatives.$$, null),
($$Quality Assurance Office$$, $$QA$$, $$Administration Building$$, null, $$Ensures institutional compliance with CHED and accreditation standards.$$, null),
($$Library$$, $$Library$$, $$Library Building$$, null, $$Provides access to books, journals, references, and digital resources.$$, null);

insert into services (name, description) values
($$Enrollment$$, $$Visit the Registrar's Office in the Administration Building for enrollment inquiries. Online enrollment may be available through the CSU Aparri portal.$$),
($$ID Processing$$, $$Student and faculty IDs are processed at the Student Affairs and Services office.$$),
($$Grades$$, $$Check grades through the CSU Aparri student portal or visit the Registrar's Office.$$),
($$Transcript of Records$$, $$Request from the Registrar's Office. Processing may take several working days.$$),
($$Library Services$$, $$Borrow books, access reference materials, and use computer facilities at the Library Building.$$),
($$Medical Services$$, $$Basic health services and first aid available at the University Clinic.$$),
($$Counseling$$, $$Free academic, personal, and career counseling at the Guidance and Counseling Office.$$),
($$Scholarships$$, $$Inquire at the Finance Office or Student Affairs for available scholarships and financial assistance programs.$$),
($$TESDA / NCIII$$, $$National Certificate assessments are conducted at the NCIII Assessment Center.$$);

insert into faqs (question, answer) values
($$What courses are offered?$$,
 $$CSU Aparri offers 18 programs across 8 colleges: CICS (Computer Science, IT), Hospitality Management, Fisheries, Industrial Technology, Criminology, Business/Accountancy, Teacher Education, and Graduate School.$$),
($$How do I enroll?$$,
 $$Visit the Registrar's Office in the Administration Building for enrollment procedures. You can also check the CSU Aparri portal for online enrollment schedules.$$),
($$Where is the campus located?$$,
 $$CSU Aparri is located in Barangay Maura, Aparri, Cagayan 3515, Philippines.$$),
($$How do I contact the campus?$$,
 $$Phone: (+63 78) 888-2751 or 822-8399. Email: ceocsuaparri@csu.edu.ph. Website: https://aparri.csu.edu.ph$$),
($$Who is the campus head?$$,
 $$The Campus Executive Officer is Dr. Policarpio L. Mabborang.$$),
($$Where can I get my grades?$$,
 $$Check your grades through the CSU Aparri student portal or visit the Registrar's Office in the Administration Building.$$),
($$Is there a library?$$,
 $$Yes, the main campus library is in the Library Building in the central area of campus. It offers books, journals, references, and computer access.$$),
($$Where can I get food?$$,
 $$The campus canteen/food court is in the central area, offering affordable meals and snacks.$$);

insert into leadership (name, position, department, image_path, initials) values
($$Dr. Policarpio L. Mabborang$$, $$Campus Executive Officer$$, $$Campus Administration$$, $$assets/ceo.png$$, $$PM$$),
($$Julieta B. Babas, DIT$$, $$Dean$$, $$College of Information and Computing Sciences$$, $$assets/Cics_Dean.jpg$$, $$JB$$),
($$Rexcel Blanes Braceros, Ph.D.$$, $$Dean$$, $$College of Hospitality Management$$, $$assets/faculty/dean_chm.png$$, $$RB$$),
($$Quirino G. Pascua, Ph.D.$$, $$Dean$$, $$College of Fisheries and Aquatic Sciences$$, $$assets/faculty/dean_cfas.png$$, $$QP$$),
($$Margarito B. Ballad, Ph.D.$$, $$Dean$$, $$College of Industrial Technology$$, $$assets/faculty/dean_cit.png$$, $$MB$$),
($$Daryl Don P. Taguba, Ph.D.$$, $$Dean$$, $$College of Criminal Justice Education$$, $$assets/faculty/dean_ccje.png$$, $$DT$$),
($$Senador V. Dela Cruz, MBA$$, $$Dean$$, $$College of Business Entrepreneurship and Accountancy$$, $$assets/faculty/dean_cbea.png$$, $$SD$$),
($$Rolly S. Acidera, Ph.D.$$, $$Dean$$, $$College of Teacher Education$$, $$assets/faculty/dean_cte.png$$, $$RA$$),
($$Mark John M. Tamanu, Ph.D.$$, $$Dean$$, $$Graduate School$$, $$assets/faculty/dean_gs.png$$, $$MT$$);

insert into college_faculty (college, faculty) values
($$CICS$$, $$Prof. Marlon T. Bautista, Prof. Christian Dave L. Aquino, Prof. Rhealyn G. Balucan$$),
($$CHM$$, $$Prof. Annie Grace T. Rodriguez, Prof. Jerome P. Sison$$),
($$CFAS$$, $$Prof. Erlinda P. Balbin, Prof. Reynaldo T. Maguira$$),
($$CIT$$, $$Prof. Ronaldo G. Dizon, Prof. Edgar T. Villanueva, Prof. Ramon C. Bernaldez$$),
($$CCJE$$, $$Prof. Ariel Q. Camayra, Prof. Shaira E. Pascual$$),
($$CBEA$$, $$Prof. Lorna P. Dela Cruz, Prof. Mark Anthony G. Soriano$$),
($$CTE$$, $$Prof. Rosalie A. Calucag, Prof. Danilo R. Pascua, Prof. Marilou G. Dizon$$),
($$GS$$, $$Prof. Teresita L. Balucan, Prof. Renato G. Quebral$$);

-- Seed the wayfinding `buildings` table with the same 13 buildings
-- campus_data.dart had, now including location/offices/dean.
insert into buildings (name, description, location, offices, dean) values
($$Administration Building$$,
 $$Houses the Office of the Campus Executive Officer, registrar, and administrative offices. This is the main building of the campus.$$,
 $$Northern section$$,
 $$Campus Executive Officer, Registrar, Finance, HRDO, Planning Office$$,
 $$Dr. Policarpio L. Mabborang$$),
($$CICS Building$$,
 $$Home of the College of Information and Computing Sciences. Contains computer laboratories, lecture rooms, and the CICS Science Laboratory.$$,
 $$Eastern side$$,
 $$Dean's Office, Computer Labs, Science Laboratory$$,
 $$Julieta B. Babas, DIT$$),
($$Library Building$$,
 $$The main campus library with reading areas, reference sections, computer access, and study rooms.$$,
 $$Central area$$,
 $$Main Library, Reading Room, Reference Section$$,
 $$null$$),
($$Canteen / Food Court$$,
 $$The main campus canteen serving affordable meals and snacks for students, faculty, and staff.$$,
 $$Central area$$,
 $$Food stalls, Seating area$$,
 $$null$$),
($$Gymnasium / Sports Complex$$,
 $$Indoor sports facility used for basketball, volleyball, university events, programs, and assemblies.$$,
 $$Southern section$$,
 $$Basketball court, Volleyball court, Stage area$$,
 $$null$$),
($$CHM Building$$,
 $$Houses the College of Hospitality Management with training kitchens, mock hotel rooms, and food service laboratories.$$,
 $$Central area$$,
 $$Dean's Office, Training Kitchen, Mock Hotel$$,
 $$Rexcel Blanes Braceros, Ph.D.$$),
($$CIT Building$$,
 $$Home of the College of Industrial Technology with workshops and laboratories for automotive, electrical, and electronics.$$,
 $$Western side$$,
 $$Dean's Office, Automotive Workshop, Electrical Lab, Electronics Lab$$,
 $$Margarito B. Ballad, Ph.D.$$),
($$CFAS Building$$,
 $$Houses the College of Fisheries and Aquatic Sciences with fisheries laboratories and research facilities.$$,
 $$Near coastal area$$,
 $$Dean's Office, Fisheries Lab, Aquaculture Lab$$,
 $$Quirino G. Pascua, Ph.D.$$),
($$NCIII Assessment Center$$,
 $$National Certificate III assessment center for technical-vocational competencies under TESDA.$$,
 $$Central area$$,
 $$Assessment rooms, Testing center$$,
 $$null$$),
($$Bookstore$$,
 $$Campus bookstore selling school supplies, books, uniforms, and other academic materials.$$,
 $$Near NCIII Assessment Center$$,
 $$Sales counter, Supply storage$$,
 $$null$$),
($$Guidance and Counseling Office$$,
 $$Provides academic, personal, and career counseling services to all students.$$,
 $$Administration Building$$,
 $$Counseling rooms, Testing area$$,
 $$null$$),
($$University Clinic$$,
 $$Provides basic health services and first aid to students, faculty, and staff.$$,
 $$Near Administration Building$$,
 $$Consultation room, First aid$$,
 $$null$$),
($$United Pentecostal Church$$,
 $$A church located on the western side of campus serving the spiritual needs of the community.$$,
 $$Western side$$,
 $$Worship area$$,
 $$null$$)
on conflict (name) do update set
  description = excluded.description,
  location = excluded.location,
  offices = excluded.offices,
  dean = excluded.dean;
