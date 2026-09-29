import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../data/achievements_catalog.dart';
import '../../services/player_service.dart';
import '../../widgets/common.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlayerService>();
    final fastest = p.fastestSeconds;
    final fastestLabel = fastest == null
        ? '—'
        : '${(fastest ~/ 60).toString().padLeft(2, '0')}:${(fastest % 60).toString().padLeft(2, '0')}';

    final stats = <({IconData icon, String label, String value})>[
      (
        icon: Icons.flag_rounded,
        label: 'Current Level',
        value: '${p.highestUnlocked}'
      ),
      (
        icon: Icons.check_circle_rounded,
        label: 'Levels Completed',
        value: '${p.levelsCompleted}'
      ),
      (
        icon: Icons.text_fields_rounded,
        label: 'Words Found',
        value: '${p.totalWordsFound}'
      ),
      (icon: Icons.timer_rounded, label: 'Fastest Level', value: fastestLabel),
      (
        icon: Icons.star_rounded,
        label: 'Stars Earned',
        value: '${p.starsEarned}'
      ),
      (
        icon: Icons.monetization_on_rounded,
        label: 'Coins Earned',
        value: '${p.totalCoinsEarned}'
      ),
      (
        icon: Icons.shopping_cart_rounded,
        label: 'Coins Spent',
        value: '${p.totalCoinsSpent}'
      ),
      (
        icon: Icons.local_fire_department_rounded,
        label: 'Current Streak',
        value: '${p.currentStreak}d'
      ),
      (
        icon: Icons.whatshot_rounded,
        label: 'Longest Streak',
        value: '${p.longestStreak}d'
      ),
      (
        icon: Icons.emoji_events_rounded,
        label: 'Achievements',
        value: '${p.unlockedAchievements.length}/${kAchievements.length}'
      ),
    ];

    return ScreenScaffold(
      title: 'Statistics',
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: stats.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, i) {
          final s = stats[i];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 320 + i * 40),
            curve: Curves.easeOutCubic,
            builder: (context, v, c) => Opacity(
              opacity: v,
              child: Transform.translate(
                  offset: Offset(0, (1 - v) * 14), child: c),
            ),
            child: SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(s.icon, color: AppColors.ink, size: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CountUpText(value: s.value, delayIndex: i),
                      const SizedBox(height: 2),
                      Text(s.label,
                          style: const TextStyle(
                              color: AppColors.grey500, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Rolls a stat's leading number up from 0 (keeping any suffix such as
/// "d" or "/40"). Time values like "01:23" are shown as-is.
class _CountUpText extends StatelessWidget {
  final String value;
  final int delayIndex;
  const _CountUpText({required this.value, required this.delayIndex});

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.number(24);
    final match = RegExp(r'^(\d+)(.*)$').firstMatch(value);
    if (match == null || value.contains(':')) return Text(value, style: style);
    final target = int.parse(match.group(1)!);
    final suffix = match.group(2)!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 800 + delayIndex * 40),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text('${(target * v).round()}$suffix', style: style),
    );
  }
}
