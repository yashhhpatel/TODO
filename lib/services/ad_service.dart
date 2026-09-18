import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/app_config.dart';

/// Centralized AdMob wrapper. Ads are monetization, never a gameplay gate:
/// every path fails soft. Premium users receive no banner/interstitial.
class AdService {
  bool _initialized = false;
  bool get isInitialized => _initialized;

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  DateTime? _lastFullScreenAd;

  Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      loadInterstitial();
      loadRewarded();
    } catch (e) {
      if (kDebugMode) debugPrint('AdMob init failed: $e');
    }
  }

  // ---- Banner ----
  BannerAd createBanner({required void Function() onLoaded}) {
    return BannerAd(
      adUnitId: AppConfig.androidBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (kDebugMode) debugPrint('Banner failed: $err');
        },
      ),
    );
  }

  // ---- Interstitial ----
  void loadInterstitial() {
    if (!_initialized) return;
    InterstitialAd.load(
      adUnitId: AppConfig.androidInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (err) {
          _interstitial = null;
          if (kDebugMode) debugPrint('Interstitial failed: $err');
        },
      ),
    );
  }

  bool get _fullScreenCooldownOk {
    if (_lastFullScreenAd == null) return true;
    return DateTime.now().difference(_lastFullScreenAd!).inSeconds >=
        AppConfig.minSecondsBetweenFullScreenAds;
  }

  /// Shows an interstitial after every N completed levels for non-premium users.
  /// Never called during active gameplay by design.
  ///
  /// Returns a Future that completes only once the ad is dismissed (or
  /// immediately when no ad is shown). Callers should await this before
  /// navigating to the next level so the level timer never runs during the ad.
  Future<void> maybeShowInterstitial({
    required int completedLevel,
    required bool premium,
  }) async {
    if (premium || !_initialized) return;
    if (completedLevel % AppConfig.interstitialEveryLevels != 0) return;
    if (!_fullScreenCooldownOk) return;
    final ad = _interstitial;
    if (ad == null) {
      loadInterstitial();
      return;
    }
    final completer = Completer<void>();
    void finish() {
      if (!completer.isCompleted) completer.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
        finish();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
        finish();
      },
    );
    _lastFullScreenAd = DateTime.now();
    ad.show();
    _interstitial = null;
    // Safety net in case a dismiss callback never arrives.
    return completer.future.timeout(const Duration(seconds: 120),
        onTimeout: () {});
  }

  // ---- Rewarded ----
  void loadRewarded() {
    if (!_initialized) return;
    RewardedAd.load(
      adUnitId: AppConfig.androidRewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (err) {
          _rewarded = null;
          if (kDebugMode) debugPrint('Rewarded failed: $err');
        },
      ),
    );
  }

  bool get isRewardedReady => _rewarded != null;

  /// Shows a rewarded ad. [onReward] fires ONLY after the SDK confirms the
  /// reward, and at most once. [onUnavailable] fires if no ad was ready.
  void showRewarded({
    required void Function() onReward,
    required void Function() onUnavailable,
  }) {
    final ad = _rewarded;
    if (ad == null || !_initialized) {
      onUnavailable();
      loadRewarded();
      return;
    }
    bool rewarded = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewarded = null;
        loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _rewarded = null;
        loadRewarded();
        onUnavailable();
      },
    );
    _lastFullScreenAd = DateTime.now();
    ad.show(onUserEarnedReward: (_, __) {
      if (!rewarded) {
        rewarded = true;
        onReward();
      }
    });
    _rewarded = null;
  }

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
  }
}
