import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/theme.dart';
import '../../services/player_service.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/common.dart';
import '../achievements/achievements_screen.dart';
import '../daily_reward/daily_reward_screen.dart';
import '../gameplay/gameplay_screen.dart';
import '../level_map/level_map_screen.dart';
import '../premium/premium_screen.dart';
import '../settings/settings_screen.dart';
import '../statistics/statistics_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final current = player.highestUnlocked;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.grid_view_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(AppConfig.appName, style: AppTheme.number(20)),
                    ],
                  ),
                  const Spacer(),
                  CoinPill(coins: player.coins),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  _HeroCard(currentLevel: current),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Streak',
                          value: '${player.currentStreak}d',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStat(
                          icon: Icons.star_rounded,
                          label: 'Stars',
                          value: '${player.starsEarned}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStat(
                          icon: Icons.check_circle_rounded,
                          label: 'Done',
                          value: '${player.levelsCompleted}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _MenuTile(
                        icon: Icons.map_rounded,
                        label: 'Level Map',
                        onTap: () => _push(context, const LevelMapScreen()),
                      ),
                      _MenuTile(
                        icon: Icons.card_giftcard_rounded,
                        label: 'Daily Reward',
                        highlight: player.canClaimDailyReward,
                        onTap: () => _push(context, const DailyRewardScreen()),
                      ),
                      _MenuTile(
                        icon: Icons.emoji_events_rounded,
                        label: 'Achievements',
                        onTap: () => _push(context, const AchievementsScreen()),
                      ),
                      _MenuTile(
                        icon: Icons.insights_rounded,
                        label: 'Statistics',
                        onTap: () => _push(context, const StatisticsScreen()),
                      ),
                      _MenuTile(
                        icon: Icons.workspace_premium_rounded,
                        label: player.premium ? 'Premium ✓' : 'Remove Ads',
                        onTap: () => _push(context, const PremiumScreen()),
                      ),
                      _MenuTile(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        onTap: () => _push(context, const SettingsScreen()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const BannerAdSlot(),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _HeroCard extends StatelessWidget {
  final int currentLevel;
  const _HeroCard({required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURRENT LEVEL',
              style: TextStyle(
                  color: AppColors.grey500,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Level $currentLevel',
              style: AppTheme.number(34, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('of ${AppConfig.totalLevels}',
              style: TextStyle(color: AppColors.grey500, fontSize: 13)),
          const SizedBox(height: 18),
          PrimaryButton(
            label: currentLevel > 1 ? 'Continue' : 'Play',
            icon: Icons.play_arrow_rounded,
            color: Colors.white,
            onTap: () => GameplayScreen.open(context, currentLevel),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MiniStat(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: AppColors.ink, size: 22),
          const SizedBox(height: 6),
          Text(value, style: AppTheme.number(18)),
          Text(label,
              style: const TextStyle(color: AppColors.grey500, fontSize: 11)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: AppColors.ink, size: 26),
              if (highlight)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        color: AppColors.danger, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
