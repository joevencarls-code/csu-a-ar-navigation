import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:csu_a_kiosk/models/campus_models.dart';
import 'package:csu_a_kiosk/screens/directory_screen.dart';
import 'package:csu_a_kiosk/services/campus_repository.dart';
import 'package:csu_a_kiosk/widgets/directory_cards.dart';
import 'package:csu_a_kiosk/widgets/directory_detail_dialog.dart';
import 'package:csu_a_kiosk/widgets/faculty_id_card.dart';

class _FakeDirectoryRepository extends CampusRepository {
  _FakeDirectoryRepository({
    this.buildings = const [],
    this.offices = const [],
    this.colleges = const [],
    this.rooms = const [],
    this.faculty = const [],
  });

  final List<Building> buildings;
  final List<OfficeEntry> offices;
  final List<College> colleges;
  final List<Room> rooms;
  final List<FacultyMember> faculty;

  @override
  Future<List<Building>> getBuildings() async => buildings;

  @override
  Future<List<OfficeEntry>> getOfficeEntries() async => offices;

  @override
  Future<List<College>> getColleges() async => colleges;

  @override
  Future<List<Room>> getRoomsForBuilding(int buildingId) async => rooms;

  @override
  Future<List<FacultyMember>> getFacultyByCollege(int collegeId) async =>
      faculty.where((member) => member.collegeId == collegeId).toList();
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final building = Building(
    id: 1,
    name: 'Main Building',
    description:
        'A full description that is far too long for the grid card to show '
        'in its entirety, so the enlarged view has to reveal all of it.',
    location: 'Aparri Campus, Cagayan',
    offices: 'Registrar, Accounting, Cashier',
    dean: 'Dr. Juan Dela Cruz',
  );

  final office = OfficeEntry(
    id: 1,
    name: 'Registrar Office',
    abbreviation: 'REG',
    location: 'Ground Floor, Main Building',
    head: 'Maria Santos',
    purpose: 'Handles student records and enrollment services.',
    contact: '0917 000 0000',
  );

  final college = College(
    id: 1,
    name: 'College of Engineering and Architecture',
    abbrev: 'CEATS',
    dean: 'Dr. Maria Clara Del Rosario Fernandez III',
    programs: 'BS InfoTech, BS CompSci, BS Mining',
    location: 'Engineering Building',
    description: 'Engineering and architecture programs.',
  );

  testWidgets('directory cards are tappable and show a details hint', (
    WidgetTester tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BuildingDirectoryCard(
                      building: building,
                      onTap: () => taps++,
                    ),
                    OfficeDirectoryCard(office: office, onTap: () => taps++),
                    CollegeDirectoryCard(college: college, onTap: () => taps++),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tap to view full details'), findsNWidgets(3));

    for (final finder in [
      find.byType(BuildingDirectoryCard),
      find.byType(OfficeDirectoryCard),
      find.byType(CollegeDirectoryCard),
    ]) {
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await tester.pump();
    }

    expect(taps, 3);
  });

  testWidgets('building detail dialog shows the full description and rooms', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showBuildingDetailDialog(
                  context,
                  building,
                  loadRooms: () async => [
                    'Registrar Office • Records • Floor 1',
                    'Computer Lab • Laboratory • Floor 2',
                  ],
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(DirectoryDetailDialog), findsOneWidget);
    expect(find.text('Main Building'), findsOneWidget);
    expect(find.text(building.description!), findsOneWidget);
    expect(find.text('Dean / Head'.toUpperCase()), findsOneWidget);
    expect(find.text('Registrar'), findsOneWidget);
    expect(find.text('Rooms'), findsOneWidget);
    expect(find.text('Registrar Office • Records • Floor 1'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.byType(DirectoryDetailDialog), findsNothing);
  });

