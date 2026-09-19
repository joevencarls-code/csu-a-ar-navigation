import 'dart:ui';

import '../models/campus_route.dart';

/// ================================================================
/// ALL BUILDINGS WITH AUTHORED ROUTES
/// ================================================================

final List<BuildingRouteSet> _buildingRoutes = [
  _administrationBuildingRoutes,
  _cteBuildingRoutes,
  _gymplexRoutes,
  _gatchalianBuildingRoutes,
  _cicsBuildingRoutes,
  _libraryBuildingRoutes,
  _avrBuildingRoutes,
  _canteenRoutes,
  _citBuildingRoutes,
  _cbeaBuildingRoutes,
  _infrastructureOfficeRoutes,
  _dnstBuildingRoutes,
  _oldAdminRoutes,
  _hatcheryRoutes,
  _icrmBuildingRoutes,
  _ceoCottageRoutes,
  _executiveVilla1Routes,
  _lecturersDormitoryRoutes,
];

List<BuildingRouteSet> get allBuildingRoutes => _buildingRoutes;

/// ================================================================
/// SEARCH ALIASES
/// ================================================================

final Map<BuildingRouteSet, List<String>> _aliases = {
  // ---------------------------------------------------------------
  // ADMINISTRATION BUILDING
  // ---------------------------------------------------------------
  _administrationBuildingRoutes: const [
    'administration building',
    'administrative building',
    'administration',
    'administrative',
    'admin',
    'admin building',
    'registrar',
    "registrar's office",
    'registrars office',
    'office of the registrar',
    'finance office',
    'hrdo',
    'human resource and development office',
    'guidance and counseling office',
    'guidance',
    'planning and management office',
    'campus executive officer',
    'ceo office',
  ],

  // ---------------------------------------------------------------
  // COLLEGE OF TEACHER EDUCATION
  // ---------------------------------------------------------------
  _cteBuildingRoutes: const [
    'college of teacher education',
    'college of teachers education',
    'teacher education',
    'teachers education',
    'cte',
    'cte building',
    'college of education',
    'education building',
  ],

  // ---------------------------------------------------------------
  // GYMPLEX
  // ---------------------------------------------------------------
  _gymplexRoutes: const [
    'gymplex',
    'gym plex',
    'gymnasium complex',
    'gymnasium',
    'gym',
    'gym building',
    'gym complex',
    'covered court',
    'sports complex',
    'athletic complex',
    'multi purpose gym',
    'multi-purpose gym',
    'multipurpose gym',
  ],

  // ---------------------------------------------------------------
  // GATCHALIAN BUILDING
  // ---------------------------------------------------------------
  _gatchalianBuildingRoutes: const [
    'gatchalian building',
    'gatchalian hall',
    'gatchalian',
  ],

  // ---------------------------------------------------------------
  // COLLEGE OF INFORMATION AND COMPUTING SCIENCES
  // ---------------------------------------------------------------
  _cicsBuildingRoutes: const [
    'college of information and computing sciences',
    'college of information and computing science',
    'information and computing sciences',
    'computing sciences',
    'cics building',
    'cics',
    'computer studies',
    'computer science building',
    'information technology building',
  ],

  // ---------------------------------------------------------------
  // LIBRARY BUILDING
  // ---------------------------------------------------------------
  _libraryBuildingRoutes: const [
    'library building',
    'lib building',
    'libbuilding',
    'library',
    'learning resource center',
    'learning resource centre',
  ],

  // ---------------------------------------------------------------
  // AVR BUILDING
  // ---------------------------------------------------------------
  _avrBuildingRoutes: const [
    'avr building',
    'avr room',
    'avr',
    'audio visual room',
    'audio-visual room',
    'audio visual',
    'audiovisual room',
    'audiovisual',
  ],

  // ---------------------------------------------------------------
  // CANTEEN / FOOD COURT
  // ---------------------------------------------------------------
  _canteenRoutes: const [
    'canteen building',
    'food court',
    'foodcourt',
    'food hub',
    'canteen',
    'cafeteria',
    'dining hall',
    'mess hall',
  ],

  // ---------------------------------------------------------------
  // CIT BUILDING
  // ---------------------------------------------------------------
  _citBuildingRoutes: const [
    'college of industrial technology',
    'industrial technology',
    'cit building',
    'cit',
  ],

  // ---------------------------------------------------------------
  // CBEA BUILDING
  // ---------------------------------------------------------------
  _cbeaBuildingRoutes: const [
    'college of business and accountancy',
    'college of business',
    'business and accountancy',
    'business administration',
    'accountancy',
    'cbea building',
    'cbea',
  ],

  // ---------------------------------------------------------------
  // INFRASTRUCTURE OFFICE
  // ---------------------------------------------------------------
  _infrastructureOfficeRoutes: const [
    'infrastructure office',
    'infrastructure building',
    'infrastructure',
    'infra office',
    'infra',
  ],

  // ---------------------------------------------------------------
  // DNST BUILDING
  // ---------------------------------------------------------------
  _dnstBuildingRoutes: const [
    'dnst building',
    'dnst',
  ],

  // ---------------------------------------------------------------
  // OLD ADMIN BUILDING
  //
  // NOTE: every one of these aliases also contains 'admin' or
  // 'administration', which belong to the (current) Administration
  // Building above. findRoutesFor below resolves that by preferring
  // the LONGEST matching alias, so 'old admin' lands here and a
  // plain 'admin' still lands on the Administration Building.
  // ---------------------------------------------------------------
  _oldAdminRoutes: const [
    'old administration building',
    'old admin building',
    'old administration',
    'old admin',
  ],

  // ---------------------------------------------------------------
  // HATCHERY
  // ---------------------------------------------------------------
  _hatcheryRoutes: const [
    'hatchery building',
    'fish hatchery',
    'hatchery',
  ],

  // ---------------------------------------------------------------
  // ICRM BUILDING
  // ---------------------------------------------------------------
  _icrmBuildingRoutes: const [
    'institute of coastal resource management',
    'integrated coastal resource management',
    'coastal resource management',
    'icrm building',
    'icrm',
  ],

  // ---------------------------------------------------------------
  // CEO'S COTTAGE
  //
  // NOTE: 'campus executive officer' and 'ceo office' belong to the
  // Administration Building. findRoutesFor prefers the LONGEST
  // matching alias, so 'campus executive officer cottage' lands
  // here while 'ceo office' still lands on Administration. A bare
  // 'ceo' goes to the office, which is the safer default.
  // ---------------------------------------------------------------
  _ceoCottageRoutes: const [
    'campus executive officer cottage',
    "ceo's cottage",
    'ceos cottage',
    'ceo cottage',
    'cottage',
  ],

  // ---------------------------------------------------------------
  // EXECUTIVE VILLA 1
  //
  // Numbered deliberately. If more villas are added later, give
  // each its own numbered aliases — do NOT add a bare
  // 'executive villa' here or it will swallow queries meant for
  // the others.
  // ---------------------------------------------------------------
  _executiveVilla1Routes: const [
    'executive villa 1',
    'executive villa one',
    'exec villa 1',
    'villa 1',
    'villa one',
  ],

  // ---------------------------------------------------------------
  // LECTURER'S DORMITORY
  //
  // 'dormitory' and 'dorm' are deliberately generic here because
  // this is currently the only one on the map. If a students'
  // dormitory is added later, DROP those two bare aliases from
  // this list — otherwise they will catch queries meant for it.
  // ---------------------------------------------------------------
  _lecturersDormitoryRoutes: const [
    "lecturer's dormitory",
    "lecture's dormitory",
    'lecturers dormitory',
    'lecturer dormitory',
    'faculty dormitory',
    'lecturers dorm',
    'lecturer dorm',
    'faculty dorm',
    'dormitory',
    'dorm',
  ],
};

