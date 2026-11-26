// Design tokens — Power Habits v2 (Soft Glass Minimal · UI/UX Pro Max)
import 'package:material_ui/material_ui.dart';

class Sp {
  Sp._();
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
}

class Rad {
  Rad._();
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double pill = 999;
}

const List<FontFeature> kTabular = [FontFeature.tabularFigures()];

@immutable
class PowerColors extends ThemeExtension<PowerColors> {
  const PowerColors({
    required this.bgTop,
    required this.bgBottom,
    required this.pinkGlow,
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassBorder,
    required this.divider,
    required this.ink,
    required this.inkMuted,
    required this.neon,
    required this.onNeon,
    required this.pink,
    required this.pinkSoft,
    required this.onPinkSoft,
    required this.workSoft,
    required this.onWorkSoft,
    required this.trackBg,
    required this.danger,
    required this.warning,
    required this.warningSoft,
  });

  final Color bgTop;
  final Color bgBottom;
  final Color pinkGlow;
  final Color glassFill;
  final Color glassFillStrong;
  final Color glassBorder;
  final Color divider;
  final Color ink;
  final Color inkMuted;
  final Color neon;
  final Color onNeon;
  final Color pink;
  final Color pinkSoft;
  final Color onPinkSoft;
  final Color workSoft;
  final Color onWorkSoft;
  final Color trackBg;
  final Color danger;
  final Color warning;
  final Color warningSoft;

  static const light = PowerColors(
    bgTop: Color(0xFFF3F4F6),
    bgBottom: Color(0xFFFFFFFF),
    pinkGlow: Color(0xFFF8C8DC),
    glassFill: Color(0xB8FFFFFF), // 72% white frosted glass
    glassFillStrong: Color(0xE6FFFFFF), // 90% white frosted glass
    glassBorder: Color(0xE0FFFFFF),
    divider: Color(0xFFE5E7EB),
    ink: Color(0xFF141517),
    inkMuted: Color(0xFF5F6570),
    neon: Color(0xFF6BFF3B),
    onNeon: Color(0xFF141517),
    pink: Color(0xFFF8C8DC),
    pinkSoft: Color(0xFFFDECF3),
    onPinkSoft: Color(0xFF5C2840),
    workSoft: Color(0xFFE8EAEE),
    onWorkSoft: Color(0xFF2C2F33),
    trackBg: Color(0xFFE6E8EC),
    danger: Color(0xFFB91C1C),
    warning: Color(0xFF92400E),
    warningSoft: Color(0xFFFEF3C7),
  );

  static const dark = PowerColors(
    bgTop: Color(0xFF111315),
    bgBottom: Color(0xFF181A1E),
    pinkGlow: Color(0xFF4A2536),
    glassFill: Color(0xB31E2126),
    glassFillStrong: Color(0xE622262C),
    glassBorder: Color(0x2EFFFFFF),
    divider: Color(0xFF2C3038),
    ink: Color(0xFFF3F4F6),
    inkMuted: Color(0xFF9CA3AF),
    neon: Color(0xFF6BFF3B),
    onNeon: Color(0xFF111315),
    pink: Color(0xFFF4B6D0),
    pinkSoft: Color(0x33F8C8DC),
    onPinkSoft: Color(0xFFFCDCE9),
    workSoft: Color(0xFF2A2E35),
    onWorkSoft: Color(0xFFD6DAE0),
    trackBg: Color(0xFF2A2E35),
    danger: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    warningSoft: Color(0x33F59E0B),
  );

  @override
  PowerColors copyWith({
    Color? bgTop,
    Color? bgBottom,
    Color? pinkGlow,
    Color? glassFill,
    Color? glassFillStrong,
    Color? glassBorder,
    Color? divider,
    Color? ink,
    Color? inkMuted,
    Color? neon,
    Color? onNeon,
    Color? pink,
    Color? pinkSoft,
    Color? onPinkSoft,
    Color? workSoft,
    Color? onWorkSoft,
    Color? trackBg,
    Color? danger,
    Color? warning,
    Color? warningSoft,
  }) => PowerColors(
    bgTop: bgTop ?? this.bgTop,
    bgBottom: bgBottom ?? this.bgBottom,
    pinkGlow: pinkGlow ?? this.pinkGlow,
    glassFill: glassFill ?? this.glassFill,
    glassFillStrong: glassFillStrong ?? this.glassFillStrong,
    glassBorder: glassBorder ?? this.glassBorder,
    divider: divider ?? this.divider,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    neon: neon ?? this.neon,
    onNeon: onNeon ?? this.onNeon,
    pink: pink ?? this.pink,
    pinkSoft: pinkSoft ?? this.pinkSoft,
    onPinkSoft: onPinkSoft ?? this.onPinkSoft,
    workSoft: workSoft ?? this.workSoft,
    onWorkSoft: onWorkSoft ?? this.onWorkSoft,
    trackBg: trackBg ?? this.trackBg,
    danger: danger ?? this.danger,
    warning: warning ?? this.warning,
    warningSoft: warningSoft ?? this.warningSoft,
  );

  @override
  PowerColors lerp(ThemeExtension<PowerColors>? other, double t) {
    if (other is! PowerColors) return this;
    return PowerColors(
      bgTop: Color.lerp(bgTop, other.bgTop, t)!,
      bgBottom: Color.lerp(bgBottom, other.bgBottom, t)!,
      pinkGlow: Color.lerp(pinkGlow, other.pinkGlow, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassFillStrong: Color.lerp(glassFillStrong, other.glassFillStrong, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      neon: Color.lerp(neon, other.neon, t)!,
      onNeon: Color.lerp(onNeon, other.onNeon, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
      pinkSoft: Color.lerp(pinkSoft, other.pinkSoft, t)!,
      onPinkSoft: Color.lerp(onPinkSoft, other.onPinkSoft, t)!,
      workSoft: Color.lerp(workSoft, other.workSoft, t)!,
      onWorkSoft: Color.lerp(onWorkSoft, other.onWorkSoft, t)!,
      trackBg: Color.lerp(trackBg, other.trackBg, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
    );
  }
}

ThemeData buildPowerTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final pc = isDark ? PowerColors.dark : PowerColors.light;

  final baseText = TextTheme(
    headlineMedium: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      color: pc.ink,
      height: 1.15,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 19,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: pc.ink,
      height: 1.2,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.15,
      color: pc.ink,
      height: 1.25,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'WorkSans',
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: pc.ink,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'WorkSans',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: pc.ink,
      height: 1.45,
    ),
    bodySmall: TextStyle(
      fontFamily: 'WorkSans',
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      color: pc.inkMuted,
      height: 1.35,
    ),
    labelMedium: TextStyle(
      fontFamily: 'WorkSans',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: pc.inkMuted,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'WorkSans',
    scaffoldBackgroundColor: pc.bgTop,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: pc.neon,
      onPrimary: pc.onNeon,
      secondary: pc.pink,
      onSecondary: pc.onPinkSoft,
      error: pc.danger,
      onError: Colors.white,
      surface: pc.glassFillStrong,
      onSurface: pc.ink,
    ),
    textTheme: baseText,
    dividerColor: pc.divider,
    extensions: [pc],
  );
}

extension PowerThemeX on BuildContext {
  PowerColors get pc => Theme.of(this).extension<PowerColors>() ?? PowerColors.light;
  TextTheme get tt => Theme.of(this).textTheme;
}
