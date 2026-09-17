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

// Representative level -> (expected grid, expected exact word length).
const _cases = <int, List<int>>{
  1: [6, 4], 12: [6, 4], 25: [6, 4],
  26: [7, 5], 40: [7, 5], 50: [7, 5],
  51: [8, 6], 60: [8, 6], 75: [8, 6],
  76: [9, 7], 88: [9, 7], 100: [9, 7],
  101: [10, 8], 130: [10, 8], 150: [10, 8],
  151: [11, 9], 175: [11, 9], 200: [11, 9],
  201: [12, 10], 260: [12, 10], 300: [12, 10],
  301: [13, 11], 400: [13, 11], 500: [13, 11],
  501: [14, 12], 750: [14, 12], 1000: [14, 12],
};

void main() {
  final bank = _bank();
  final gen = LevelGenerator(bank);

  test('every range uses the exact grid size and word length', () {
    _cases.forEach((level, expected) {
      final grid = expected[0];
      final len = expected[1];

      final profile = Difficulty.forLevel(level);
      expect(profile.gridSize, grid, reason: 'level $level grid');
      expect(profile.wordLength, len, reason: 'level $level word length');

      final def = gen.generate(level);
      expect(def.gridSize, grid, reason: 'level $level generated grid');
      expect(def.grid.length, grid);
      for (final row in def.grid) {
        expect(row.length, grid);
      }
      expect(def.placements, isNotEmpty);
      for (final p in def.placements) {
        expect(p.word.length, len,
            reason: 'level $level word "${p.word}" must be $len letters');
        // Word actually present at its coordinates and in bounds.
        expect(p.cells.length, len);
        for (int i = 0; i < len; i++) {
          final c = p.cells[i];
          expect(c.row >= 0 && c.row < grid, isTrue);
          expect(c.col >= 0 && c.col < grid, isTrue);
          expect(def.grid[c.row][c.col], p.word[i]);
        }
      }
    });
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
