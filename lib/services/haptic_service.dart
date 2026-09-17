import 'package:flutter/services.dart';
import 'settings_service.dart';

/// Thin wrapper over Flutter haptics that respects the vibration setting.
class HapticService {
  HapticService(this._settings);
  final SettingsService _settings;

  void light() {
    if (_settings.vibration) HapticFeedback.selectionClick();
  }

  void success() {
    if (_settings.vibration) HapticFeedback.mediumImpact();
  }

  void error() {
    if (_settings.vibration) HapticFeedback.heavyImpact();
  }

  void celebrate() {
    if (_settings.vibration) HapticFeedback.heavyImpact();
  }
}
