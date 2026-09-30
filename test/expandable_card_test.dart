import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/widgets/expandable_card.dart';

void main() {
  testWidgets('ExpandableCard hides body when collapsed and reveals it on tap',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExpandableCard(
            header: Text('College A'),
            body: Text('Hidden faculty grid'),
          ),
        ),
      ),
    );

    expect(find.text('Hidden faculty grid'), findsNothing);
    expect(find.text('College A'), findsOne);

    await tester.tap(find.text('College A'));
    await tester.pumpAndSettle();

    expect(find.text('Hidden faculty grid'), findsOne);
  });
}