// Identidad visual única de Power Habits: isotipo "rayo + check minimalista"
// en carbón (#141517) y verde fosforescente (#6BFF3B) sobre vidrio porcelana con halo rosado pastel.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Isotipo vectorial reutilizable de Power Habits con soporte de animación de trazado ([drawProgress]).
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
    return Semantics(
      label: 'Logo de Power Habits',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _PowerHabitsLogoPainter(
            progress: drawProgress.clamp(0.0, 1.0),
            showTile: showTile,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
        ),
      ),
    );
  }
}

class _PowerHabitsLogoPainter extends CustomPainter {
  _PowerHabitsLogoPainter({
    required this.progress,
    required this.showTile,
    required this.isDark,
  });

  final double progress;
  final bool showTile;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Offset.zero & Size(s, s);
    final radius = Radius.circular(s * 0.27);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    if (showTile) {
      // Base porcelana / vidrio claro (siempre fiel al ícono elegido).
      final basePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFFF3F4F6), Color(0xFFFFFFFF)]
              : const [Color(0xFFFFFFFF), Color(0xFFF3F4F6)],
        ).createShader(rect);
      canvas.drawRRect(rrect, basePaint);

      // Halo suave rosado pastel superior derecho + acento inferior izquierdo.
      canvas.save();
      canvas.clipRRect(rrect);
      final pinkGlow = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.75, -0.7),
          radius: 0.95,
          colors: [
            const Color(0xFFF8C8DC).withValues(alpha: 0.72),
            const Color(0xFFF8C8DC).withValues(alpha: 0.0),
          ],
        ).createShader(rect);
      canvas.drawRect(rect, pinkGlow);

      final neonWash = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.75, 0.85),
          radius: 0.75,
          colors: [
            const Color(0xFF6BFF3B).withValues(alpha: 0.16),
            const Color(0xFF6BFF3B).withValues(alpha: 0.0),
          ],
        ).createShader(rect);
      canvas.drawRect(rect, neonWash);
      canvas.restore();

      // Borde especular fino.
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, s * 0.022)
        ..color = const Color(0xFFE5E7EB);
      canvas.drawRRect(rrect.deflate(borderPaint.strokeWidth / 2), borderPaint);
    }

    // Trazo 1: Rayo minimalista ascendente en carbón (#141517).
    final boltPath = Path()
      ..moveTo(s * 0.56, s * 0.20)
      ..lineTo(s * 0.30, s * 0.54)
      ..lineTo(s * 0.48, s * 0.54);

    // Trazo 2: Check impulsado en verde fosforescente (#6BFF3B) que nace del quiebre del rayo.
    final checkPath = Path()
      ..moveTo(s * 0.38, s * 0.61)
      ..lineTo(s * 0.49, s * 0.76)
      ..lineTo(s * 0.74, s * 0.38);

    final strokeW = s * 0.105;

    final boltPaint = Paint()
      ..color = const Color(0xFF141517)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkOutlinePaint = Paint()
      ..color = const Color(0xFF141517)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW * 1.32
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkNeonPaint = Paint()
      ..color = const Color(0xFF6BFF3B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW * 0.92
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pBolt = (progress / 0.55).clamp(0.0, 1.0);
    final pCheck = ((progress - 0.35) / 0.65).clamp(0.0, 1.0);

    _drawTrimmed(canvas, boltPath, boltPaint, pBolt);
    if (pCheck > 0) {
      _drawTrimmed(canvas, checkPath, checkOutlinePaint, pCheck);
      _drawTrimmed(canvas, checkPath, checkNeonPaint, pCheck);
    }
  }

  void _drawTrimmed(Canvas canvas, Path path, Paint paint, double t) {
    if (t <= 0) return;
    if (t >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      final sub = metric.extractPath(0, metric.length * t);
      canvas.drawPath(sub, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PowerHabitsLogoPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.showTile != showTile ||
      oldDelegate.isDark != isDark;
}

/// Splash animado breve (~900 ms) que dibuja el isotipo y se desvanece suavemente.
class PowerSplashOverlay extends StatefulWidget {
  const PowerSplashOverlay({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<PowerSplashOverlay> createState() => _PowerSplashOverlayState();
}

class _PowerSplashOverlayState extends State<PowerSplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _drawAnim;
  late final Animation<double> _fadeOut;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _drawAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.62, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
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
                    PowerHabitsLogo(size: 88, drawProgress: _drawAnim.value),
                    const SizedBox(height: Sp.x4),
                    Text(
                      'Power Habits',
                      style: context.tt.titleLarge?.copyWith(
                        letterSpacing: -0.4,
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
