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

    // Stagger index is tracked separately from list position so the fade-in
    // pacing depends only on actual cards, not spacers/labels between them.
    var i = 0;
    Widget card(Widget child) => _entrance(i++, child);
    const gap = SizedBox(height: 10);
    const sectionGap = SizedBox(height: 24);

    return ScreenScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionLabel('Audio & Feedback'),
          card(_SettingsCard(
            icon: Icons.volume_up_rounded,
            title: 'Sound Effects',
            subtitle: 'Tap and match sound cues',
            active: settings.sound,
            onTap: () => settings.sound = !settings.sound,
            trailing: _ToggleSwitch(
              value: settings.sound,
              onChanged: (v) => settings.sound = v,
            ),
          )),
          gap,
          card(_SettingsCard(
            icon: Icons.music_note_rounded,
            title: 'Music',
            subtitle: 'Background music while you play',
            active: settings.music,
            onTap: () {
              settings.music = !settings.music;
              context.read<AudioService>().syncMusic();
            },
            trailing: _ToggleSwitch(
              value: settings.music,
              onChanged: (v) {
                settings.music = v;
                context.read<AudioService>().syncMusic();
              },
            ),
          )),
          gap,
          card(_SettingsCard(
            icon: Icons.vibration_rounded,
            title: 'Vibration',
            subtitle: 'Haptic feedback on taps and wins',
            active: settings.vibration,
            onTap: () => settings.vibration = !settings.vibration,
            trailing: _ToggleSwitch(
              value: settings.vibration,
              onChanged: (v) => settings.vibration = v,
            ),
          )),
          gap,
          card(_SettingsCard(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Daily reward reminders',
            active: settings.notifications,
            onTap: () =>
                _toggleNotifications(context, !settings.notifications),
            trailing: _ToggleSwitch(
              value: settings.notifications,
              onChanged: (v) => _toggleNotifications(context, v),
            ),
          )),
          sectionGap,
          _sectionLabel('Premium'),
          card(_SettingsCard(
            icon: Icons.workspace_premium_rounded,
            title: player.premium
                ? '${AppConfig.removeAdsLabel} Active'
                : 'Remove Ads',
            subtitle: player.premium
                ? 'Thank you for your support!'
                : 'One-time purchase • lifetime ad-free',
            active: player.premium,
            activeColor: AppColors.success,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumScreen())),
            trailing: player.premium
                ? const Icon(Icons.check_circle_rounded,
                    color: AppColors.success)
                : const Icon(Icons.chevron_right_rounded,
                    color: AppColors.grey500),
          )),
          gap,
          card(_SettingsCard(
            icon: Icons.restore_rounded,
            title: 'Restore Purchases',
            subtitle: 'Already purchased? Restore it on this device',
            onTap: () async {
              await purchases.restorePurchases();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Restore requested'),
                  duration: Duration(seconds: 2),
                ));
              }
            },
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.grey500),
          )),
          sectionGap,
          _sectionLabel('About'),
          card(_SettingsCard(
            icon: Icons.star_rounded,
            title: 'Rate Us',
            subtitle: 'Enjoying the game? Leave a review',
            onTap: () => _openUrl(context, AppConfig.playStoreUrl),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.grey500),
          )),
          gap,
          card(_SettingsCard(
            icon: Icons.share_rounded,
            title: 'Share App',
            subtitle: 'Invite friends to play',
            onTap: () => _shareApp(context),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.grey500),
          )),
          gap,
          card(_SettingsCard(
            icon: Icons.mail_rounded,
            title: 'Contact Us',
            subtitle: 'Get help or send feedback',
            onTap: () => _contactUs(context),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.grey500),
          )),
          gap,
          card(_SettingsCard(
            icon: Icons.privacy_tip_rounded,
            title: 'Privacy Policy',
            subtitle: 'How your data is handled',
            onTap: () => _openUrl(context, AppConfig.privacyPolicyUrl),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.grey500),
          )),
          const SizedBox(height: 20),
          const Center(
            child: Text('Version ${AppConfig.appVersion}',
                style:
                    TextStyle(color: AppColors.grey500, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _toggleNotifications(BuildContext context, bool v) {
    final settings = context.read<SettingsService>();
    final player = context.read<PlayerService>();
    settings.notifications = v;
    context.read<NotificationService>().scheduleDailyReminder(
          enabled: v,
          claimedToday: !player.canClaimDailyReward,
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

  /// Lightweight fade + slide-up entrance so the list feels polished on
  /// open, without pulling in an animation package.
  Widget _entrance(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 30),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 12),
          child: c,
        ),
      ),
      child: child,
    );
  }
}

/// A single Settings option rendered as its own clean, consistent card:
/// icon avatar, title, optional short description, and a trailing control.
/// The icon avatar tints with the app's accent color when [active] is true
/// (e.g. a toggle is ON) and stays a neutral grey otherwise, so the state is
/// obvious at a glance using only colors already in the app's palette.
class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool active;
  final Color? activeColor;

  const _SettingsCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.trailing,
    this.onTap,
    this.active = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final tint = activeColor ?? AppColors.accent;
    final iconBg = active ? tint.withOpacity(0.12) : AppColors.grey100;
    final iconColor = active ? tint : AppColors.grey500;

    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: const TextStyle(
                          color: AppColors.grey500, fontSize: 12)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

/// Switch styled to match the app's ON/OFF language used across Settings:
/// accent when ON, neutral grey when OFF.
class _ToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: AppColors.accent,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: AppColors.grey300,
      trackOutlineColor:
          WidgetStateProperty.all(Colors.transparent),
    );
  }
}
