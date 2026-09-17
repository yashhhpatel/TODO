import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_config.dart';
import '../../core/theme.dart';
import '../../services/player_service.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // Register daily activity/streak once at startup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerService>().registerDailyActivity();
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: FadeTransition(
          opacity: _c,
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _LogoMark(),
                const SizedBox(height: 24),
                Text(
                  AppConfig.appName,
                  style: AppTheme.number(30, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppConfig.appTagline,
                  style: TextStyle(color: AppColors.grey500, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Original geometric logo: a rounded square holding stacked "word" bars.
class _LogoMark extends StatelessWidget {
  const _LogoMark();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bar(48, AppColors.ink),
            const SizedBox(height: 7),
            _bar(30, AppColors.accent),
            const SizedBox(height: 7),
            _bar(40, AppColors.ink),
          ],
        ),
      ),
    );
  }

  Widget _bar(double w, Color c) => Container(
        width: w,
        height: 10,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(6),
        ),
      );
}
