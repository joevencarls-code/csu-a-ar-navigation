import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:csu_a_kiosk/models/campus_models.dart';
import 'package:csu_a_kiosk/widgets/directory_cards.dart';

void main() {
  testWidgets('CollegeDirectoryCard does not overflow with long content',
      (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    final college = College(
      id: 1,
      name: 'College of Engineering and Architecture and Technology Studies',
      abbrev: 'CEATS',
      dean: 'Dr. Maria Clara Del Rosario Fernandez III, PhD, MAEd, DBA',
      programs: 'BS InfoTech, BS CompSci, BS Mining, BS Civil Eng, BS Mech Eng',
      location: 'Main Building, Aparri Campus, Cagayan, Philippines',
      description: 'Long description that should not matter here',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: CollegeDirectoryCard(college: college),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}