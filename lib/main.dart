import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'game/level_generator.dart';
import 'game/word_bank.dart';
import 'services/ad_service.dart';
import 'services/audio_service.dart';
import 'services/connectivity_service.dart';
import 'services/haptic_service.dart';
import 'services/notification_service.dart';
import 'services/player_service.dart';
import 'services/purchase_service.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Load persistent + static data before the first frame.
  final storage = await StorageService.create();
  await WordBank.instance.load();

  final settings = SettingsService(storage);
  final player = PlayerService(storage);
  final connectivity = ConnectivityService();
  final audio = AudioService(settings);
  final haptics = HapticService(settings);
  final ads = AdService();
  final purchases = PurchaseService(player);
  final notifications = NotificationService();
  final generator = LevelGenerator(WordBank.instance);

  // Fire-and-forget async init; the UI never blocks on these.
  connectivity.init();
  ads.init();
  purchases.init();
  notifications.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<LevelGenerator>.value(value: generator),
        Provider<AudioService>.value(value: audio),
        Provider<HapticService>.value(value: haptics),
        Provider<AdService>.value(value: ads),
        Provider<NotificationService>.value(value: notifications),
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        ChangeNotifierProvider<PlayerService>.value(value: player),
        ChangeNotifierProvider<ConnectivityService>.value(value: connectivity),
        ChangeNotifierProvider<PurchaseService>.value(value: purchases),
      ],
      child: const WordFinderApp(),
    ),
  );
}
