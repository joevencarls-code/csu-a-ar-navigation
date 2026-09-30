import '../models/campus_models.dart';

class PathfindingResult {
  final List<int> waypointIds;
  final double totalDistance;

  PathfindingResult(this.waypointIds, this.totalDistance);
}

/// Dijkstra shortest path over the waypoint/path graph. Paths are treated
/// as bidirectional corridors.
class Pathfinder {
  static PathfindingResult? shortestPath({
    required List<Waypoint> waypoints,
    required List<PathEdge> edges,
    required int startId,
    required int endId,
  }) {
    final nodeIds = waypoints.map((w) => w.id).toSet();
    if (!nodeIds.contains(startId) || !nodeIds.contains(endId)) return null;
    if (startId == endId) return PathfindingResult([startId], 0);

    final adjacency = <int, List<(int, double)>>{};
    for (final edge in edges) {
      adjacency
          .putIfAbsent(edge.fromNode, () => [])
          .add((edge.toNode, edge.distance));
      adjacency
          .putIfAbsent(edge.toNode, () => [])
          .add((edge.fromNode, edge.distance));
    }

    final distances = <int, double>{for (final id in nodeIds) id: double.infinity};
    final previous = <int, int>{};
    final unvisited = nodeIds.toSet();
    distances[startId] = 0;

    while (unvisited.isNotEmpty) {
      int? current;
      var best = double.infinity;
      for (final id in unvisited) {
        final d = distances[id]!;
        if (d < best) {
          best = d;
          current = id;
        }
      }
      if (current == null) break;
      unvisited.remove(current);
      if (current == endId) break;

      final neighbors = adjacency[current] ?? <(int, double)>[];
      for (final (neighborId, weight) in neighbors) {
        if (!unvisited.contains(neighborId)) continue;
        final candidate = distances[current]! + weight;
        if (candidate < distances[neighborId]!) {
          distances[neighborId] = candidate;
          previous[neighborId] = current;
        }
      }
    }

    if (distances[endId] == double.infinity) return null;

    final path = <int>[];
    int? node = endId;
    while (node != null) {
      path.add(node);
      if (node == startId) break;
      node = previous[node];
    }
    return PathfindingResult(path.reversed.toList(), distances[endId]!);
  }
}
