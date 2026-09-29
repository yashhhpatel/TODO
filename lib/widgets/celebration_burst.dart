import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A small one-shot particle burst — a lightweight "confetti" effect —
/// driven by an externally owned [progress] animation (0 -> 1). Purely
/// decorative and reused across the app's reward moments (level complete,
/// daily reward claim, achievement unlock) so celebrations share one
/// consistent, light-themed visual language instead of each screen
/// inventing its own.
class CelebrationBurst extends StatelessWidget {
  final Animation<double> progress;
  final double size;
  final int particleCount;
  final List<Color>? colors;

  const CelebrationBurst({
    super.key,
    required this.progress,
    this.size = 160,
    this.particleCount = 14,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => CustomPaint(
          size: Size.square(size),
          painter: _BurstPainter(
            t: progress.value,
            particleCount: particleCount,
            colors: colors ??
                const [
                  AppColors.star,
                  AppColors.accent,
                  AppColors.success,
                  AppColors.coin,
                ],
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double t;
  final int particleCount;
  final List<Color> colors;
  _BurstPainter({
    required this.t,
    required this.particleCount,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return; // nothing to draw before start / after fade
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    for (int i = 0; i < particleCount; i++) {
      final angle = (2 * pi * i) / particleCount + (i.isEven ? 0.15 : -0.1);
      final speed = 0.7 + (i % 3) * 0.15; // slight variety per particle
      final dist = maxRadius * t * speed;
      final pos = center + Offset(cos(angle), sin(angle)) * dist;
      final alpha = (1 - t).clamp(0.0, 1.0);
      final radius = (3.2 - t * 1.6).clamp(0.8, 3.2);
      final color = colors[i % colors.length].withOpacity(alpha * 0.85);
      canvas.drawCircle(pos, radius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => oldDelegate.t != t;
}
