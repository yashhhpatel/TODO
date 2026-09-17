import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../services/player_service.dart';

/// Bottom anchored banner. Renders nothing for premium users or until the ad
/// has actually loaded, so it never reserves space it can't fill or overlaps
/// content.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});
  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final player = context.read<PlayerService>();
    if (player.premium) return;
    final ads = context.read<AdService>();
    if (!ads.isInitialized) return;
    final banner = ads.createBanner(
      onLoaded: () {
        if (mounted) setState(() => _loaded = true);
      },
    );
    banner.load();
    _ad = banner;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PlayerService>().premium;
    if (premium || !_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
