import '../models/level_definition.dart';

class RewardResult {
  final int stars; // 1..3
  final int base;
  final int fastBonus;
  int get total => base + fastBonus;

  const RewardResult({
    required this.stars,
    required this.base,
    required this.fastBonus,
  });
}

/// Deterministic, always-non-negative reward + star computation.
class RewardCalculator {
  RewardCalculator._();

  static int baseReward({
    required int tier,
    required int wordCount,
    required int gridSize,
  }) {
    final r = 20 + tier * 10 + wordCount * 5 + (gridSize - 5) * 5;
    return r < 10 ? 10 : r;
  }

  /// Star time thresholds derived from level shape.
  static ({int three, int two}) starThresholds({
    required int wordCount,
    required int gridSize,
  }) {
    final three = 8 + wordCount * 6 + (gridSize - 5) * 3;
    return (three: three, two: three * 2);
  }

  static RewardResult compute({
    required LevelDefinition level,
    required int elapsedSeconds,
  }) {
    final t = elapsedSeconds < 0 ? 0 : elapsedSeconds;
    int stars;
    int bonus;
    if (t <= level.threeStarSeconds) {
      stars = 3;
      bonus = (level.baseReward * 0.5).round();
    } else if (t <= level.twoStarSeconds) {
      stars = 2;
      bonus = (level.baseReward * 0.2).round();
    } else {
      stars = 1;
      bonus = 0;
    }
    return RewardResult(stars: stars, base: level.baseReward, fastBonus: bonus);
  }
}
