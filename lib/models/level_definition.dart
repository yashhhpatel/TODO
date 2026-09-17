import 'word_placement.dart';

/// A fully generated, validated level ready to be played.
class LevelDefinition {
  final int levelNumber;
  final int gridSize;
  final String category;
  final int difficulty; // 1..5
  final List<List<String>> grid; // grid[row][col], uppercase letters
  final List<WordPlacement> placements;

  /// Base reward (before fast bonus) and star time thresholds (seconds).
  final int baseReward;
  final int threeStarSeconds;
  final int twoStarSeconds;

  const LevelDefinition({
    required this.levelNumber,
    required this.gridSize,
    required this.category,
    required this.difficulty,
    required this.grid,
    required this.placements,
    required this.baseReward,
    required this.threeStarSeconds,
    required this.twoStarSeconds,
  });

  List<String> get words => placements.map((p) => p.word).toList();

  String letterAt(int row, int col) => grid[row][col];
}
