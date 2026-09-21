import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_config.dart';
import '../../core/theme.dart';
import '../../services/player_service.dart';
import '../../services/purchase_service.dart';
import '../../widgets/common.dart';

/// Settings -> Remove Ads. The single purchase surface for the lifetime
/// ad-free product; there is no other "Remove Ads" entry point in the app.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String? _shownError;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final purchases = context.watch<PurchaseService>();
    final premium = player.premium;

    // Surface a failed purchase once (cancellations stay silent by design).
    final error = purchases.lastError;
    if (error != null && error != _shownError) {
      _shownError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), duration: const Duration(seconds: 3)),
        );
        purchases.clearError();
      });
    }

    return ScreenScaffold(
      title: 'Remove Ads',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Icon(
                  premium
                      ? Icons.workspace_premium_rounded
                      : Icons.workspace_premium_outlined,
                  color: AppColors.star,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                premium ? '${AppConfig.removeAdsLabel} Active' : 'Go Ad-Free',
                textAlign: TextAlign.center,
                style: AppTheme.number(26),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                premium
                    ? 'This device is permanently ad-free. Thank you for your support!'
                    : 'A one-time purchase (not a subscription) that gives you '
                        'lifetime ad-free access.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey700, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            const SoftCard(
              child: Column(
                children: [
                  _Benefit(text: 'No banner ads'),
                  _Benefit(text: 'No interstitial ads between levels'),
                  _Benefit(text: 'Rewarded ads stay optional for bonus coins'),
                  _Benefit(text: 'Support future updates'),
                ],
              ),
            ),
            const Spacer(),
            if (premium)
              const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text('Lifetime Ads-Free Active',
                        style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              )
            else ...[
              if (!purchases.storeAvailable)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Store not available. Product must be configured in Google Play Console before purchase works.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                ),
              PrimaryButton(
                label: purchases.purchaseInProgress
                    ? 'Processing…'
                    : '${AppConfig.removeAdsLabel} — ${purchases.priceLabel}',
                icon: Icons.lock_open_rounded,
                onTap: (purchases.removeAdsProduct == null ||
                        purchases.purchaseInProgress)
                    ? null
                    : purchases.buyRemoveAds,
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'Restore Purchases',
                icon: Icons.restore_rounded,
                onTap: purchases.restorePurchases,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final String text;
  const _Benefit({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
