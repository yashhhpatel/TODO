import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'core/route_observer.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'features/offline/offline_overlay.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'services/player_service.dart';

class WordFinderApp extends StatelessWidget {
  const WordFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorObservers: [appRouteObserver],
      builder: (context, child) {
        // Global offline overlay preserves navigation underneath.
        return Stack(
          children: [
            if (child != null) child,
            const OfflineOverlay(),
          ],
        );
      },
      home: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(onDone: () => setState(() => _splashDone = true));
    }
    final player = context.watch<PlayerService>();
    if (!player.onboardingDone) {
      return const OnboardingScreen();
    }
    return const HomeScreen();
  }
}
