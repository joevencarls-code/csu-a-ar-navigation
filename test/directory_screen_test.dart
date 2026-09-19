import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:csu_a_kiosk/screens/directory_screen.dart';

void main() {
  testWidgets('DirectoryScreen renders tabs and error states without crashing',
      (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DirectoryScreen()),
      ),
    );

    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Directory'), findsOneWidget);
    expect(find.text('Buildings'), findsOneWidget);
    expect(find.text('Offices'), findsOneWidget);
    expect(find.text('Colleges'), findsOneWidget);

    await tester.tap(find.text('Offices'));
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('Colleges'));
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('Buildings'));
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
  });
}