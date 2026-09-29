import 'package:flutter/material.dart';

/// Wraps a child with a subtle "press to shrink" micro-interaction: the
/// child scales down slightly on touch-down and springs back on release,
/// giving buttons a tactile, premium feel on top of their normal ink ripple.
/// Purely visual — taps still reach [child] unaffected.
class PressableScale extends StatefulWidget {
  final Widget child;
  final double scaleDown;
  const PressableScale({
    super.key,
    required this.child,
    this.scaleDown = 0.96,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
