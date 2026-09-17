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

  /// Flat, de-duplicated pool of (word, category) within a length band, stably
  /// shuffled so the whole pool has one deterministic order per band. Because
  /// selection walks this shared order with an offset that advances every
  /// level, consecutive levels draw different words until the pool cycles.
  List<MapEntry<String, String>> _bandPool(int minLen, int maxLen) {
    final seen = <String>{};
    final flat = <MapEntry<String, String>>[];
    for (final cat in _categoryNames) {
      for (final w in _byCategory[cat]!) {
        if (w.length >= minLen && w.length <= maxLen && seen.add(w)) {
          flat.add(MapEntry(w, cat));
        }
      }
    }
    // Seed keyed by the band so each length stage has its own stable order.
    return _seededShuffle(flat, minLen * 131 + maxLen);
  }

  /// Selects [count] distinct target words for a level and a fitting category
  /// label. Draws from the full cross-category pool within the length band so
  /// there is always plenty of variety, even for short 3-letter stages where a
  /// single themed category would be too small.
  ///
  /// Deterministic: the same (level, count, band) always yields the same words.
  ({String category, List<String> words}) selectForLevel({
    required int level,
    required int count,
    required int minLen,
    required int maxLen,
  }) {
    var pool = _bandPool(minLen, maxLen);
    // If a stage is too thin, widen downward (shorter words) but never longer
    // than the grid allows (maxLen is the hard cap).
    if (pool.length < count && minLen > 3) {
      pool = _bandPool(3, maxLen);
    }
    if (pool.isEmpty) {
      pool = _bandPool(3, 99); // last resort: anything
    }
    if (pool.isEmpty) return (category: 'Words', words: const []);

    final chosen = <String>[];
    final cats = <String>[];
    final seen = <String>{};
    // Advance the window by a full batch each level → no nearby repeats.
    int idx = ((level - 1) * count) % pool.length;
    int guard = 0;
    while (chosen.length < count && guard < pool.length) {
      final entry = pool[idx % pool.length];
      if (seen.add(entry.key)) {
        chosen.add(entry.key);
        cats.add(entry.value);
      }
      idx++;
      guard++;
    }

    // Label the level with whichever category contributed the most words.
    final counts = <String, int>{};
    for (final c in cats) {
      counts[c] = (counts[c] ?? 0) + 1;
    }
    String label = 'Words';
    int best = -1;
    counts.forEach((c, n) {
      if (n > best) {
        best = n;
        label = c;
      }
    });

    return (category: label, words: chosen);
  }
}
