// Primitivas reutilizables Soft Glass Minimal (UI/UX Pro Max: vidrio diurno, >=4.5:1 contraste, cero emojis).
import 'dart:ui';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import 'glass.dart';
import 'tokens.dart';

/// Estado vacío minimalista en tarjeta de vidrio esmerilado con acción opcional.
class GlassEmptyState extends StatelessWidget {
  const GlassEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final tt = context.tt;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: Sp.x6, vertical: Sp.x6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: pc.pinkSoft,
              shape: BoxShape.circle,
              border: Border.all(color: pc.glassBorder),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: pc.onPinkSoft),
          ),
          const SizedBox(height: Sp.x4),
          Text(
            title,
            style: tt.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Sp.x2),
          Text(
            subtitle,
            style: tt.bodyMedium?.copyWith(color: pc.inkMuted),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: Sp.x5),
            action!,
          ] else if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Sp.x5),
            PrimaryNeonButton(
              label: actionLabel!,
              icon: actionIcon,
              onPressed: onAction,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Encabezado limpio de sección con etiqueta o widget opcional a la derecha.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailingLabel,
    this.trailing,
    this.icon,
    this.padding = const EdgeInsets.symmetric(vertical: Sp.x2),
  });

  final String title;
  final String? trailingLabel;
  final Widget? trailing;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final tt = context.tt;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: pc.inkMuted),
            const SizedBox(width: Sp.x2),
          ],
          Expanded(
            child: Text(
              title,
              style: tt.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Sp.x2),
            trailing!,
          ] else if (trailingLabel != null) ...[
            const SizedBox(width: Sp.x2),
            Text(
              trailingLabel!,
              style: tt.bodySmall?.copyWith(
                color: pc.inkMuted,
                fontFeatures: kTabular,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// Variantes semánticas de [MetricPill] garantizando contraste WCAG AA >= 4.5:1.
enum MetricPillTone { neutral, neon, pink, work }

/// Insignia compacta con tipografía tabular para métricas (ej. 67%, 14/30, 7 d).
class MetricPill extends StatelessWidget {
  const MetricPill({
    super.key,
    required this.value,
    this.label,
    this.icon,
    this.tone = MetricPillTone.neutral,
  });

  final String value;
  final String? label;
  final IconData? icon;
  final MetricPillTone tone;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final tt = context.tt;

    final (bg, border, fg, mutedFg) = switch (tone) {
      MetricPillTone.neutral => (
        pc.glassFillStrong,
        pc.glassBorder,
        pc.ink,
        pc.inkMuted,
      ),
      MetricPillTone.neon => (
        pc.neon,
        Colors.transparent,
        pc.onNeon,
        pc.onNeon,
      ),
      MetricPillTone.pink => (
        pc.pinkSoft,
        Colors.transparent,
        pc.onPinkSoft,
        pc.onPinkSoft,
      ),
      MetricPillTone.work => (
        pc.workSoft,
        Colors.transparent,
        pc.onWorkSoft,
        pc.onWorkSoft,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.x3, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Rad.pill),
        border: border == Colors.transparent
            ? null
            : Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            value,
            style: tt.titleMedium?.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: fg,
              fontFeatures: kTabular,
              height: 1.1,
            ),
          ),
          if (label != null && label!.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(
              label!,
              style: tt.labelMedium?.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: mutedFg,
                height: 1.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Aviso flotante Soft Glass Minimal sin ruido visual.
void showPowerToast(
  BuildContext context,
  String message, {
  bool isHighlight = false,
  IconData? icon,
  Duration duration = const Duration(seconds: 2),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final pc = context.pc;
  final tt = context.tt;
  final resolvedIcon = icon ?? (isHighlight ? LucideIcons.check : LucideIcons.info);
  final fg = isHighlight ? pc.onNeon : pc.ink;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(Sp.x4, 0, Sp.x4, Sp.x4),
        padding: EdgeInsets.zero,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(Rad.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Sp.x4,
                vertical: Sp.x3,
              ),
              decoration: BoxDecoration(
                color: isHighlight ? pc.neon : pc.glassFillStrong,
                borderRadius: BorderRadius.circular(Rad.lg),
                border: Border.all(
                  color: isHighlight ? pc.neon : pc.glassBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: pc.ink.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(resolvedIcon, size: 18, color: fg),
                  const SizedBox(width: Sp.x3),
                  Expanded(
                    child: Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
}
