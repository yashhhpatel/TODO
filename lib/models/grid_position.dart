import 'package:flutter/foundation.dart';

/// Immutable row/column coordinate inside the letter grid.
@immutable
class GridPos {
  final int row;
  final int col;
  const GridPos(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is GridPos && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}
