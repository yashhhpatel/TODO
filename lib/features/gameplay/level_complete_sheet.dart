import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/celebration_burst.dart';
import '../../widgets/common.dart';

/// Result screen shown when a level is completed. It stays visible until the
/// player explicitly chooses to move on or go home — there is no auto-advance.
class LevelCompleteSheet extends StatefulWidget {
  final int level;
  final int stars;
  final int wordsFound;
  final int totalWords;
  final String time;
  final int baseCoins;
  final int fastBonus;
  final bool canWatchAd;
  final int adBonus;
  final VoidCallback onWatchAd;

  /// Shows a rewarded ad; the passed callback fires only after the ad is
  /// completed successfully, at which point the result becomes 3 stars.
  final void Function(VoidCallback onRewarded) onWatchAdForStars;
  final VoidCallback onNext;
  final VoidCallback onHome;

  const LevelCompleteSheet({
    super.key,
    required this.level,
    required this.stars,
    required this.wordsFound,
    required this.totalWords,
    required this.time,
    required this.baseCoins,
    required this.fastBonus,
    required this.canWatchAd,
    required this.adBonus,
    required this.onWatchAd,
    required this.onWatchAdForStars,
    required this.onNext,
    required this.onHome,
  });

  @override
  State<LevelCompleteSheet> createState() => _LevelCompleteSheetState();
}

class _LevelCompleteSheetState extends State<LevelCompleteSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _adUsed = false;
  late int _stars;
  bool _starsUpgraded = false;

  @override
  void initState() {
    super.initState();
    _stars = widget.stars;
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.baseCoins + widget.fastBonus;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                CelebrationBurst(
                  progress: CurvedAnimation(
                      parent: _c,
                      curve: const Interval(0.1, 1, curve: Curves.easeOut)),
                  size: 220,
                  particleCount: 20,
                ),
                _AnimatedStars(progress: _c, count: _stars, size: 44),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Level ${widget.level} Complete!', style: AppTheme.number(24)),
          const SizedBox(height: 4),
          Text('${widget.wordsFound} / ${widget.totalWords} words found',
              style: const TextStyle(color: AppColors.grey700)),
          const SizedBox(height: 20),
          SoftCard(
            child: Column(
              children: [
                _row('Time', widget.time),
                const Divider(height: 20),
                _countRow('Base reward', widget.baseCoins),
                if (widget.fastBonus > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _countRow('Fast bonus', widget.fastBonus,
                        color: AppColors.success),
                  ),
                const Divider(height: 20),
                _countRow('Total earned', total,
                    bold: true, color: AppColors.coin, delayMs: 200),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_stars < 3 && widget.canWatchAd) ...[
            SecondaryButton(
              label: 'Watch Ad & Get 3 Stars',
              icon: Icons.star_rounded,
              onTap: () {
                widget.onWatchAdForStars(() {
                  if (mounted) {
                    setState(() {
                      _stars = 3;
                      _starsUpgraded = true;
                    });
                    _c
                      ..reset()
                      ..forward();
                  }
                });
              },
            ),
            const SizedBox(height: 10),
          ],
          if (_starsUpgraded) ...[
            const Text('Upgraded to 3 stars!',
                style: TextStyle(
                    color: AppColors.success, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
          ],
          if (widget.canWatchAd && !_adUsed) ...[
            SecondaryButton(
              label: 'Watch Ad  +${widget.adBonus} Coins',
              icon: Icons.play_circle_fill_rounded,
              onTap: () {
                setState(() => _adUsed = true);
                widget.onWatchAd();
              },
            ),
            const SizedBox(height: 10),
          ],
          PrimaryButton(
            label: 'Move to Next Level',
            icon: Icons.arrow_forward_rounded,
            onTap: widget.onNext,
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Return Home',
            icon: Icons.home_rounded,
            onTap: widget.onHome,
          ),
        ],
      ),
    );
  }

  /// Reward row whose number rolls up from 0 once when the sheet appears.
  Widget _countRow(String label, int value,
      {bool bold = false, Color? color, int delayMs = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 900 + delayMs),
      curve: Interval(delayMs / (900 + delayMs), 1, curve: Curves.easeOutCubic),
      builder: (context, v, _) =>
          _row(label, '+${(value * v).round()}', bold: bold, color: color),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.grey700,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        Text(value,
            style:
                AppTheme.number(bold ? 20 : 16, color: color ?? AppColors.ink)),
      ],
    );
  }
}

/// Three stars that pop in one after another with a slight overshoot; the
/// middle star sits a touch higher and larger, like a classic podium.
class _AnimatedStars extends StatelessWidget {
  final Animation<double> progress;
  final int count;
  final double size;
  const _AnimatedStars({
    required this.progress,
    required this.count,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            final on = i < count;
            final start = i * 0.18;
            final local = ((progress.value - start) / 0.5).clamp(0.0, 1.0);
            final scale = Curves.easeOutBack.transform(local);
            final isMiddle = i == 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isMiddle ? 10 : 0),
              child: Transform.scale(
                scale: scale,
                child: Transform.rotate(
                  angle: (1 - local) * (i - 1) * 0.5,
                  child: Icon(
                    on ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: on ? AppColors.star : AppColors.grey300,
                    size: isMiddle ? size * 1.2 : size,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