/// ================================================================
/// ADMINISTRATION BUILDING
/// ================================================================

const BuildingRouteSet _administrationBuildingRoutes =
    BuildingRouteSet(
  buildingName: 'Administration Building',

  markerPoint: Offset(
    0.671,
    0.414,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // START HERE
        Offset(0.935, 0.379),

        // Main road
        Offset(0.900, 0.374),
        Offset(0.850, 0.363),
        Offset(0.800, 0.350),
        Offset(0.750, 0.340),
        Offset(0.700, 0.328),
        Offset(0.670, 0.319),
        Offset(0.640, 0.304),

        // Turn toward Administration
        Offset(0.634, 0.330),
        Offset(0.630, 0.363),
        Offset(0.650, 0.372),
        Offset(0.662, 0.377),
        Offset(0.660, 0.400),

        // Destination
        Offset(0.671, 0.414),
      ],

      distanceLabel: '~280 m',
      timeLabel: '~4 min walk',
    ),
  },
);

/// ================================================================
/// COLLEGE OF TEACHER EDUCATION — CTE
/// ================================================================
///
/// THIS ROUTE MATCHES THE BLUE LINE IN THE PROVIDED SCREENSHOT.
///
/// Start:
///   approximately x = 1358, y = 314
///
/// Destination / route endpoint:
///   approximately x = 546, y = 190
///
/// Screenshot size:
///   1458 x 822
///
/// Normalized:
///
/// Start:
///   x = 1358 / 1458 = 0.931
///   y = 314  / 822 = 0.382
///
/// Destination:
///   x = 546 / 1458 = 0.375
///   y = 190 / 822 = 0.231
///
/// The blue route is intentionally a long diagonal line,
/// matching the supplied reference image.
/// ================================================================

const BuildingRouteSet _cteBuildingRoutes =
    BuildingRouteSet(
  buildingName: 'College of Teacher Education',

  /// Yellow marker above the route endpoint.
  markerPoint: Offset(
    0.377,
    0.184,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE
        // ==========================================================
        Offset(0.931, 0.382),

        // ==========================================================
        // BLUE ROUTE — MATCH SCREENSHOT
        // ==========================================================

        Offset(0.878, 0.367),
        Offset(0.823, 0.353),
        Offset(0.768, 0.338),
        Offset(0.713, 0.324),
        Offset(0.658, 0.309),
        Offset(0.604, 0.294),
        Offset(0.549, 0.280),
        Offset(0.494, 0.265),
        Offset(0.439, 0.248),
        Offset(0.391, 0.237),

        // ==========================================================
        // CTE ROUTE ENDPOINT
        // ==========================================================
        Offset(0.375, 0.231),
      ],

      distanceLabel: '~430 m',
      timeLabel: '~5 min walk',
    ),
  },
);

/// ================================================================
/// GYMPLEX
/// ================================================================
///
/// THIS ROUTE IS TRACED PIXEL-BY-PIXEL FROM THE BLUE LINE IN THE
/// PROVIDED SCREENSHOT — it is not an approximation.
///
/// Screenshot file : 1465 x 826
/// Map content box : x 7..1458  (w = 1452)
///                   y 6..822   (h = 817)
///                   (the screenshot has a ~6 px UI frame around
///                    the map; normalization uses the inner box)
///
/// Traced pixels -> normalized:
///
///   Start dot        (1361, 315)  ->  (0.9325, 0.3782)
///   Road bend        (1045, 267)  ->  (0.7149, 0.3195)
///   Top of the leg   (1058, 192)  ->  (0.7238, 0.2276)
///   Endpoint dot     (1035, 170)  ->  (0.7083, 0.2007)
///   Yellow marker    (1050, 122)  ->  (0.7181, 0.1420)
///
/// Shape: one long straight run west along the main road (it
/// rises gently, it is NOT horizontal), a right turn north that
/// leans very slightly east, then a short hop west onto the
/// Gymplex frontage where the route dot sits.
/// ================================================================

const BuildingRouteSet _gymplexRoutes =
    BuildingRouteSet(
  buildingName: 'Gymplex',

  /// Yellow marker on the Gymplex roof, above the route endpoint.
  markerPoint: Offset(
    0.7181,
    0.1420,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1361, 315)
        // ==========================================================
        Offset(0.9325, 0.3782),

        // ==========================================================
        // LEG 1 — WEST ALONG THE MAIN ROAD
        // straight line, rising ~0.16 px of y per px of x
        // ==========================================================
        Offset(0.8962, 0.3684),
        Offset(0.8600, 0.3586),
        Offset(0.8237, 0.3489),
        Offset(0.7874, 0.3391),
        Offset(0.7512, 0.3293),

        // Road bend — right turn  (1045, 267)
        Offset(0.7149, 0.3195),

        // ==========================================================
        // LEG 2 — NORTH TOWARD THE GYMPLEX
        // leans a few px east on the way up
        // ==========================================================
        Offset(0.7179, 0.2889),
        Offset(0.7208, 0.2582),
        Offset(0.7238, 0.2276),

        // ==========================================================
        // LEG 3 — SHORT HOP ONTO THE GYMPLEX FRONTAGE
        // ==========================================================
        Offset(0.7161, 0.2142),

        // ==========================================================
        // GYMPLEX ROUTE ENDPOINT  (1035, 170)
        // ==========================================================
        Offset(0.7083, 0.2007),
      ],

      distanceLabel: '~217 m',
      timeLabel: '~3 min walk',
    ),
  },
);

/// ================================================================
/// GATCHALIAN BUILDING
/// ================================================================
///
/// TRACED PIXEL-BY-PIXEL FROM THE SECOND PROVIDED SCREENSHOT.
///
/// Screenshot file : 1456 x 826
/// Map content box : x 3..1454  (w = 1452)
///                   y 6..822   (h = 817)
///
/// Traced pixels -> normalized:
///
///   Start dot        (1354, 315)  ->  (0.9304, 0.3782)
///   Road bend        (1040, 266)  ->  (0.7142, 0.3182)
///   Top of the leg   (1055, 191)  ->  (0.7245, 0.2264)
///   Endpoint dot     (1099, 197)  ->  (0.7551, 0.2340)
///   Yellow marker    (1120, 177)  ->  (0.7695, 0.2093)
///
/// Shape: legs 1 and 2 are the SAME road the Gymplex route uses —
/// west along the main road, then the right turn north. Instead of
/// stopping at the Gymplex frontage it turns RIGHT (east) at the
/// top and runs along the building face to the Gatchalian entrance.
///
/// The shared corner is intentionally kept at the same coordinates
/// as the Gymplex route so the two paths overlap cleanly on screen.
/// ================================================================

