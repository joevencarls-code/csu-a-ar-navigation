import 'package:flutter_test/flutter_test.dart';
import 'package:csu_a_kiosk/models/campus_models.dart';
import 'package:csu_a_kiosk/services/pathfinder.dart';

void main() {
  // Graph:
  // 1 --5-- 2 --2-- 3
  // |________10_______|
  final waypoints = [
    Waypoint(id: 1, name: 'A', x: 0, y: 0, floor: 1),
    Waypoint(id: 2, name: 'B', x: 5, y: 0, floor: 1),
    Waypoint(id: 3, name: 'C', x: 10, y: 0, floor: 1),
    Waypoint(id: 4, name: 'Isolated', x: 99, y: 99, floor: 2),
  ];
  final edges = [
    PathEdge(id: 1, fromNode: 1, toNode: 2, distance: 5),
    PathEdge(id: 2, fromNode: 2, toNode: 3, distance: 2),
    PathEdge(id: 3, fromNode: 1, toNode: 3, distance: 10),
  ];

  test('finds the shorter two-hop route over the direct edge', () {
    final result = Pathfinder.shortestPath(
      waypoints: waypoints,
      edges: edges,
      startId: 1,
      endId: 3,
    );
    expect(result, isNotNull);
    expect(result!.waypointIds, [1, 2, 3]);
    expect(result.totalDistance, 7);
  });

  test('returns zero-length path when start equals end', () {
    final result = Pathfinder.shortestPath(
      waypoints: waypoints,
      edges: edges,
      startId: 1,
      endId: 1,
    );
    expect(result, isNotNull);
    expect(result!.waypointIds, [1]);
    expect(result.totalDistance, 0);
  });

  test('returns null when no path exists', () {
    final result = Pathfinder.shortestPath(
      waypoints: waypoints,
      edges: edges,
      startId: 1,
      endId: 4,
    );
    expect(result, isNull);
  });

  test('returns null for an unknown waypoint id', () {
    final result = Pathfinder.shortestPath(
      waypoints: waypoints,
      edges: edges,
      startId: 1,
      endId: 999,
    );
    expect(result, isNull);
  });
}
