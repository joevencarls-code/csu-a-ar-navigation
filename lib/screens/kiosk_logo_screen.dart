import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'main_kiosk_screen.dart';

// ─────────────────────────────────────────────────────────────
// Colours: change these to restyle the whole animation
// ─────────────────────────────────────────────────────────────
const Color kNavy = Color(0xFF061230);
const Color kNavyGlow = Color(0xFF0C2A6B);
const Color kYellow = Color(0xFFFFD60A);

/// Left-to-right fill of the wordmark: blue into yellow.
const List<Color> _kColors = <Color>[
  Color(0xFF1747E8), // deep blue at the left edge
  Color(0xFF3A86FF), // bright blue through K-I-O
  Color(0xFFFFD60A), // yellow from the S onwards
  Color(0xFFFFB703), // warmer amber at the right edge
];
// The blue-to-yellow switch sits in the gap between the O and the S, so no
// letter is caught in the muddy middle of the blend.
const List<double> _kStops = <double>[0.0, 0.535, 0.555, 1.0];

// ─────────────────────────────────────────────────────────────
// Geometry of the traced wordmark (units = source-image pixels)
// ─────────────────────────────────────────────────────────────
const double _kLogoW = 521.0;
const double _kLogoH = 95.0;
const double _kSlant = 0.162; // italic lean: horizontal shift per unit of height

// The S and the last K are fused at the top in the original artwork, so they
// are separated with a slanted cut that follows the K's stem.
const double _kRefY = 93.0;
const double _kCutXb = 387.5;

class KioskLogoScreen extends StatefulWidget {
  const KioskLogoScreen({super.key});

  @override
  State<KioskLogoScreen> createState() => _KioskLogoScreenState();
}