const BuildingRouteSet _gatchalianBuildingRoutes =
    BuildingRouteSet(
  buildingName: 'Gatchalian Building',

  /// Yellow marker on the Gatchalian roof, up-right of the endpoint.
  markerPoint: Offset(
    0.7695,
    0.2093,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1354, 315)
        // ==========================================================
        Offset(0.9304, 0.3782),

        // ==========================================================
        // LEG 1 — WEST ALONG THE MAIN ROAD
        // ==========================================================
        Offset(0.8944, 0.3682),
        Offset(0.8583, 0.3582),
        Offset(0.8223, 0.3482),
        Offset(0.7863, 0.3382),
        Offset(0.7502, 0.3282),

        // Road bend — right turn  (1040, 266)
        Offset(0.7142, 0.3182),

        // ==========================================================
        // LEG 2 — NORTH ALONG THE SAME LEG AS THE GYMPLEX ROUTE
        // ==========================================================
        Offset(0.7176, 0.2876),
        Offset(0.7211, 0.2570),
        Offset(0.7245, 0.2264),

        // ==========================================================
        // LEG 3 — RIGHT TURN EAST ALONG THE BUILDING FACE
        // ==========================================================
        Offset(0.7398, 0.2302),

        // ==========================================================
        // GATCHALIAN ROUTE ENDPOINT  (1099, 197)
        // ==========================================================
        Offset(0.7551, 0.2340),
      ],

      distanceLabel: '~240 m',
      timeLabel: '~3 min walk',
    ),
  },
);

/// ================================================================
/// COLLEGE OF INFORMATION AND COMPUTING SCIENCES — CICS
/// ================================================================
///
/// TRACED PIXEL-BY-PIXEL FROM THE THIRD PROVIDED SCREENSHOT.
///
/// Screenshot file : 1461 x 835
/// Map content box : x 2..1453  (w = 1452)
///                   y 10..826  (h = 817)
///
/// Traced pixels -> normalized:
///
///   Start dot        (1353, 319)  ->  (0.9307, 0.3782)
///   Road bend        (1090, 283)  ->  (0.7493, 0.3342)
///   Endpoint dot     (1094, 258)  ->  (0.7522, 0.3040)
///
/// Shape: west along the main road, then a SHORT right turn north
/// onto the CICS frontage. This turn happens well before the
/// Gymplex / Gatchalian bend — CICS is the nearer building, so
/// this is the shortest of the four routes.
///
/// NOTE: this screenshot has NO yellow destination marker, so
/// markerPoint is not traced — it is placed on the CICS roof at
/// (1130, 252), up-right of the route endpoint, matching how the
/// Gatchalian marker sits relative to its dot. Move it if the
/// intended marker position is somewhere else on the building.
/// ================================================================

const BuildingRouteSet _cicsBuildingRoutes =
    BuildingRouteSet(
  buildingName: 'College of Information and Computing Sciences',

  /// Placed on the CICS roof, up-right of the route endpoint
  /// (same relationship the Gatchalian marker has to its dot).
  markerPoint: Offset(
    0.7769,
    0.2962,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1353, 319)
        // ==========================================================
        Offset(0.9307, 0.3782),

        // ==========================================================
        // LEG 1 — WEST ALONG THE MAIN ROAD
        // ==========================================================
        Offset(0.8942, 0.3694),
        Offset(0.8580, 0.3606),
        Offset(0.8218, 0.3518),
        Offset(0.7856, 0.3430),

        // Road bend — right turn  (1090, 283)
        Offset(0.7493, 0.3342),

        // ==========================================================
        // LEG 2 — SHORT HOP NORTH ONTO THE CICS FRONTAGE
        // ==========================================================
        Offset(0.7507, 0.3191),

        // ==========================================================
        // CICS ROUTE ENDPOINT  (1094, 258)
        // ==========================================================
        Offset(0.7522, 0.3040),
      ],

      distanceLabel: '~120 m',
      timeLabel: '~2 min walk',
    ),
  },
);

/// ================================================================
/// LIBRARY BUILDING
/// ================================================================
///
/// TRACED PIXEL-BY-PIXEL FROM THE FOURTH PROVIDED SCREENSHOT.
///
/// Screenshot file : 1466 x 823
/// Map content box : x 6..1457  (w = 1452)
///                   y 6..822   (h = 817)
///
/// Traced pixels -> normalized:
///
///   Start dot      (1357, 315)  ->  (0.9302, 0.3781)
///   Endpoint dot   ( 966, 262)  ->  (0.6608, 0.3139)
///
/// Shape: a SINGLE straight run west along the main road — no
/// turn at all. It continues past the CICS, Gymplex and
/// Gatchalian bends and ends at the road corner by the Library.
///
/// NOTE: this screenshot has NO yellow destination marker, so
/// markerPoint is not traced — it is placed at (958, 285), on the
/// octagonal Library roof just SOUTH of the endpoint (this is the
/// one building that sits below its route dot rather than above).
/// ================================================================

const BuildingRouteSet _libraryBuildingRoutes =
    BuildingRouteSet(
  buildingName: 'Library Building',

  /// On the octagonal Library roof, below the route endpoint.
  markerPoint: Offset(
    0.6557,
    0.3415,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1357, 315)
        // ==========================================================
        Offset(0.9302, 0.3781),

        // ==========================================================
        // ONE STRAIGHT LEG — WEST ALONG THE MAIN ROAD
        // constant slope, no bend anywhere along the path
        // ==========================================================
        Offset(0.8917, 0.3689),
        Offset(0.8532, 0.3598),
        Offset(0.8147, 0.3506),
        Offset(0.7763, 0.3414),
        Offset(0.7378, 0.3323),
        Offset(0.6993, 0.3231),

        // ==========================================================
        // LIBRARY ROUTE ENDPOINT  (966, 262)
        // ==========================================================
        Offset(0.6608, 0.3139),
      ],

      distanceLabel: '~185 m',
      timeLabel: '~2 min walk',
    ),
  },
);

/// ================================================================
/// AVR BUILDING (AUDIO VISUAL ROOM)
/// ================================================================
///
/// TRACED PIXEL-BY-PIXEL FROM THE FIFTH PROVIDED SCREENSHOT.
///
/// Screenshot file : 1464 x 831
/// Map content box : x 4..1455  (w = 1452)
///                   y 5..821   (h = 817)
///
/// Traced pixels -> normalized:
///
///   Start dot      (1356, 313)  ->  (0.9311, 0.3770)
///   Road bend      (1068, 274)  ->  (0.7328, 0.3292)
///   Endpoint dot   (1062, 292)  ->  (0.7287, 0.3519)
///
/// Shape: west along the main road, then a LEFT turn SOUTH off the
/// road onto the AVR roof. Every other building so far sits north
/// of the road, so this is the first route whose final leg goes
/// DOWN the screen instead of up.
///
/// NOTE: this screenshot has NO yellow destination marker, so
/// markerPoint is not traced — it is placed at (1058, 304), on the
/// hexagonal AVR roof. The AVR is small on the map (~50 px wide),
/// so the marker is nudged DOWN-LEFT of the endpoint rather than
/// centred, otherwise it hides the route dot completely.
/// ================================================================

