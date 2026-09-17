import 'package:flutter_test/flutter_test.dart';
import 'package:word_finder/game/difficulty.dart';
import 'package:word_finder/game/level_generator.dart';
import 'package:word_finder/game/word_bank.dart';

/// Verifies the actual bundled assets/data/words.json (not a synthetic bank)
/// produces the exact grid size and word length for every range.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cases = <int, List<int>>{
    1: [6, 4], 25: [6, 4],
    26: [7, 5], 50: [7, 5],
    51: [8, 6], 75: [8, 6],
    76: [9, 7], 100: [9, 7],
    101: [10, 8], 150: [10, 8],
    151: [11, 9], 200: [11, 9],
    201: [12, 10], 300: [12, 10],
    301: [13, 11], 500: [13, 11],
    501: [14, 12], 750: [14, 12], 1000: [14, 12],
  };

  test('bundled word data yields exact grid + word length for all ranges',
      () async {
    final bank = WordBank.instance;
    await bank.load();
    final gen = LevelGenerator(bank);

    cases.forEach((level, exp) {
      final grid = exp[0];
      final len = exp[1];
      expect(Difficulty.forLevel(level).gridSize, grid);
      expect(Difficulty.forLevel(level).wordLength, len);

      final def = gen.generate(level);
      expect(def.gridSize, grid, reason: 'level $level grid');
      expect(def.placements, isNotEmpty, reason: 'level $level has words');
      for (final p in def.placements) {
        expect(p.word.length, len,
            reason: 'level $level word "${p.word}" must be $len letters');
      }
    });
  });
}
