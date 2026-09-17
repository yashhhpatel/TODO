import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/connectivity_service.dart';
import '../../widgets/common.dart';

/// Full-screen blocker shown whenever the device has no internet. It sits above
/// the navigator so gameplay cannot continue offline, but the stack underneath
/// is preserved so returning online resumes exactly where the user was.
class OfflineOverlay extends StatefulWidget {
  const OfflineOverlay({super.key});
  @override
  State<OfflineOverlay> createState() => _OfflineOverlayState();
}

class _OfflineOverlayState extends State<OfflineOverlay> {
  bool _checking = false;

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityService>().isOnline;
    if (online) return const SizedBox.shrink();

    return Positioned.fill(
      child: Material(
        color: AppColors.bg,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(Icons.wifi_off_rounded,
                      size: 56, color: AppColors.ink),
                ),
                const SizedBox(height: 28),
                Text('No Internet Connection', style: AppTheme.number(22)),
                const SizedBox(height: 12),
                const Text(
                  'An internet connection is required to play. Please reconnect and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.grey700, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  child: PrimaryButton(
                    label: _checking ? 'Checking…' : 'Retry',
                    icon: Icons.refresh_rounded,
                    onTap: _checking
                        ? null
                        : () async {
                            setState(() => _checking = true);
                            await context.read<ConnectivityService>().retry();
                            if (mounted) setState(() => _checking = false);
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