  testWidgets('office and college cards open their enlarged views', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showOfficeDetailDialog(context, office),
                child: const Text('office'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('office'));
    await tester.pumpAndSettle();

    expect(find.byType(DirectoryDetailDialog), findsOneWidget);
    expect(find.text('Registrar Office'), findsOneWidget);
    expect(find.text('Head / Person in Charge'.toUpperCase()), findsOneWidget);
    expect(find.text('0917 000 0000'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showCollegeDetailDialog(context, college),
                child: const Text('college'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('college'));
    await tester.pumpAndSettle();

    expect(find.byType(DirectoryDetailDialog), findsOneWidget);
    expect(find.text('CEATS'), findsOneWidget);
    expect(find.text('Programs'), findsOneWidget);
    expect(find.text('BS Mining'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('college detail lists its faculty without an auto-added dean', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final faculty = [
      for (var i = 1; i <= 20; i++)
        FacultyMember(
          id: i,
          collegeId: college.id,
          fullname: 'Faculty Member $i',
          position: i == 7 ? 'Department Head' : 'Instructor I',
          imageUrl: i == 20 ? 'assets/faculty/araa.png' : null,
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showCollegeDetailDialog(
                  context,
                  college,
                  loadFaculty: () async => faculty,
                ),
                child: const Text('college'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('college'));
    await tester.pumpAndSettle();

    expect(find.byType(DirectoryDetailDialog), findsOneWidget);
    expect(find.text('Faculty (20)'), findsOneWidget);

    final facultyList = find.descendant(
      of: find.byType(DirectoryDetailDialog),
      matching: find.byType(ListView),
    );
    expect(facultyList, findsOneWidget);

    final cards = tester
        .widgetList<FacultyIdCard>(find.byType(FacultyIdCard))
        .toList();
    expect(cards, isNotEmpty);

    // The dean is no longer injected into the roster — only real faculty
    // rows are listed, so the college's head leads by position instead.
    expect(cards.first.fullname, 'Faculty Member 7');
    expect(
      cards.any((card) => (card.position ?? '').toUpperCase() == 'DEAN'),
      isFalse,
    );

    // The roster scrolls instead of pushing the rest of the dialog away.
    expect(find.text('Faculty Member 20'), findsNothing);
    final facultyScrollable = find.descendant(
      of: facultyList,
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Faculty Member 20'),
      200,
      scrollable: facultyScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Faculty Member 20'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tapping a card opens that member's own enlarged view on top.
    await tester.tap(
      find.ancestor(
        of: find.text('Faculty Member 20'),
        matching: find.byType(FacultyIdCard),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DirectoryDetailDialog), findsNWidgets(2));
    expect(find.text('Instructor I'.toUpperCase()), findsWidgets);
    expect(tester.takeException(), isNull);

    // The member's photo sits in a square frame and is shown whole rather
    // than cropped, so their full face stays visible.
    final memberDialog = find.byType(DirectoryDetailDialog).last;
    final photo = tester.widgetList<Image>(
      find.descendant(of: memberDialog, matching: find.byType(Image)),
    );
    expect(photo.map((image) => image.fit), contains(BoxFit.contain));

    final squareFrames = tester
        .widgetList<Container>(
          find.descendant(of: memberDialog, matching: find.byType(Container)),
        )
        .where(
          (box) =>
              box.constraints != null &&
              box.constraints!.isTight &&
              box.constraints!.maxWidth == box.constraints!.maxHeight &&
              box.constraints!.maxWidth > 100,
        )
        .toList();
    expect(squareFrames, isNotEmpty);

    await tester.tap(find.text('Close').last);
    await tester.pumpAndSettle();
    expect(find.byType(DirectoryDetailDialog), findsOneWidget);
  });

  testWidgets('college detail with no faculty falls back gracefully', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showCollegeDetailDialog(
                  context,
                  College(id: 9, name: 'Graduate School'),
                  loadFaculty: () async => const [],
                ),
                child: const Text('college'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('college'));
    await tester.pumpAndSettle();

    expect(find.text('Faculty'), findsOneWidget);
    expect(
      find.text('No faculty listed for this college yet.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('faculty popup uses the showcase layout and copies its info', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    String? clipboardText = '';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    final member = FacultyMember(
      id: 42,
      fullname: 'Billy S. Javier',
      position: 'Professor III',
      email: 'billy.javier@csu.edu.ph',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showFacultyDetailDialog(
                  context,
                  member,
                  collegeName: 'College of Engineering and Architecture',
                ),
                child: const Text('faculty'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('faculty'));
    await tester.pumpAndSettle();

    expect(find.byType(DirectoryDetailDialog), findsOneWidget);
    expect(find.text('Billy S. Javier'), findsOneWidget);
    expect(find.text('PROFESSOR III'), findsOneWidget);
    expect(
      find.text('College of Engineering and Architecture'),
      findsOneWidget,
    );
    expect(find.text('billy.javier@csu.edu.ph'), findsOneWidget);

    // No photo yet, so the header falls back to the member's initials.
    expect(find.text('BJ'), findsOneWidget);

    // Tapping the info card copies it and confirms inline.
    await tester.tap(find.text('billy.javier@csu.edu.ph'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(clipboardText, 'billy.javier@csu.edu.ph');
    expect(find.text('Copied to clipboard'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Tap to copy'), findsOneWidget);

    // The footer button does the same thing with a big touch target.
    await tester.tap(find.text('Copy Email'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(clipboardText, 'billy.javier@csu.edu.ph');
    expect(find.text('Copied'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Copy Email'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(DirectoryDetailDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('orderCollegeFaculty puts leaders first, then sorts by name', () {
    final ordered = orderCollegeFaculty([
      FacultyMember(id: 1, fullname: 'Zeta Ramos', position: 'Instructor I'),
      FacultyMember(id: 2, fullname: 'Ana Bautista', position: 'Instructor I'),
      FacultyMember(id: 3, fullname: 'Milo Cruz', position: 'Dean'),
    ]);

    expect(ordered.map((member) => member.fullname), [
      'Milo Cruz',
      'Ana Bautista',
      'Zeta Ramos',
    ]);
  });

  testWidgets('DirectoryScreen search filters the active tab', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DirectoryScreen(
            repository: _FakeDirectoryRepository(
              buildings: [
                building,
                Building(id: 2, name: 'Science Laboratories'),
                Building(id: 3, name: 'Workshop Building'),
              ],
              offices: [office],
              colleges: [college],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Colleges is the first tab, so it is what opens by default.
    expect(find.byType(CollegeDirectoryCard), findsOneWidget);

    // The header search starts collapsed behind a single icon.
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('directory-search-toggle')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Search colleges...'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CollegeDirectoryCard), findsNothing);
    expect(find.textContaining('No matches for "zzz"'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CollegeDirectoryCard), findsOneWidget);

    await tester.tap(find.text('Buildings'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Search buildings...'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'science');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(BuildingDirectoryCard), findsOneWidget);
    expect(find.text('Science Laboratories'), findsOneWidget);
    expect(find.text('Main Building'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(BuildingDirectoryCard), findsNothing);
    expect(find.textContaining('No matches for "zzz"'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('directory-search-clear')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(BuildingDirectoryCard), findsNWidgets(3));

    await tester.tap(find.text('Offices'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Search offices...'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'registrar');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(OfficeDirectoryCard), findsOneWidget);

    await tester.tap(find.text('Colleges'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Search colleges...'), findsOneWidget);
    expect(find.byType(CollegeDirectoryCard), findsNothing);
    expect(find.textContaining('No matches for "registrar"'), findsOneWidget);

    // The suffix button clears the query first, then collapses the field.
    await tester.tap(find.byKey(const ValueKey('directory-search-clear')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('directory-search-clear')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(CollegeDirectoryCard), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('DirectoryScreen entries open the enlarged view', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DirectoryScreen(
            repository: _FakeDirectoryRepository(
              buildings: [building],
              offices: [office],
              colleges: [college],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    Future<void> openAndClose(Finder card) async {
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DirectoryDetailDialog), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DirectoryDetailDialog), findsNothing);
    }

    await openAndClose(find.byType(CollegeDirectoryCard));

    await tester.tap(find.text('Buildings'));
    await tester.pump(const Duration(milliseconds: 100));
    await openAndClose(find.byType(BuildingDirectoryCard));

    await tester.tap(find.text('Offices'));
    await tester.pump(const Duration(milliseconds: 100));
    await openAndClose(find.byType(OfficeDirectoryCard));

    expect(tester.takeException(), isNull);
  });
}
