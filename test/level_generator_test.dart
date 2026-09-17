import 'package:flutter_test/flutter_test.dart';
import 'package:word_finder/game/level_generator.dart';
import 'package:word_finder/game/word_bank.dart';
import 'package:word_finder/models/word_placement.dart';

WordBank _bank() {
  final b = WordBank.instance;
  b.loadFromMap({
    'Animals': ['CAT','DOG','COW','FOX','LION','BEAR','WOLF','TIGER','ZEBRA','HORSE','SNAKE','WHALE','SHARK','PANDA','MOOSE','OTTER','CAMEL'],
    'Fruits': ['FIG','KIWI','LIME','PEAR','PLUM','APPLE','GRAPE','MELON','MANGO','PEACH','LEMON','BANANA','ORANGE','CHERRY'],
    'Food': ['PIE','JAM','EGG','RICE','CAKE','SOUP','BREAD','PASTA','PIZZA','SALAD','HONEY','CHEESE','BUTTER','COOKIE'],
    'Nature': ['SUN','SKY','SEA','TREE','LEAF','ROCK','LAKE','RIVER','OCEAN','BEACH','STONE','STORM','FOREST','ISLAND'],
  });
  return b;
}

void main() {
  final bank = _bank();
  final gen = LevelGenerator(bank);

  test('generates valid levels across the whole progression', () {
    for (final level in [1, 2, 3, 5, 10, 25, 50, 100, 250, 500, 999]) {
      final def = gen.generate(level);
      final size = def.gridSize;

      // Grid is square and fully filled.
      expect(def.grid.length, size);
      for (final row in def.grid) {
        expect(row.length, size);
        for (final cell in row) {
          expect(cell.length, 1);
        }
      }
      expect(def.placements, isNotEmpty);

      // Every word sits correctly at its coordinates and inside bounds.
      for (final p in def.placements) {
        expect(p.cells.length, p.word.length);
        for (int i = 0; i < p.cells.length; i++) {
          final c = p.cells[i];
          expect(c.row >= 0 && c.row < size, isTrue);
          expect(c.col >= 0 && c.col < size, isTrue);
          expect(def.grid[c.row][c.col], p.word[i]);
        }
      }
    }
  });

  test('generation is deterministic per level number', () {
    for (final level in [1, 7, 42, 123, 777]) {
      final a = gen.generate(level);
      final b = gen.generate(level);
      expect(a.grid.toString(), b.grid.toString());
      expect(a.words, b.words);
    }
  });

  test('word count and length grow with level', () {
    final early = gen.generate(2);
    final late = gen.generate(400);
    expect(late.gridSize, greaterThanOrEqualTo(early.gridSize));
  });

  test('all 8 directions are representable', () {
    expect(WordDirection.values.length, 8);
  });
}