class _KioskLogoScreenState extends State<KioskLogoScreen>
    with TickerProviderStateMixin {
  // Intro: letters slide in and settle. Idle: glow pulse + a shine sweep, looping.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  bool _started = false;
  bool _calm = false; // true when the system asks for reduced motion
  bool _going = false;
  Timer? _continueTimer;

  @override
  void initState() {
    super.initState();
    _intro.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        if (!_calm) {
          _idle.repeat();
        }
        _continueLater();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool calm = MediaQuery.of(context).disableAnimations;
    if (!_started || calm != _calm) {
      _started = true;
      _calm = calm;
      _play();
    }
  }

  void _play() {
    _idle.stop();
    _idle.value = 0;
    if (_calm) {
      _intro.value = 1;
      _continueLater();
      return;
    }
    _intro.forward(from: 0);
  }

  void _continueLater() {
    if (_going || _continueTimer != null) return;
    _continueTimer = Timer(const Duration(milliseconds: 1600), _goToKiosk);
  }

  void _goToKiosk() {
    if (!mounted || _going) return;
    _going = true;
    _continueTimer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainKioskScreen()),
    );
  }

  @override
  void dispose() {
    _continueTimer?.cancel();
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goToKiosk,
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              radius: 0.85,
              colors: <Color>[kNavyGlow, kNavy],
            ),
          ),
          child: Center(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final double w = math.min(c.maxWidth * 0.84, 640.0);
                return Semantics(
                  button: true,
                  label: 'KIOSK logo. Tap to continue.',
                  child: SizedBox(
                    width: w,
                    height: w * _kLogoH / _kLogoW,
                    child: CustomPaint(
                      painter: KioskPainter(
                        intro: _intro,
                        idle: _idle,
                        calm: _calm,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────
class KioskPainter extends CustomPainter {
  KioskPainter({
    required this.intro,
    required this.idle,
    required this.calm,
  }) : super(repaint: Listenable.merge(<Listenable>[intro, idle]));

  final Animation<double> intro; // 0..1 over the intro
  final Animation<double> idle; // 0..1, repeating after the intro
  final bool calm;

  static const double _introSeconds = 2.4;
  static const double _stagger = 0.14; // delay between letters
  static const double _letterSeconds = 0.9; // time each letter takes to land

  @override
  void paint(Canvas canvas, Size size) {
    final _Glyphs g = _glyphs;
    canvas.save();
    canvas.scale(size.width / _kLogoW);

    final double t = intro.value * _introSeconds;
    final ui.Shader fill = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(_kLogoW, 0),
      _kColors,
      _kStops,
    );

    // 1) Where is each letter right now?
    final List<Path> moved = <Path>[];
    final List<double> fade = <double>[];
    final List<double> lineAlpha = <double>[];
    final List<double> trail = <double>[];
    final List<double> lead = <double>[]; // x offset of the letter's leading edge
    for (int i = 0; i < g.letters.length; i++) {
      // The rightmost letter leads and the rest trail behind it like a train,
      // so letters spread apart in flight instead of overlapping.
      final int order = g.letters.length - 1 - i;
      final double lp = _c01((t - order * _stagger) / _letterSeconds);
      final double e = Curves.easeOutCubic.transform(lp);
      final double dx = -(1 - e) * _kLogoW * 0.32; // slides in from the left
      final double shear = (1 - e) * 0.6; // leans harder while it moves
      final Matrix4 m = Matrix4.identity()
        ..setEntry(0, 1, -shear)
        ..setTranslationRaw(dx + shear * _kLogoH, 0, 0);
      moved.add(g.letters[i].transform(m.storage));
      fade.add(_c01(lp * 4));
      lineAlpha.add(lp > 0 && lp < 1 ? _c01(lp * 5) * (1 - lp) * 0.9 : 0.0);
      trail.add((1 - e) * 150.0 + 6.0);
      lead.add(dx + shear * _kLogoH * 0.5);
    }

    // 2) Yellow speed lines trailing each letter while it slides in
    for (int i = 0; i < g.letters.length; i++) {
      if (lineAlpha[i] <= 0.01) continue;
      for (int k = 0; k < 3; k++) {
        final double y = _kLogoH * (0.2 + 0.3 * k);
        final double len = trail[i] * (1.0 - 0.28 * k);
        final double xEdge = g.bounds[i].left + lead[i] + _kSlant * (_kLogoH - y);
        final Paint line = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..color = _alpha(kYellow, lineAlpha[i] * (1 - 0.25 * k));
        canvas.drawLine(Offset(xEdge - len, y), Offset(xEdge + 8, y), line);
      }
    }

    // 3) Soft glow behind the wordmark once it has landed
    final double ramp = _c01((t - 1.5) / 0.7);
    final double pulse = calm ? 0.0 : 0.5 + 0.5 * math.sin(idle.value * math.pi * 2);
    final double glow = calm ? 0.28 : ramp * (0.2 + 0.18 * pulse);
    if (glow > 0.01) {
      final Paint glowPaint = Paint()
        ..shader = fill
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 9)
        ..colorFilter = ColorFilter.mode(_alpha(Colors.white, glow), BlendMode.modulate);
      for (final Path p in moved) {
        canvas.drawPath(p, glowPaint);
      }
    }

    // 4) The letters themselves
    for (int i = 0; i < moved.length; i++) {
      final Paint letterPaint = Paint()
        ..shader = fill
        ..isAntiAlias = true;
      if (fade[i] < 1.0) {
        letterPaint.colorFilter =
            ColorFilter.mode(_alpha(Colors.white, fade[i]), BlendMode.modulate);
      }
      canvas.drawPath(moved[i], letterPaint);
    }

    // 5) A bright band sweeps across the finished wordmark every few seconds
    if (!calm && intro.value >= 1.0) {
      const double window = 0.5; // share of the idle loop spent sweeping
      final double p = idle.value;
      if (p < window) {
        final double sp = Curves.easeInOut.transform(p / window);
        final double x = -80 + sp * (_kLogoW + 160);
        const double w = 64.0;
        const double lean = _kSlant * (_kLogoH + 8);
        final Path band = Path()
          ..moveTo(x, _kLogoH + 4)
          ..lineTo(x + w, _kLogoH + 4)
          ..lineTo(x + w + lean, -4)
          ..lineTo(x + lean, -4)
          ..close();
        final ui.Shader sheen = ui.Gradient.linear(
          Offset(x, 0),
          Offset(x + w + lean, 0),
          const <Color>[Color(0x00FFFFFF), Color(0xCCFFFFFF), Color(0x00FFFFFF)],
          const <double>[0.0, 0.5, 1.0],
        );
        canvas.save();
        canvas.clipPath(g.all);
        canvas.drawPath(band, Paint()..shader = sheen);
        canvas.restore();
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant KioskPainter old) => old.calm != calm;
}

double _c01(double v) => v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);

Color _alpha(Color c, double o) => c.withAlpha((_c01(o) * 255).round());

// ─────────────────────────────────────────────────────────────
// Glyphs: K, I, O, S, K as separate paths
// ─────────────────────────────────────────────────────────────
class _Glyphs {
  _Glyphs(this.letters, this.all)
      : bounds = letters.map((Path p) => p.getBounds()).toList();

  final List<Path> letters;
  final Path all;
  final List<Rect> bounds;
}

final _Glyphs _glyphs = _buildGlyphs();

_Glyphs _buildGlyphs() {
  final Path k1 = _buildPath(_kGlyphK1);
  final Path i = _buildPath(_kGlyphI);
  final Path o = _buildPath(_kGlyphO);
  final Path sk = _buildPath(_kGlyphSK);
  // Split the fused "SK". The K gets a 0.8-unit overlap so no hairline shows.
  final Path s = Path.combine(ui.PathOperation.intersect, sk, _slab(-100.0, _kCutXb));
  final Path k2 = Path.combine(ui.PathOperation.intersect, sk, _slab(_kCutXb - 0.8, 700.0));
  final List<Path> letters = <Path>[k1, i, o, s, k2];
  final Path all = Path();
  for (final Path p in letters) {
    all.addPath(p, Offset.zero);
  }
  return _Glyphs(letters, all);
}

/// A slanted vertical strip between two italic lines (given by their x at _kRefY).
Path _slab(double xbLeft, double xbRight) {
  const double y0 = -10.0;
  const double y1 = _kLogoH + 10.0;
  double xAt(double xb, double y) => xb + _kSlant * (_kRefY - y);
  return Path()
    ..moveTo(xAt(xbLeft, y0), y0)
    ..lineTo(xAt(xbRight, y0), y0)
    ..lineTo(xAt(xbRight, y1), y1)
    ..lineTo(xAt(xbLeft, y1), y1)
    ..close();
}

/// Reads path data: 0 = moveTo x y, 1 = lineTo x y, 2 = cubicTo x1 y1 x2 y2 x y, 3 = close.
Path _buildPath(List<double> d) {
  final Path p = Path();
  int i = 0;
  while (i < d.length) {
    final int op = d[i].toInt();
    i++;
    switch (op) {
      case 0:
        p.moveTo(d[i], d[i + 1]);
        i += 2;
        break;
      case 1:
        p.lineTo(d[i], d[i + 1]);
        i += 2;
        break;
      case 2:
        p.cubicTo(d[i], d[i + 1], d[i + 2], d[i + 3], d[i + 4], d[i + 5]);
        i += 6;
        break;
      default:
        p.close();
        break;
    }
  }
  return p;
}

// ─────────────────────────────────────────────────────────────
// Traced outline data (generated from the logo image)
// ─────────────────────────────────────────────────────────────
const List<double> _kGlyphK1 = <double>[
  0, 1.0, 94.1, 2, 0.1, 94.1, -0.0, 93.5, 0.5, 91.1, 2, 0.7, 90.2, 0.9,
  88.9, 1.0, 88.3, 2, 1.1, 87.7, 1.3, 86.4, 1.5, 85.5, 2, 1.7, 84.6, 1.9,
  83.3, 2.0, 82.6, 2, 2.1, 82.0, 2.3, 80.7, 2.5, 79.8, 2, 2.7, 78.9, 2.9,
  77.7, 3.0, 77.0, 2, 3.1, 76.3, 3.3, 75.1, 3.5, 74.1, 2, 3.7, 73.2, 3.9,
  71.9, 4.0, 71.3, 2, 4.1, 70.7, 4.3, 69.4, 4.5, 68.5, 2, 4.7, 67.6, 4.9,
  66.3, 5.0, 65.8, 2, 5.1, 65.2, 5.3, 63.7, 5.6, 62.6, 2, 5.8, 61.4, 6.0,
  59.9, 6.1, 59.3, 2, 6.2, 58.7, 6.4, 57.7, 6.5, 57.2, 2, 6.6, 56.6, 6.8,
  55.4, 7.0, 54.4, 2, 7.1, 53.5, 7.4, 52.2, 7.5, 51.5, 2, 7.6, 50.9, 7.9,
  49.6, 8.0, 48.7, 2, 8.1, 47.8, 8.4, 46.4, 8.5, 45.6, 2, 8.7, 44.8, 8.9,
  43.7, 9.0, 43.0, 2, 9.1, 42.3, 9.3, 41.1, 9.5, 40.2, 2, 9.7, 39.3, 9.9,
  38.0, 10.0, 37.4, 2, 10.1, 36.7, 10.3, 35.5, 10.5, 34.6, 2, 10.7, 33.7, 10.9,
  32.4, 11.0, 31.8, 2, 11.1, 31.1, 11.3, 29.6, 11.6, 28.5, 2, 11.8, 27.4, 12.0,
  26.3, 12.0, 26.1, 2, 12.0, 25.9, 12.2, 24.9, 12.4, 23.9, 2, 12.6, 22.9, 12.9,
  21.3, 13.0, 20.3, 2, 13.1, 19.4, 13.4, 18.0, 13.6, 17.3, 2, 13.7, 16.5, 13.9,
  15.4, 14.0, 14.8, 2, 14.1, 14.2, 14.3, 12.9, 14.5, 11.9, 2, 14.7, 11.0, 14.9,
  9.7, 15.0, 9.1, 2, 15.1, 8.5, 15.3, 7.2, 15.5, 6.2, 2, 15.7, 5.3, 16.0,
  3.8, 16.1, 2.9, 2, 16.3, 1.1, 16.5, 0.7, 16.9, 0.3, 2, 17.3, 0.0, 47.3,
  -0.2, 48.0, 0.1, 2, 48.7, 0.4, 48.8, 0.7, 48.5, 2.0, 2, 48.4, 2.6, 48.1,
  3.8, 48.0, 4.8, 2, 47.9, 5.7, 47.6, 7.0, 47.5, 7.5, 2, 47.4, 8.1, 47.2,
  9.3, 47.1, 10.1, 2, 46.9, 10.9, 46.7, 12.3, 46.5, 13.2, 2, 46.3, 14.2, 46.1,
  15.4, 46.0, 16.0, 2, 45.9, 16.6, 45.7, 17.9, 45.5, 18.9, 2, 45.3, 19.9, 45.1,
  21.2, 45.0, 21.8, 2, 44.9, 22.3, 44.7, 23.4, 44.6, 24.2, 2, 44.4, 24.9, 44.2,
  26.1, 44.1, 26.9, 2, 44.0, 27.7, 43.8, 28.8, 43.6, 29.4, 2, 42.5, 34.8, 42.6,
  34.9, 47.4, 31.0, 2, 48.3, 30.2, 49.7, 29.1, 50.4, 28.6, 2, 51.4, 27.8, 54.1,
  25.7, 56.9, 23.4, 2, 57.5, 23.0, 58.4, 22.2, 58.9, 21.8, 2, 59.5, 21.4, 60.6,
  20.5, 61.4, 19.9, 2, 62.2, 19.2, 63.3, 18.3, 63.9, 17.9, 2, 64.5, 17.4, 65.7,
  16.4, 66.7, 15.6, 2, 71.7, 11.7, 74.7, 9.3, 75.3, 8.8, 2, 76.1, 8.2, 79.3,
  5.6, 81.5, 3.9, 2, 83.9, 2.0, 86.2, 0.2, 86.4, 0.1, 2, 86.8, -0.0, 130.4,
  -0.1, 130.7, 0.0, 2, 131.6, 0.4, 131.4, 0.7, 128.7, 2.8, 2, 126.4, 4.7, 124.3,
  6.4, 123.0, 7.4, 2, 120.4, 9.4, 117.3, 11.9, 116.5, 12.6, 2, 115.6, 13.3, 113.7,
  14.8, 109.4, 18.2, 2, 108.4, 19.0, 107.2, 20.0, 106.7, 20.4, 2, 106.2, 20.7, 105.1,
  21.6, 104.2, 22.4, 2, 103.3, 23.1, 102.0, 24.1, 101.4, 24.6, 2, 100.7, 25.1, 99.2,
  26.3, 98.0, 27.3, 2, 96.8, 28.3, 94.7, 29.9, 93.3, 31.0, 2, 91.9, 32.1, 90.0,
  33.7, 89.1, 34.4, 2, 88.1, 35.2, 86.9, 36.2, 86.4, 36.5, 2, 85.9, 36.9, 85.0,
  37.6, 84.4, 38.1, 2, 83.7, 38.7, 81.9, 40.1, 80.3, 41.4, 2, 78.8, 42.6, 77.5,
  43.7, 77.4, 43.9, 2, 77.0, 44.6, 77.4, 45.1, 83.1, 51.5, 2, 85.9, 54.6, 87.1,
  56.0, 89.0, 58.1, 2, 92.7, 62.3, 96.1, 66.2, 98.8, 69.2, 2, 100.3, 70.8, 102.0,
  72.8, 102.6, 73.5, 2, 103.3, 74.3, 104.4, 75.6, 105.2, 76.4, 2, 105.9, 77.3, 107.7,
  79.3, 109.2, 80.9, 2, 110.6, 82.6, 112.9, 85.2, 114.3, 86.8, 2, 120.6, 93.8, 120.3,
  93.4, 119.8, 94.0, 2, 119.4, 94.4, 80.1, 94.4, 79.3, 94.0, 2, 78.8, 93.8, 75.0,
  89.7, 70.6, 84.5, 2, 69.9, 83.7, 68.2, 81.8, 66.9, 80.3, 2, 65.5, 78.8, 63.9,
  76.9, 63.2, 76.1, 2, 62.5, 75.3, 61.0, 73.6, 59.9, 72.4, 2, 58.7, 71.1, 57.3,
  69.4, 56.6, 68.7, 2, 54.3, 66.0, 52.6, 64.1, 52.4, 64.1, 2, 51.9, 63.9, 51.3,
  64.1, 50.8, 64.5, 2, 50.5, 64.8, 49.8, 65.3, 49.2, 65.8, 2, 48.6, 66.3, 47.6,
  67.1, 46.9, 67.6, 2, 46.3, 68.1, 44.9, 69.3, 43.8, 70.2, 2, 35.3, 76.9, 35.3,
  76.9, 35.1, 78.0, 2, 35.1, 78.4, 34.9, 79.4, 34.7, 80.3, 2, 34.5, 81.2, 34.3,
  82.5, 34.2, 83.1, 2, 34.1, 83.8, 33.8, 85.5, 33.5, 86.9, 2, 33.2, 88.3, 32.9,
  90.0, 32.8, 90.8, 2, 32.4, 93.4, 32.1, 94.0, 31.0, 94.2, 2, 30.5, 94.3, 1.9,
  94.2, 1.0, 94.1, 3,
];

const List<double> _kGlyphI = <double>[
  0, 122.4, 94.1, 2, 121.8, 93.9, 121.8, 92.4, 122.5, 90.0, 2, 122.6, 89.4, 122.8,
  88.1, 122.9, 87.3, 2, 123.0, 86.4, 123.3, 85.2, 123.4, 84.6, 2, 123.6, 84.0, 123.8,
  82.7, 123.9, 81.7, 2, 124.0, 80.8, 124.3, 79.6, 124.4, 78.9, 2, 124.6, 78.3, 124.8,
  77.2, 124.9, 76.4, 2, 125.0, 75.7, 125.2, 74.4, 125.4, 73.6, 2, 125.6, 72.8, 125.8,
  71.6, 125.9, 70.8, 2, 126.0, 70.1, 126.2, 68.9, 126.4, 68.0, 2, 126.6, 67.1, 126.8,
  65.9, 126.9, 65.2, 2, 127.0, 64.6, 127.2, 63.4, 127.3, 62.7, 2, 127.5, 61.9, 127.7,
  60.7, 127.8, 59.9, 2, 127.9, 59.2, 128.2, 57.7, 128.4, 56.7, 2, 128.6, 55.7, 128.8,
  54.6, 128.8, 54.2, 2, 128.9, 53.9, 129.1, 52.5, 129.4, 51.0, 2, 129.6, 49.5, 130.1,
  47.2, 130.3, 45.8, 2, 132.3, 34.4, 132.1, 35.2, 133.2, 35.0, 2, 134.1, 34.8, 163.0,
  34.8, 163.5, 35.0, 2, 164.3, 35.2, 164.4, 35.6, 164.3, 36.5, 2, 164.2, 37.0, 164.1,
  37.7, 164.1, 38.2, 2, 164.0, 38.7, 163.8, 39.9, 163.6, 40.9, 2, 163.3, 41.9, 163.1,
  43.2, 163.1, 43.8, 2, 163.0, 44.3, 162.8, 45.6, 162.6, 46.6, 2, 162.3, 47.6, 162.1,
  49.0, 162.0, 49.8, 2, 161.9, 50.5, 161.7, 51.7, 161.5, 52.6, 2, 161.3, 53.4, 161.1,
  54.7, 161.0, 55.5, 2, 160.9, 56.2, 160.7, 57.4, 160.6, 58.1, 2, 160.4, 58.7, 160.1,
  60.1, 160.0, 61.1, 2, 159.9, 62.2, 159.6, 63.5, 159.5, 64.0, 2, 159.4, 64.6, 159.1,
  65.9, 159.0, 66.9, 2, 158.8, 67.9, 158.6, 69.3, 158.4, 70.0, 2, 158.3, 70.7, 158.1,
  71.8, 158.0, 72.4, 2, 157.9, 73.0, 157.7, 74.4, 157.4, 75.6, 2, 157.2, 76.8, 157.0,
  78.1, 156.9, 78.4, 2, 156.9, 78.7, 156.6, 80.1, 156.4, 81.6, 2, 156.1, 83.0, 155.7,
  85.5, 155.4, 87.1, 2, 154.2, 93.9, 154.2, 93.8, 153.6, 94.1, 2, 153.3, 94.3, 122.8,
  94.3, 122.4, 94.1, 3,
];

const List<double> _kGlyphO = <double>[
  0, 203.1, 94.2, 2, 197.9, 93.9, 194.8, 93.3, 188.8, 91.1, 2, 185.9, 90.2, 182.8,
  88.7, 181.6, 87.7, 2, 181.1, 87.4, 180.3, 86.7, 179.7, 86.3, 2, 176.1, 83.6, 176.1,
  83.6, 174.1, 81.2, 2, 170.7, 77.4, 168.4, 73.0, 166.9, 67.5, 2, 166.7, 66.6, 166.5,
  65.8, 166.4, 65.6, 2, 166.3, 65.3, 165.8, 62.2, 165.3, 58.5, 2, 165.1, 56.6, 165.2,
  53.3, 165.6, 51.2, 2, 165.7, 50.6, 165.8, 49.4, 165.9, 48.6, 2, 166.1, 47.7, 166.3,
  46.5, 166.4, 45.9, 2, 166.6, 45.2, 166.8, 44.0, 167.0, 43.1, 2, 167.2, 42.1, 167.5,
  40.8, 167.9, 39.7, 2, 168.2, 38.7, 168.7, 37.5, 168.9, 36.9, 2, 169.3, 35.6, 169.7,
  35.2, 170.5, 35.0, 2, 171.4, 34.8, 203.2, 34.8, 203.6, 35.1, 2, 204.2, 35.4, 204.1,
  35.8, 203.3, 36.8, 2, 200.5, 40.5, 198.9, 44.2, 198.3, 49.0, 2, 197.4, 56.2, 202.2,
  64.1, 208.7, 66.0, 2, 209.1, 66.1, 209.8, 66.4, 210.3, 66.5, 2, 210.8, 66.7, 211.8,
  66.9, 212.4, 67.0, 2, 213.1, 67.1, 214.1, 67.2, 214.5, 67.2, 2, 215.6, 67.4, 229.2,
  67.2, 232.2, 66.9, 2, 239.2, 66.4, 246.8, 62.5, 249.9, 57.7, 2, 253.2, 52.8, 253.8,
  51.4, 254.8, 47.2, 2, 256.7, 38.7, 251.5, 29.9, 243.2, 27.9, 2, 239.6, 27.1, 244.0,
  27.1, 186.8, 27.1, 2, 147.0, 27.1, 135.0, 27.1, 134.6, 27.0, 2, 133.7, 26.7, 133.7,
  25.9, 134.4, 22.8, 2, 134.7, 21.8, 134.9, 20.6, 134.9, 20.1, 2, 135.0, 19.5, 135.2,
  18.4, 135.4, 17.6, 2, 135.6, 16.7, 135.8, 15.5, 135.9, 14.8, 2, 136.0, 14.1, 136.1,
  13.2, 136.2, 12.8, 2, 136.4, 12.0, 136.7, 10.2, 137.8, 3.6, 2, 138.3, 0.6, 138.3,
  0.5, 138.9, 0.2, 2, 139.3, -0.1, 141.6, -0.1, 193.6, -0.1, 2, 249.4, -0.1, 252.0,
  -0.1, 254.3, 0.4, 2, 254.9, 0.5, 256.1, 0.7, 256.8, 0.8, 2, 257.6, 0.9, 258.6,
  1.1, 259.0, 1.3, 2, 259.4, 1.4, 260.2, 1.6, 260.9, 1.8, 2, 264.5, 2.7, 269.8,
  5.0, 271.6, 6.3, 2, 272.2, 6.7, 273.1, 7.3, 273.5, 7.6, 2, 274.7, 8.4, 277.0,
  10.3, 277.4, 10.8, 2, 277.6, 11.0, 278.3, 11.8, 278.9, 12.5, 2, 281.3, 15.0, 282.1,
  16.2, 283.6, 18.9, 2, 285.7, 23.0, 286.6, 25.4, 287.1, 28.4, 2, 287.3, 29.3, 287.5,
  30.6, 287.7, 31.4, 2, 287.8, 32.3, 288.1, 33.8, 288.1, 35.0, 2, 288.2, 36.1, 288.3,
  37.1, 288.3, 37.1, 2, 288.4, 37.3, 288.1, 42.5, 287.9, 44.8, 2, 287.8, 46.7, 287.2,
  49.4, 286.5, 51.3, 2, 286.4, 51.7, 286.2, 52.4, 286.1, 52.8, 2, 285.0, 57.2, 281.2,
  65.3, 278.8, 68.4, 2, 278.4, 68.9, 277.9, 69.6, 277.6, 70.0, 2, 276.0, 72.4, 274.7,
  73.9, 271.5, 77.2, 2, 268.0, 80.7, 267.7, 81.0, 264.4, 83.3, 2, 260.7, 85.8, 259.7,
  86.4, 258.3, 87.1, 2, 257.6, 87.4, 256.0, 88.2, 254.8, 88.7, 2, 251.7, 90.3, 250.6,
  90.7, 249.2, 91.1, 2, 248.5, 91.2, 247.6, 91.5, 247.0, 91.7, 2, 246.5, 91.8, 245.9,
  92.0, 245.6, 92.1, 2, 245.4, 92.1, 244.6, 92.3, 243.9, 92.6, 2, 241.7, 93.3, 238.6,
  93.7, 233.3, 94.1, 2, 230.6, 94.4, 207.2, 94.4, 203.1, 94.2, 3,
];

const List<double> _kGlyphSK = <double>[
  0, 310.1, 94.2, 2, 305.5, 93.8, 305.5, 93.8, 301.7, 92.5, 2, 299.7, 91.9, 298.9,
  91.5, 295.7, 89.5, 2, 293.1, 88.0, 288.7, 83.0, 287.5, 80.2, 2, 286.7, 78.3, 286.0,
  76.4, 285.9, 75.6, 2, 285.0, 70.3, 285.0, 70.3, 285.4, 67.7, 2, 285.6, 66.7, 285.8,
  65.4, 285.8, 64.9, 2, 286.0, 62.6, 284.3, 62.9, 302.5, 62.9, 2, 320.1, 62.9, 318.5,
  62.8, 318.7, 64.1, 2, 318.9, 65.7, 319.4, 66.5, 320.5, 66.8, 2, 321.4, 67.0, 353.0,
  67.0, 353.9, 66.8, 2, 355.8, 66.2, 357.0, 64.7, 357.2, 62.4, 2, 357.4, 60.1, 355.7,
  59.4, 349.5, 59.1, 2, 346.9, 59.0, 345.0, 58.8, 341.2, 58.4, 2, 340.2, 58.3, 338.2,
  58.2, 336.8, 58.1, 2, 334.0, 58.0, 333.1, 57.9, 329.0, 57.5, 2, 327.7, 57.4, 325.4,
  57.2, 324.1, 57.1, 2, 320.8, 57.0, 318.9, 56.8, 317.0, 56.5, 2, 316.2, 56.4, 314.7,
  56.2, 313.8, 56.1, 2, 312.8, 56.0, 311.6, 55.9, 311.1, 55.7, 2, 310.6, 55.6, 309.4,
  55.3, 308.5, 55.1, 2, 302.7, 53.9, 297.8, 50.8, 294.5, 46.5, 2, 293.4, 45.1, 292.1,
  41.6, 291.9, 39.7, 2, 291.8, 38.9, 291.7, 37.7, 291.5, 37.0, 2, 291.3, 35.7, 291.3,
  35.5, 291.5, 33.4, 2, 291.7, 32.2, 291.8, 30.7, 291.8, 30.2, 2, 292.0, 28.3, 292.5,
  25.9, 293.7, 22.7, 2, 295.4, 17.8, 300.8, 11.1, 306.0, 7.4, 2, 306.8, 6.9, 307.7,
  6.3, 308.0, 6.0, 2, 309.9, 4.6, 314.8, 2.4, 317.0, 1.9, 2, 317.6, 1.8, 318.4,
  1.5, 318.7, 1.4, 2, 319.5, 1.1, 322.7, 0.4, 325.2, 0.1, 2, 327.4, -0.2, 436.4,
  -0.3, 437.2, 0.0, 2, 437.9, 0.3, 438.0, 0.6, 437.6, 2.1, 2, 437.3, 2.8, 437.2,
  3.5, 437.1, 4.6, 2, 437.0, 5.8, 436.9, 6.5, 436.6, 7.5, 2, 436.4, 8.4, 436.2,
  9.3, 436.1, 10.3, 2, 436.0, 11.3, 435.9, 12.2, 435.6, 13.1, 2, 435.4, 13.9, 435.2,
  15.0, 435.1, 15.9, 2, 435.0, 17.4, 434.9, 18.0, 434.5, 19.2, 2, 434.4, 19.7, 434.2,
  20.7, 434.1, 21.5, 2, 434.0, 22.3, 433.8, 23.6, 433.6, 24.3, 2, 433.4, 25.1, 433.2,
  26.3, 433.1, 27.0, 2, 433.0, 27.7, 432.8, 29.0, 432.6, 29.8, 2, 431.5, 34.1, 431.9,
  34.2, 435.7, 31.2, 2, 437.1, 30.1, 439.2, 28.4, 440.4, 27.4, 2, 441.7, 26.5, 443.7,
  24.9, 444.9, 23.9, 2, 446.1, 23.0, 448.2, 21.3, 449.6, 20.2, 2, 451.0, 19.1, 453.0,
  17.5, 454.0, 16.7, 2, 455.1, 15.9, 456.5, 14.8, 457.1, 14.2, 2, 457.8, 13.7, 459.0,
  12.8, 459.8, 12.2, 2, 460.5, 11.6, 462.3, 10.1, 463.7, 9.0, 2, 465.2, 7.9, 467.2,
  6.3, 468.2, 5.4, 2, 469.3, 4.6, 470.6, 3.6, 471.1, 3.2, 2, 471.5, 2.9, 472.6,
  2.0, 473.5, 1.3, 2, 474.3, 0.7, 475.2, 0.1, 475.4, -0.0, 2, 476.0, -0.2, 519.4,
  -0.2, 519.8, -0.0, 2, 520.7, 0.3, 520.4, 0.8, 518.5, 2.3, 2, 517.8, 2.9, 516.4,
  3.9, 515.4, 4.7, 2, 513.6, 6.2, 511.7, 7.7, 509.4, 9.5, 2, 508.7, 10.1, 507.3,
  11.2, 506.4, 11.9, 2, 505.5, 12.7, 504.4, 13.5, 503.9, 13.9, 2, 503.3, 14.4, 497.4,
  19.0, 491.0, 24.2, 2, 489.6, 25.3, 485.5, 28.6, 481.9, 31.4, 2, 469.3, 41.5, 467.3,
  43.1, 466.8, 43.5, 2, 465.9, 44.4, 465.9, 44.5, 468.0, 46.8, 2, 469.0, 47.8, 470.7,
  49.7, 471.7, 50.9, 2, 472.8, 52.2, 474.6, 54.2, 475.7, 55.4, 2, 476.9, 56.7, 478.4,
  58.4, 479.1, 59.2, 2, 479.8, 60.1, 481.3, 61.8, 482.4, 63.0, 2, 483.5, 64.2, 485.3,
  66.2, 486.3, 67.4, 2, 487.3, 68.6, 488.7, 70.1, 489.2, 70.7, 2, 489.8, 71.3, 491.1,
  72.8, 492.2, 74.0, 2, 493.2, 75.2, 495.0, 77.3, 496.2, 78.6, 2, 497.4, 79.9, 499.2,
  82.0, 500.4, 83.3, 2, 501.5, 84.6, 502.8, 86.1, 503.4, 86.7, 2, 504.7, 88.1, 508.8,
  92.8, 509.0, 93.2, 2, 509.2, 93.6, 509.2, 94.0, 508.8, 94.2, 2, 508.3, 94.5, 468.5,
  94.4, 467.9, 94.1, 2, 467.4, 93.9, 465.3, 91.5, 461.8, 87.5, 2, 461.1, 86.7, 459.5,
  84.9, 458.2, 83.4, 2, 456.9, 81.9, 455.2, 80.0, 454.6, 79.2, 2, 453.2, 77.7, 449.8,
  73.8, 444.6, 67.9, 2, 440.5, 63.3, 441.3, 63.4, 437.3, 66.7, 2, 436.4, 67.4, 435.2,
  68.4, 434.6, 68.9, 2, 424.4, 77.0, 424.3, 77.1, 424.1, 78.8, 2, 424.0, 79.4, 423.8,
  80.6, 423.6, 81.5, 2, 423.4, 82.4, 423.2, 83.7, 423.1, 84.5, 2, 422.9, 85.3, 422.7,
  86.5, 422.5, 87.2, 2, 422.4, 88.0, 422.2, 89.1, 422.1, 89.8, 2, 421.6, 92.7, 421.2,
  93.9, 420.6, 94.2, 2, 419.9, 94.6, 389.4, 94.4, 389.1, 94.0, 2, 388.7, 93.5, 388.8,
  91.5, 389.4, 89.8, 2, 389.6, 88.9, 389.8, 88.0, 389.9, 86.9, 2, 390.0, 85.9, 390.1,
  85.0, 390.4, 84.1, 2, 390.6, 83.2, 390.8, 82.3, 390.9, 81.3, 2, 391.0, 80.3, 391.1,
  79.4, 391.4, 78.5, 2, 391.6, 77.6, 391.8, 76.7, 391.9, 75.7, 2, 392.0, 74.7, 392.1,
  73.8, 392.4, 72.9, 2, 392.6, 72.0, 392.8, 71.1, 392.9, 70.1, 2, 393.0, 69.0, 393.1,
  68.2, 393.4, 67.3, 2, 393.6, 66.4, 393.8, 65.6, 393.9, 64.5, 2, 394.0, 63.4, 394.1,
  62.5, 394.4, 61.7, 2, 394.6, 60.8, 394.8, 60.0, 394.9, 58.9, 2, 395.0, 57.9, 395.1,
  57.0, 395.4, 56.1, 2, 395.6, 55.2, 395.8, 54.3, 395.9, 53.3, 2, 395.9, 52.3, 396.1,
  51.4, 396.4, 50.5, 2, 396.6, 49.6, 396.8, 48.7, 396.9, 47.7, 2, 397.0, 46.7, 397.1,
  45.8, 397.4, 44.9, 2, 397.6, 44.0, 397.8, 43.1, 397.9, 42.1, 2, 398.0, 41.1, 398.1,
  40.1, 398.4, 39.2, 2, 398.6, 38.3, 398.8, 37.5, 398.9, 36.4, 2, 399.0, 35.4, 399.1,
  34.5, 399.4, 33.6, 2, 399.6, 32.7, 399.8, 31.9, 399.9, 30.9, 2, 399.9, 30.2, 400.1,
  29.2, 400.2, 28.7, 2, 400.4, 27.7, 400.4, 27.7, 400.1, 27.5, 2, 399.8, 27.1, 330.4,
  26.9, 328.5, 27.3, 2, 325.1, 27.8, 322.9, 31.4, 324.8, 33.5, 2, 325.7, 34.5, 326.5,
  34.7, 328.9, 34.9, 2, 331.6, 35.0, 332.3, 35.1, 335.8, 35.4, 2, 337.5, 35.6, 340.1,
  35.8, 341.6, 35.9, 2, 343.1, 36.0, 346.0, 36.2, 348.0, 36.4, 2, 350.0, 36.6, 352.9,
  36.8, 354.4, 36.9, 2, 357.5, 37.0, 360.5, 37.3, 363.6, 37.7, 2, 364.3, 37.8, 365.4,
  37.9, 366.1, 38.0, 2, 367.2, 38.1, 369.8, 38.7, 371.3, 39.1, 2, 371.8, 39.3, 372.9,
  39.6, 373.8, 39.8, 2, 374.7, 40.1, 375.6, 40.4, 375.8, 40.5, 2, 376.1, 40.6, 376.5,
  40.8, 376.6, 40.8, 2, 379.5, 41.7, 382.9, 43.9, 384.7, 46.2, 2, 385.1, 46.7, 385.8,
  47.6, 386.2, 48.1, 2, 386.7, 48.6, 387.1, 49.4, 387.5, 50.1, 2, 387.7, 50.8, 388.2,
  51.8, 388.5, 52.4, 2, 388.9, 53.3, 389.0, 53.9, 389.2, 54.8, 2, 389.3, 55.5, 389.5,
  56.6, 389.6, 57.1, 2, 390.1, 59.0, 390.1, 59.6, 389.5, 64.1, 2, 389.4, 65.2, 389.2,
  66.6, 389.1, 67.3, 2, 389.0, 68.2, 388.9, 68.9, 388.7, 69.5, 2, 388.5, 69.9, 388.3,
  70.8, 388.1, 71.3, 2, 387.7, 73.1, 385.6, 77.4, 384.6, 78.6, 2, 381.5, 82.4, 377.5,
  86.2, 375.6, 87.3, 2, 372.1, 89.4, 371.5, 89.7, 370.4, 90.2, 2, 368.3, 91.1, 367.7,
  91.4, 367.2, 91.6, 2, 366.6, 91.9, 363.0, 92.9, 361.9, 93.1, 2, 361.5, 93.2, 360.7,
  93.4, 360.3, 93.5, 2, 359.6, 93.7, 357.9, 94.0, 354.5, 94.2, 2, 352.6, 94.4, 311.7,
  94.4, 310.1, 94.2, 3,
];