const BuildingRouteSet _avrBuildingRoutes =
    BuildingRouteSet(
  buildingName: 'AVR Building',

  /// On the hexagonal AVR roof, down-left of the route endpoint so
  /// the dot stays visible.
  markerPoint: Offset(
    0.7259,
    0.3660,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1356, 313)
        // ==========================================================
        Offset(0.9311, 0.3770),

        // ==========================================================
        // LEG 1 — WEST ALONG THE MAIN ROAD
        // ==========================================================
        Offset(0.8914, 0.3674),
        Offset(0.8518, 0.3579),
        Offset(0.8121, 0.3483),
        Offset(0.7725, 0.3388),

        // Road bend — turn left, off the road  (1068, 274)
        Offset(0.7328, 0.3292),

        // ==========================================================
        // LEG 2 — SHORT HOP SOUTH ONTO THE AVR
        // ==========================================================
        Offset(0.7308, 0.3406),

        // ==========================================================
        // AVR ROUTE ENDPOINT  (1062, 292)
        // ==========================================================
        Offset(0.7287, 0.3519),
      ],

      distanceLabel: '~168 m',
      timeLabel: '~2 min walk',
    ),
  },
);

/// ================================================================
/// CANTEEN / FOOD COURT
/// ================================================================
///
/// TRACED PIXEL-BY-PIXEL FROM THE SIXTH PROVIDED SCREENSHOT.
///
/// Screenshot file : 1463 x 830
/// Map content box : x 4..1455  (w = 1452)
///                   y 6..822   (h = 817)
///
/// Traced pixels -> normalized:
///
///   Start dot      (1356, 314)  ->  (0.9311, 0.3764)
///   Road corner    ( 962, 257)  ->  (0.6594, 0.3072)
///   Jog vertex     ( 985, 178)  ->  (0.6753, 0.2105)
///   Endpoint dot   ( 957, 137)  ->  (0.6560, 0.1603)
///
/// Shape: the long run west along the main road, then a right turn
/// north that does NOT go straight up — it leans EAST to clear the
/// building corner, then cuts back WEST to the canteen door. That
/// dog-leg is in the drawn line, so it is kept here rather than
/// smoothed into one straight leg.
///
/// This is the longest route in the file.
///
/// NOTE: this screenshot has NO yellow destination marker, so
/// markerPoint is not traced — it is placed at (948, 110), squarely
/// on the canteen roof up-left of the route endpoint (a little
/// further left and it spills onto the grass).
/// ================================================================

const BuildingRouteSet _canteenRoutes =
    BuildingRouteSet(
  buildingName: 'Canteen / Food Court',

  /// On the canteen roof, up-left of the route endpoint.
  markerPoint: Offset(
    0.6501,
    0.1273,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1356, 314)
        // ==========================================================
        Offset(0.9311, 0.3764),

        // ==========================================================
        // LEG 1 — WEST ALONG THE MAIN ROAD
        // ==========================================================
        Offset(0.8858, 0.3649),
        Offset(0.8405, 0.3533),
        Offset(0.7953, 0.3418),
        Offset(0.7500, 0.3303),
        Offset(0.7047, 0.3187),

        // Road corner — turn north  (962, 257)
        Offset(0.6594, 0.3072),

        // ==========================================================
        // LEG 2 — NORTH, LEANING EAST AROUND THE BUILDING CORNER
        // ==========================================================
        Offset(0.6647, 0.2750),
        Offset(0.6700, 0.2427),

        // Jog vertex  (985, 178)
        Offset(0.6753, 0.2105),

        // ==========================================================
        // LEG 3 — CUT BACK WEST TO THE CANTEEN DOOR
        // ==========================================================
        Offset(0.6657, 0.1854),

        // ==========================================================
        // CANTEEN ROUTE ENDPOINT  (957, 137)
        // ==========================================================
        Offset(0.6560, 0.1603),
      ],

      distanceLabel: '~265 m',
      timeLabel: '~3 min walk',
    ),
  },
);

/// ================================================================
/// CIT BUILDING
/// ================================================================
///
/// TRACED PIXEL-BY-PIXEL FROM THE SEVENTH PROVIDED SCREENSHOT.
///
/// Screenshot file : 1467 x 824
/// Map content box : x 8..1459  (w = 1452)
///                   y 3..819   (h = 817)
///
/// Traced pixels -> normalized:
///
///   Start dot      (1359, 311)  ->  (0.9304, 0.3770)
///   Road corner    ( 781, 223)  ->  (0.5324, 0.2693)
///   Endpoint dot   ( 784, 199)  ->  (0.5341, 0.2399)
///
/// Shape: the longest straight run in the file — west along the
/// main road, past the Library turn-off and on across the middle
/// of the campus, then a very short hop north onto the CIT
/// frontage. Only two legs.
///
/// NOTE: this screenshot has NO yellow destination marker, so
/// markerPoint is not traced — it is placed at (790, 175), on the
/// CIT roof directly above the route endpoint.
/// ================================================================

const BuildingRouteSet _citBuildingRoutes =
    BuildingRouteSet(
  buildingName: 'CIT Building',

  /// On the CIT roof, above the route endpoint.
  markerPoint: Offset(
    0.5386,
    0.2105,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1359, 311)
        // ==========================================================
        Offset(0.9304, 0.3770),

        // ==========================================================
        // LEG 1 — LONG STRAIGHT RUN WEST ALONG THE MAIN ROAD
        // constant slope, no bend anywhere along this leg
        // ==========================================================
        Offset(0.8807, 0.3635),
        Offset(0.8309, 0.3501),
        Offset(0.7812, 0.3366),
        Offset(0.7314, 0.3232),
        Offset(0.6816, 0.3097),
        Offset(0.6319, 0.2962),
        Offset(0.5821, 0.2828),

        // Road corner — turn north  (781, 223)
        Offset(0.5324, 0.2693),

        // ==========================================================
        // LEG 2 — SHORT HOP NORTH ONTO THE CIT FRONTAGE
        // ==========================================================
        Offset(0.5333, 0.2546),

        // ==========================================================
        // CIT ROUTE ENDPOINT  (784, 199)
        // ==========================================================
        Offset(0.5341, 0.2399),
      ],

      distanceLabel: '~287 m',
      timeLabel: '~4 min walk',
    ),
  },
);

/// ================================================================
/// CBEA BUILDING
/// ================================================================
///
/// TRACED PIXEL-BY-PIXEL FROM THE EIGHTH PROVIDED SCREENSHOT.
///
/// Screenshot file : 1474 x 838
/// Map content box : x 10..1461  (w = 1452)
///                   y 5..821    (h = 817)
///
/// Traced pixels -> normalized:
///
///   Start dot      (1361, 313)  ->  (0.9304, 0.3770)
///   Road corner    ( 748, 221)  ->  (0.5083, 0.2644)
///   Endpoint dot   ( 732, 181)  ->  (0.4972, 0.2154)
///
/// Shape: the same long road run as the CIT route but carried
/// further west, then a short leg north-WEST (it leans back on
/// itself, ~0.44 px of x for every px of y) onto the east end of
/// the CBEA building.
///
/// This is now the longest route in the file, just past the CIT.
///
/// NOTE: this screenshot has NO yellow destination marker, so
/// markerPoint is not traced — it is placed at (700, 165), on the
/// main CBEA roof face up-left of the route endpoint.
/// ================================================================

