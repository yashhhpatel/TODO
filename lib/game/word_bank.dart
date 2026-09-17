import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

/// Loads the word database and serves words of an EXACT length. Words are
/// always bucketed by their real character count, so a word can never be
/// returned at the wrong length even if the source data mistags it.
class WordBank {
  static final WordBank instance = WordBank._();
  WordBank._();

  final Map<int, List<String>> _byLength = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  int countForLength(int len) => _byLength[len]?.length ?? 0;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/words.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final all = <String>[];
    if (json['byLength'] is Map) {
      (json['byLength'] as Map).forEach((_, list) {
        for (final w in (list as List)) {
          all.add(w as String);
        }
      });
    } else if (json['categories'] is Map) {
      (json['categories'] as Map).forEach((_, list) {
        for (final w in (list as List)) {
          all.add(w as String);
        }
      });
    }
    _bucket(all);
    _loaded = true;
  }

  /// For tests: accepts any collection of word lists and buckets by length.
  void loadFromMap(Map<String, List<String>> data) {
    final all = <String>[];
    data.forEach((_, list) => all.addAll(list));
    _byLength.clear();
    _bucket(all);
    _loaded = true;
  }

  void _bucket(List<String> words) {
    final seenByLen = <int, Set<String>>{};
    for (final raw in words) {
      final w = raw.trim().toUpperCase();
      if (w.isEmpty) continue;
      final len = w.length;
      final seen = seenByLen.putIfAbsent(len, () => <String>{});
      if (!RegExp(r'^[A-Z]+$').hasMatch(w)) continue;
      if (seen.add(w)) {
        _byLength.putIfAbsent(len, () => []).add(w);
      }
    }
    // Stable order so shuffles are reproducible across runs.
    for (final list in _byLength.values) {
      list.sort();
    }
  }

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

  /// Selects [count] distinct words of EXACTLY [length] characters for a level.
  ///
  /// Deterministic for a given (level, count, length). A per-level advancing
  /// offset into a stably shuffled pool keeps neighbouring levels from reusing
  /// the same words until the pool cycles.
  ({String category, List<String> words}) selectForLevel({
    required int level,
    required int count,
    required int length,
  }) {
    final pool = (_byLength[length] ?? const [])
        .where((w) => w.length == length)
        .toList();
    if (pool.isEmpty) return (category: '$length Letters', words: const []);

    final shuffled = _seededShuffle(pool, length * 7919 + 13);
    final chosen = <String>[];
    final seen = <String>{};
    int idx = ((level - 1) * count) % shuffled.length;
    int guard = 0;
    final want = count < shuffled.length ? count : shuffled.length;
    while (chosen.length < want && guard < shuffled.length * 2) {
      final w = shuffled[idx % shuffled.length];
      if (seen.add(w)) chosen.add(w);
      idx++;
      guard++;
    }
    return (category: '$length Letters', words: chosen);
  }
}
