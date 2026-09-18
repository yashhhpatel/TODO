import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/app_config.dart';
import 'player_service.dart';

/// Google Play Billing wrapper for the one-time (non-consumable) lifetime
/// "Remove Ads" purchase.
///
/// Premium is unlocked ONLY on a real purchased/restored callback from Google
/// Play — never because a button was pressed. The state is persisted through
/// [PlayerService], so the ad-free state survives restarts, and a silent
/// restore on launch re-grants it after a reinstall or on a new device (and
/// covers the already-owned case).
///
/// Note: this is a client-side flow that relies on Google Play's own purchase
/// validation and acknowledgement. Full server-side receipt verification would
/// require a backend, which this app intentionally does not have.
class PurchaseService extends ChangeNotifier {
  PurchaseService(this._player);
  final PlayerService _player;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _available = false;
  ProductDetails? _removeAdsProduct;
  String? lastError;
  bool purchaseInProgress = false;

  bool get storeAvailable => _available;
  ProductDetails? get removeAdsProduct => _removeAdsProduct;
  String get priceLabel => _removeAdsProduct?.price ?? '—';
  bool get isPremium => _player.premium;

  Future<void> init() async {
    try {
      _available = await _iap.isAvailable();
    } catch (e) {
      _available = false;
      if (kDebugMode) debugPrint('IAP availability failed: $e');
    }
    if (!_available) {
      notifyListeners();
      return;
    }

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => lastError = e.toString(),
    );

    try {
      final resp =
          await _iap.queryProductDetails({AppConfig.removeAdsProductId});
      if (resp.productDetails.isNotEmpty) {
        _removeAdsProduct = resp.productDetails.first;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('queryProductDetails failed: $e');
    }

    // Silently restore any existing entitlement so owners are ad-free after a
    // reinstall / on a new device, and so re-purchase of an owned item is
    // never attempted. Past purchases arrive on the purchase stream above.
    try {
      await _iap.restorePurchases();
    } catch (e) {
      if (kDebugMode) debugPrint('restore on init failed: $e');
    }
    notifyListeners();
  }

  Future<void> buyRemoveAds() async {
    final product = _removeAdsProduct;
    if (product == null || purchaseInProgress) return;
    purchaseInProgress = true;
    lastError = null;
    notifyListeners();
    try {
      final param = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      purchaseInProgress = false;
      lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (!_available) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          purchaseInProgress = true;
          break;
        case PurchaseStatus.error:
          purchaseInProgress = false;
          lastError = p.error?.message ?? 'Purchase failed';
          // An "item already owned" failure means the user owns it on this
          // Google account — recover the entitlement instead of failing.
          final msg = (p.error?.message ?? '').toLowerCase();
          if (!_player.premium &&
              (msg.contains('already') || msg.contains('owned'))) {
            restorePurchases();
          }
          break;
        case PurchaseStatus.canceled:
          purchaseInProgress = false;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (p.productID == AppConfig.removeAdsProductId) {
            _player.setPremium(true);
          }
          purchaseInProgress = false;
          break;
      }
      if (p.pendingCompletePurchase) {
        _iap.completePurchase(p);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
