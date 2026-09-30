import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:csu_a_kiosk/screens/admin/admin_crud_screen.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  CrudScreen<int> buildScreen({
    Future<String?> Function(int item)? deleteImpact,
    required Future<void> Function(int id) onDelete,
  }) {
    return CrudScreen<int>(
      title: 'Manage Widgets',
      fields: const [
        CrudField(key: 'name', label: 'Name', type: CrudFieldType.text),
      ],
      fetchAll: () async => [7],
      onCreate: (_) async {},
      onUpdate: (id, values) async {},
      onDelete: onDelete,
      idOf: (id) => id,
      titleOf: (id) => 'Widget $id',
      valuesOf: (id) => {'name': 'Widget $id'},
      deleteImpact: deleteImpact,
    );
  }

  Future<void> pumpCrud(WidgetTester tester, CrudScreen<int> screen) async {
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
  }

  Future<void> dismissSnackBars(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('delete confirmation shows the impact warning', (tester) async {
    await pumpCrud(
      tester,
      buildScreen(
        deleteImpact: (id) async => 'Its 3 rooms will be deleted with it.',
        onDelete: (id) async {},
      ),
    );

    await tester.tap(find.byIcon(Icons.delete_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Delete Record'), findsOneWidget);
    expect(
      find.textContaining('Its 3 rooms will be deleted with it.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('This action cannot be undone.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await dismissSnackBars(tester);
  });

  testWidgets('confirmation runs the delete for that record', (tester) async {
    final deleted = <int>[];
    await pumpCrud(
      tester,
      buildScreen(
        deleteImpact: (id) async => 'Its 3 rooms will be deleted with it.',
        onDelete: (id) async => deleted.add(id),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deleted, [7]);

    await dismissSnackBars(tester);
  });

  testWidgets('keeps the plain warning when there is no impact', (
    tester,
  ) async {
    await pumpCrud(tester, buildScreen(onDelete: (id) async {}));

    await tester.tap(find.byIcon(Icons.delete_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Delete Record'), findsOneWidget);
    expect(
      find.text(
        'Are you sure you want to delete "Widget 7"?\n'
        'This action cannot be undone.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await dismissSnackBars(tester);
  });
}
