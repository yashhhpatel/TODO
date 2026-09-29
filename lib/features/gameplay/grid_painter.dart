import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../game/word_search_controller.dart';
import '../../models/grid_position.dart';

/// Draws the entire letter grid in one pass: backgrounds, found-word fills,
/// hint outlines, the live selection band/line, and the letters on top. Using
/// a single CustomPainter avoids per-cell widget rebuilds during a swipe.
///
/// When a word is found, [pulse] briefly animates 0->1 (driven externally by
/// the gameplay screen) while [pulsingWord] names which word to celebrate: a
/// glowing "connection" line is flashed along its path, its letters pop with
/// a quick bounce, and a few sparkles drift outward from each cell before
/// settling into the steady highlighted state.
class GridPainter extends CustomPainter {
  final WordSearchController controller;
  final int gridSize;
  final Animation<double> pulse;
  final FoundWord? pulsingWord;

  GridPainter(
    this.controller,
    this.gridSize, {
    required this.pulse,
    this.pulsingWord,
  }) : super(repaint: Listenable.merge([controller, pulse]));

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

    final pulsing = pulsingWord;
    final t = pulse.value;
    final celebrating = pulsing != null && t < 1.0;
    final pulseCellSet =
        celebrating ? pulsing.cells.toSet() : const <GridPos>{};

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

    // 2b) Found-word celebration: a glowing connector flash + expanding
    // rings + a few outward sparkles, all fading out as the pulse settles.
    if (celebrating) {
      final hue = _hue(pulsing.hue);

      if (pulsing.cells.length > 1) {
        final path = Path()
          ..moveTo(
              center(pulsing.cells.first).dx, center(pulsing.cells.first).dy);
        for (int i = 1; i < pulsing.cells.length; i++) {
          path.lineTo(center(pulsing.cells[i]).dx, center(pulsing.cells[i]).dy);
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = cell * 0.5 * (1 - t * 0.7)
            ..color = hue.withOpacity((1 - t) * 0.45),
        );
      }

      for (final p in pulsing.cells) {
        final c = center(p);
        final ringRadius = cell * 0.5 + t * cell * 0.85;
        canvas.drawCircle(
          c,
          ringRadius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (3 * (1 - t) + 0.6)
            ..color = hue.withOpacity((1 - t).clamp(0.0, 1.0) * 0.85),
        );

        const sparkles = 6;
        for (int s = 0; s < sparkles; s++) {
          final angle = (2 * pi * s) / sparkles + p.row + p.col;
          final dist = cell * 0.35 + t * cell * 0.75;
          final pos = c + Offset(cos(angle), sin(angle)) * dist;
          final a = (1 - t).clamp(0.0, 1.0);
          canvas.drawCircle(
            pos,
            (2.4 * (1 - t) + 0.4),
            Paint()..color = AppColors.star.withOpacity(a * 0.9),
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
      final selColor = controller.wrongFlash ? AppColors.danger : AppColors.ink;
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

        final cx = c * cell + cell / 2;
        final cy = r * cell + cell / 2;
        final off = Offset(cx - tp.width / 2, cy - tp.height / 2);

        if (pulseCellSet.contains(p)) {
          // Quick pop-then-settle bounce for freshly found letters.
          final bounce = 1 + 0.32 * sin(t * pi);
          canvas.save();
          canvas.translate(cx, cy);
          canvas.scale(bounce);
          canvas.translate(-cx, -cy);
          tp.paint(canvas, off);
          canvas.restore();
        } else {
          tp.paint(canvas, off);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => false;
}
