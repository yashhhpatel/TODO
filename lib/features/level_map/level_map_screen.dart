import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/theme.dart';
import '../../services/player_service.dart';
import '../../widgets/common.dart';
import '../gameplay/gameplay_screen.dart';

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});
  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  static const double _itemExtent = 108;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _scrollToCurrent() {
    final current = context.read<PlayerService>().highestUnlocked;
    final target = ((current - 1) * _itemExtent) - 240;
    _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    return ScreenScaffold(
      title: 'Level Map',
      actions: [
        Center(
            child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CoinPill(coins: player.coins),
        )),
      ],
      body: ListView.builder(
        controller: _scroll,
        itemExtent: _itemExtent,
        itemCount: AppConfig.totalLevels,
        itemBuilder: (context, index) {
          final level = index + 1;
          return _LevelNodeItem(
            level: level,
            index: index,
            stars: player.starsFor(level),
            completed: player.isCompleted(level),
            unlocked: player.isUnlocked(level),
            isCurrent: level == player.highestUnlocked,
            onTap: () {
              if (player.isUnlocked(level)) {
                GameplayScreen.open(context, level);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Complete earlier levels to unlock this one'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _LevelNodeItem extends StatelessWidget {
  final int level;
  final int index;
  final int stars;
  final bool completed;
  final bool unlocked;
  final bool isCurrent;
  final VoidCallback onTap;

  const _LevelNodeItem({
    required this.level,
    required this.index,
    required this.stars,
    required this.completed,
    required this.unlocked,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Zigzag offset that connects through the horizontal center at each edge.
    final width = MediaQuery.of(context).size.width;
    final amp = width * 0.28;
    final nodeX = width / 2 + amp * sin(index * 0.9);

    // Nodes fade in softly as they scroll into view.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (context, v, c) => Opacity(opacity: v, child: c),
      child: CustomPaint(
        painter: _PathPainter(nodeX: nodeX, centerX: width / 2),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: nodeX - 34,
              top: (108 - 68) / 2,
              child: _NodeCircle(
                level: level,
                stars: stars,
                completed: completed,
                unlocked: unlocked,
                isCurrent: isCurrent,
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final double nodeX;
  final double centerX;
  _PathPainter({required this.nodeX, required this.centerX});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grey300
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final midY = size.height / 2;
    canvas.drawLine(Offset(centerX, 0), Offset(nodeX, midY), paint);
    canvas.drawLine(Offset(nodeX, midY), Offset(centerX, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) =>
      old.nodeX != nodeX || old.centerX != centerX;
}

class _NodeCircle extends StatelessWidget {
  final int level;
  final int stars;
  final bool completed;
  final bool unlocked;
  final bool isCurrent;
  final VoidCallback onTap;

  const _NodeCircle({
    required this.level,
    required this.stars,
    required this.completed,
    required this.unlocked,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (completed) {
      bg = AppColors.ink;
      fg = Colors.white;
    } else if (isCurrent) {
      bg = AppColors.accent;
      fg = Colors.white;
    } else if (unlocked) {
      bg = AppColors.card;
      fg = AppColors.ink;
    } else {
      bg = AppColors.grey200;
      fg = AppColors.grey500;
    }

    final circle = Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent ? AppColors.accent : AppColors.grey200,
          width: isCurrent ? 3 : 1.5,
        ),
        boxShadow: [
          if (unlocked)
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Center(
        child: !unlocked
            ? Icon(Icons.lock_rounded, color: fg, size: 24)
            : completed
                ? Icon(Icons.check_rounded, color: fg, size: 28)
                : Text('$level', style: AppTheme.number(20, color: fg)),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isCurrent ? _CurrentPulse(child: circle) : circle,
          const SizedBox(height: 2),
          if (completed)
            StarRow(count: stars, size: 13)
          else if (isCurrent)
            const Text('PLAY',
                style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
        ],
      ),
    );
  }
}

/// Soft repeating ripple + gentle breathing scale that marks the level the
/// player should play next. Only the single current node ever animates.
class _CurrentPulse extends StatefulWidget {
  final Widget child;
  const _CurrentPulse({required this.child});

  @override
  State<_CurrentPulse> createState() => _CurrentPulseState();
}

class _CurrentPulseState extends State<_CurrentPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final breath = 1 + 0.04 * sin(t * 2 * pi);
        final ring = Curves.easeOut.transform(t);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -13 * ring,
              top: -13 * ring,
              width: 68 + 26 * ring,
              height: 68 + 26 * ring,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.45 * (1 - ring)),
                    width: 2,
                  ),
                ),
              ),
            ),
            Transform.scale(scale: breath, child: child),
          ],
        );
      },
      child: widget.child,
    );
  }
}
