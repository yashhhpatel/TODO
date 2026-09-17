import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/theme.dart';
import '../../game/level_generator.dart';
import '../../game/reward_calculator.dart';
import '../../game/word_search_controller.dart';
import '../../models/achievement.dart';
import '../../models/grid_position.dart';
import '../../services/ad_service.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';
import '../../services/player_service.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/common.dart';
import 'grid_painter.dart';
import 'level_complete_sheet.dart';

class GameplayScreen extends StatefulWidget {
  final int level;
  const GameplayScreen({super.key, required this.level});

  static void open(BuildContext context, int level) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameplayScreen(level: level)),
    );
  }

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late WordSearchController _controller;
  bool _handled = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    final gen = context.read<LevelGenerator>();
    final level = gen.generate(widget.level);
    _controller = WordSearchController(
      level: level,
      audio: context.read<AudioService>(),
      haptics: context.read<HapticService>(),
    );
    _controller.addListener(_onControllerChanged);
    _controller.start();
  }

  void _onControllerChanged() {
    if (_controller.isComplete && !_handled) {
      _handled = true;
      _onComplete();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  GridPos _posFromOffset(Offset local, double cellSize) {
    final size = _controller.level.gridSize;
    int col = (local.dx / cellSize).floor().clamp(0, size - 1);
    int row = (local.dy / cellSize).floor().clamp(0, size - 1);
    return GridPos(row, col);
  }

  Future<void> _onComplete() async {
    final player = context.read<PlayerService>();
    final ads = context.read<AdService>();
    final level = _controller.level;
    final reward = RewardCalculator.compute(
      level: level,
      elapsedSeconds: _controller.elapsedSeconds,
    );
    context.read<AudioService>().play(Sfx.coin);

    final newAchievements = player.applyLevelResult(
      level: level.levelNumber,
      stars: reward.stars,
      rewardCoins: reward.total,
      wordsFound: level.placements.length,
      seconds: _controller.elapsedSeconds,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => LevelCompleteSheet(
        level: level.levelNumber,
        stars: reward.stars,
        wordsFound: level.placements.length,
        totalWords: level.placements.length,
        time: _controller.formattedTime(),
        baseCoins: reward.base,
        fastBonus: reward.fastBonus,
        canWatchAd: ads.isInitialized,
        adBonus: AppConfig.levelCompleteAdBonus,
        onWatchAd: _watchRewardedForBonus,
        onNext: () => Navigator.of(sheetCtx).pop(),
      ),
    );

    if (!mounted) return;
    for (final a in newAchievements) {
      await _showAchievement(a);
    }
    // Interstitial only happens here — between levels, never during play.
    ads.maybeShowInterstitial(
      completedLevel: level.levelNumber,
      premium: player.premium,
    );
    _goToNextLevel();
  }

  void _watchRewardedForBonus() {
    final ads = context.read<AdService>();
    final player = context.read<PlayerService>();
    ads.showRewarded(
      onReward: () {
        player.addCoins(AppConfig.levelCompleteAdBonus, 'rewarded_ad');
        context.read<AudioService>().play(Sfx.coin);
        _snack('+${AppConfig.levelCompleteAdBonus} coins!');
      },
      onUnavailable: () => _snack('Ad not available right now'),
    );
  }

  void _goToNextLevel() {
    if (_navigating) return;
    _navigating = true;
    final next = widget.level + 1;
    if (next <= AppConfig.totalLevels) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GameplayScreen(level: next)),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showAchievement(Achievement a) async {
    context.read<AudioService>().play(Sfx.achievement);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(a.icon, color: AppColors.star, size: 38),
            ),
            const SizedBox(height: 16),
            const Text('Achievement Unlocked!',
                style: TextStyle(color: AppColors.grey500, fontSize: 12)),
            const SizedBox(height: 4),
            Text(a.title, style: AppTheme.number(20)),
            const SizedBox(height: 4),
            Text(a.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey700)),
            if (a.rewardCoins > 0) ...[
              const SizedBox(height: 8),
              Text('+${a.rewardCoins} coins',
                  style: AppTheme.number(16, color: AppColors.coin)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Nice!'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  // ---- Hints ----
  Future<void> _requestHint({
    required String title,
    required int cost,
    required bool Function() apply,
  }) async {
    final player = context.read<PlayerService>();
    final ads = context.read<AdService>();
    final canPay = player.coins >= cost;
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(canPay
            ? 'Use $cost coins for this hint?'
            : 'Not enough coins. Watch an ad to get this hint free?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('CANCEL'),
          ),
          if (canPay)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'coins'),
              child: Text('USE $cost'),
            ),
          if (!canPay && ads.isRewardedReady)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'ad'),
              child: const Text('WATCH AD'),
            ),
        ],
      ),
    );
    if (action == 'coins') {
      if (player.spendCoins(cost)) {
        if (!apply()) _snack('No hint available');
      }
    } else if (action == 'ad') {
      ads.showRewarded(
        onReward: () {
          if (!apply()) _snack('No hint available');
        },
        onUnavailable: () => _snack('Ad not available right now'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(controller: _controller, coins: player.coins),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gridSide = _minD(
                    constraints.maxWidth - 32,
                    constraints.maxHeight * 0.5,
                  );
                  final cellSize = gridSide / _controller.level.gridSize;
                  return Column(
                    children: [
                      // Grid + word list are vertically centred in the
                      // available space so the grid sits comfortably below the
                      // header rather than hugging the top.
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildGrid(gridSide, cellSize),
                                const SizedBox(height: 28),
                                _buildWordList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildHintBar(),
                    ],
                  );
                },
              ),
            ),
            const BannerAdSlot(),
          ],
        ),
      ),
    );
  }

  double _minD(double a, double b) => a < b ? a : b;

  Widget _buildGrid(double side, double cellSize) {
    return SizedBox(
      width: side,
      height: side,
      child: GestureDetector(
        onPanStart: (d) =>
            _controller.beginAt(_posFromOffset(d.localPosition, cellSize)),
        onPanUpdate: (d) =>
            _controller.extendTo(_posFromOffset(d.localPosition, cellSize)),
        onPanEnd: (_) => _controller.endSelection(),
        onTapUp: (d) =>
            _controller.tapCell(_posFromOffset(d.localPosition, cellSize)),
        child: CustomPaint(
          painter: GridPainter(_controller, _controller.level.gridSize),
          size: Size.square(side),
        ),
      ),
    );
  }

  Widget _buildWordList() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                '${_controller.foundCount} / ${_controller.totalWords} words found',
                style: const TextStyle(
                    color: AppColors.grey500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _controller.level.words.map((w) {
                  final found = _controller.isWordFound(w);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: found ? AppColors.ink : AppColors.grey100,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      w,
                      style: TextStyle(
                        color: found ? Colors.white : AppColors.grey700,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        decoration: found
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHintBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Letter (${AppConfig.letterHintCost})',
              icon: Icons.lightbulb_outline_rounded,
              onTap: () => _requestHint(
                title: 'Letter Hint',
                cost: AppConfig.letterHintCost,
                apply: _controller.useLetterHint,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SecondaryButton(
              label: 'Word (${AppConfig.wordHintCost})',
              icon: Icons.auto_awesome_rounded,
              onTap: () => _requestHint(
                title: 'Word Hint',
                cost: AppConfig.wordHintCost,
                apply: _controller.useWordHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final WordSearchController controller;
  final int coins;
  const _TopBar({required this.controller, required this.coins});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LEVEL ${controller.level.levelNumber}',
                  style: const TextStyle(
                      color: AppColors.grey500,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600)),
              Text(controller.level.category,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 16, color: AppColors.grey700),
                  const SizedBox(width: 5),
                  Text(controller.formattedTime(),
                      style: AppTheme.number(15)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CoinPill(coins: coins),
        ],
      ),
    );
  }
}
