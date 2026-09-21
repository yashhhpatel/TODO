import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_config.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../services/notification_service.dart';
import '../../services/player_service.dart';
import '../../services/purchase_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/common.dart';
import '../premium/premium_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final player = context.watch<PlayerService>();
    final purchases = context.read<PurchaseService>();

    return ScreenScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionLabel('Audio & Feedback'),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _switchTile('Sound Effects', Icons.volume_up_rounded,
                    settings.sound, (v) => settings.sound = v),
                _divider(),
                _switchTile('Music', Icons.music_note_rounded, settings.music,
                    (v) {
                  settings.music = v;
                  context.read<AudioService>().syncMusic();
                }),
                _divider(),
                _switchTile('Vibration', Icons.vibration_rounded,
                    settings.vibration, (v) => settings.vibration = v),
                _divider(),
                _switchTile('Notifications', Icons.notifications_rounded,
                    settings.notifications, (v) {
                  settings.notifications = v;
                  context.read<NotificationService>().scheduleDailyReminder(
                        enabled: v,
                        claimedToday: !player.canClaimDailyReward,
                      );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Premium'),
          SoftCard(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumScreen())),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.ink),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    player.premium
                        ? '${AppConfig.removeAdsLabel} Active'
                        : 'Remove Ads',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                if (player.premium)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success)
                else
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.grey500),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _actionTile('Restore Purchases', Icons.restore_rounded, () async {
            await purchases.restorePurchases();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Restore requested'),
                duration: Duration(seconds: 2),
              ));
            }
          }),
          const SizedBox(height: 20),
          _sectionLabel('About'),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _actionTile('Rate Us', Icons.star_rounded,
                    () => _openUrl(context, AppConfig.playStoreUrl)),
                _divider(),
                _actionTile('Share App', Icons.share_rounded,
                    () => _shareApp(context)),
                _divider(),
                _actionTile('Contact Us', Icons.mail_rounded,
                    () => _contactUs(context)),
                _divider(),
                _actionTile('Privacy Policy', Icons.privacy_tip_rounded,
                    () => _openUrl(context, AppConfig.privacyPolicyUrl)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text('Version ${AppConfig.appVersion}',
                style: TextStyle(color: AppColors.grey500, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _todo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Link to be configured before release'),
      duration: Duration(seconds: 2),
    ));
  }

  Future<void> _contactUs(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConfig.contactEmail,
      query: 'subject=${Uri.encodeComponent('${AppConfig.appName} Support')}',
    );
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication)
            .catchError((_) => false);
    if (!launched && context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Contact Us'),
          content: const SelectableText(AppConfig.contactEmail),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url),
            mode: LaunchMode.externalApplication)
        .catchError((_) => false);
    if (!ok && context.mounted) _todo(context);
  }

  Future<void> _shareApp(BuildContext context) async {
    try {
      await Share.share(AppConfig.shareMessage);
    } catch (_) {
      if (context.mounted) _todo(context);
    }
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                color: AppColors.grey500,
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w700)),
      );

  Widget _divider() =>
      const Divider(height: 1, indent: 56, color: AppColors.grey200);

  Widget _switchTile(
      String label, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppColors.ink),
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: Switch(
        value: value,
        activeColor: Colors.white,
        activeTrackColor: AppColors.ink,
        onChanged: onChanged,
      ),
    );
  }

  Widget _actionTile(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.ink),
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppColors.grey500),
      onTap: onTap,
    );
  }
}
