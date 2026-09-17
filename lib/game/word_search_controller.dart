import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/grid_position.dart';
import '../models/level_definition.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class FoundWord {
  final String word;
  final List<GridPos> cells;
  final int hue;
  const FoundWord(this.word, this.cells, this.hue);
}

/// Owns all live gameplay state for one level: selection, found words, timer.
/// UI renders this; it does not hold game logic itself.
class WordSearchController extends ChangeNotifier {
  WordSearchController({
    required this.level,
    this.audio,
    this.haptics,
  });

  final LevelDefinition level;
  final AudioService? audio;
  final HapticService? haptics;

  final List<GridPos> _selection = [];
  final Map<String, FoundWord> _found = {};
  final Map<GridPos, int> _foundCellHue = {};
  final Set<GridPos> _hintCells = {};

  GridPos? _anchor; // for tap mode
  Timer? _timer;
  int _elapsed = 0;
  bool _completed = false;
  bool wrongFlash = false;

  // ---- Getters ----
  List<GridPos> get selection => List.unmodifiable(_selection);
  bool get hasSelection => _selection.isNotEmpty;
  int get elapsedSeconds => _elapsed;
  bool get isComplete => _completed;
  int get totalWords => level.placements.length;
  int get foundCount => _found.length;
  Iterable<FoundWord> get foundWords => _found.values;
  Set<GridPos> get hintCells => Set.unmodifiable(_hintCells);

  bool isWordFound(String word) => _found.containsKey(word);
  int? foundHueAt(GridPos p) => _foundCellHue[p];
  bool isSelected(GridPos p) => _selection.contains(p);

  String get selectionString {
    final b = StringBuffer();
    for (final c in _selection) {
      b.write(level.grid[c.row][c.col]);
    }
    return b.toString();
  }

  String formattedTime() {
    final m = (_elapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ---- Lifecycle ----
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_completed) {
        _elapsed++;
        notifyListeners();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ---- Swipe input ----
  void beginAt(GridPos p) {
    if (_completed) return;
    _selection
      ..clear()
      ..add(p);
    audio?.play(Sfx.select);
    haptics?.light();
    notifyListeners();
  }

  void extendTo(GridPos p) {
    if (_completed || _selection.isEmpty) return;
    final start = _selection.first;
    final line = _lineBetween(start, p);
    if (line == null) return; // not a straight line; keep last valid path
    if (line.length == _selection.length &&
        line.isNotEmpty &&
        line.last == _selection.last) {
      return; // unchanged
    }
    _selection
      ..clear()
      ..addAll(line);
    haptics?.light();
    notifyListeners();
  }

  void endSelection() {
    if (_completed) return;
    _validateSelection();
  }

  // ---- Tap input ----
  void tapCell(GridPos p) {
    if (_completed) return;
    if (_anchor == null) {
      _anchor = p;
      _selection
        ..clear()
        ..add(p);
      audio?.play(Sfx.select);
      haptics?.light();
      notifyListeners();
      return;
    }
    if (_anchor == p) {
      // tapped same cell again: cancel
      _anchor = null;
      _selection.clear();
      notifyListeners();
      return;
    }
    final line = _lineBetween(_anchor!, p);
    _anchor = null;
    if (line == null) {
      _selection.clear();
      notifyListeners();
      return;
    }
    _selection
      ..clear()
      ..addAll(line);
    _validateSelection();
  }

  // ---- Core validation ----
  void _validateSelection() {
    if (_selection.length < 2) {
      _selection.clear();
      notifyListeners();
      return;
    }
    final str = selectionString;
    final rev = str.split('').reversed.join();
    final target = level.words.firstWhere(
      (w) => (w == str || w == rev) && !_found.containsKey(w),
      orElse: () => '',
    );
    if (target.isNotEmpty) {
      _registerFound(target, List<GridPos>.from(_selection), reward: true);
    } else {
      _flashWrong();
    }
    _selection.clear();
    notifyListeners();
  }

  void _registerFound(String word, List<GridPos> cells, {required bool reward}) {
    final hue = _found.length; // cycle handled at render time
    _found[word] = FoundWord(word, cells, hue);
    for (final c in cells) {
      _foundCellHue[c] = hue;
      _hintCells.remove(c);
    }
    if (reward) {
      audio?.play(Sfx.correct);
      haptics?.success();
    }
    if (_found.length >= totalWords && !_completed) {
      _completed = true;
      _stopTimer();
      audio?.play(Sfx.levelComplete);
      haptics?.celebrate();
    }
  }

  Future<void> _flashWrong() async {
    audio?.play(Sfx.wrong);
    haptics?.error();
    wrongFlash = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 350));
    wrongFlash = false;
    notifyListeners();
  }

  /// Builds the straight-line cell path from [a] to [b], or null if the two
  /// points are not aligned on one of the 8 directions.
  List<GridPos>? _lineBetween(GridPos a, GridPos b) {
    final dr = b.row - a.row;
    final dc = b.col - a.col;
    if (dr == 0 && dc == 0) return [a];
    final aligned = dr == 0 || dc == 0 || dr.abs() == dc.abs();
    if (!aligned) return null;
    final steps = dr.abs() > dc.abs() ? dr.abs() : dc.abs();
    final sr = dr.sign;
    final sc = dc.sign;
    return List.generate(steps + 1, (i) => GridPos(a.row + sr * i, a.col + sc * i));
  }

  // ---- Hints ----
  /// Reveals one letter of an unfound word. Returns false if none available.
  bool useLetterHint() {
    for (final p in level.placements) {
      if (_found.containsKey(p.word)) continue;
      for (final c in p.cells) {
        if (!_hintCells.contains(c) && !_foundCellHue.containsKey(c)) {
          _hintCells.add(c);
          audio?.play(Sfx.hint);
          haptics?.light();
          notifyListeners();
          return true;
        }
      }
    }
    return false;
  }

  /// Reveals (completes) an entire unfound word. Returns false if none left.
  bool useWordHint() {
    for (final p in level.placements) {
      if (_found.containsKey(p.word)) continue;
      _registerFound(p.word, List<GridPos>.from(p.cells), reward: false);
      audio?.play(Sfx.hint);
      haptics?.light();
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