const BuildingRouteSet _cbeaBuildingRoutes =
    BuildingRouteSet(
  buildingName: 'CBEA Building',

  /// On the CBEA roof, up-left of the route endpoint.
  markerPoint: Offset(
    0.4752,
    0.1958,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1361, 313)
        // ==========================================================
        Offset(0.9304, 0.3770),

        // ==========================================================
        // LEG 1 — LONG STRAIGHT RUN WEST ALONG THE MAIN ROAD
        // ==========================================================
        Offset(0.8776, 0.3629),
        Offset(0.8249, 0.3489),
        Offset(0.7721, 0.3348),
        Offset(0.7194, 0.3207),
        Offset(0.6666, 0.3066),
        Offset(0.6139, 0.2926),
        Offset(0.5611, 0.2785),

        // Road corner — turn north  (748, 221)
        Offset(0.5083, 0.2644),

        // ==========================================================
        // LEG 2 — SHORT LEG NORTH-WEST ONTO THE CBEA
        // ==========================================================
        Offset(0.5028, 0.2399),

        // ==========================================================
        // CBEA ROUTE ENDPOINT  (732, 181)
        // ==========================================================
        Offset(0.4972, 0.2154),
      ],

      distanceLabel: '~332 m',
      timeLabel: '~4 min walk',
    ),
  },
);

/// ================================================================
/// INFRASTRUCTURE OFFICE
/// ================================================================
///
/// TRACED PIXEL-BY-PIXEL FROM THE NINTH PROVIDED SCREENSHOT.
///
/// Screenshot file : 1464 x 828
/// Map content box : x 5..1456  (w = 1452)
///                   y 5..821   (h = 817)
///
/// Traced pixels -> normalized:
///
///   Start dot      (1356, 313)  ->  (0.9304, 0.3770)
///   Road corner    ( 485, 181)  ->  (0.3306, 0.2154)
///   Turn vertex    ( 502, 140)  ->  (0.3423, 0.1652)
///   Endpoint dot   ( 458, 130)  ->  (0.3116, 0.1530)
///
/// Shape: the full length of the main road — the longest straight
/// leg in the file, roughly 870 px — then north up the side road
/// (leaning slightly EAST as it climbs), then a left turn WEST
/// out onto the pavilion that sits in the middle of the pond.
///
/// This is the longest route in the file overall.
///
/// NOTE: this screenshot has NO yellow destination marker, so
/// markerPoint is not traced — it is placed at (438, 133), beside
/// the endpoint on the pavilion roof. The pavilion is only ~48 px
/// wide on the map, so the marker cannot sit fully inside it; it
/// is offset west so the route dot stays readable.
/// ================================================================

const BuildingRouteSet _infrastructureOfficeRoutes =
    BuildingRouteSet(
  buildingName: 'Infrastructure Office',

  /// On the pond pavilion, west of the route endpoint.
  markerPoint: Offset(
    0.2982,
    0.1567,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1356, 313)
        // ==========================================================
        Offset(0.9304, 0.3770),

        // ==========================================================
        // LEG 1 — THE FULL RUN WEST ALONG THE MAIN ROAD
        // ==========================================================
        Offset(0.8704, 0.3608),
        Offset(0.8105, 0.3447),
        Offset(0.7505, 0.3285),
        Offset(0.6905, 0.3124),
        Offset(0.6305, 0.2962),
        Offset(0.5705, 0.2800),
        Offset(0.5106, 0.2639),
        Offset(0.4506, 0.2477),
        Offset(0.3906, 0.2316),

        // Road corner — turn north  (485, 181)
        Offset(0.3306, 0.2154),

        // ==========================================================
        // LEG 2 — NORTH UP THE SIDE ROAD, LEANING EAST
        // ==========================================================
        Offset(0.3365, 0.1903),

        // Turn vertex  (502, 140)
        Offset(0.3423, 0.1652),

        // ==========================================================
        // LEG 3 — WEST OUT ONTO THE POND PAVILION
        // ==========================================================
        Offset(0.3270, 0.1591),

        // ==========================================================
        // INFRASTRUCTURE OFFICE ROUTE ENDPOINT  (458, 130)
        // ==========================================================
        Offset(0.3116, 0.1530),
      ],

      distanceLabel: '~522 m',
      timeLabel: '~7 min walk',
    ),
  },
);

/// ================================================================
/// DNST BUILDING
/// ================================================================
///
/// TRACED PIXEL-BY-PIXEL FROM THE TENTH PROVIDED SCREENSHOT.
///
/// Screenshot file : 1467 x 841
/// Map content box : x 8..1459  (w = 1452)
///                   y 10..826  (h = 817)
///
/// Traced pixels -> normalized:
///
///   Start dot      (1359, 317)  ->  (0.9304, 0.3758)
///   Road corner    ( 488, 186)  ->  (0.3306, 0.2154)
///   Slope change   ( 547,  79)  ->  (0.3712, 0.0845)
///   Endpoint dot   ( 594,  36)  ->  (0.4036, 0.0312)
///
/// Shape: the full main-road run, then north-EAST up the hill on
/// two different slopes — about 0.55 px of x per px of y on the
/// lower stretch, steepening to about 0.97 on the upper one. The
/// bend at (547, 79) is a real change in the drawn line, not a
/// rounding artefact, so it is kept as a vertex.
///
/// The road corner is deliberately the SAME coordinate as the
/// Infrastructure Office route (0.3306, 0.2154) — both leave the
/// main road at that junction, so the shared stretch overlaps
/// cleanly instead of showing a faint double line.
///
/// This is the longest route in the file.
///
/// NOTE: this screenshot has NO yellow destination marker, so
/// markerPoint is not traced — it is placed at (625, 47), east of
/// the endpoint. The building is small and sits hard against the
/// top edge of the map, so there is no room to mark above it.
/// ================================================================

const BuildingRouteSet _dnstBuildingRoutes =
    BuildingRouteSet(
  buildingName: 'DNST Building',

  /// East of the route endpoint — no room above, the map ends there.
  markerPoint: Offset(
    0.4249,
    0.0453,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1359, 317)
        // ==========================================================
        Offset(0.9304, 0.3758),

        // ==========================================================
        // LEG 1 — THE FULL RUN WEST ALONG THE MAIN ROAD
        // ==========================================================
        Offset(0.8704, 0.3598),
        Offset(0.8104, 0.3437),
        Offset(0.7505, 0.3277),
        Offset(0.6905, 0.3116),
        Offset(0.6305, 0.2956),
        Offset(0.5705, 0.2796),
        Offset(0.5105, 0.2635),
        Offset(0.4506, 0.2475),
        Offset(0.3906, 0.2314),

        // Road corner — turn north  (488, 186)
        Offset(0.3306, 0.2154),

        // ==========================================================
        // LEG 2 — NORTH-EAST UP THE HILL, SHALLOW STRETCH
        // ==========================================================
        Offset(0.3441, 0.1718),
        Offset(0.3577, 0.1281),

        // Slope change  (547, 79)
        Offset(0.3712, 0.0845),

        // ==========================================================
        // LEG 3 — STEEPER RUN UP TO THE DNST
        // ==========================================================
        Offset(0.3874, 0.0579),

        // ==========================================================
        // DNST ROUTE ENDPOINT  (594, 36)
        // ==========================================================
        Offset(0.4036, 0.0312),
      ],

      distanceLabel: '~589 m',
      timeLabel: '~8 min walk',
    ),
  },
);

