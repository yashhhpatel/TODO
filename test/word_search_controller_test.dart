import 'package:flutter_test/flutter_test.dart';
import 'package:word_finder/game/level_generator.dart';
import 'package:word_finder/game/word_search_controller.dart';
import 'package:word_finder/game/word_bank.dart';

WordBank _bank() {
  final b = WordBank.instance;
  b.loadFromMap({
    'Animals': ['CAT','DOG','COW','FOX','LION','BEAR','WOLF','TIGER','ZEBRA','HORSE','SNAKE','WHALE','SHARK','PANDA'],
    'Fruits': ['FIG','KIWI','LIME','PEAR','PLUM','APPLE','GRAPE','MELON','MANGO','PEACH','LEMON','BANANA'],
    'Food': ['PIE','JAM','EGG','RICE','CAKE','SOUP','BREAD','PASTA','PIZZA','SALAD','HONEY'],
    'Nature': ['SUN','SKY','SEA','TREE','LEAF','ROCK','LAKE','RIVER','OCEAN','BEACH','STONE'],
  });
  return b;
}

void main() {
  final gen = LevelGenerator(_bank());

  test('finds every placed word by swiping start->end (any direction)', () {
    final level = gen.generate(120); // uses diagonals + reverse
    final c = WordSearchController(level: level);
    for (final p in level.placements) {
      c.beginAt(p.cells.first);
      c.extendTo(p.cells.last);
      c.endSelection();
      expect(c.isWordFound(p.word), isTrue, reason: 'should find ${p.word}');
    }
    expect(c.isComplete, isTrue);
    expect(c.foundCount, level.placements.length);
    c.dispose();
  });

  test('reverse selection also validates', () {
    final level = gen.generate(30);
    final c = WordSearchController(level: level);
    final p = level.placements.first;
    c.beginAt(p.cells.last); // reversed
    c.extendTo(p.cells.first);
    c.endSelection();
    expect(c.isWordFound(p.word), isTrue);
    c.dispose();
  });

  test('wrong selection does not complete or crash', () {
    final level = gen.generate(3);
    final c = WordSearchController(level: level);
    // A single cell is too short -> ignored, no crash.
    c.beginAt(level.placements.first.cells.first);
    c.endSelection();
    expect(c.foundCount, 0);
    c.dispose();
  });

  test('completion is guarded against duplicates', () {
    final level = gen.generate(2);
    final c = WordSearchController(level: level);
    for (final p in level.placements) {
      c.beginAt(p.cells.first);
      c.extendTo(p.cells.last);
      c.endSelection();
    }
    expect(c.isComplete, isTrue);
    final countAtComplete = c.foundCount;
    // Re-selecting a found word must not change counts.
    final p = level.placements.first;
    c.beginAt(p.cells.first);
    c.extendTo(p.cells.last);
    c.endSelection();
    expect(c.foundCount, countAtComplete);
    c.dispose();
  });

  test('word hint completes a word without extra selection', () {
    final level = gen.generate(10);
    final c = WordSearchController(level: level);
    final before = c.foundCount;
    expect(c.useWordHint(), isTrue);
    expect(c.foundCount, before + 1);
    c.dispose();
  });
}
