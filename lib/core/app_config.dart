/// Centralized, easily changeable app configuration.
///
/// The final brand name / logo / store IDs are NOT decided yet, so everything
/// that may change before release lives here rather than being scattered.
class AppConfig {
  AppConfig._();

  // ---- Brand (placeholder, change freely) ----
  static const String appName = 'Word Finder';
  static const String appTagline = 'Find the hidden words';
  static const String appVersion = '1.0.0';

  // ---- Progression ----
  static const int totalLevels = 1000;

  // ---- Monetization: AdMob ----
  // Google official TEST ids. Replace with production ids before release.
  static const bool useTestAds = true;

  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String androidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String androidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String androidRewardedId =
      'ca-app-pub-3940256099942544/5224354917';

  // Show an interstitial after every N completed levels.
  static const int interstitialEveryLevels = 2;
  // Minimum seconds between two full screen ads.
  static const int minSecondsBetweenFullScreenAds = 45;

  // ---- Monetization: Google Play Billing ----
  // NOTE: not yet created in Play Console; configurable placeholder id.
  static const String removeAdsProductId = 'remove_ads';

  // ---- Rewards ----
  static const int rewardedAdCoins = 100;
  static const int levelCompleteAdBonus = 100;

  // ---- Hint costs (coins) ----
  static const int letterHintCost = 25;
  static const int wordHintCost = 50;

  // ---- Legal / contact placeholders ----
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsUrl = 'https://example.com/terms';
  static const String contactEmail = 'support@example.com';
}
