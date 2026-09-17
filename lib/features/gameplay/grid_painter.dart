import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../game/word_search_controller.dart';
import '../../models/grid_position.dart';

/// Draws the entire letter grid in one pass: backgrounds, found-word fills,
/// hint outlines, the live selection band/line, and the letters on top. Using a
/// single CustomPainter avoids per-cell widget rebuilds during a swipe.
class GridPainter extends CustomPainter {
  final WordSearchController controller;
  final int gridSize;

  GridPainter(this.controller, this.gridSize) : super(repaint: controller);

  Color _hue(int i) => AppColors.wordHues[i % AppColors.wordHues.length];

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / gridSize;
    final radius = Radius.circular(cell * 0.22);
    final gap = cell * 0.08;

    Rect cellRect(int r, int c) => Rect.fromLTWH(
          c * cell + gap,
          r * cell + gap,
          cell - gap * 2,
          cell - gap * 2,
        );

    Offset center(GridPos p) =>
        Offset(p.col * cell + cell / 2, p.row * cell + cell / 2);

    // 1) Base backgrounds.
    final basePaint = Paint()..color = AppColors.card;
    final baseBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.grey200;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final rr = RRect.fromRectAndRadius(cellRect(r, c), radius);
        canvas.drawRRect(rr, basePaint);
        canvas.drawRRect(rr, baseBorder);
      }
    }

    // 2) Found-word fills.
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final hueIndex = controller.foundHueAt(GridPos(r, c));
        if (hueIndex != null) {
          final col = _hue(hueIndex);
          final rr = RRect.fromRectAndRadius(cellRect(r, c), radius);
          canvas.drawRRect(rr, Paint()..color = col.withOpacity(0.16));
          canvas.drawRRect(
            rr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = col.withOpacity(0.9),
          );
        }
      }
    }

    // 3) Hint outlines.
    for (final p in controller.hintCells) {
      final rr = RRect.fromRectAndRadius(cellRect(p.row, p.col), radius);
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = AppColors.accent,
      );
    }

    // 4) Selection band + line.
    final sel = controller.selection;
    if (sel.isNotEmpty) {
      final selColor =
          controller.wrongFlash ? AppColors.danger : AppColors.ink;
      final linePaint = Paint()
        ..color = selColor.withOpacity(0.22)
        ..strokeWidth = cell * 0.72
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (sel.length == 1) {
        canvas.drawCircle(center(sel.first), cell * 0.36,
            Paint()..color = selColor.withOpacity(0.22));
      } else {
        final path = Path()..moveTo(center(sel.first).dx, center(sel.first).dy);
        for (int i = 1; i < sel.length; i++) {
          path.lineTo(center(sel[i]).dx, center(sel[i]).dy);
        }
        canvas.drawPath(path, linePaint);
      }
    }

    // 5) Letters on top.
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final p = GridPos(r, c);
        final hueIndex = controller.foundHueAt(p);
        final selected = controller.isSelected(p);
        Color color;
        if (selected) {
          color = controller.wrongFlash ? AppColors.danger : AppColors.ink;
        } else if (hueIndex != null) {
          color = _hue(hueIndex);
        } else {
          color = AppColors.grey900;
        }
        final tp = TextPainter(
          text: TextSpan(
            text: controller.level.grid[r][c],
            style: TextStyle(
              color: color,
              fontSize: cell * 0.44,
              fontWeight: selected || hueIndex != null
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final off = Offset(
          c * cell + (cell - tp.width) / 2,
          r * cell + (cell - tp.height) / 2,
        );
        tp.paint(canvas, off);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => false;
}
