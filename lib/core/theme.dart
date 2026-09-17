import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Black + white design system with a single restrained accent.
class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF0E0E10); // near-black
  static const Color surface = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF6F6F7);
  static const Color card = Color(0xFFFFFFFF);

  static const Color grey900 = Color(0xFF1A1A1D);
  static const Color grey700 = Color(0xFF3D3D42);
  static const Color grey500 = Color(0xFF8A8A93);
  static const Color grey300 = Color(0xFFD6D6DB);
  static const Color grey200 = Color(0xFFE9E9ED);
  static const Color grey100 = Color(0xFFF2F2F4);

  // Single accent used sparingly.
  static const Color accent = Color(0xFF2E6BFF);
  static const Color success = Color(0xFF1FB56A);
  static const Color danger = Color(0xFFE23A46);
  static const Color coin = Color(0xFFF5A623);
  static const Color star = Color(0xFFFFC53D);

  // Selection palette used on the grid (cycled per found word).
  static const List<Color> wordHues = [
    Color(0xFF2E6BFF),
    Color(0xFF1FB56A),
    Color(0xFFF5A623),
    Color(0xFFB25BEE),
    Color(0xFFEE5BA0),
    Color(0xFF16B8C7),
    Color(0xFFE07A3A),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.ink,
        primary: AppColors.ink,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }

  static TextStyle number(double size, {Color? color, FontWeight? weight}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w700,
      color: color ?? AppColors.ink,
      letterSpacing: 0.5,
    );
  }
}

class AppRadii {
  AppRadii._();
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double pill = 100;
}