/// ================================================================
/// OLD ADMIN BUILDING
/// ================================================================
///
/// TRACED PIXEL-BY-PIXEL FROM THE ELEVENTH PROVIDED SCREENSHOT.
///
/// Screenshot file : 1472 x 832
/// Map content box : x 9..1460  (w = 1452)
///                   y 3..819   (h = 817)
///
/// Traced pixels -> normalized:
///
///   Start dot      (1360, 311)  ->  (0.9304, 0.3770)
///   Road corner    ( 490, 179)  ->  (0.3313, 0.2154)  [snapped]
///   Endpoint dot   ( 425, 211)  ->  (0.2865, 0.2546)
///
/// Shape: the full main-road run, then a turn back DOWN-WEST off
/// the road (~0.52 px of y for every px of x) to the east corner
/// of the Old Admin building. The final leg descends, unlike the
/// Infrastructure and DNST routes that climb from the same corner.
///
/// The corner traced to x = 0.3313, one pixel off the Infrastructure
/// Office and DNST corner. It is snapped to their 0.3306 so all
/// three routes leave the main road at exactly the same point.
///
/// NOTE: this screenshot has NO yellow destination marker, so
/// markerPoint is not traced — it is placed at (395, 195), on the
/// Old Admin roof west of the route endpoint.
/// ================================================================

const BuildingRouteSet _oldAdminRoutes =
    BuildingRouteSet(
  buildingName: 'Old Admin Building',

  /// On the Old Admin roof, west of the route endpoint.
  markerPoint: Offset(
    0.2659,
    0.2350,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1360, 311)
        // ==========================================================
        Offset(0.9304, 0.3770),

        // ==========================================================
        // LEG 1 — THE FULL RUN WEST ALONG THE MAIN ROAD
        // (same stretch the Infrastructure Office route uses)
        // ==========================================================
        Offset(0.8704, 0.3608),
        Offset(0.8105, 0.3447),
        Offset(0.7505, 0.3285),
        Offset(0.6905, 0.3124),
        Offset(0.6305, 0.2962),
        Offset(0.5705, 0.2800),
        Offset(0.5106, 0.2639),
        Offset(0.4506, 0.2477),
        Offset(0.3906, 0.2316),

        // Shared road corner  (488, 179)
        Offset(0.3306, 0.2154),

        // ==========================================================
        // LEG 2 — DOWN-WEST OFF THE ROAD TO THE OLD ADMIN
        // ==========================================================
        Offset(0.3159, 0.2285),
        Offset(0.3012, 0.2415),

        // ==========================================================
        // OLD ADMIN ROUTE ENDPOINT  (425, 211)
        // ==========================================================
        Offset(0.2865, 0.2546),
      ],

      distanceLabel: '~490 m',
      timeLabel: '~6 min walk',
    ),
  },
);

/// ================================================================
/// HATCHERY
/// ================================================================
///
/// TRACED PIXEL-BY-PIXEL FROM THE TWELFTH PROVIDED SCREENSHOT.
///
/// Screenshot file : 1470 x 853
/// Map content box : x 7..1458  (w = 1452)
///                   y 11..827  (h = 817)
///
/// Traced pixels -> normalized:
///
///   Start dot      (1358, 319)  ->  (0.9304, 0.3770)
///   Road corner    ( 487, 187)  ->  (0.3306, 0.2154)
///   Bottom corner  ( 428, 322)  ->  (0.2899, 0.3806)
///   Turn vertex    ( 343, 310)  ->  (0.2314, 0.3660)
///   Endpoint dot   ( 334, 329)  ->  (0.2252, 0.3892)
///
/// Shape: four legs. West along the main road to the shared corner,
/// then SOUTH down the long side road (leaning west, ~0.44 px of x
/// per px of y), then WEST along the pond edge — that leg RISES
/// slightly as it goes west, it is not level — and finally a short
/// hop down-left onto the hatchery.
///
/// The road corner traced to exactly (0.3306, 0.2154), the same
/// junction the Infrastructure Office, DNST and Old Admin routes
/// use. Four routes now share that point, so their common stretch
/// overlaps perfectly.
///
/// This is the longest route in the file.
///
/// NOTE: this screenshot has NO yellow destination marker, so
/// markerPoint is not traced — it is placed at (330, 345), just
/// below the route endpoint. The buildings here are small and
/// tightly packed, so nudge it if it reads as the wrong one.
/// ================================================================

const BuildingRouteSet _hatcheryRoutes =
    BuildingRouteSet(
  buildingName: 'Hatchery',

  /// Just below the route endpoint.
  markerPoint: Offset(
    0.2225,
    0.4088,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1358, 319)
        // ==========================================================
        Offset(0.9304, 0.3770),

        // ==========================================================
        // LEG 1 — THE FULL RUN WEST ALONG THE MAIN ROAD
        // ==========================================================
        Offset(0.8704, 0.3608),
        Offset(0.8105, 0.3447),
        Offset(0.7505, 0.3285),
        Offset(0.6905, 0.3124),
        Offset(0.6305, 0.2962),
        Offset(0.5705, 0.2800),
        Offset(0.5106, 0.2639),
        Offset(0.4506, 0.2477),
        Offset(0.3906, 0.2316),

        // Shared road corner  (487, 187)
        Offset(0.3306, 0.2154),

        // ==========================================================
        // LEG 2 — SOUTH DOWN THE SIDE ROAD, LEANING WEST
        // ==========================================================
        Offset(0.3204, 0.2567),
        Offset(0.3103, 0.2980),
        Offset(0.3001, 0.3393),

        // Bottom corner  (428, 322)
        Offset(0.2899, 0.3806),

        // ==========================================================
        // LEG 3 — WEST ALONG THE POND EDGE (rises going west)
        // ==========================================================
        Offset(0.2607, 0.3733),

        // Turn vertex  (343, 310)
        Offset(0.2314, 0.3660),

        // ==========================================================
        // LEG 4 — SHORT HOP DOWN-LEFT ONTO THE HATCHERY
        // ==========================================================
        Offset(0.2283, 0.3776),

        // ==========================================================
        // HATCHERY ROUTE ENDPOINT  (334, 329)
        // ==========================================================
        Offset(0.2252, 0.3892),
      ],

      distanceLabel: '~618 m',
      timeLabel: '~8 min walk',
    ),
  },
);

/// ================================================================
/// ICRM BUILDING
/// ================================================================
///
/// TRACED PIXEL-BY-PIXEL FROM THE THIRTEENTH PROVIDED SCREENSHOT.
///
/// Screenshot file : 1450 x 818
/// Map content box : x 5..1442  (w = 1438)
///                   y 3..811   (h = 809)
///
/// NOTE ON SIZE: this screenshot is rendered SMALLER than the
/// others — a 1438 x 809 map instead of 1452 x 817. The aspect
/// ratio is identical (1.7775 vs 1.7772), so normalizing against
/// this image's own content box lands on the same map positions.
/// The start dot confirms it: (0.9305, 0.3770), the same as every
/// other route in this file.
///
/// Traced pixels -> normalized:
///
///   Start dot      (1343, 308)  ->  (0.9305, 0.3770)
///   North corner   ( 920, 243)  ->  (0.6363, 0.2967)
///   South corner   ( 883, 391)  ->  (0.6106, 0.4796)
///   West corner    ( 633, 348)  ->  (0.4367, 0.4264)
///   Down vertex    ( 620, 376)  ->  (0.4277, 0.4611)
///   Endpoint dot   ( 636, 376)  ->  (0.4388, 0.4611)
///
/// Shape: this route does NOT use the long main road. It leaves
/// the start heading west-north-west, turns SOUTH early at
/// (920, 243) — well before every other route's junction — crosses
/// down past the pond, then runs WEST along the inner path, drops
/// down at (620, 376), and finally steps back EAST a few pixels
/// into the ICRM entrance where the dot sits.
///
/// That last eastward step is only ~16 px but it is in the drawn
/// line, so it is kept rather than ending the route at the corner.
///
/// NOTE: this screenshot has NO yellow destination marker, so
/// markerPoint is not traced — it is placed at (660, 385), on the
/// ICRM roof east of the route endpoint.
/// ================================================================

