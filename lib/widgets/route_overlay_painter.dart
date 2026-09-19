import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/campus_route.dart';

/// Draws a single [CampusRoutePath] over the campus map image. The route's
/// points are normalized (0..1), so [size] must match the rendered size of
/// the map image exactly for the line to land on the right streets.
///
/// [pathProgress] (0..1) reveals the line progressively, like it's being
/// drawn. Once it reaches 1.0, the destination pin appears and — if
/// [walkerT] is supplied — a small walking-person marker is drawn at that
/// normalized position along the path, meant to be driven by a repeating
/// animation so it loops from start to end once the path finishes drawing.
class RouteOverlayPainter extends CustomPainter {
  final CampusRoutePath route;
  final double pathProgress;
  final double? walkerT;

  RouteOverlayPainter(this.route, {this.pathProgress = 1.0, this.walkerT});

  @override
  void paint(Canvas canvas, Size size) {
    final points = route.points
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();
    if (points.length < 2) return;

    final fullPath = _buildSmoothPath(points);
    final metrics = fullPath.computeMetrics().toList();
    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final visibleLength = totalLength * pathProgress.clamp(0.0, 1.0);
    final visiblePath = _extractPartialPath(metrics, visibleLength);

    final isVehicle = route.mode == RouteMode.vehicle;

    final outline = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isVehicle ? 9 : 7.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(visiblePath, outline);

    final line = Paint()
      ..color = route.mode.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isVehicle ? 5 : 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (isVehicle) {
      canvas.drawPath(visiblePath, line);
    } else {
      _drawDashedPath(canvas, visiblePath, line, dashLength: 10, gapLength: 7);
    }

    _drawStartMarker(canvas, points.first);

    final isFullyDrawn = pathProgress >= 0.999;
    if (isFullyDrawn) {
      _drawEndMarker(canvas, points.last, route.mode.color);
    }

    final t = walkerT;
    if (isFullyDrawn && t != null && metrics.isNotEmpty) {
      final tangent = _tangentAt(metrics, totalLength, t);
      if (tangent != null) {
        _drawWalker(canvas, tangent.position, route.mode.color, route.mode.icon);
      }
    }
  }

  Path _buildSmoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 2) {
      path.lineTo(points.last.dx, points.last.dy);
      return path;
    }
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final isLastSegment = i == points.length - 2;
      final end = isLastSegment
          ? next
          : Offset((current.dx + next.dx) / 2, (current.dy + next.dy) / 2);
      path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
    }
    return path;
  }

  Path _extractPartialPath(List<PathMetric> metrics, double targetLength) {
    final result = Path();
    var remaining = targetLength;
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final take = remaining.clamp(0.0, metric.length);
      result.addPath(metric.extractPath(0, take), Offset.zero);
      remaining -= metric.length;
    }
    return result;
  }

  Tangent? _tangentAt(List<PathMetric> metrics, double totalLength, double t) {
    final target = (totalLength * t.clamp(0.0, 1.0));
    var remaining = target;
    for (final metric in metrics) {
      if (remaining <= metric.length) {
        return metric.getTangentForOffset(remaining);
      }
      remaining -= metric.length;
    }
    final last = metrics.last;
    return last.getTangentForOffset(last.length);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  void _drawStartMarker(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 10, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = const Color(0xFF2979FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(center, 4, Paint()..color = const Color(0xFF2979FF));

    _drawStartLabel(canvas, center);
  }

  void _drawStartLabel(Canvas canvas, Offset dotCenter) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Kiosk is here',
        style: TextStyle(
          color: Color(0xFF0B3D91),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const paddingH = 8.0;
    const paddingV = 5.0;
    const gapFromDot = 14.0;

    final badgeWidth = textPainter.width + paddingH * 2;
    final badgeHeight = textPainter.height + paddingV * 2;
    // Label sits to the right of the dot (not above it), so it stays clear
    // of the route line and doesn't get clipped by the top of the map.
    final badgeLeft = dotCenter.dx + gapFromDot;
    final badgeTop = dotCenter.dy - badgeHeight / 2;
    final badgeRect = Rect.fromLTWH(badgeLeft, badgeTop, badgeWidth, badgeHeight);
    final rrect = RRect.fromRectAndRadius(badgeRect, const Radius.circular(6));

    canvas.drawRRect(
      rrect.shift(const Offset(0, 1.5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF2979FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    textPainter.paint(
      canvas,
      Offset(badgeLeft + paddingH, badgeTop + paddingV),
    );
  }

  void _drawEndMarker(Canvas canvas, Offset tip, Color color) {
    const pinRadius = 11.0;
    final pinCenter = tip - const Offset(0, 24);

    final pinPath = Path()
      ..moveTo(pinCenter.dx - pinRadius * 0.85, pinCenter.dy + pinRadius * 0.55)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(pinCenter.dx + pinRadius * 0.85, pinCenter.dy + pinRadius * 0.55)
      ..close();
    canvas.drawPath(pinPath, Paint()..color = Colors.white);
    canvas.drawPath(
      Path()..addOval(Rect.fromCircle(center: pinCenter, radius: pinRadius + 1.5)),
      Paint()..color = Colors.white,
    );
    canvas.drawPath(pinPath, Paint()..color = color);
    canvas.drawCircle(pinCenter, pinRadius, Paint()..color = color);
    canvas.drawCircle(
      pinCenter,
      pinRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(pinCenter, 4, Paint()..color = Colors.white);
  }

  void _drawWalker(Canvas canvas, Offset position, Color color, IconData icon) {
    const radius = 13.0;
    canvas.drawCircle(position, radius + 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(position, radius, Paint()..color = color);
    canvas.drawCircle(
      position,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 15,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      position - Offset(iconPainter.width / 2, iconPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant RouteOverlayPainter oldDelegate) =>
      oldDelegate.route != route ||
      oldDelegate.pathProgress != pathProgress ||
      oldDelegate.walkerT != walkerT;
}
