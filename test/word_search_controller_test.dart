import 'package:flutter_test/flutter_test.dart';
import 'package:word_finder/game/level_generator.dart';
import 'package:word_finder/game/word_search_controller.dart';
import 'package:word_finder/game/word_bank.dart';
import 'package:word_finder/models/word_placement.dart';

WordBank _bank() {
  final b = WordBank.instance;
  b.loadFromMap({
    '4': ['WORD','TREE','BOOK','FISH','BIRD','CAKE','MILK','RAIN','SNOW','STAR','MOON','LAKE','LEAF','ROCK','SAND','WOLF','BEAR','FROG','GOAT','LION'],
    '5': ['APPLE','GRAPE','MANGO','PEACH','LEMON','MELON','TIGER','ZEBRA','HORSE','SHEEP','MOUSE','SNAKE','WHALE','SHARK','KOALA','OTTER','CAMEL','PANDA','ROBIN','EAGLE'],
    '6': ['BANANA','ORANGE','CHERRY','TOMATO','CHEESE','BUTTER','COOKIE','MUFFIN','NOODLE','BURGER','FOREST','ISLAND','VALLEY','MEADOW','CANYON','DESERT','FLOWER','ANIMAL','RABBIT','MONKEY'],
    '7': ['GIRAFFE','LEOPARD','PENGUIN','GORILLA','HAMSTER','PEACOCK','DOLPHIN','CHEETAH','CHICKEN','BUFFALO','OCTOPUS','RAINBOW','MORNING','EVENING','KITCHEN','BEDROOM','TEACHER','STUDENT','SCIENCE','HISTORY'],
    '8': ['ELEPHANT','DINOSAUR','MOUNTAIN','SANDWICH','COMPUTER','KEYBOARD','BASEBALL','FOOTBALL','HOSPITAL','UMBRELLA','BIRTHDAY','CALENDAR','CAMPFIRE','DAUGHTER','EXERCISE','MUSHROOM','NOTEBOOK','PAINTING','SUNSHINE','TREASURE'],
  });
  return b;
}

void main() {
  final gen = LevelGenerator(_bank());

  const diagonals = {
    WordDirection.downRight,
    WordDirection.upLeft,
    WordDirection.downLeft,
    WordDirection.upRight,
  };

  test('diagonal words are generated in the mid/late levels', () {
    var diagonalCount = 0;
    for (int level = 21; level <= 80; level++) {
      final def = gen.generate(level);
      diagonalCount +=
          def.placements.where((p) => diagonals.contains(p.direction)).length;
    }
    expect(diagonalCount, greaterThan(0),
        reason: 'diagonally-placed words should appear from level 21 on');
  });

  test('early levels stay beginner-friendly (no diagonals in levels 1-5)', () {
    for (int level = 1; level <= 5; level++) {
      final def = gen.generate(level);
      for (final p in def.placements) {
        expect(diagonals.contains(p.direction), isFalse,
            reason: 'level $level should have no diagonal words');
      }
    }
  });

  test('a diagonal word can be selected from both ends', () {
    // Find a level that contains a diagonal placement.
    WordPlacement? diag;
    for (int level = 1; level <= 60 && diag == null; level++) {
      final def = gen.generate(level);
      for (final p in def.placements) {
        if (diagonals.contains(p.direction)) {
          final c = WordSearchController(level: def);
          // forward
          c.beginAt(p.cells.first);
          c.extendTo(p.cells.last);
          c.endSelection();
          expect(c.isWordFound(p.word), isTrue,
              reason: 'diagonal ${p.word} forward');
          // reverse
          final c2 = WordSearchController(level: def);
          c2.beginAt(p.cells.last);
          c2.extendTo(p.cells.first);
          c2.endSelection();
          expect(c2.isWordFound(p.word), isTrue,
              reason: 'diagonal ${p.word} reverse');
          c.dispose();
          c2.dispose();
          diag = p;
          break;
        }
      }
    }
    expect(diag, isNotNull, reason: 'expected at least one diagonal word');
  });

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
