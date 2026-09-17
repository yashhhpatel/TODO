import '../models/word_placement.dart';

/// Derived parameters for a given level number. Pure function of the level
/// number so the whole curve is deterministic and testable.
class DifficultyProfile {
  final int gridSize;
  final int wordCount;
  final int minWordLen;
  final int maxWordLen;
  final int tier; // 1..5
  final List<WordDirection> directions;

  const DifficultyProfile({
    required this.gridSize,
    required this.wordCount,
    required this.minWordLen,
    required this.maxWordLen,
    required this.tier,
    required this.directions,
  });
}

class Difficulty {
  Difficulty._();

  static int _gridSize(int level) {
    if (level <= 5) return 5;
    if (level <= 20) return 6;
    if (level <= 60) return 7;
    if (level <= 150) return 8;
    return 9;
  }

  static int _tier(int level) {
    if (level <= 10) return 1;
    if (level <= 40) return 2;
    if (level <= 120) return 3;
    if (level <= 300) return 4;
    return 5;
  }

  static List<WordDirection> _directions(int tier) {
    switch (tier) {
      case 1:
        return const [WordDirection.right, WordDirection.down];
      case 2:
        return const [
          WordDirection.right,
          WordDirection.down,
          WordDirection.left,
          WordDirection.up,
        ];
      case 3:
        return const [
          WordDirection.right,
          WordDirection.down,
          WordDirection.left,
          WordDirection.up,
          WordDirection.downRight,
          WordDirection.upLeft,
        ];
      default:
        return WordDirection.values; // all 8
    }
  }

  static DifficultyProfile forLevel(int level) {
    final size = _gridSize(level);
    final tier = _tier(level);

    // Word count grows smoothly from 3 toward a cap that fits the grid.
    final grown = 3 + (level ~/ 12);
    final cap = size - 1; // keep comfortably placeable
    final wordCount = grown.clamp(3, cap.clamp(3, 9));

    // Length window widens as levels progress but never exceeds the grid.
    final minLen = level <= 15 ? 3 : (level <= 80 ? 3 : 4);
    var maxLen = 3 + (level ~/ 20);
    maxLen = maxLen.clamp(4, size);

    return DifficultyProfile(
      gridSize: size,
      wordCount: wordCount,
      minWordLen: minLen,
      maxWordLen: maxLen,
      tier: tier,
      directions: _directions(tier),
    );
  }
}
