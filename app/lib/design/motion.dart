// Motor de movimiento táctil, háptica sutil y micro-celebración (respeta disableAnimations).
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Feedback háptico discreto y consistente en Android.
abstract final class PowerHaptics {
  static void tap() => HapticFeedback.selectionClick();
  static void check() => HapticFeedback.lightImpact();
  static void celebrate() => HapticFeedback.mediumImpact();
}

/// Comprueba si el usuario activó "Reducir animaciones" en Android.
bool reduceMotionOf(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Envuelve cualquier control táctil con un micro-rebote spring (sin mover el layout vecino).
class TactilePress extends StatefulWidget {
  const TactilePress({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.965,
    this.haptic = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  @override
  State<TactilePress> createState() => _TactilePressState();
}

class _TactilePressState extends State<TactilePress> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v || !mounted) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) PowerHaptics.tap();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: (_pressed && !reduce) ? widget.scale : 1.0,
        duration: reduce
            ? Duration.zero
            : const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Contador numérico tabular animado para porcentajes y unidades (ej. 45% -> 67%).
class AnimatedPercentText extends StatelessWidget {
  const AnimatedPercentText({
    super.key,
    required this.value,
    this.suffix = '%',
    this.style,
  });

  final int value;
  final String suffix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    if (reduce) {
      return Text('$value$suffix', style: style);
    }
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: value, end: value),
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      builder: (_, animatedVal, _) => Text('$animatedVal$suffix', style: style),
    );
  }
}

/// Micro-celebración sutil (14 chispas geométricas en #6BFF3B, #F8C8DC y #141517)
/// disparada cuando [triggerCount] incrementa (100 % del día o hito desbloqueado).
class CelebrationBurst extends StatefulWidget {
  const CelebrationBurst({
    super.key,
    required this.triggerCount,
    required this.child,
  });

  final int triggerCount;
  final Widget child;

  @override
  State<CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<CelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
  }

  @override
  void didUpdateWidget(covariant CelebrationBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerCount > oldWidget.triggerCount &&
        !reduceMotionOf(context)) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) {
                if (_ctrl.isDismissed || _ctrl.isCompleted) {
                  return const SizedBox.shrink();
                }
                return CustomPaint(
                  painter: _BurstPainter(
                    t: _ctrl.value,
                    neon: pc.neon,
                    pink: pc.pink,
                    ink: pc.ink,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.t,
    required this.neon,
    required this.pink,
    required this.ink,
  });

  final double t;
  final Color neon;
  final Color pink;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.84, size.height * 0.35);
    final ease = Curves.easeOutCubic.transform(t);
    final opacity = (1.0 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
    const count = 14;
    final palette = [neon, pink, neon, ink];

    for (var i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + (i.isEven ? 0.14 : -0.1);
      final dist = (22 + (i % 3) * 16) * ease;
      final dx = origin.dx + math.cos(angle) * dist;
      final dy = origin.dy + math.sin(angle) * dist - (8 * ease) + (14 * t * t);
      final color = palette[i % palette.length].withValues(alpha: opacity);
      final paint = Paint()..color = color;

      if (i % 3 == 0) {
        // Pequeña cápsula rotada
        canvas.save();
        canvas.translate(dx, dy);
        canvas.rotate(angle + t * 2.2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4, -1.8, 8, 3.6),
            const Radius.circular(2),
          ),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(dx, dy), 2.8 + (i % 2) * 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => oldDelegate.t != t;
}