const BuildingRouteSet _icrmBuildingRoutes =
    BuildingRouteSet(
  buildingName: 'ICRM Building',

  /// On the ICRM roof, east of the route endpoint.
  markerPoint: Offset(
    0.4555,
    0.4722,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1343, 308)
        // ==========================================================
        Offset(0.9305, 0.3770),

        // ==========================================================
        // LEG 1 — WEST-NORTH-WEST, SHORTER THAN THE USUAL ROAD RUN
        // ==========================================================
        Offset(0.8717, 0.3609),
        Offset(0.8128, 0.3449),
        Offset(0.7540, 0.3288),
        Offset(0.6951, 0.3128),

        // North corner — turn south early  (920, 243)
        Offset(0.6363, 0.2967),

        // ==========================================================
        // LEG 2 — SOUTH PAST THE POND, LEANING WEST
        // ==========================================================
        Offset(0.6277, 0.3577),
        Offset(0.6192, 0.4186),

        // South corner  (883, 391)
        Offset(0.6106, 0.4796),

        // ==========================================================
        // LEG 3 — WEST ALONG THE INNER PATH (rises going west)
        // ==========================================================
        Offset(0.5671, 0.4663),
        Offset(0.5237, 0.4530),
        Offset(0.4802, 0.4397),

        // West corner  (633, 348)
        Offset(0.4367, 0.4264),

        // ==========================================================
        // LEG 4 — DOWN THE BUILDING SIDE
        // ==========================================================
        Offset(0.4322, 0.4438),
        Offset(0.4277, 0.4611),

        // ==========================================================
        // LEG 5 — SHORT STEP EAST INTO THE ENTRANCE
        // ==========================================================
        // ==========================================================
        // ICRM ROUTE ENDPOINT  (636, 376)
        // ==========================================================
        Offset(0.4388, 0.4611),
      ],

      distanceLabel: '~479 m',
      timeLabel: '~6 min walk',
    ),
  },
);

/// ================================================================
/// CEO'S COTTAGE
/// ================================================================
///
/// TRACED PIXEL-BY-PIXEL FROM THE FOURTEENTH PROVIDED SCREENSHOT.
///
/// Screenshot file : 1454 x 822
/// Map content box : x 5..1442  (w = 1438)
///                   y 2..810   (h = 809)
///                   (same smaller rendering as the ICRM shot)
///
/// Traced pixels -> normalized:
///
///   Start dot      (1343, 307)  ->  (0.9305, 0.3770)
///   North corner   ( 920, 242)  ->  (0.6363, 0.2967)
///   South corner   ( 883, 390)  ->  (0.6106, 0.4796)
///   Branch vertex  ( 764, 370)  ->  (0.5278, 0.4549)
///   Down vertex    ( 747, 416)  ->  (0.5160, 0.5117)
///   Endpoint dot   ( 729, 412)  ->  (0.5035, 0.5068)
///
/// Shape: this route SHARES the ICRM path — legs 1 and 2 trace to
/// the same two corners, (0.6363, 0.2967) and (0.6106, 0.4796),
/// with no snapping needed. It then runs west along the same inner
/// path as the ICRM but branches off early at (764, 370), drops
/// south between the cottages, and steps back west onto the
/// cottage itself.
///
/// So the two routes overlap exactly from the start dot all the
/// way to the branch vertex, then separate.
///
/// NOTE: this screenshot has NO yellow destination marker, so
/// markerPoint is not traced — it is placed at (715, 415), on the
/// cottage roof west of the route endpoint.
/// ================================================================

const BuildingRouteSet _ceoCottageRoutes =
    BuildingRouteSet(
  buildingName: "CEO's Cottage",

  /// On the cottage roof, west of the route endpoint.
  markerPoint: Offset(
    0.4937,
    0.5105,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1343, 307)
        // ==========================================================
        Offset(0.9305, 0.3770),

        // ==========================================================
        // LEG 1 — WEST-NORTH-WEST  (shared with the ICRM route)
        // ==========================================================
        Offset(0.8717, 0.3609),
        Offset(0.8128, 0.3449),
        Offset(0.7540, 0.3288),
        Offset(0.6951, 0.3128),

        // North corner  (920, 242)
        Offset(0.6363, 0.2967),

        // ==========================================================
        // LEG 2 — SOUTH PAST THE POND  (shared with the ICRM route)
        // ==========================================================
        Offset(0.6277, 0.3577),
        Offset(0.6192, 0.4186),

        // South corner  (883, 390)
        Offset(0.6106, 0.4796),

        // ==========================================================
        // LEG 3 — WEST, BRANCHING OFF THE ICRM PATH EARLY
        // ==========================================================
        Offset(0.5692, 0.4673),

        // Branch vertex  (764, 370)
        Offset(0.5278, 0.4549),

        // ==========================================================
        // LEG 4 — SOUTH BETWEEN THE COTTAGES
        // ==========================================================
        Offset(0.5219, 0.4833),
        Offset(0.5160, 0.5117),

        // ==========================================================
        // LEG 5 — SHORT STEP WEST ONTO THE COTTAGE
        // ==========================================================
        // ==========================================================
        // CEO'S COTTAGE ROUTE ENDPOINT  (729, 412)
        // ==========================================================
        Offset(0.5035, 0.5068),
      ],

      distanceLabel: '~424 m',
      timeLabel: '~5 min walk',
    ),
  },
);

/// ================================================================
/// EXECUTIVE VILLA 1
/// ================================================================
///
/// TRACED PIXEL-BY-PIXEL FROM THE FIFTEENTH PROVIDED SCREENSHOT.
///
/// Screenshot file : 1223 x 693
/// Map content box : x 8..1211  (w = 1204)
///                   y 10..687  (h = 678)
///
/// NOTE ON SIZE: this is the SMALLEST screenshot supplied so far —
/// a 1204 x 678 map, about 83% of the usual 1452 x 817. The aspect
/// ratio still matches (1.7758 vs 1.7772) and the start dot lands
/// on (0.9302, 0.3761), so the normalization holds.
///
/// Traced pixels -> normalized:
///
///   Start dot      (1128, 265)  ->  (0.9302, 0.3761)
///   North corner   ( 774, 211)  ->  (0.6363, 0.2967)  [snapped]
///   South corner   ( 743, 335)  ->  (0.6106, 0.4796)  [snapped]
///   Branch vertex  ( 643, 318)  ->  (0.5278, 0.4549)  [snapped]
///   Endpoint dot   ( 631, 328)  ->  (0.5175, 0.4690)
///
/// Shape: identical to the CEO's Cottage route as far as the branch
/// vertex, then it stops there instead of continuing south — one
/// short step down-left onto the villa roof and it is done.
///
/// All three shared vertices traced to within ~1.6 px of the CEO's
/// Cottage values, so they are snapped to be byte-identical. Three
/// routes (ICRM, CEO's Cottage, Executive Villa 1) now overlay
/// exactly along this whole stretch.
///
/// NOTE: this screenshot has NO yellow destination marker, so
/// markerPoint is not traced — it is placed at (617, 318). The
/// villa is only ~22 px across on the map, so the marker covers
/// most of it whatever position is chosen; this one keeps the
/// route dot visible to its right.
/// ================================================================

