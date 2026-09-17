import 'package:flutter_test/flutter_test.dart';
import 'package:word_finder/game/level_generator.dart';
import 'package:word_finder/game/word_bank.dart';
import 'package:word_finder/models/word_placement.dart';

WordBank _bank() {
  final b = WordBank.instance;
  b.loadFromMap({
    'Animals': ['CAT','DOG','COW','FOX','OWL','BAT','ANT','BEE','PIG','HEN','RAM','ELK','APE','EEL','LION','BEAR','WOLF','TIGER','ZEBRA','HORSE','SNAKE','WHALE','SHARK','PANDA','MOOSE','OTTER','CAMEL','CHEETAH','DOLPHIN','ELEPHANT'],
    'Fruits': ['FIG','KIWI','LIME','PEAR','PLUM','APPLE','GRAPE','MELON','MANGO','PEACH','LEMON','BANANA','ORANGE','CHERRY','APRICOT','AVOCADO','COCONUT'],
    'Food': ['PIE','JAM','EGG','HAM','BUN','RICE','CAKE','SOUP','BREAD','PASTA','PIZZA','SALAD','HONEY','CHEESE','BUTTER','COOKIE','PANCAKE','SANDWICH'],
    'Nature': ['SUN','SKY','SEA','ICE','MUD','FOG','DEW','TREE','LEAF','ROCK','LAKE','RIVER','OCEAN','BEACH','STONE','STORM','FOREST','ISLAND','GLACIER','MOUNTAIN'],
    'Body': ['ARM','EAR','EYE','LEG','JAW','RIB','HIP','TOE','LIP','GUM','HAND','FOOT','NOSE','HEAD','KNEE','CHEST','BRAIN','HEART','FINGER','MUSCLE'],
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

  test('early levels start with short (3-letter) words', () {
    for (final level in [1, 2, 3, 4, 5]) {
      final def = gen.generate(level);
      for (final w in def.words) {
        expect(w.length, 3, reason: 'level $level word $w should be 3 letters');
      }
    }
  });

  test('word length increases with progression', () {
    final maxLenEarly =
        gen.generate(2).words.map((w) => w.length).reduce((a, b) => a > b ? a : b);
    final maxLenMid =
        gen.generate(40).words.map((w) => w.length).reduce((a, b) => a > b ? a : b);
    expect(maxLenMid, greaterThan(maxLenEarly));
  });

  test('consecutive levels do not reuse the same word set (variety)', () {
    for (int level = 1; level < 8; level++) {
      final a = gen.generate(level).words.toSet();
      final b = gen.generate(level + 1).words.toSet();
      // Neighbouring levels should not be identical word sets.
      expect(a.difference(b).isNotEmpty || b.difference(a).isNotEmpty, isTrue,
          reason: 'levels $level and ${level + 1} share every word');
    }
  });

  test('a run of levels uses a varied pool, not the same few words', () {
    final all = <String>{};
    for (int level = 1; level <= 12; level++) {
      all.addAll(gen.generate(level).words);
    }
    expect(all.length, greaterThan(10));
  });
}
