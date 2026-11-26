// Identidad de marca oficial "Calm Voltage" de Power Habits:
// Isotipo "Volt-Check" en versión Porcelain Daylight (claro) y Carbon Night (oscuro),
// acompañado del logotipo en Bricolage Grotesque ExtraBold + tagline oficial.
import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Isotipo oficial de Power Habits fiel 1:1 al arte aprobado (Porcelain Daylight / Carbon Night).
class PowerHabitsLogo extends StatelessWidget {
  const PowerHabitsLogo({
    super.key,
    this.size = 56,
    this.drawProgress = 1.0,
    this.showTile = true,
  });

  final double size;
  final double drawProgress;
  final bool showTile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clamped = drawProgress.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(size * 0.25);
    final assetPath = isDark
        ? 'assets/brand/logo_dark.png'
        : 'assets/brand/logo_light.png';

    return Semantics(
      label: 'Logo de Power Habits',
      image: true,
      child: Opacity(
        opacity: clamped,
        child: Transform.scale(
          scale: 0.92 + (0.08 * clamped),
          child: Container(
            width: size,
            height: size,
            decoration: showTile
                ? BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2A2E35)
                          : const Color(0xFFE4E6EC),
                      width: size >= 72 ? 1.4 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF141517).withValues(
                          alpha: isDark ? 0.28 : 0.08,
                        ),
                        blurRadius: size * 0.24,
                        offset: Offset(0, size * 0.08),
                      ),
                    ],
                  )
                : null,
            child: ClipRRect(
              borderRadius: radius,
              child: Image.asset(
                assetPath,
                width: size,
                height: size,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lockup horizontal reutilizable (isotipo Volt-Check + wordmark en Bricolage Grotesque + tagline opcional).
class PowerBrandLockup extends StatelessWidget {
  const PowerBrandLockup({
    super.key,
    this.iconSize = 46,
    this.showTagline = true,
  });

  final double iconSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PowerHabitsLogo(size: iconSize),
        const SizedBox(width: Sp.x3),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kBrandName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kFontDisplay,
                  fontSize: iconSize * 0.44,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.65,
                  color: pc.ink,
                  height: 1.05,
                ),
              ),
              if (showTagline) ...[
                const SizedBox(height: 2),
                Text(
                  kBrandTagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: pc.inkMuted,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Splash animado breve (~900 ms) con la identidad "Calm Voltage".
class PowerSplashOverlay extends StatefulWidget {
  const PowerSplashOverlay({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<PowerSplashOverlay> createState() => _PowerSplashOverlayState();
}

class _PowerSplashOverlayState extends State<PowerSplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _revealAnim;
  late final Animation<double> _fadeOut;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
    _revealAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.58, curve: Curves.easeOutBack),
      ),
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.74, 1.0, curve: Curves.easeOut),
      ),
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onFinished();
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => IgnorePointer(
        ignoring: _fadeOut.value < 0.2,
        child: Opacity(
          opacity: _fadeOut.value,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [pc.bgTop, pc.bgBottom],
              ),
            ),
            child: Center(
              child: Transform.scale(
                scale: _scale.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PowerHabitsLogo(size: 92, drawProgress: _revealAnim.value),
                    const SizedBox(height: Sp.x4),
                    Text(
                      kBrandName,
                      style: TextStyle(
                        fontFamily: kFontDisplay,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.9,
                        color: pc.ink,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      kBrandTagline,
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: pc.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