const BuildingRouteSet _executiveVilla1Routes =
    BuildingRouteSet(
  buildingName: 'Executive Villa 1',

  /// On the villa roof, left of the route endpoint.
  markerPoint: Offset(
    0.5058,
    0.4543,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1128, 265)
        // ==========================================================
        Offset(0.9302, 0.3761),

        // ==========================================================
        // LEG 1 — WEST-NORTH-WEST  (shared with ICRM / CEO Cottage)
        // ==========================================================
        Offset(0.8714, 0.3602),
        Offset(0.8126, 0.3443),
        Offset(0.7538, 0.3283),
        Offset(0.6950, 0.3124),

        // North corner  (774, 211)
        Offset(0.6363, 0.2967),

        // ==========================================================
        // LEG 2 — SOUTH PAST THE POND  (shared)
        // ==========================================================
        Offset(0.6277, 0.3576),
        Offset(0.6191, 0.4185),

        // South corner  (743, 335)
        Offset(0.6106, 0.4796),

        // ==========================================================
        // LEG 3 — WEST ALONG THE INNER PATH  (shared, rises west)
        // ==========================================================
        Offset(0.5692, 0.4672),

        // Branch vertex  (643, 318)
        Offset(0.5278, 0.4549),

        // ==========================================================
        // LEG 4 — SHORT STEP DOWN-LEFT ONTO THE VILLA
        // ==========================================================
        // ==========================================================
        // EXECUTIVE VILLA 1 ROUTE ENDPOINT  (631, 328)
        // ==========================================================
        Offset(0.5175, 0.4690),
      ],

      distanceLabel: '~400 m',
      timeLabel: '~5 min walk',
    ),
  },
);

/// ================================================================
/// LECTURER'S DORMITORY
/// ================================================================
///
/// TRACED PIXEL-BY-PIXEL FROM THE SIXTEENTH PROVIDED SCREENSHOT.
///
/// Screenshot file : 1448 x 820
/// Map content box : x 4..1441  (w = 1438)
///                   y 6..814   (h = 809)
///
/// Traced pixels -> normalized:
///
///   Start dot      (1343, 311)  ->  (0.9312, 0.3770)
///   North corner   ( 919, 247)  ->  (0.6363, 0.2967)  [snapped]
///   Shared corner  ( 882, 394)  ->  (0.6106, 0.4796)
///   Endpoint dot   ( 889, 419)  ->  (0.6154, 0.5105)
///
/// Shape: only two legs. West-north-west to the north corner, then
/// straight down the side road to the dormitory.
///
/// The interesting part is the middle: this route runs down the
/// SAME side road as the ICRM, CEO's Cottage and Executive Villa 1,
/// and the point (0.6106, 0.4796) — where those three turn west —
/// falls exactly on this leg. It is included as an interpolation
/// point rather than a turn, so all four routes lie on top of each
/// other down to that spot and this one simply carries on south.
///
/// NOTE: this screenshot has NO yellow destination marker, so
/// markerPoint is not traced — it is placed at (908, 425), on the
/// dormitory roof east of the route endpoint.
/// ================================================================

const BuildingRouteSet _lecturersDormitoryRoutes =
    BuildingRouteSet(
  buildingName: "Lecturer's Dormitory",

  /// On the dormitory roof, east of the route endpoint.
  markerPoint: Offset(
    0.6286,
    0.5179,
  ),

  routes: {
    RouteMode.fastestWalk: CampusRoutePath(
      mode: RouteMode.fastestWalk,

      points: [
        // ==========================================================
        // START HERE  (1343, 311)
        // ==========================================================
        Offset(0.9312, 0.3770),

        // ==========================================================
        // LEG 1 — WEST-NORTH-WEST  (shared with ICRM / Cottage /
        // Executive Villa 1)
        // ==========================================================
        Offset(0.8722, 0.3609),
        Offset(0.8132, 0.3449),
        Offset(0.7543, 0.3288),
        Offset(0.6953, 0.3128),

        // North corner  (919, 247)
        Offset(0.6363, 0.2967),

        // ==========================================================
        // LEG 2 — STRAIGHT DOWN THE SIDE ROAD, LEANING WEST
        // ==========================================================
        Offset(0.6286, 0.3510),
        Offset(0.6212, 0.4042),
        Offset(0.6137, 0.4573),

        // The other three routes turn WEST here. This one does not.
        Offset(0.6106, 0.4796),

        // ==========================================================
        // LECTURER'S DORMITORY ROUTE ENDPOINT  (889, 419)
        // ==========================================================
        Offset(0.6154, 0.5105),
      ],

      distanceLabel: '~341 m',
      timeLabel: '~4 min walk',
    ),
  },
);

/// ================================================================
/// FIND BUILDING ROUTE
/// ================================================================

///
/// Scores EVERY alias and returns the best match instead of
/// returning the first hit in list order. That matters as soon as
/// one building's name contains another's:
///
///   'old admin'            -> Old Admin      (not Administration)
///   'admin'                -> Administration (not Old Admin)
///   'business administration' -> CBEA         (not Administration)
///
/// The first-hit version returned the wrong building for all three,
/// because 'admin' / 'administration' belong to the Administration
/// Building and it sits first in the list.
///
/// Ranking, best first:
///
///   tier 3  the query IS the alias          -> exact
///   tier 2  the query CONTAINS the alias    -> longest alias wins
///   tier 1  the alias CONTAINS the query    -> shortest alias wins
///
/// Within tier 2 a longer alias is the more specific reading of the
/// query ('old admin' beats 'admin'). Within tier 1 a shorter alias
/// is the closer one ('adm' should reach 'admin', not
/// 'administration building').
///
/// Because every alias is scored, list order no longer decides the
/// winner — new buildings can be appended anywhere.
BuildingRouteSet? findRoutesFor(String query) {
  final q = query.toLowerCase().trim();

  if (q.isEmpty) {
    return null;
  }

  BuildingRouteSet? best;
  int bestTier = 0;
  int bestScore = 0;

  for (final routeSet in _buildingRoutes) {
    final aliases = _aliases[routeSet] ?? const <String>[];

    for (final alias in aliases) {
      final int tier;
      final int score;

      if (q == alias) {
        // Exact hit.
        tier = 3;
        score = alias.length;
      } else if (q.contains(alias)) {
        // The query spells out this alias plus extra words.
        tier = 2;
        score = alias.length;
      } else if (q.length >= 3 && alias.contains(q)) {
        // Partial / prefix search. Negative so SHORTER wins.
        tier = 1;
        score = -alias.length;
      } else {
        continue;
      }

      if (tier > bestTier || (tier == bestTier && score > bestScore)) {
        bestTier = tier;
        bestScore = score;
        best = routeSet;
      }
    }
  }

  return best;
}
