import 'package:flutter_test/flutter_test.dart';
import 'package:word_finder/game/difficulty.dart';
import 'package:word_finder/game/level_generator.dart';
import 'package:word_finder/game/word_bank.dart';
import 'package:word_finder/models/word_placement.dart';

/// Test bank with enough words of every exact length (4..12).
WordBank _bank() {
  final b = WordBank.instance;
  b.loadFromMap({
    '4': ['WORD','TREE','BOOK','FISH','BIRD','CAKE','MILK','RAIN','SNOW','STAR','MOON','LAKE','LEAF','ROCK','SAND','WOLF','BEAR','FROG','GOAT','LION'],
    '5': ['APPLE','GRAPE','MANGO','PEACH','LEMON','MELON','TIGER','ZEBRA','HORSE','SHEEP','MOUSE','SNAKE','WHALE','SHARK','KOALA','OTTER','CAMEL','PANDA','ROBIN','EAGLE'],
    '6': ['BANANA','ORANGE','CHERRY','TOMATO','CHEESE','BUTTER','COOKIE','MUFFIN','NOODLE','BURGER','FOREST','ISLAND','VALLEY','MEADOW','CANYON','DESERT','FLOWER','ANIMAL','RABBIT','MONKEY'],
    '7': ['GIRAFFE','LEOPARD','PENGUIN','GORILLA','HAMSTER','PEACOCK','DOLPHIN','CHEETAH','CHICKEN','BUFFALO','OCTOPUS','RAINBOW','MORNING','EVENING','KITCHEN','BEDROOM','TEACHER','STUDENT','SCIENCE','HISTORY'],
    '8': ['ELEPHANT','DINOSAUR','MOUNTAIN','SANDWICH','COMPUTER','KEYBOARD','BASEBALL','FOOTBALL','HOSPITAL','UMBRELLA','BIRTHDAY','CALENDAR','CAMPFIRE','DAUGHTER','EXERCISE','MUSHROOM','NOTEBOOK','PAINTING','SUNSHINE','TREASURE'],
    '9': ['CHOCOLATE','BUTTERFLY','ADVENTURE','EDUCATION','BEAUTIFUL','BREAKFAST','COMMUNITY','DANGEROUS','DIFFERENT','IMPORTANT','KNOWLEDGE','TELEPHONE','ORCHESTRA','VEGETABLE','WONDERFUL','YESTERDAY','ASTRONAUT','WATERFALL','CROCODILE','DANDELION'],
    '10': ['BASKETBALL','VOLLEYBALL','STRAWBERRY','TECHNOLOGY','HELICOPTER','MOTORCYCLE','PLAYGROUND','TOOTHBRUSH','WATERMELON','SKATEBOARD','FRIENDSHIP','INSTRUMENT','RESTAURANT','WILDERNESS','GENERATION','REFLECTION','COLLECTION','BACKGROUND','BLACKBERRY','DICTIONARY'],
    '11': ['TEMPERATURE','EXAMINATION','IMAGINATION','CELEBRATION','COMBINATION','COMFORTABLE','INTERESTING','DEVELOPMENT','ENVIRONMENT','ACHIEVEMENT','ENGINEERING','CAULIFLOWER','GRANDMOTHER','GRANDFATHER','ELECTRICITY','COUNTRYSIDE','OPPORTUNITY','PERSONALITY','POSSIBILITY','REQUIREMENT'],
    '12': ['REFRIGERATOR','CHAMPIONSHIP','RELATIONSHIP','CONSTRUCTION','CONVERSATION','INTRODUCTION','INTELLIGENCE','ARCHITECTURE','NEIGHBORHOOD','KINDERGARTEN','THANKSGIVING','ORGANIZATION','PROFESSIONAL','PRESENTATION','CIVILIZATION','HEADQUARTERS','CONSIDERABLE','SUCCESSFULLY','PRODUCTIVITY','TRANSMISSION'],
  });
  return b;
}

