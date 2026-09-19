import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:csu_a_kiosk/screens/campus_info_screen.dart';

void main() {
  testWidgets(
    'CampusInfoScreen shows a friendly error when campus data is unavailable',
    (WidgetTester tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CampusInfoScreen()),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(
        find.text('Unable to load campus information'),
        findsOneWidget,
      );
    },
  );
}
