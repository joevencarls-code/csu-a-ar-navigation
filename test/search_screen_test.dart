import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:csu_a_kiosk/models/campus_models.dart';
import 'package:csu_a_kiosk/screens/search_screen.dart';
import 'package:csu_a_kiosk/services/campus_repository.dart';

class _FakeSearchRepository extends CampusRepository {
  _FakeSearchRepository({
    this.buildings = const [],
    this.collegeFaculty = const [],
  });

  final List<Building> buildings;
  final List<CollegeFacultyGroup> collegeFaculty;

  @override
  Future<List<Building>> getBuildings() async => buildings;

  @override
  Future<List<OfficeEntry>> getOfficeEntries() async => [];

  @override
  Future<List<LeadershipMember>> getLeadership() async => [];

  @override
  Future<List<CollegeFacultyGroup>> getCollegeFacultyGroups() async =>
      collegeFaculty;
}

/// Types [query] into the kiosk search field and returns the visible result
/// names.
Future<List<String>> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField).first, query);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  final names = <String>[];
  for (final text in find.byType(Text).evaluate()) {
    final value = (text.widget as Text).data;
    if (value != null && value.trim().isNotEmpty) names.add(value.trim());
  }
  return names;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final gatchalian = Building(
    id: 4,
    name: 'Gatchalian Building',
    description: 'Holds the CFAS and CCJE classes.',
    location: 'North campus - Gatchalian Hall',
  );
  final canteen = Building(
    id: 5,
    name: 'Canteen / Food Court',
    description: 'Food hub',
    location: 'Central campus',
  );

  Future<void> pumpSearch(
    WidgetTester tester, {
    List<Building> buildings = const [],
    List<CollegeFacultyGroup> collegeFaculty = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(
          repository: _FakeSearchRepository(
            buildings: buildings,
            collegeFaculty: collegeFaculty,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('searching CFAS or CCJE surfaces Gatchalian Building', (
    tester,
  ) async {
    for (final query in const ['cfas', 'CFAS', 'ccje', 'CCJE']) {
      await pumpSearch(tester, buildings: [gatchalian, canteen]);

      final names = await _search(tester, query);

      expect(
        names,
        contains('Gatchalian Building'),
        reason: '"$query" should surface Gatchalian Building',
      );
      expect(
        names,
        isNot(contains('Canteen / Food Court')),
        reason: '"$query" should not pull in unrelated buildings',
      );
    }
  });

  testWidgets('the full college names also resolve to Gatchalian Building', (
    tester,
  ) async {
    await pumpSearch(tester, buildings: [gatchalian, canteen]);

    for (final query in const [
      'College of Fisheries and Aquatic Sciences',
      'College of Criminal Justice Education',
    ]) {
      final names = await _search(tester, query);
      expect(
        names,
        contains('Gatchalian Building'),
        reason: '"$query" should surface Gatchalian Building',
      );
    }
  });

  testWidgets('a real college faculty hit is still listed', (tester) async {
    final faculty = <CollegeFacultyGroup>[
      CollegeFacultyGroup(
        id: 1,
        college: 'College of Fisheries and Aquatic Sciences',
        abbrev: 'CFAS',
        faculty: 'Faculty of Fisheries',
      ),
    ];
    await pumpSearch(tester, collegeFaculty: faculty);

    final names = await _search(tester, 'cfas');

    expect(names, contains('College of Fisheries and Aquatic Sciences'));
    expect(
      names.any((n) => n.contains('CFAS')),
      isTrue,
      reason: 'the abbreviation should be shown on the hit: $names',
    );
  });

  testWidgets('an unknown query still returns nothing', (tester) async {
    await pumpSearch(tester, buildings: [gatchalian, canteen]);

    final names = await _search(tester, 'zzzz');

    expect(names, isNot(contains('Gatchalian Building')));
    expect(find.text('No results found'), findsOneWidget);
  });
}
