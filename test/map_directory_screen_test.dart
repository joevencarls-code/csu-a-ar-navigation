import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:csu_a_kiosk/data/campus_routes_data.dart';
import 'package:csu_a_kiosk/models/campus_models.dart';
import 'package:csu_a_kiosk/screens/map_directory_screen.dart';
import 'package:csu_a_kiosk/services/campus_repository.dart';

class _FakeCampusRepository extends CampusRepository {
  @override
  Future<List<Building>> getBuildings() async => [];

  @override
  Future<List<OfficeEntry>> getOfficeEntries() async => [];

  @override
  Future<CampusSettings?> getCampusSettings() async => null;
}

void main() {
  test('searching CFAS or CCJE resolves to Gatchalian Building', () {
    for (final query in const [
      'cfas',
      'CFAS',
      'College of Fisheries and Aquatic Sciences',
      'College of Fisheries',
      'ccje',
      'CCJE',
      'College of Criminal Justice Education',
      'College of Criminal Justice',
      'where is ccfas',
    ]) {
      expect(
        findRoutesFor(query)?.buildingName,
        'Gatchalian Building',
        reason: 'query "$query" should route to Gatchalian Building',
      );
    }
  });

  test('Gatchalian Building still resolves to itself', () {
    for (final query in const [
      'gatchalian',
      'Gatchalian Building',
      'gatchalian hall',
    ]) {
      expect(findRoutesFor(query)?.buildingName, 'Gatchalian Building');
    }
  });

  testWidgets('tapping a building pin zooms and centers it', (
    WidgetTester tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapDirectoryScreen(repository: _FakeCampusRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final viewerFinder = find.byType(InteractiveViewer);
    final route = allBuildingRoutes.firstWhere(
      (route) => route.buildingName == 'Administration Building',
    );
    final pinFinder = find.byKey(
      ValueKey('building-pin-${route.buildingName}'),
    );
    final tappablePinFinder = find
        .ancestor(of: pinFinder, matching: find.byType(GestureDetector))
        .first;
    final viewer = tester.widget<InteractiveViewer>(viewerFinder);
    final controller = viewer.transformationController!;
    final viewerCenter = tester.getCenter(viewerFinder);

    expect(tappablePinFinder, findsOneWidget);
    await tester.tap(tappablePinFinder);
    await tester.pumpAndSettle();

    final focusedCenter = tester.getCenter(tappablePinFinder);
    expect(controller.value.getMaxScaleOnAxis(), closeTo(2.5, 0.001));
    expect(focusedCenter.dx, closeTo(viewerCenter.dx, 0.5));
    expect(focusedCenter.dy, closeTo(viewerCenter.dy, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('starting navigation resets the map and positions the QR card', (
    WidgetTester tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapDirectoryScreen(repository: _FakeCampusRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final route = allBuildingRoutes.firstWhere(
      (route) => route.buildingName == 'Administration Building',
    );
    final pinFinder = find.byKey(
      ValueKey('building-pin-${route.buildingName}'),
    );
    final tappablePinFinder = find
        .ancestor(of: pinFinder, matching: find.byType(GestureDetector))
        .first;

    await tester.tap(tappablePinFinder);
    await tester.pumpAndSettle();

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final controller = viewer.transformationController!;
    expect(controller.value.getMaxScaleOnAxis(), closeTo(2.5, 0.001));

    final navigateFinder = find.text('Navigate to ${route.buildingName}');
    expect(navigateFinder, findsOneWidget);
    await tester.tap(navigateFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.value.getMaxScaleOnAxis(), closeTo(1.0, 0.001));
    expect(find.byKey(const ValueKey('navigation-qr-panel')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map search collapses into a header icon and expands', (
    WidgetTester tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapDirectoryScreen(repository: _FakeCampusRepository()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const ValueKey('map-search-toggle')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('map-search-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search building or office...'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-search-clear')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final fieldRect = tester.getRect(
      find.byKey(const ValueKey('map-search-field')),
    );
    final panelRect = tester.getRect(
      find.byKey(const ValueKey('map-search-panel')),
    );
    expect(panelRect.left, closeTo(fieldRect.left, 1.0));
    expect(panelRect.width, closeTo(fieldRect.width, 1.0));
    expect(panelRect.top, greaterThanOrEqualTo(fieldRect.bottom));

    await tester.enterText(find.byType(TextField), 'gatchalian');
    await tester.pump();
    expect(find.text('No results found'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('map-search-clear')));
    await tester.pump();
    expect(find.text('Search building or office...'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-search-clear')));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('buildings without a surveyed AR destination still show a QR', (
    WidgetTester tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final name in const [
      'CHM Building',
      'Cafeteria',
      'Business Center',
      'Science Laboratories',
      'Workshop Building',
      'Dormitory',
    ]) {
      // Fresh tree per building so navigation state never carries over.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapDirectoryScreen(repository: _FakeCampusRepository()),
          ),
        ),
      );
      // Fixed pumps: the map runs a repeating marker animation, so
      // pumpAndSettle never returns.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      final route = allBuildingRoutes.firstWhere(
        (route) => route.buildingName == name,
      );
      final pinFinder = find.byKey(
        ValueKey('building-pin-${route.buildingName}'),
      );
      expect(pinFinder, findsOneWidget, reason: 'no pin for $name');

      final tappablePinFinder = find
          .ancestor(of: pinFinder, matching: find.byType(GestureDetector))
          .first;
      await tester.tap(tappablePinFinder);
      // Fixed pumps instead of pumpAndSettle: some pins run a repeating
      // pulse animation that never settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final navigateFinder = find.text('Navigate to $name');
      expect(
        navigateFinder,
        findsOneWidget,
        reason: 'no navigate button for $name',
      );
      await tester.tap(navigateFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byKey(const ValueKey('navigation-qr-panel')),
        findsOneWidget,
        reason: 'no navigation QR panel for $name',
      );
      expect(tester.takeException(), isNull);
    }
  });
}
