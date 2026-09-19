import 'package:flutter_test/flutter_test.dart';
import 'package:word_finder/game/difficulty.dart';
import 'package:word_finder/game/level_generator.dart';
import 'package:word_finder/game/word_bank.dart';

/// Verifies the actual bundled assets/data/words.json (not a synthetic bank)
/// produces the exact grid size and word length for every range.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // [grid, minLen, maxLen] across the full 1..1000 progression.
  const cases = <int, List<int>>{
    1: [6, 4, 4], 5: [6, 4, 4], 10: [6, 4, 4], 20: [6, 4, 5],
    30: [7, 5, 5], 50: [8, 6, 6], 100: [9, 7, 7], 200: [10, 8, 8],
    300: [11, 9, 9], 400: [11, 9, 10], 500: [12, 10, 10], 600: [12, 10, 11],
    700: [13, 11, 11], 800: [13, 11, 12], 900: [14, 12, 12], 1000: [15, 12, 12],
  };

  test('bundled word data yields correct grid + length window for all ranges',
      () async {
    final bank = WordBank.instance;
    await bank.load();
    final gen = LevelGenerator(bank);

    cases.forEach((level, exp) {
      final grid = exp[0];
      final minLen = exp[1];
      final maxLen = exp[2];
      expect(Difficulty.forLevel(level).gridSize, grid);
      expect(Difficulty.forLevel(level).minWordLen, minLen);
      expect(Difficulty.forLevel(level).maxWordLen, maxLen);

      final def = gen.generate(level);
      expect(def.gridSize, grid, reason: 'level $level grid');
      expect(def.placements, isNotEmpty, reason: 'level $level has words');
      for (final p in def.placements) {
        expect(p.word.length >= minLen && p.word.length <= maxLen, isTrue,
            reason:
                'level $level word "${p.word}" must be $minLen-$maxLen letters');
        // Every word must actually exist at its coordinates (solvable).
        for (int i = 0; i < p.word.length; i++) {
          final c = p.cells[i];
          expect(def.grid[c.row][c.col], p.word[i]);
        }
      }
    });
  });

  test('every level 1..1000 is generated, in-range and solvable', () async {
    final bank = WordBank.instance;
    await bank.load();
    final gen = LevelGenerator(bank);

    for (int level = 1; level <= 1000; level++) {
      final profile = Difficulty.forLevel(level);
      final def = gen.generate(level);

      // Grid is the expected square, fully filled, words fit and are present.
      expect(def.gridSize, profile.gridSize, reason: 'level $level grid');
      expect(def.grid.length, profile.gridSize);
      expect(def.placements, isNotEmpty, reason: 'level $level empty');
      for (final row in def.grid) {
        expect(row.length, profile.gridSize);
        for (final cell in row) {
          expect(cell.length, 1);
        }
      }
      for (final p in def.placements) {
        expect(p.word.length >= profile.minWordLen &&
            p.word.length <= profile.maxWordLen && p.word.length <= profile.gridSize,
            isTrue,
            reason: 'level $level word "${p.word}" out of range/grid');
        for (int i = 0; i < p.word.length; i++) {
          final c = p.cells[i];
          expect(c.row >= 0 && c.row < profile.gridSize, isTrue);
          expect(c.col >= 0 && c.col < profile.gridSize, isTrue);
          expect(def.grid[c.row][c.col], p.word[i],
              reason: 'level $level word "${p.word}" not at coords (solvable)');
        }
      }
    }
  });
}
