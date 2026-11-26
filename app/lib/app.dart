// Raíz de la aplicación Power Habits (Soft Glass Minimal, Light & Dark, localización es).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import 'core/providers.dart';
import 'core/router.dart';
import 'design/glass.dart';
import 'design/primitives.dart';
import 'design/tokens.dart';

/// Aplicación principal de Power Habits con inyección opcional de pantallas para composición modular.
class PowerHabitsApp extends ConsumerStatefulWidget {
  const PowerHabitsApp({
    super.key,
    this.todayPage,
    this.goalsPage,
    this.progressPage,
    this.settingsPage,
    this.onAppReady,
  });

  final Widget? todayPage;
  final Widget? goalsPage;
  final Widget? progressPage;
  final Widget? settingsPage;
  final void Function(BuildContext context, WidgetRef ref)? onAppReady;

  @override
  ConsumerState<PowerHabitsApp> createState() => _PowerHabitsAppState();
}

class _PowerHabitsAppState extends ConsumerState<PowerHabitsApp> {
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'powerHabitsRoot');
  late GoRouter _router;
  BuildContext? _appInnerContext;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
    if (widget.onAppReady != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final readyContext =
            _rootNavigatorKey.currentContext ?? _appInnerContext ?? context;
        widget.onAppReady?.call(readyContext, ref);
      });
    }
  }

  @override
  void didUpdateWidget(covariant PowerHabitsApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.todayPage != widget.todayPage ||
        oldWidget.goalsPage != widget.goalsPage ||
        oldWidget.progressPage != widget.progressPage ||
        oldWidget.settingsPage != widget.settingsPage) {
      _router.dispose();
      _router = _createRouter();
    }
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  GoRouter _createRouter() => buildAppRouter(
        navigatorKey: _rootNavigatorKey,
        todayPage: widget.todayPage ??
            const _PlaceholderShellPage(
              title: 'Hoy',
              subtitle: 'Tus rutinas y tareas del día aparecerán aquí.',
              icon: LucideIcons.calendarCheck,
            ),
        goalsPage: widget.goalsPage ??
            const _PlaceholderShellPage(
              title: 'Metas',
              subtitle: 'Define metas por unidades y sigue tu avance paso a paso.',
              icon: LucideIcons.target,
            ),
        progressPage: widget.progressPage ??
            const _PlaceholderShellPage(
              title: 'Progreso',
              subtitle: 'Consulta tu constancia mensual, balance y logros.',
              icon: LucideIcons.trendingUp,
            ),
        settingsPage: widget.settingsPage ?? const _PlaceholderSettingsPage(),
      );

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Power Habits',
      debugShowCheckedModeBanner: false,
      theme: buildPowerTheme(Brightness.light),
      darkTheme: buildPowerTheme(Brightness.dark),
      themeMode: themeMode,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
      builder: (context, child) {
        _appInnerContext = context;
        return SoftGlassBackground(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _PlaceholderShellPage extends StatelessWidget {
  const _PlaceholderShellPage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Sp.x4,
          Sp.x4,
          Sp.x4,
          kFloatingNavClearance,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: tt.headlineMedium),
              ),
              GlassIconButton(
                icon: LucideIcons.settings,
                tooltip: 'Ajustes',
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
          const SizedBox(height: Sp.x6),
          GlassEmptyState(
            icon: icon,
            title: title,
            subtitle: subtitle,
          ),
        ],
      ),
    );
  }
}

class _PlaceholderSettingsPage extends StatelessWidget {
  const _PlaceholderSettingsPage();

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Sp.x4),
          children: [
            Row(
              children: [
                GlassIconButton(
                  icon: LucideIcons.arrowLeft,
                  tooltip: 'Volver',
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: Sp.x3),
                Expanded(
                  child: Text('Ajustes', style: tt.headlineMedium),
                ),
              ],
            ),
            const SizedBox(height: Sp.x6),
            const GlassEmptyState(
              icon: LucideIcons.slidersHorizontal,
              title: 'Ajustes',
              subtitle: 'Preferencias de apariencia, recordatorios y respaldo local.',
            ),
          ],
        ),
      ),
    );
  }
}
