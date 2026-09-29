import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/app_route.dart';
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
import '../../widgets/celebration_burst.dart';
import '../../widgets/common.dart';
import 'grid_painter.dart';
import 'level_complete_sheet.dart';

class GameplayScreen extends StatefulWidget {
  final int level;
  const GameplayScreen({super.key, required this.level});

  static void open(BuildContext context, int level) {
    Navigator.of(context).push(
      FadeSlideRoute(builder: (_) => GameplayScreen(level: level)),
    );
  }

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with SingleTickerProviderStateMixin {
  late WordSearchController _controller;
  bool _handled = false;
  bool _navigating = false;

  // Drives the brief "found word" celebration (glow, sparkles, letter pop)
  // on the grid; see grid_painter.dart. Runs once per found word, then idles.
  late final AnimationController _foundPulse;
  late final Animation<double> _foundPulseCurve;
  int _lastFoundCount = 0;
  FoundWord? _pulsingWord;

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
    _foundPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _foundPulseCurve =
        CurvedAnimation(parent: _foundPulse, curve: Curves.easeOut);
    _controller.addListener(_onControllerChanged);
    _controller.start();
  }

  void _onControllerChanged() {
    if (_controller.foundCount > _lastFoundCount) {
      _lastFoundCount = _controller.foundCount;
      if (_controller.foundWords.isNotEmpty) {
        _pulsingWord = _controller.foundWords.last;
        _foundPulse
          ..stop()
          ..reset()
          ..forward();
      }
    }
    if (_controller.isComplete && !_handled) {
      _handled = true;
      _onComplete();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _foundPulse.dispose();
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

    // The result screen stays up until the player chooses; no auto-advance.
    final action = await showModalBottomSheet<String>(
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
        onWatchAdForStars: (onRewarded) =>
            _watchRewardedForStars(level.levelNumber, onRewarded),
        onNext: () => Navigator.of(sheetCtx).pop('next'),
        onHome: () => Navigator.of(sheetCtx).pop('home'),
      ),
    );

    if (!mounted) return;
    for (final a in newAchievements) {
      await _showAchievement(a);
    }
    // Interstitial only happens here — between levels, never during play.
    // Await its dismissal so the NEXT level's timer only starts once the ad
    // is gone and the gameplay screen is actually shown.
    await ads.maybeShowInterstitial(
      completedLevel: level.levelNumber,
      premium: player.premium,
    );
    if (!mounted) return;
    if (action == 'home') {
      _returnHome();
    } else {
      _goToNextLevel();
    }
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

  /// Rewarded ad that upgrades the level to 3 stars. The stars are only
  /// changed and persisted after the ad's reward callback confirms completion.
  void _watchRewardedForStars(int level, VoidCallback onRewarded) {
    final ads = context.read<AdService>();
    final player = context.read<PlayerService>();
    ads.showRewarded(
      onReward: () {
        player.setLevelStars(level, 3);
        context.read<AudioService>().play(Sfx.achievement);
        onRewarded();
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
        FadeSlideRoute(builder: (_) => GameplayScreen(level: next)),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _returnHome() {
    if (_navigating) return;
    _navigating = true;
    Navigator.of(context).pop();
  }

  Future<void> _showAchievement(Achievement a) async {
    context.read<AudioService>().play(Sfx.achievement);
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Achievement',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (ctx, anim, secondaryAnim) => _AchievementDialog(a: a),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  final n = _controller.level.gridSize;

                  // Reserve only a compact strip for the words-to-find list;
                  // the grid takes the rest of the space (width-first) so its
                  // letters stay large and readable even on the biggest grids.
                  final wordReserve = (h * 0.22).clamp(96.0, 170.0);
                  var gridSide = w - 20;
                  final maxByHeight = h - wordReserve - 20;
                  if (gridSide > maxByHeight) gridSide = maxByHeight;

                  var cellSize = gridSide / n;
                  // Cap cell size so small grids keep a comfortable (not
                  // oversized) look; large grids are unaffected.
                  const maxCell = 56.0;
                  if (cellSize > maxCell) {
                    cellSize = maxCell;
                    gridSide = maxCell * n;
                  }
                  if (gridSide < 60) {
                    gridSide = w - 20;
                    cellSize = gridSide / n;
                  }

                  return Column(
                    children: [
                      // Grid + compact word list are vertically centred in the
                      // available space. The grid is sized to fill the width so
                      // higher-level (larger) grids stay prominent and legible.
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildGrid(gridSide, cellSize),
                                const SizedBox(height: 14),
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
          painter: GridPainter(
            _controller,
            _controller.level.gridSize,
            pulse: _foundPulseCurve,
            pulsingWord: _pulsingWord,
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              Text(
                '${_controller.foundCount} / ${_controller.totalWords} words found',
                style: const TextStyle(
                    color: AppColors.grey500,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 140,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    end: _controller.totalWords == 0
                        ? 0
                        : _controller.foundCount / _controller.totalWords,
                  ),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 4,
                      backgroundColor: AppColors.grey200,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: _controller.level.words
                    .map((w) => _WordChip(
                          word: w,
                          found: _controller.isWordFound(w),
                        ))
                    .toList(),
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
              label: 'Hint for Letter',
              icon: Icons.lightbulb_outline_rounded,
              onTap: () => _requestHint(
                title: 'Hint for Letter',
                cost: AppConfig.letterHintCost,
                apply: _controller.useLetterHint,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SecondaryButton(
              label: 'Hint for Word',
              icon: Icons.auto_awesome_rounded,
              onTap: () => _requestHint(
                title: 'Hint for Word',
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

/// Achievement unlock card, shown via a bouncy scale/fade dialog transition.
/// The badge gets a one-shot sparkle burst behind it.
class _AchievementDialog extends StatefulWidget {
  final Achievement a;
  const _AchievementDialog({required this.a});

  @override
  State<_AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<_AchievementDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _burst.forward();
    });
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.a;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 150,
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      CelebrationBurst(
                        progress: CurvedAnimation(
                            parent: _burst, curve: Curves.easeOut),
                        size: 170,
                        particleCount: 16,
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.star.withOpacity(0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(a.icon, color: AppColors.star, size: 38),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('ACHIEVEMENT UNLOCKED',
                    style: TextStyle(
                        color: AppColors.grey500,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(a.title,
                    textAlign: TextAlign.center, style: AppTheme.number(20)),
                const SizedBox(height: 4),
                Text(a.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.grey700)),
                if (a.rewardCoins > 0) ...[
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: a.rewardCoins),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Text('+$v coins',
                        style: AppTheme.number(16, color: AppColors.coin)),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Nice!'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single "words to find" chip. Plays a quick pop/bounce the moment its
/// word transitions from unfound to found, echoing the grid's celebration
/// without duplicating its logic.
class _WordChip extends StatefulWidget {
  final String word;
  final bool found;
  const _WordChip({required this.word, required this.found});

  @override
  State<_WordChip> createState() => _WordChipState();
}

class _WordChipState extends State<_WordChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void didUpdateWidget(covariant _WordChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.found && widget.found) {
      _bounce.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final found = widget.found;
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        final t = _bounce.value;
        final bump = t <= 0.5 ? t / 0.5 : (1 - t) / 0.5;
        return Transform.scale(scale: 1 + bump * 0.22, child: child);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: found ? AppColors.ink : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          widget.word,
          style: TextStyle(
            color: found ? Colors.white : AppColors.grey700,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            decoration:
                found ? TextDecoration.lineThrough : TextDecoration.none,
            decorationColor: Colors.white,
          ),
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 16, color: AppColors.grey700),
                  const SizedBox(width: 5),
                  Text(controller.formattedTime(), style: AppTheme.number(15)),
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
