import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/app_config.dart';
import 'player_service.dart';

/// Google Play Billing wrapper for the one-time "Remove Ads" purchase.
///
/// Premium is unlocked ONLY on a real purchased/restored callback — never
/// because a button was pressed. State is persisted through [PlayerService].
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
