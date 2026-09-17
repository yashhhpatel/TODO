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

    // Try the full profile first, then progressively relax word count.
    for (int wanted = profile.wordCount; wanted >= 2; wanted--) {
      final selection = bank.selectForLevel(
        level: level,
        count: wanted,
        length: profile.wordLength,
      );
      final words = selection.words;
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

        final def = _assemble(level, profile, selection.category, placed.grid,
            placed.placements);
        if (_validate(def, profile.wordLength)) return def;
      }
    }

    // Guaranteed fallback: a trivially solvable level that still honours the
    // exact grid size and word length for this range.
    return _fallback(level, profile);
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
  bool _validate(LevelDefinition def, int expectedLen) {
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
      if (p.word.length != expectedLen) return false; // exact length required
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

  LevelDefinition _fallback(int level, DifficultyProfile profile) {
    final size = profile.gridSize;
    // Easiest possible layout: a few exact-length words, straight lines only.
    for (int wanted = 3; wanted >= 1; wanted--) {
      final sel = bank.selectForLevel(
        level: level,
        count: wanted,
        length: profile.wordLength,
      );
      if (sel.words.length < wanted) continue;
      for (int attempt = 0; attempt < 200; attempt++) {
        final placed = WordPlacer.tryPlace(
          words: sel.words,
          size: size,
          directions: const [WordDirection.right, WordDirection.down],
          rng: Random(level * 7 + attempt),
        );
        if (placed == null) continue;
        return LevelDefinition(
          levelNumber: level,
          gridSize: size,
          category: sel.category,
          difficulty: profile.tier,
          grid: placed.grid,
          placements: placed.placements,
          baseReward: RewardCalculator.baseReward(
              tier: profile.tier,
              wordCount: placed.placements.length,
              gridSize: size),
          threeStarSeconds: RewardCalculator.starThresholds(
                  wordCount: placed.placements.length, gridSize: size)
              .three,
          twoStarSeconds: RewardCalculator.starThresholds(
                  wordCount: placed.placements.length, gridSize: size)
              .two,
        );
      }
    }
    // Should be unreachable given the bundled vocabulary covers all lengths.
    throw StateError('Unable to generate level $level');
  }
}
