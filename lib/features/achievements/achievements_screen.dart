import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../data/achievements_catalog.dart';
import '../../models/achievement.dart';
import '../../services/player_service.dart';
import '../../widgets/common.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final unlocked = player.unlockedAchievements.length;

    return ScreenScaffold(
      title: 'Achievements',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Text('$unlocked / ${kAchievements.length} unlocked',
                    style: const TextStyle(
                        color: AppColors.grey700,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: kAchievements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final a = kAchievements[i];
                return _AchievementCard(
                  achievement: a,
                  unlocked: player.isAchievementUnlocked(a.id),
                  progress: player.achievementProgress(a),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final double progress;
  const _AchievementCard({
    required this.achievement,
    required this.unlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: unlocked ? AppColors.ink : AppColors.grey100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              achievement.icon,
              color: unlocked ? AppColors.star : AppColors.grey500,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(achievement.description,
                    style: const TextStyle(
                        color: AppColors.grey500, fontSize: 12)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.grey200,
                    valueColor: AlwaysStoppedAnimation(
                        unlocked ? AppColors.success : AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (unlocked)
            const Icon(Icons.check_circle_rounded, color: AppColors.success)
          else
            Text('+${achievement.rewardCoins}',
                style: AppTheme.number(13, color: AppColors.coin)),
        ],
      ),
    );
  }
}
