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

  /// Number of target words, growing with level and capped by the grid.
  static int _wordCount(int level, int size) {
    int c;
    if (level <= 3) {
      c = 3;
    } else if (level <= 10) {
      c = 4;
    } else if (level <= 25) {
      c = 5;
    } else if (level <= 60) {
      c = 6;
    } else {
      c = 7;
    }
    // Never ask for more words than comfortably fit the grid.
    return c.clamp(3, size - 1);
  }

  /// Staged word-length band. Starts at strictly 3-letter words, then widens
  /// after ~5 levels to 4, then 5, then longer — a smooth difficulty ramp.
  static ({int min, int max}) _lengthBand(int level, int size) {
    int lo, hi;
    if (level <= 5) {
      lo = 3;
      hi = 3;
    } else if (level <= 12) {
      lo = 3;
      hi = 4;
    } else if (level <= 25) {
      lo = 4;
      hi = 5;
    } else if (level <= 45) {
      lo = 4;
      hi = 6;
    } else if (level <= 90) {
      lo = 5;
      hi = 7;
    } else if (level <= 180) {
      lo = 5;
      hi = 8;
    } else {
      lo = 6;
      hi = 9;
    }
    // A word can never be longer than the grid.
    hi = hi > size ? size : hi;
    if (lo > hi) lo = hi;
    return (min: lo, max: hi);
  }

  static DifficultyProfile forLevel(int level) {
    final size = _gridSize(level);
    final tier = _tier(level);
    final band = _lengthBand(level, size);

    return DifficultyProfile(
      gridSize: size,
      wordCount: _wordCount(level, size),
      minWordLen: band.min,
      maxWordLen: band.max,
      tier: tier,
      directions: _directions(tier),
    );
  }
}
