import '../models/word_placement.dart';

/// Derived parameters for a given level number: grid size, the word-length
/// window, the number of target words, the allowed placement directions and a
/// difficulty tier. See [Difficulty] for the full 1..1000 progression.
class DifficultyProfile {
  final int gridSize;
  final int wordCount;
  final int minWordLen;
  final int maxWordLen;
  final int tier; // 1..8, drives reward scaling
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

/// Complete Word Finder difficulty progression for every level from 1 to 1000.
///
/// The design ramps five dimensions smoothly, with no sudden jumps:
///  - grid size:        6 -> 15
///  - word length:      4 -> 12 letters (widening windows in between)
///  - target words:     4 -> 9
///  - placement dirs:   forward-only -> +reverse -> +one diagonal -> all 8
///  - overall:          Level 1000 is dramatically harder than Level 1
///
/// Full table (grid, word-length window, word count, placement):
///
///   Lvl 1–5      6x6   4        4 words   right/down (easiest)
///   Lvl 6–10     6x6   4        4 words   +reverse (left/up)
///   Lvl 11–20    6x6   4–5      5 words   +reverse
///   Lvl 21–30    7x7   5        5 words   +one diagonal pair
///   Lvl 31–40    7x7   5–6      5 words   +one diagonal pair
///   Lvl 41–50    8x8   6        6 words   +one diagonal pair
///   Lvl 51–75    8x8   6–7      6 words   all 8 directions
///   Lvl 76–100   9x9   7        6 words   all 8
///   Lvl 101–150  9x9   7–8      6 words   all 8
///   Lvl 151–200  10x10 8        7 words   all 8
///   Lvl 201–275  10x10 8–9      7 words   all 8
///   Lvl 276–350  11x11 9        7 words   all 8
///   Lvl 351–450  11x11 9–10     7 words   all 8
///   Lvl 451–550  12x12 10       8 words   all 8
///   Lvl 551–650  12x12 10–11    8 words   all 8
///   Lvl 651–750  13x13 11       8 words   all 8
///   Lvl 751–850  13x13 11–12    8 words   all 8
///   Lvl 851–950  14x14 12       9 words   all 8
///   Lvl 951–1000 15x15 12       9 words   all 8 (hardest)
class Difficulty {
  Difficulty._();

  /// Grid size + inclusive word-length window per level range.
  static ({int grid, int min, int max}) _gridAndLength(int level) {
    if (level <= 10) return (grid: 6, min: 4, max: 4);
    if (level <= 20) return (grid: 6, min: 4, max: 5);
    if (level <= 30) return (grid: 7, min: 5, max: 5);
    if (level <= 40) return (grid: 7, min: 5, max: 6);
    if (level <= 50) return (grid: 8, min: 6, max: 6);
    if (level <= 75) return (grid: 8, min: 6, max: 7);
    if (level <= 100) return (grid: 9, min: 7, max: 7);
    if (level <= 150) return (grid: 9, min: 7, max: 8);
    if (level <= 200) return (grid: 10, min: 8, max: 8);
    if (level <= 275) return (grid: 10, min: 8, max: 9);
    if (level <= 350) return (grid: 11, min: 9, max: 9);
    if (level <= 450) return (grid: 11, min: 9, max: 10);
    if (level <= 550) return (grid: 12, min: 10, max: 10);
    if (level <= 650) return (grid: 12, min: 10, max: 11);
    if (level <= 750) return (grid: 13, min: 11, max: 11);
    if (level <= 850) return (grid: 13, min: 11, max: 12);
    if (level <= 950) return (grid: 14, min: 12, max: 12);
    return (grid: 15, min: 12, max: 12); // 951..1000 — hardest
  }

  /// Number of target words, rising gently and always fitting the grid.
  static int _wordCount(int level, int grid) {
    int c;
    if (level <= 10) {
      c = 4;
    } else if (level <= 40) {
      c = 5;
    } else if (level <= 150) {
      c = 6;
    } else if (level <= 450) {
      c = 7;
    } else if (level <= 850) {
      c = 8;
    } else {
      c = 9;
    }
    return c.clamp(3, grid - 1);
  }

  /// Placement difficulty ramp — early levels are beginner-friendly (forward
  /// only), then reverse words appear, then diagonals, then all 8 directions.
  static List<WordDirection> _directions(int level) {
    if (level <= 5) {
      // Forward horizontal / vertical only.
      return const [WordDirection.right, WordDirection.down];
    }
    if (level <= 20) {
      // Add reverse (backwards) words.
      return const [
        WordDirection.right,
        WordDirection.down,
        WordDirection.left,
        WordDirection.up,
      ];
    }
    if (level <= 50) {
      // Introduce one diagonal axis (both ways).
      return const [
        WordDirection.right,
        WordDirection.down,
        WordDirection.left,
        WordDirection.up,
        WordDirection.downRight,
        WordDirection.upLeft,
      ];
    }
    // 51+ : all 8 directions, including both diagonal cross directions.
    return WordDirection.values;
  }

  /// A 1..8 difficulty tier used for reward scaling (bigger reward later).
  static int _tier(int level) {
    if (level <= 20) return 1;
    if (level <= 50) return 2;
    if (level <= 150) return 3;
    if (level <= 350) return 4;
    if (level <= 550) return 5;
    if (level <= 750) return 6;
    if (level <= 950) return 7;
    return 8;
  }

  static DifficultyProfile forLevel(int level) {
    final gl = _gridAndLength(level);
    // Safety: a word can never be longer than the grid.
    final maxLen = gl.max > gl.grid ? gl.grid : gl.max;
    final minLen = gl.min > maxLen ? maxLen : gl.min;
    return DifficultyProfile(
      gridSize: gl.grid,
      wordCount: _wordCount(level, gl.grid),
      minWordLen: minLen,
      maxWordLen: maxLen,
      tier: _tier(level),
      directions: _directions(level),
    );
  }
}
