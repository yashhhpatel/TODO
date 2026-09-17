import 'package:flutter/material.dart';
import '../../core/theme.dart';
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

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
          const SizedBox(height: 20),
          ScaleTransition(
            scale: CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
            child: StarRow(count: widget.stars, size: 44),
          ),
          const SizedBox(height: 16),
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
                _row('Base reward', '+${widget.baseCoins}'),
                if (widget.fastBonus > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _row('Fast bonus', '+${widget.fastBonus}',
                        color: AppColors.success),
                  ),
                const Divider(height: 20),
                _row('Total earned', '+$total',
                    bold: true, color: AppColors.coin),
              ],
            ),
          ),
          const SizedBox(height: 16),
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

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.grey700,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        Text(value,
            style: AppTheme.number(bold ? 20 : 16,
                color: color ?? AppColors.ink)),
      ],
    );
  }
}
