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

class _MenuEntry {
  final IconData icon;
  final String label;
  final WidgetBuilder builder;
  const _MenuEntry(this.icon, this.label, this.builder);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final current = player.highestUnlocked;

    // Overflow menu keeps the two secondary destinations.
    final menuEntries = <_MenuEntry>[
      _MenuEntry(Icons.workspace_premium_rounded,
          player.premium ? 'Premium' : 'Remove Ads',
          (_) => const PremiumScreen()),
      _MenuEntry(Icons.settings_rounded, 'Settings',
          (_) => const SettingsScreen()),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
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
                  const Spacer(),
                  CoinPill(coins: player.coins),
                  const SizedBox(width: 10),
                  _HomeMenuButton(entries: menuEntries),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Two cards above the Level section.
                      Row(
                        children: [
                          Expanded(
                            child: _HomeCard(
                              icon: Icons.map_rounded,
                              label: 'Level Map',
                              onTap: () =>
                                  _push(context, const LevelMapScreen()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _HomeCard(
                              icon: Icons.card_giftcard_rounded,
                              label: 'Daily Reward',
                              highlight: player.canClaimDailyReward,
                              onTap: () =>
                                  _push(context, const DailyRewardScreen()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Centered Level section.
                      _HeroCard(currentLevel: current),
                      const SizedBox(height: 16),
                      // Streak / Stars / Done — directly below the Level section.
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
                      const SizedBox(height: 16),
                      // Two cards below.
                      Row(
                        children: [
                          Expanded(
                            child: _HomeCard(
                              icon: Icons.emoji_events_rounded,
                              label: 'Achievements',
                              onTap: () =>
                                  _push(context, const AchievementsScreen()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _HomeCard(
                              icon: Icons.insights_rounded,
                              label: 'Statistics',
                              onTap: () =>
                                  _push(context, const StatisticsScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const BannerAdSlot(),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;
  const _HomeCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.ink, size: 26),
              ),
              if (highlight)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.card, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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

class _HomeMenuButton extends StatelessWidget {
  final List<_MenuEntry> entries;
  const _HomeMenuButton({required this.entries});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Menu',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      color: AppColors.card,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: const BorderSide(color: AppColors.grey200),
      ),
      onSelected: (i) => Navigator.of(context)
          .push(MaterialPageRoute(builder: entries[i].builder)),
      itemBuilder: (context) => [
        for (int i = 0; i < entries.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              children: [
                Icon(entries[i].icon, color: AppColors.ink, size: 22),
                const SizedBox(width: 14),
                Text(entries[i].label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
      ],
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey200),
        ),
        child: const Icon(Icons.menu_rounded, color: AppColors.ink),
      ),
    );
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
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Start',
            icon: Icons.play_arrow_rounded,
            color: Colors.white,
            large: true,
            onTap: () => GameplayScreen.open(context, currentLevel),
          ),
        ],
      ),
    );
  }
}