// Representative level -> [grid, minLen, maxLen] per the 1..1000 progression.
const _cases = <int, List<int>>{
  1: [6, 4, 4], 5: [6, 4, 4], 10: [6, 4, 4],
  20: [6, 4, 5],
  30: [7, 5, 5], 40: [7, 5, 6],
  50: [8, 6, 6], 75: [8, 6, 7],
  100: [9, 7, 7], 150: [9, 7, 8],
  200: [10, 8, 8], 275: [10, 8, 9],
  300: [11, 9, 9], 400: [11, 9, 10],
  500: [12, 10, 10], 600: [12, 10, 11],
  700: [13, 11, 11], 800: [13, 11, 12],
  900: [14, 12, 12], 1000: [15, 12, 12],
};

void main() {
  final bank = _bank();
  final gen = LevelGenerator(bank);

  test('every range uses the correct grid + word-length window', () {
    _cases.forEach((level, expected) {
      final grid = expected[0];
      final minLen = expected[1];
      final maxLen = expected[2];

      final profile = Difficulty.forLevel(level);
      expect(profile.gridSize, grid, reason: 'level $level grid');
      expect(profile.minWordLen, minLen, reason: 'level $level minLen');
      expect(profile.maxWordLen, maxLen, reason: 'level $level maxLen');

      final def = gen.generate(level);
      expect(def.gridSize, grid, reason: 'level $level generated grid');
      expect(def.grid.length, grid);
      for (final row in def.grid) {
        expect(row.length, grid);
      }
      expect(def.placements, isNotEmpty);
      for (final p in def.placements) {
        expect(p.word.length >= minLen && p.word.length <= maxLen, isTrue,
            reason:
                'level $level word "${p.word}" must be $minLen-$maxLen letters');
        // Word actually present at its coordinates and in bounds (solvable).
        expect(p.cells.length, p.word.length);
        for (int i = 0; i < p.word.length; i++) {
          final c = p.cells[i];
          expect(c.row >= 0 && c.row < grid, isTrue);
          expect(c.col >= 0 && c.col < grid, isTrue);
          expect(def.grid[c.row][c.col], p.word[i]);
        }
      }
    });
  });

  test('word count and grid grow with level (no shrinking)', () {
    final samples = [1, 30, 100, 300, 600, 1000];
    int prevGrid = 0, prevCount = 0;
    for (final level in samples) {
      final p = Difficulty.forLevel(level);
      expect(p.gridSize, greaterThanOrEqualTo(prevGrid),
          reason: 'grid should not shrink at $level');
      expect(p.wordCount, greaterThanOrEqualTo(prevCount),
          reason: 'word count should not shrink at $level');
      prevGrid = p.gridSize;
      prevCount = p.wordCount;
    }
    // Level 1000 must be meaningfully harder than level 1.
    final a = Difficulty.forLevel(1);
    final z = Difficulty.forLevel(1000);
    expect(z.gridSize, greaterThan(a.gridSize));
    expect(z.maxWordLen, greaterThan(a.maxWordLen));
    expect(z.wordCount, greaterThan(a.wordCount));
    expect(z.directions.length, greaterThan(a.directions.length));
  });

  test('generation is deterministic per level number', () {
    for (final level in [1, 26, 51, 101, 201, 301, 501, 999]) {
      final a = gen.generate(level);
      final b = gen.generate(level);
      expect(a.grid.toString(), b.grid.toString());
      expect(a.words, b.words);
    }
  });

  test('consecutive levels do not reuse the same word set (variety)', () {
    for (final level in [1, 27, 52, 102, 202]) {
      final a = gen.generate(level).words.toSet();
      final b = gen.generate(level + 1).words.toSet();
      expect(a.difference(b).isNotEmpty || b.difference(a).isNotEmpty, isTrue,
          reason: 'levels $level and ${level + 1} share every word');
    }
  });

  test('all 8 directions are representable', () {
    expect(WordDirection.values.length, 8);
  });
}
