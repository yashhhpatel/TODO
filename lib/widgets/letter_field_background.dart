import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../core/route_observer.dart';
import '../core/theme.dart';

class _FloatItem {
  final String text;
  final double fx; // horizontal anchor, fraction of width (0..1)
  final double fy; // vertical anchor within the wrap band, fraction (0..1)
  final double amplitude; // px of horizontal sway
  final double swaySpeed; // rad/sec
  final double phase;
  final double rise; // px/sec upward drift
  final double fadeSpeed; // rad/sec for the opacity breathing
  final double fadePhase;
  final double maxAlpha;
  final double fontSize;
  final double rotation; // fixed subtle tilt, radians
  final bool accent;

  const _FloatItem({
    required this.text,
    required this.fx,
    required this.fy,
    required this.amplitude,
    required this.swaySpeed,
    required this.phase,
    required this.rise,
    required this.fadeSpeed,
    required this.fadePhase,
    required this.maxAlpha,
    required this.fontSize,
    required this.rotation,
    required this.accent,
  });
}

/// Subtle, game-themed animated backdrop for the Home screen.
///
/// Faint letters — and the occasional short word — drift slowly upward with
/// a gentle sway and a slow fade in/out, echoing the letter-grid theme
/// without ever competing with the foreground content. It is purely
/// decorative: it never intercepts touches, uses only the app's existing
/// ink/accent palette at very low opacity, and pauses itself whenever
/// another screen is pushed on top so it costs nothing while off-screen.
class LetterFieldBackground extends StatefulWidget {
  const LetterFieldBackground({super.key});

  @override
  State<LetterFieldBackground> createState() => _LetterFieldBackgroundState();
}

class _LetterFieldBackgroundState extends State<LetterFieldBackground>
    with SingleTickerProviderStateMixin, RouteAware {
  late final Ticker _ticker;
  double _t = 0;
  double _baseT = 0;
  PageRoute<void>? _route;
  late final List<_FloatItem> _items = _generate();

  static const _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _words = ['PLAY', 'FIND', 'WORD', 'SEEK', 'WIN'];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    setState(() => _t = _baseT + elapsed.inMilliseconds / 1000.0);
  }

  List<_FloatItem> _generate() {
    // Fixed seed: a tasteful, reproducible layout every launch rather than a
    // jarringly different scatter each time.
    final rng = Random(7);
    final items = <_FloatItem>[];
    for (int i = 0; i < 14; i++) {
      items.add(_FloatItem(
        text: _letters[rng.nextInt(_letters.length)],
        fx: rng.nextDouble(),
        fy: rng.nextDouble(),
        amplitude: 8 + rng.nextDouble() * 14,
        swaySpeed: 0.15 + rng.nextDouble() * 0.25,
        phase: rng.nextDouble() * 2 * pi,
        rise: 3 + rng.nextDouble() * 5,
        fadeSpeed: 0.12 + rng.nextDouble() * 0.18,
        fadePhase: rng.nextDouble() * 2 * pi,
        maxAlpha: 0.05 + rng.nextDouble() * 0.045,
        fontSize: 22 + rng.nextDouble() * 18,
        rotation: (rng.nextDouble() - 0.5) * 0.3,
        accent: rng.nextDouble() < 0.16,
      ));
    }
    for (int i = 0; i < 3; i++) {
      items.add(_FloatItem(
        text: _words[rng.nextInt(_words.length)],
        fx: rng.nextDouble(),
        fy: rng.nextDouble(),
        amplitude: 6 + rng.nextDouble() * 8,
        swaySpeed: 0.1 + rng.nextDouble() * 0.12,
        phase: rng.nextDouble() * 2 * pi,
        rise: 2 + rng.nextDouble() * 3,
        fadeSpeed: 0.08 + rng.nextDouble() * 0.08,
        fadePhase: rng.nextDouble() * 2 * pi,
        maxAlpha: 0.045 + rng.nextDouble() * 0.03,
        fontSize: 15 + rng.nextDouble() * 4,
        rotation: 0,
        accent: rng.nextDouble() < 0.34,
      ));
    }
    return items;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void> && route != _route) {
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  // Another screen was pushed on top of Home: pause, we're not visible.
  @override
  void didPushNext() {
    _baseT = _t;
    _ticker.stop();
  }

  // Back to Home: resume from where we left off (no jump).
  @override
  void didPopNext() => _ticker.start();

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _LetterFieldPainter(_items, _t),
        ),
      ),
    );
  }
}

class _LetterFieldPainter extends CustomPainter {
  final List<_FloatItem> items;
  final double t;
  _LetterFieldPainter(this.items, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    // Wrap band taller than the viewport so items rising past the top loop
    // back in from below seamlessly, regardless of screen size.
    final band = size.height + 140;

    for (final item in items) {
      final sway = sin(t * item.swaySpeed + item.phase) * item.amplitude;
      final x = item.fx * size.width + sway;
      final rawY = item.fy * band - t * item.rise;
      final y = (rawY % band + band) % band - 70;

      final fade = (sin(t * item.fadeSpeed + item.fadePhase) + 1) / 2;
      final alpha = (item.maxAlpha * (0.3 + 0.7 * fade)).clamp(0.0, 1.0);
      final color =
          (item.accent ? AppColors.accent : AppColors.ink).withOpacity(alpha);

      final tp = TextPainter(
        text: TextSpan(
          text: item.text,
          style: TextStyle(
            fontSize: item.fontSize,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: item.text.length > 1 ? 2 : 0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(x, y);
      if (item.rotation != 0) canvas.rotate(item.rotation);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LetterFieldPainter oldDelegate) =>
      oldDelegate.t != t;
}
