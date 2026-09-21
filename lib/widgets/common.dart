import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Primary filled (black) button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;
  final bool expand;
  final bool large;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
    this.expand = true,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = onTap == null ? AppColors.grey300 : (color ?? AppColors.ink);
    // Auto-contrast: dark text on light buttons, light text on dark buttons.
    final fg = bg.computeLuminance() > 0.5 ? AppColors.ink : Colors.white;
    final vPad = large ? 20.0 : 16.0;
    final fontSize = large ? 18.0 : 16.0;
    final iconSize = large ? 24.0 : 20.0;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: vPad, horizontal: 22),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: fg, size: iconSize),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary outlined button.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: const BorderSide(color: AppColors.grey300, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.ink, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded white card with subtle shadow.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  const SoftCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.grey200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(18),
          child: child,
        ),
      ),
    );
  }
}

/// Coin balance pill.
class CoinPill extends StatelessWidget {
  final int coins;
  const CoinPill({super.key, required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded,
              color: AppColors.coin, size: 20),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: AppTheme.number(16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Row of 1..3 stars (filled up to [count]).
class StarRow extends StatelessWidget {
  final int count;
  final double size;
  const StarRow({super.key, required this.count, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final on = i < count;
        return Icon(
          on ? Icons.star_rounded : Icons.star_outline_rounded,
          color: on ? AppColors.star : AppColors.grey300,
          size: size,
        );
      }),
    );
  }
}

class ScreenScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  const ScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(child: body),
    );
  }
}
