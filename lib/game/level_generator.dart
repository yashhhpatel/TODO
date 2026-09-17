import 'dart:math';
import '../models/level_definition.dart';
import '../models/word_placement.dart';
import 'difficulty.dart';
import 'reward_calculator.dart';
import 'word_bank.dart';
import 'word_placer.dart';

/// Deterministically builds and validates a level from its number.
///
/// Same level number + same word database => identical level. Generation
/// retries with new seeds on placement failure; an impossible level is never
/// returned.
class LevelGenerator {
  final WordBank bank;
  LevelGenerator(this.bank);

  static const int _maxOuterAttempts = 60;

  LevelDefinition generate(int level) {
    assert(bank.isLoaded, 'WordBank must be loaded first');
    final profile = Difficulty.forLevel(level);
    final category = bank.categoryForLevel(level);

    // Try the full profile first, then progressively relax word count.
    for (int wanted = profile.wordCount; wanted >= 3; wanted--) {
      final words = bank.selectWords(
        level: level,
        category: category,
        count: wanted,
        minLen: profile.minWordLen,
        maxLen: profile.maxWordLen,
      );
      if (words.length < wanted) continue;

      for (int attempt = 0; attempt < _maxOuterAttempts; attempt++) {
        final rng = Random(level * 1000 + attempt);
        final placed = WordPlacer.tryPlace(
          words: words,
          size: profile.gridSize,
          directions: profile.directions,
          rng: rng,
        );
        if (placed == null) continue;

        final def = _assemble(level, profile, category, placed.grid,
            placed.placements);
        if (_validate(def)) return def;
      }
    }

    // Guaranteed fallback: a trivially solvable small level.
    return _fallback(level);
  }

  LevelDefinition _assemble(
    int level,
    DifficultyProfile profile,
    String category,
    List<List<String>> grid,
    List placements,
  ) {
    final base = RewardCalculator.baseReward(
      tier: profile.tier,
      wordCount: placements.length,
      gridSize: profile.gridSize,
    );
    final th = RewardCalculator.starThresholds(
      wordCount: placements.length,
      gridSize: profile.gridSize,
    );
    return LevelDefinition(
      levelNumber: level,
      gridSize: profile.gridSize,
      category: category,
      difficulty: profile.tier,
      grid: grid,
      placements: List.from(placements),
      baseReward: base,
      threeStarSeconds: th.three,
      twoStarSeconds: th.two,
    );
  }

  /// Full structural validation. Every failure means we discard and retry.
  bool _validate(LevelDefinition def) {
    final size = def.gridSize;
    if (def.grid.length != size) return false;
    for (final row in def.grid) {
      if (row.length != size) return false;
      for (final cell in row) {
        if (cell.length != 1) return false; // no empty cells
      }
    }
    if (def.placements.isEmpty) return false;

    for (final p in def.placements) {
      if (p.cells.length != p.word.length) return false;
      for (int i = 0; i < p.cells.length; i++) {
        final c = p.cells[i];
        if (c.row < 0 || c.row >= size || c.col < 0 || c.col >= size) {
          return false; // invalid coordinate
        }
        if (def.grid[c.row][c.col] != p.word[i]) {
          return false; // word not actually present at its coordinates
        }
      }
    }
    return true;
  }

  LevelDefinition _fallback(int level) {
    const words = ['CAT', 'DOG', 'SUN'];
    const size = 5;
    final rng = Random(level);
    final placed = WordPlacer.tryPlace(
      words: words,
      size: size,
      directions: const [WordDirection.right, WordDirection.down],
      rng: rng,
    )!;
    return LevelDefinition(
      levelNumber: level,
      gridSize: size,
      category: 'Animals',
      difficulty: 1,
      grid: placed.grid,
      placements: placed.placements,
      baseReward: 30,
      threeStarSeconds: 26,
      twoStarSeconds: 52,
    );
  }
}
