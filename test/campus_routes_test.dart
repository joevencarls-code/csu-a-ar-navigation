import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:csu_a_kiosk/data/campus_routes_data.dart';
import 'package:csu_a_kiosk/models/campus_route.dart';

void main() {
  test('Cafeteria and Canteen / Food Court are one dining place', () {
    final byName = {
      for (final route in allBuildingRoutes) route.buildingName: route,
    };
    final canteen = byName['Canteen / Food Court'];
    final cafeteria = byName['Cafeteria'];

    expect(canteen, isNotNull);
    expect(cafeteria, isNotNull);
    expect(cafeteria!.markerPoint, canteen!.markerPoint);
    expect(
      identical(
        cafeteria.routes[RouteMode.fastestWalk],
        canteen.routes[RouteMode.fastestWalk],
      ),
      isTrue,
      reason: 'both names must draw the exact same path',
    );
  });

  test('searching either name lands on the same route', () {
    final canteen = findRoutesFor('canteen');
    final cafeteria = findRoutesFor('cafeteria');

    expect(canteen, isNotNull);
    expect(cafeteria, isNotNull);
    expect(cafeteria!.markerPoint, canteen!.markerPoint);
    expect(
      cafeteria.routes[RouteMode.fastestWalk]!.points,
      canteen.routes[RouteMode.fastestWalk]!.points,
    );
    expect(
      cafeteria.routes[RouteMode.fastestWalk]!.distanceLabel,
      canteen.routes[RouteMode.fastestWalk]!.distanceLabel,
    );
    expect(
      cafeteria.routes[RouteMode.fastestWalk]!.points.first,
      const Offset(0.9311, 0.3764),
    );
  });
}
