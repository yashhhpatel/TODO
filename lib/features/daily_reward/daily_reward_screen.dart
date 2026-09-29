import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../services/notification_service.dart';
import '../../services/player_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/celebration_burst.dart';
import '../../widgets/common.dart';

class DailyRewardScreen extends StatefulWidget {
  const DailyRewardScreen({super.key});

  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// Which day card the celebration burst is centred on.
  int? _burstIndex;

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _claim(PlayerService player) {
    final claimingIndex = player.pendingDailyIndex;
    final result = player.claimDailyReward();
    if (result == null) return;
    setState(() => _burstIndex = claimingIndex);
    _burst.forward(from: 0);
    context.read<AudioService>().play(Sfx.coin);
    // Already claimed today -> next reminder is tomorrow.
    context.read<NotificationService>().scheduleDailyReminder(
          enabled: context.read<SettingsService>().notifications,
          claimedToday: true,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Claimed +${result.reward} coins!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
                clipBehavior: Clip.none,
                itemCount: PlayerService.dailyRewardTable.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, i) {
                  final reward = PlayerService.dailyRewardTable[i];
                  final isToday = canClaim && i == pending;
                  final claimedDay = !canClaim && i == player.dailyDayIndex;
                  return _Entrance(
                    index: i,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: _DayCard(
                            day: i + 1,
                            reward: reward,
                            isToday: isToday,
                            claimed: claimedDay,
                            isBig:
                                i == PlayerService.dailyRewardTable.length - 1,
                          ),
                        ),
                        if (_burstIndex == i)
                          CelebrationBurst(
                            progress: CurvedAnimation(
                                parent: _burst, curve: Curves.easeOut),
                            size: 180,
                            particleCount: 18,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: canClaim
                  ? 'Claim Day ${pending + 1} (+${PlayerService.dailyRewardTable[pending]})'
                  : 'Come back tomorrow',
              icon: canClaim
                  ? Icons.card_giftcard_rounded
                  : Icons.schedule_rounded,
              onTap: canClaim ? () => _claim(player) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fade + slight scale-up entrance, staggered by grid position.
class _Entrance extends StatelessWidget {
  final int index;
  final Widget child;
  const _Entrance({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 45),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) => Opacity(
        opacity: v,
        child: Transform.scale(scale: 0.9 + 0.1 * v, child: c),
      ),
      child: child,
    );
  }
}

class _DayCard extends StatefulWidget {
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
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> with TickerProviderStateMixin {
  // Only the claimable "today" card breathes; others never tick.
  AnimationController? _breath;

  @override
  void initState() {
    super.initState();
    _syncBreath();
  }

  @override
  void didUpdateWidget(covariant _DayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isToday != widget.isToday) _syncBreath();
  }

  void _syncBreath() {
    if (widget.isToday && _breath == null) {
      _breath = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    } else if (!widget.isToday && _breath != null) {
      _breath!.dispose();
      _breath = null;
    }
  }

  @override
  void dispose() {
    _breath?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isToday = widget.isToday;
    final claimed = widget.claimed;
    final bg = isToday
        ? AppColors.accent
        : claimed
            ? AppColors.ink
            : AppColors.card;
    final fg = (isToday || claimed) ? Colors.white : AppColors.ink;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isToday ? AppColors.accent : AppColors.grey200,
          width: isToday ? 2 : 1,
        ),
        boxShadow: [
          if (isToday)
            BoxShadow(
              color: AppColors.accent.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('DAY ${widget.day}',
              style: TextStyle(
                  color: fg.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              claimed
                  ? Icons.check_circle_rounded
                  : Icons.monetization_on_rounded,
              key: ValueKey(claimed),
              color: claimed ? Colors.white : AppColors.coin,
              size: widget.isBig ? 34 : 28,
            ),
          ),
          const SizedBox(height: 4),
          Text('${widget.reward}',
              style: AppTheme.number(widget.isBig ? 18 : 15, color: fg)),
        ],
      ),
    );

    final breath = _breath;
    if (breath == null) return card;
    return AnimatedBuilder(
      animation: breath,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.035 * Curves.easeInOut.transform(breath.value),
        child: child,
      ),
      child: card,
    );
  }
}
