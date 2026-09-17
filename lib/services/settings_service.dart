import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class SettingsService extends ChangeNotifier {
  SettingsService(this._storage) {
    _sound = _storage.getBool('set_sound', fallback: true);
    _music = _storage.getBool('set_music', fallback: true);
    _vibration = _storage.getBool('set_vibration', fallback: true);
    _notifications = _storage.getBool('set_notifications', fallback: true);
  }

  final StorageService _storage;

  late bool _sound;
  late bool _music;
  late bool _vibration;
  late bool _notifications;

  bool get sound => _sound;
  bool get music => _music;
  bool get vibration => _vibration;
  bool get notifications => _notifications;

  set sound(bool v) {
    _sound = v;
    _storage.setBool('set_sound', v);
    notifyListeners();
  }

  set music(bool v) {
    _music = v;
    _storage.setBool('set_music', v);
    notifyListeners();
  }

  set vibration(bool v) {
    _vibration = v;
    _storage.setBool('set_vibration', v);
    notifyListeners();
  }

  set notifications(bool v) {
    _notifications = v;
    _storage.setBool('set_notifications', v);
    notifyListeners();
  }
}
