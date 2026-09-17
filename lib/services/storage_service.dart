import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// The only place that talks to SharedPreferences. Everything else goes through
/// typed helpers here so raw storage calls never leak into widgets.
class StorageService {
  StorageService._(this._prefs);
  final SharedPreferences _prefs;

  static const int schemaVersion = 1;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final svc = StorageService._(prefs);
    await svc._prefs.setInt('schema_version', schemaVersion);
    return svc;
  }

  Map<String, dynamic> readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Corrupted data: recover with defaults rather than crashing.
    }
    return {};
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  bool getBool(String key, {bool fallback = false}) =>
      _prefs.getBool(key) ?? fallback;

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
}
