// Raíz de la aplicación Power Habits (Soft Glass Minimal, Light & Dark, localización es).
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'core/dates.dart';
import 'core/home_widget.dart';
import 'core/notifier.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'core/updater.dart';
import 'data/db.dart';
import 'design/brand_logo.dart';
import 'design/glass.dart';
import 'design/motion.dart';
import 'design/tokens.dart';
import 'features/goals/goal_form_sheet.dart';
import 'features/goals/goals_page.dart';
import 'features/progress/progress_page.dart';
import 'features/settings/settings_page.dart';
import 'features/today/routine_form_sheet.dart';
import 'features/today/today_page.dart';

/// Aplicación principal de Power Habits con integración completa de pantallas, widgets y servicios.
class PowerHabitsApp extends ConsumerStatefulWidget {
  const PowerHabitsApp({
    super.key,
    this.todayPage,
    this.goalsPage,
    this.progressPage,
    this.settingsPage,
    this.onAppReady,
    this.enableStartupHooks = true,
  });

  final Widget? todayPage;
  final Widget? goalsPage;
  final Widget? progressPage;
  final Widget? settingsPage;
  final void Function(BuildContext context, WidgetRef ref)? onAppReady;
  final bool enableStartupHooks;

  @override
  ConsumerState<PowerHabitsApp> createState() => _PowerHabitsAppState();
}

class _PowerHabitsAppState extends ConsumerState<PowerHabitsApp> {
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'powerHabitsRoot');
  late GoRouter _router;
  AppLifecycleListener? _lifecycle;
  BuildContext? _appInnerContext;
  bool _openingQuickAdd = false;
  late bool _showSplash;

  @override
  void initState() {
    super.initState();
    _showSplash = widget.enableStartupHooks;
    _router = _createRouter();
    if (widget.enableStartupHooks) {
      _lifecycle = AppLifecycleListener(
        onResume: () {
          if (mounted) unawaited(_syncWidget(force: true));
        },
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final readyContext =
          _rootNavigatorKey.currentContext ?? _appInnerContext ?? context;
      if (widget.enableStartupHooks) {
        unawaited(_bootstrapPlatformServices(readyContext));
      }
      widget.onAppReady?.call(readyContext, ref);
    });
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
    _lifecycle?.dispose();
    _router.dispose();
    super.dispose();
  }

  Future<void> _bootstrapPlatformServices(BuildContext readyContext) async {
    await PhoneNotifier.instance.init(
      onMarkDone: _handleNotificationMarkDone,
    );
    if (!mounted) return;

    await _syncWidget(force: true);

    setupHomeWidgetNavigation(
      _handleWidgetRoute,
      onPendingActions: () => unawaited(_syncWidget(force: true)),
    );

    if (readyContext.mounted) {
      unawaited(maybePromptForUpdate(readyContext, ref));
    }
  }

  Future<void> _handleNotificationMarkDone(String routineId) async {
    if (!mounted) return;
    final routineRepo = ref.read(routineRepoProvider);
    final todayKey = dayStr(DateTime.now());
    final completed = await routineRepo.toggleCompletion(
      routineId: routineId,
      dateKey: todayKey,
      forceValue: true,
    );
    if (completed) {
      final totalCompleted = await routineRepo.countCompletedLogs(routineId);
      if (totalCompleted >= 7) {
        final active = await routineRepo.getActive();
        for (final r in active) {
          if (r.id == routineId) {
            await ref.read(achievementRepoProvider).unlockAuto(
                  sourceKey: 'routine:${r.id}:7days',
                  title: '7 días constantes — ${r.title}',
                  detail: 'Completaste esta rutina 7 veces',
                  context: r.context,
                );
            break;
          }
        }
      }
    }
    await _syncWidget(force: true);
  }

  Future<void> _syncWidget({bool force = false}) async {
    if (!mounted) return;
    try {
      await syncTodayWidgetFromDb(ref.read(dbProvider), force: force);
    } catch (_) {
      // Silencioso si la DB fue cerrada en teardown de pruebas.
    }
  }

  Future<void> _onRoutineSaved(Routine routine) async {
    await PhoneNotifier.instance.scheduleForRoutine(routine);
    await _syncWidget(force: true);
  }

  Future<void> _onRoutineDeleted(String routineId) async {
    await PhoneNotifier.instance.cancelForRoutine(routineId);
    await _syncWidget(force: true);
  }

  void _openSettings() {
    _router.push(AppRoutes.settings);
  }

  void _handleWidgetRoute(String rawRoute) {
    if (!mounted) return;
    final uri = Uri.tryParse(rawRoute);
    final path = (uri?.path ?? '').isEmpty ? AppRoutes.today : uri!.path;

    if (path == AppRoutes.settings) {
      _router.push(AppRoutes.settings);
      return;
    }

    if (path == AppRoutes.goals ||
        path == AppRoutes.progress ||
        path == AppRoutes.today) {
      _router.go(path);
    } else {
      _router.go(AppRoutes.today);
    }

    if (uri?.queryParameters['new'] == '1') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _openingQuickAdd) return;
        final navCtx = _rootNavigatorKey.currentContext;
        if (navCtx == null || !navCtx.mounted) return;
        _openingQuickAdd = true;
        final Future<Object?> sheetFuture = path == AppRoutes.goals
            ? showGoalFormSheet(navCtx)
            : showRoutineFormSheet(
                navCtx,
                initialDate: dateOnly(DateTime.now()),
                onSaved: _onRoutineSaved,
                onDeleted: _onRoutineDeleted,
              );
        sheetFuture.whenComplete(() {
          _openingQuickAdd = false;
        });
      });
    }
  }

  GoRouter _createRouter() => buildAppRouter(
        navigatorKey: _rootNavigatorKey,
        todayPage: widget.todayPage ??
            TodayPage(
              onOpenSettings: _openSettings,
              onRoutineSaved: _onRoutineSaved,
              onRoutineDeleted: _onRoutineDeleted,
              onDataChanged: () => unawaited(_syncWidget(force: true)),
            ),
        goalsPage: widget.goalsPage ??
            GoalsPage(
              onOpenSettings: _openSettings,
            ),
        progressPage: widget.progressPage ??
            ProgressPage(
              onOpenSettings: _openSettings,
            ),
        settingsPage: widget.settingsPage ??
            SettingsPage(
              onDataImported: () => unawaited(_syncWidget(force: true)),
            ),
      );

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    if (widget.enableStartupHooks) {
      // Mantiene sincronizado el Widget de Metas ante cualquier +1, paso o creación.
      ref.listen(goalsStreamProvider, (_, next) {
        if (next.hasValue) unawaited(_syncWidget());
      });
    }

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
        final skipSplash = !_showSplash || reduceMotionOf(context);
        return SoftGlassBackground(
          child: Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              if (!skipSplash)
                PowerSplashOverlay(
                  onFinished: () {
                    if (mounted) setState(() => _showSplash = false);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
