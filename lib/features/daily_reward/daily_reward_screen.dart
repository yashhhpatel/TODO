import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../services/notification_service.dart';
import '../../services/player_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/common.dart';

class DailyRewardScreen extends StatelessWidget {
  const DailyRewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final canClaim = player.canClaimDailyReward;
    final pending = player.pendingDailyIndex;

    return ScreenScaffold(
      title: 'Daily Reward',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Come back every day', style: AppTheme.number(22)),
            const SizedBox(height: 6),
            const Text(
              'Claim a reward each day. Miss a day and the cycle restarts.',
              style: TextStyle(color: AppColors.grey700),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: PlayerService.dailyRewardTable.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, i) {
                  final reward = PlayerService.dailyRewardTable[i];
                  final isToday = canClaim && i == pending;
                  final claimedDay = !canClaim && i == player.dailyDayIndex;
                  return _DayCard(
                    day: i + 1,
                    reward: reward,
                    isToday: isToday,
                    claimed: claimedDay,
                    isBig: i == PlayerService.dailyRewardTable.length - 1,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: canClaim
                  ? 'Claim Day ${pending + 1} (+${PlayerService.dailyRewardTable[pending]})'
                  : 'Come back tomorrow',
              icon: canClaim ? Icons.card_giftcard_rounded : Icons.schedule_rounded,
              onTap: canClaim
                  ? () {
                      final result = player.claimDailyReward();
                      if (result != null) {
                        context.read<AudioService>().play(Sfx.coin);
                        // Already claimed today -> next reminder is tomorrow.
                        context
                            .read<NotificationService>()
                            .scheduleDailyReminder(
                              enabled: context.read<SettingsService>().notifications,
                              claimedToday: true,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Claimed +${result.reward} coins!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final int day;
  final int reward;
  final bool isToday;
  final bool claimed;
  final bool isBig;
  const _DayCard({
    required this.day,
    required this.reward,
    required this.isToday,
    required this.claimed,
    required this.isBig,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isToday
        ? AppColors.accent
        : claimed
            ? AppColors.ink
            : AppColors.card;
    final fg = (isToday || claimed) ? Colors.white : AppColors.ink;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isToday ? AppColors.accent : AppColors.grey200,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('DAY $day',
              style: TextStyle(
                  color: fg.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Icon(
            claimed ? Icons.check_circle_rounded : Icons.monetization_on_rounded,
            color: claimed ? Colors.white : AppColors.coin,
            size: isBig ? 34 : 28,
          ),
          const SizedBox(height: 4),
          Text('$reward', style: AppTheme.number(isBig ? 18 : 15, color: fg)),
        ],
      ),
    );
  }
}
