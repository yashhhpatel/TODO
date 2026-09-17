import 'grid_position.dart';

/// The 8 directions a word may run in the grid.
enum WordDirection {
  right(0, 1),
  left(0, -1),
  down(1, 0),
  up(-1, 0),
  downRight(1, 1),
  upLeft(-1, -1),
  downLeft(1, -1),
  upRight(-1, 1);

  final int dRow;
  final int dCol;
  const WordDirection(this.dRow, this.dCol);
}

/// A concrete placement of one target word: the word plus the exact ordered
/// cells it occupies.
class WordPlacement {
  final String word; // uppercase
  final GridPos start;
  final WordDirection direction;
  final List<GridPos> cells;

  const WordPlacement({
    required this.word,
    required this.start,
    required this.direction,
    required this.cells,
  });
}
