import 'dart:math';
import '../models/grid_position.dart';
import '../models/word_placement.dart';

class PlacedGrid {
  final List<List<String>> grid;
  final List<WordPlacement> placements;
  const PlacedGrid(this.grid, this.placements);
}

/// Places target words into a square grid, allowing valid letter overlaps and
/// filling the remainder with deterministic random letters.
class WordPlacer {
  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// Attempts to place all [words]. Returns null if any word could not be
  /// placed within the attempt budget (caller should retry with a new seed).
  static PlacedGrid? tryPlace({
    required List<String> words,
    required int size,
    required List<WordDirection> directions,
    required Random rng,
  }) {
    final grid = List.generate(size, (_) => List.filled(size, ''));
    final placements = <WordPlacement>[];

    // Longest first: easier to fit while the grid is empty.
    final ordered = List<String>.from(words)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final word in ordered) {
      if (word.length > size) return null;
      if (!_placeWord(word, grid, size, directions, rng, placements)) {
        return null;
      }
    }

    // Fill empty cells with random letters.
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c].isEmpty) {
          grid[r][c] = _alphabet[rng.nextInt(26)];
        }
      }
    }
    return PlacedGrid(grid, placements);
  }

  static bool _placeWord(
    String word,
    List<List<String>> grid,
    int size,
    List<WordDirection> directions,
    Random rng,
    List<WordPlacement> out,
  ) {
    const maxAttempts = 300;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final dir = directions[rng.nextInt(directions.length)];
      final len = word.length;

      // Valid starting-cell ranges so the whole word stays in bounds.
      final rowSpan = dir.dRow * (len - 1);
      final colSpan = dir.dCol * (len - 1);

      final minRow = rowSpan < 0 ? -rowSpan : 0;
      final maxRow = rowSpan > 0 ? size - 1 - rowSpan : size - 1;
      final minCol = colSpan < 0 ? -colSpan : 0;
      final maxCol = colSpan > 0 ? size - 1 - colSpan : size - 1;

      if (minRow > maxRow || minCol > maxCol) continue;

      final startRow = minRow + rng.nextInt(maxRow - minRow + 1);
      final startCol = minCol + rng.nextInt(maxCol - minCol + 1);

      final cells = <GridPos>[];
      bool ok = true;
      for (int i = 0; i < len; i++) {
        final r = startRow + dir.dRow * i;
        final c = startCol + dir.dCol * i;
        final existing = grid[r][c];
        if (existing.isNotEmpty && existing != word[i]) {
          ok = false;
          break;
        }
        cells.add(GridPos(r, c));
      }
      if (!ok) continue;

      for (int i = 0; i < len; i++) {
        grid[cells[i].row][cells[i].col] = word[i];
      }
      out.add(WordPlacement(
        word: word,
        start: GridPos(startRow, startCol),
        direction: dir,
        cells: cells,
      ));
      return true;
    }
    return false;
  }
}
