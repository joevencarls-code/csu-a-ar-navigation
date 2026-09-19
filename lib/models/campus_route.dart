import 'package:flutter/material.dart';

/// Available navigation modes.
enum RouteMode {
  fastestWalk,
  mainEntrance,
  vehicle,
}

extension RouteModeInfo on RouteMode {
  String get label => switch (this) {
        RouteMode.fastestWalk => 'Fastest Walk',
        RouteMode.mainEntrance => 'Main Entrance',
        RouteMode.vehicle => 'By Vehicle',
      };

  Color get color => switch (this) {
        // Blue route to match your reference screenshot.
        RouteMode.fastestWalk => const Color(0xFF2979FF),

        RouteMode.mainEntrance => const Color(0xFFFFC700),

        RouteMode.vehicle => const Color(0xFF2979FF),
      };

  IconData get icon => switch (this) {
        RouteMode.fastestWalk => Icons.directions_walk_rounded,
        RouteMode.mainEntrance => Icons.sensor_door_rounded,
        RouteMode.vehicle => Icons.directions_car_rounded,
      };
}

/// A route drawn over the campus map.
///
/// x and y are normalized from 0.0 to 1.0:
///
/// x = 0.0 → left side of map
/// x = 1.0 → right side of map
///
/// y = 0.0 → top of map
/// y = 1.0 → bottom of map
class CampusRoutePath {
  final RouteMode mode;
  final List<Offset> points;
  final String distanceLabel;
  final String timeLabel;

  const CampusRoutePath({
    required this.mode,
    required this.points,
    required this.distanceLabel,
    required this.timeLabel,
  });
}

/// Routes belonging to a destination building.
class BuildingRouteSet {
  final String buildingName;
  final Map<RouteMode, CampusRoutePath> routes;

  /// Normalized position of the destination marker.
  final Offset markerPoint;

  const BuildingRouteSet({
    required this.buildingName,
    required this.routes,
    required this.markerPoint,
  });
}