import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks real internet reachability (not just an active interface). Having
/// Wi-Fi does not guarantee internet, so we confirm with a lightweight lookup.
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _sub;

  bool _online = true;
  bool get isOnline => _online;

  Future<void> init() async {
    _sub = _connectivity.onConnectivityChanged.listen((_) => _refresh());
    await _refresh();
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('one.one.one.one')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _refresh() async {
    final results = await _connectivity.checkConnectivity();
    final hasInterface = results.any((r) => r != ConnectivityResult.none);
    final online = hasInterface && await _hasInternet();
    if (online != _online) {
      _online = online;
      notifyListeners();
    }
  }

  /// User-triggered retry from the offline screen.
  Future<bool> retry() async {
    await _refresh();
    return _online;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
