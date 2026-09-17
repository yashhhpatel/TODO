import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

/// Loads the curated word database and provides deterministic word selection.
class WordBank {
  static final WordBank instance = WordBank._();
  WordBank._();

  final Map<String, List<String>> _byCategory = {};
  List<String> _categoryNames = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<String> get categories => List.unmodifiable(_categoryNames);

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/words.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final cats = json['categories'] as Map<String, dynamic>;
    cats.forEach((name, list) {
      final words = (list as List)
          .map((w) => (w as String).trim().toUpperCase())
          .where((w) => w.length >= 3)
          .toSet()
          .toList();
      words.sort();
      _byCategory[name] = words;
    });
    _categoryNames = _byCategory.keys.toList()..sort();
    _loaded = true;
  }

  /// For tests / non-async use.
  void loadFromMap(Map<String, List<String>> data) {
    _byCategory.clear();
    data.forEach((k, v) {
      _byCategory[k] = v.map((e) => e.toUpperCase()).toList();
    });
    _categoryNames = _byCategory.keys.toList()..sort();
    _loaded = true;
  }

  String categoryForLevel(int level) {
    final n = _categoryNames.length;
    // Rotate through categories so neighbours differ, deterministic per level.
    return _categoryNames[(level - 1) % n];
  }

  /// Deterministically shuffle a list using a seed (Fisher-Yates).
  List<T> _seededShuffle<T>(List<T> src, int seed) {
    final out = List<T>.from(src);
    final rng = Random(seed);
    for (int i = out.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = out[i];
      out[i] = out[j];
      out[j] = tmp;
    }
    return out;
  }

  /// Select [count] distinct words for a level within [minLen]..[maxLen].
  ///
  /// Deterministic for a given (level, category, count, length window). Words
  /// are drawn from a level-rotated offset into a stably shuffled pool, which
  /// naturally avoids nearby repetition until the pool cycles.
  List<String> selectWords({
    required int level,
    required String category,
    required int count,
    required int minLen,
    required int maxLen,
  }) {
    final pool = _byCategory[category] ?? const [];
    // Stable shuffle keyed by category name so each category has its own order.
    final shuffled = _seededShuffle(pool, category.hashCode & 0x7fffffff);

    bool fits(String w) => w.length >= minLen && w.length <= maxLen;

    final primary = shuffled.where(fits).toList();
    // Fallback: widen from all categories if a category is too small.
    final widened = <String>[];
    if (primary.length < count) {
      for (final c in _categoryNames) {
        for (final w in _byCategory[c]!) {
          if (w.length >= minLen && w.length <= maxLen) widened.add(w);
        }
      }
    }
    final source = primary.length >= count ? primary : widened.toSet().toList()
      ..sort();
    final ordered = primary.length >= count
        ? primary
        : _seededShuffle(source, 99991);

    if (ordered.isEmpty) return [];

    final chosen = <String>[];
    final seen = <String>{};
    // Offset by level to move the window forward each level.
    int idx = (level * 7) % ordered.length;
    int guard = 0;
    while (chosen.length < count && guard < ordered.length * 2) {
      final w = ordered[idx % ordered.length];
      if (!seen.contains(w)) {
        seen.add(w);
        chosen.add(w);
      }
      idx++;
      guard++;
    }
    return chosen;
  }
}
