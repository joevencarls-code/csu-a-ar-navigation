import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fl_chart/fl_chart.dart';

class _Cat {
  _Cat(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}

class _Probe extends StatefulWidget {
  final List<_Cat> cats;
  const _Probe(this.cats);
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  int _touchedSegment = -1;

  @override
  Widget build(BuildContext context) {
    final cats = widget.cats;
    final visible = cats.where((c) => c.value > 0).toList();
    final total = visible.fold<int>(0, (sum, c) => sum + c.value);
    final touched =
        _touchedSegment >= 0 && _touchedSegment < visible.length
            ? visible[_touchedSegment]
            : null;

    return Scaffold(
      body: Center(
        child: SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 62,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (!mounted) return;
                      if (!event.isInterestedForInteractions ||
                          response?.touchedSection == null) {
                        if (event is FlPointerExitEvent ||
                            event is FlTapCancelEvent ||
                            _touchedSegment != -1) {
                          setState(() => _touchedSegment = -1);
                        }
                        return;
                      }
                      final index =
                          response?.touchedSection?.touchedSectionIndex;
                      if (index == null ||
                          index < 0 ||
                          index >= visible.length) {
                        if (_touchedSegment != -1) {
                          setState(() => _touchedSegment = -1);
                        }
                        return;
                      }
                      if (_touchedSegment != index) {
                        setState(() => _touchedSegment = index);
                      }
                    },
                  ),
                  sections: [
                    for (int i = 0; i < visible.length; i++)
                      () {
                        final c = visible[i];
                        final isTouched = i == _touchedSegment;
                        final pct = c.value / total;
                        return PieChartSectionData(
                          value: c.value.toDouble(),
                          color: c.color,
                          radius: isTouched ? 66 : 56,
                          showTitle: pct >= 0.06,
                          title: '${(pct * 100).round()}%',
                          titleStyle: GoogleFonts.inter(
                            fontSize: isTouched ? 15 : 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black26, blurRadius: 3),
                            ],
                          ),
                        );
                      }(),
                  ],
                ),
              ),
              IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    key: ValueKey('seg$_touchedSegment'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (touched != null) ...[
                        Text(
                          touched.value.toString(),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: touched.color,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          touched.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          '${((touched.value / total) * 100).toStringAsFixed(1)}% of total',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ] else ...[
                        Text(
                          total.toString(),
                          style: const TextStyle(fontSize: 32),
                        ),
                        const Text('Total Records'),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('pie chart hover does not crash', (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(MaterialApp(
      home: _Probe([
        _Cat('Buildings', 12, const Color(0xFF003D82)),
        _Cat('Offices', 8, const Color(0xFF1A5FAF)),
        _Cat('Colleges', 5, const Color(0xFF3949AB)),
        _Cat('Faculty', 3, const Color(0xFF9C27B0)),
      ]),
    ));
    await tester.pump(const Duration(milliseconds: 500));

    final pieFinder = find.byType(PieChart);
    expect(pieFinder, findsOneWidget);

    final chart = tester.getRect(pieFinder);
    final center = chart.center;

    // A mouse gesture moving away from the center always crosses sections.
    final gesture =
        await tester.startGesture(center, kind: PointerDeviceKind.mouse);
    for (var r = 0; r <= 120; r += 4) {
      await gesture.moveTo(center + Offset(0, -r.toDouble()));
      await tester.pump(const Duration(milliseconds: 40));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
  });

  testWidgets('pie chart hover works with a single category',
      (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(MaterialApp(
      home: _Probe([
        _Cat('Buildings', 10, const Color(0xFF003D82)),
      ]),
    ));
    await tester.pump(const Duration(milliseconds: 500));

    final chart = tester.getRect(find.byType(PieChart));
    final center = chart.center;

    final gesture =
        await tester.startGesture(center, kind: PointerDeviceKind.mouse);
    for (var r = 10; r <= 100; r += 10) {
      await gesture.moveTo(center + Offset(0, -r.toDouble()));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });
}