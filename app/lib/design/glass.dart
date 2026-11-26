// Primitivas compartidas Soft Glass Minimal (UI/UX Pro Max: vidrio esmerilado diurno, 48dp touch targets, cero emojis).
import 'dart:ui';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Fondo atmosférico limpio (gris/blanco + halo rosado pastel muy suave detrás del vidrio).
class SoftGlassBackground extends StatelessWidget {
  const SoftGlassBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pc.bgTop, pc.bgBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      pc.pinkGlow.withValues(alpha: 0.48),
                      pc.pinkGlow.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -90,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      pc.pinkGlow.withValues(alpha: 0.28),
                      pc.pinkGlow.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Tarjeta translúcida de vidrio esmerilado diurno (blur 16px, borde especular 1px).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Sp.x4),
    this.radius = Rad.lg,
    this.strong = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool strong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: strong ? pc.glassFillStrong : pc.glassFill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: pc.glassBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: pc.ink.withValues(alpha: 0.045),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

/// Control segmentado tipo píldora (Todo | Personal | Laboral u otros).
class GlassSegmented<T> extends StatelessWidget {
  const GlassSegmented({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return GlassCard(
      padding: const EdgeInsets.all(4),
      radius: Rad.pill,
      child: Row(
        children: [
          for (final (itemValue, label) in items)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(itemValue),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  constraints: const BoxConstraints(minHeight: 40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == itemValue
                        ? pc.glassFillStrong
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(Rad.pill),
                    boxShadow: value == itemValue
                        ? [
                            BoxShadow(
                              color: pc.ink.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label,
                    style: context.tt.labelMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: value == itemValue
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: value == itemValue ? pc.ink : pc.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Insignia sutil de contexto (Personal = rosado pastel, Laboral = gris neutro).
class ContextBadge extends StatelessWidget {
  const ContextBadge({super.key, required this.contextType, this.compact = false});

  final String contextType; // 'personal' | 'work'
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final isWork = contextType == 'work';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 2.5 : 3.5,
      ),
      decoration: BoxDecoration(
        color: isWork ? pc.workSoft : pc.pinkSoft,
        borderRadius: BorderRadius.circular(Rad.pill),
      ),
      child: Text(
        isWork ? (compact ? 'L' : 'Laboral') : (compact ? 'P' : 'Personal'),
        style: TextStyle(
          fontFamily: 'WorkSans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isWork ? pc.onWorkSoft : pc.onPinkSoft,
        ),
      ),
    );
  }
}

/// Barra de progreso minimalista con relleno verde fosforescente (#6BFF3B) o grafito para laboral.
class NeonProgressBar extends StatelessWidget {
  const NeonProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.isWork = false,
  });

  final double progress;
  final double height;
  final bool isWork;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final clamped = progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(Rad.pill),
      child: Container(
        height: height,
        width: double.infinity,
        color: pc.trackBg,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: clamped),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          builder: (_, val, _) => FractionallySizedBox(
            widthFactor: val,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: isWork ? pc.onWorkSoft : pc.neon,
                borderRadius: BorderRadius.circular(Rad.pill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón primario en verde fosforescente con texto carbón (>12:1 contraste WCAG).
class PrimaryNeonButton extends StatelessWidget {
  const PrimaryNeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: compact ? 44 : 50),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: pc.neon,
          foregroundColor: pc.onNeon,
          disabledBackgroundColor: pc.trackBg,
          disabledForegroundColor: pc.inkMuted,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? Sp.x4 : Sp.x5,
            vertical: compact ? Sp.x2 : Sp.x3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Rad.pill),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17),
              const SizedBox(width: 7),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// Botón de ícono circular de vidrio esmerilado con área táctil >= 48x48dp.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(Rad.pill),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: pc.glassFillStrong,
              shape: BoxShape.circle,
              border: Border.all(color: pc.glassBorder),
            ),
            child: Icon(icon, size: 20, color: pc.ink),
          ),
        ),
      ),
    );
  }
}

/// Hoja modal inferior unificada en estilo Soft Glass Minimal.
Future<T?> showPowerSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
}) {
  final pc = context.pc;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final inset = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: pc.glassFillStrong,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border(top: BorderSide(color: pc.glassBorder)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: pc.divider,
                        borderRadius: BorderRadius.circular(Rad.pill),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Sp.x5,
                      Sp.x3,
                      Sp.x3,
                      Sp.x2,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(title, style: ctx.tt.titleLarge),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: Icon(LucideIcons.x, color: pc.inkMuted, size: 20),
                        ),
                      ],
                    ),
                  ),
                  Flexible(child: builder(ctx)),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
