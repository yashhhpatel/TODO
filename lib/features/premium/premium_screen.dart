import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/player_service.dart';
import '../../services/purchase_service.dart';
import '../../widgets/common.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final purchases = context.watch<PurchaseService>();
    final premium = player.premium;

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
                child: const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.star, size: 50),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(premium ? 'You are Premium' : 'Go Ad-Free',
                  style: AppTheme.number(26)),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'A one-time purchase removes all banner and interstitial ads forever.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey700, height: 1.5),
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
                child: Text('Thank you for your support!',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700)),
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
                    : purchases.removeAdsProduct != null
                        ? 'Remove Ads  ${purchases.priceLabel}'
                        : 'Remove Ads',
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
