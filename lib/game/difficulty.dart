import '../models/word_placement.dart';

/// Derived parameters for a given level number. Grid size and word length are
/// fixed per range exactly as specified — every target word in a level has the
/// same, exact length.
class DifficultyProfile {
  final int gridSize;
  final int wordCount;
  final int wordLength; // exact length every target word must have
  final int tier; // 1..5 (controls allowed directions)
  final List<WordDirection> directions;

  const DifficultyProfile({
    required this.gridSize,
    required this.wordCount,
    required this.wordLength,
    required this.tier,
    required this.directions,
  });

  int get minWordLen => wordLength;
  int get maxWordLen => wordLength;
}

class Difficulty {
  Difficulty._();

  /// (gridSize, exact word length) for each level range — the exact spec.
  static ({int grid, int len}) _gridAndLength(int level) {
    if (level <= 25) return (grid: 6, len: 4);
    if (level <= 50) return (grid: 7, len: 5);
    if (level <= 75) return (grid: 8, len: 6);
    if (level <= 100) return (grid: 9, len: 7);
    if (level <= 150) return (grid: 10, len: 8);
    if (level <= 200) return (grid: 11, len: 9);
    if (level <= 300) return (grid: 12, len: 10);
    if (level <= 500) return (grid: 13, len: 11);
    return (grid: 14, len: 12); // 501..1000
  }

  /// Target word count per range, rising gently so difficulty grows on top of
  /// the increasing grid size / word length. Always fits the grid.
  static int _wordCount(int level, int grid) {
    int c;
    if (level <= 25) {
      c = 4;
    } else if (level <= 75) {
      c = 5;
    } else if (level <= 200) {
      c = 5;
    } else {
      c = 6;
    }
    return c.clamp(3, grid - 1);
  }

  static int _tier(int level) {
    if (level <= 25) return 1;
    if (level <= 75) return 2;
    if (level <= 150) return 3;
    if (level <= 300) return 4;
    return 5;
  }

  /// All 8 directions (horizontal, vertical and both diagonals, each way) are
  /// available on every level so words can be generated — and found — in any
  /// direction. Difficulty still ramps via grid size, word length and count.
  static List<WordDirection> _directions() => WordDirection.values;

  static DifficultyProfile forLevel(int level) {
    final gl = _gridAndLength(level);
    final tier = _tier(level);
    return DifficultyProfile(
      gridSize: gl.grid,
      wordCount: _wordCount(level, gl.grid),
      wordLength: gl.len,
      tier: tier,
      directions: _directions(),
    );
  }
}
