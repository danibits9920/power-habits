import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:power_habits/app.dart';
import 'package:power_habits/core/providers.dart';
import 'package:power_habits/data/db.dart';
import 'package:power_habits/design/primitives.dart';
import 'package:power_habits/design/tokens.dart';

class _TestThemeModeNotifier extends ThemeModeNotifier {
  _TestThemeModeNotifier(this._initialMode);

  final ThemeMode _initialMode;

  @override
  ThemeMode build() => _initialMode;

  @override
  Future<void> setMode(ThemeMode mode) async {
    state = mode;
  }
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets(
    'Integrated PowerHabitsApp renders real Hoy, Metas, Progreso, and Ajustes',
    (WidgetTester tester) async {
      _setPhoneViewport(tester);

      final db = AppDb.forTesting(NativeDatabase.memory());
      var appReadyCount = 0;
      var readyContextHasNavigator = false;
      var readyContextHasSpanishLocale = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(db),
            themeModeProvider.overrideWith(
              () => _TestThemeModeNotifier(ThemeMode.light),
            ),
          ],
          child: PowerHabitsApp(
            enableStartupHooks: false,
            onAppReady: (ctx, _) {
              appReadyCount++;
              readyContextHasNavigator = Navigator.maybeOf(ctx) != null;
              readyContextHasSpanishLocale =
                  Localizations.localeOf(ctx).languageCode == 'es';
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // onAppReady fires once after first frame with Navigator + Spanish locale.
      expect(appReadyCount, 1);
      expect(readyContextHasNavigator, isTrue);
      expect(readyContextHasSpanishLocale, isTrue);

      // Initial tab is real TodayPage showing clean first-run empty state.
      expect(find.text('Crear primera rutina'), findsOneWidget);
      expect(find.text('Cargar ejemplos iniciales'), findsOneWidget);

      // Verify >= 48dp touch target on floating bottom pill nav buttons.
      for (final label in const ['Hoy', 'Metas', 'Progreso']) {
        final navButton = find.ancestor(
          of: find.text(label).last,
          matching: find.byType(InkWell),
        );
        final size = tester.getSize(navButton.first);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }

      // Seed initial examples via 1-tap CTA on real TodayPage.
      await tester.tap(find.text('Cargar ejemplos iniciales'));
      await tester.pumpAndSettle();
      expect(find.text('Progreso de hoy'), findsOneWidget);
      expect(find.text('Skincare mañana'), findsOneWidget);

      // Switch to real GoalsPage.
      await tester.tap(find.text('Metas').last);
      await tester.pumpAndSettle();
      expect(find.text('Aún no tienes metas'), findsOneWidget);

      // Switch to real ProgressPage.
      await tester.tap(find.text('Progreso').last);
      await tester.pumpAndSettle();
      expect(find.text('Constancia mensual'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Estadísticas del mes'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView).last, const Offset(0, 300));
      await tester.pumpAndSettle();

      // Open real SettingsPage and pop back.
      await tester.tap(find.byTooltip('Ajustes').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Preferencias, respaldos y actualizaciones'),
        findsOneWidget,
      );
      expect(find.text('Tema de la interfaz'), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, -320));
      await tester.pumpAndSettle();
      expect(find.text('RESPALDO LOCAL JSON'), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, 320));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('Constancia mensual'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Cleanly unmount before closing Drift in-memory DB.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
    },
  );

  testWidgets(
    'PowerHabitsApp renders cleanly in Light and Dark modes without resetting tab',
    (WidgetTester tester) async {
      _setPhoneViewport(tester);

      final container = ProviderContainer(
        overrides: [
          themeModeProvider.overrideWith(
            () => _TestThemeModeNotifier(ThemeMode.light),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const PowerHabitsApp(
            enableStartupHooks: false,
            todayPage: Center(child: Text('Pantalla Hoy Inyectada')),
            goalsPage: Center(child: Text('Pantalla Metas Inyectada')),
            progressPage: Center(child: Text('Pantalla Progreso Inyectada')),
            settingsPage: Center(child: Text('Pantalla Ajustes Inyectada')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pantalla Hoy Inyectada'), findsOneWidget);

      // Verify Light PowerColors extension is active.
      final lightContext = tester.element(find.text('Pantalla Hoy Inyectada'));
      expect(lightContext.pc.bgTop, PowerColors.light.bgTop);

      // Navigate to Metas tab before switching theme.
      await tester.tap(find.text('Metas'));
      await tester.pumpAndSettle();
      expect(find.text('Pantalla Metas Inyectada'), findsOneWidget);

      // Switch dynamically to Dark mode.
      await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      // Still on Metas tab and now using Dark PowerColors.
      expect(find.text('Pantalla Metas Inyectada'), findsOneWidget);
      final darkContext = tester.element(find.text('Pantalla Metas Inyectada'));
      expect(darkContext.pc.bgTop, PowerColors.dark.bgTop);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Soft Glass primitives render and showPowerToast displays feedback',
    (WidgetTester tester) async {
      _setPhoneViewport(tester);

      var actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildPowerTheme(Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (context) => ListView(
                padding: const EdgeInsets.all(Sp.x4),
                children: [
                  const SectionHeader(
                    title: 'Rutinas de hoy',
                    trailingLabel: '3/5',
                    icon: LucideIcons.sun,
                  ),
                  const Wrap(
                    spacing: Sp.x2,
                    children: [
                      MetricPill(value: '67%', label: 'hoy'),
                      MetricPill(
                        value: '14/30',
                        tone: MetricPillTone.neon,
                        icon: LucideIcons.check,
                      ),
                      MetricPill(value: 'Personal', tone: MetricPillTone.pink),
                      MetricPill(value: 'Laboral', tone: MetricPillTone.work),
                    ],
                  ),
                  const SizedBox(height: Sp.x4),
                  GlassEmptyState(
                    icon: LucideIcons.calendarCheck,
                    title: 'Sin rutinas pendientes',
                    subtitle: 'Agrega una rutina para comenzar tu día.',
                    actionLabel: 'Nueva rutina',
                    actionIcon: LucideIcons.plus,
                    onAction: () {
                      actionTapped = true;
                      showPowerToast(
                        context,
                        'Rutina guardada',
                        isHighlight: true,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rutinas de hoy'), findsOneWidget);
      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
      expect(find.text('14/30'), findsOneWidget);

      await tester.tap(find.text('Nueva rutina'));
      await tester.pumpAndSettle();

      expect(actionTapped, isTrue);
      expect(find.text('Rutina guardada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Bottom sheet modals render above the floating bottom navigation bar',
    (WidgetTester tester) async {
      _setPhoneViewport(tester);

      final db = AppDb.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(db),
            themeModeProvider.overrideWith(
              () => _TestThemeModeNotifier(ThemeMode.light),
            ),
          ],
          child: const PowerHabitsApp(enableStartupHooks: false),
        ),
      );
      await tester.pumpAndSettle();

      // Open the "Crear nuevo" modal sheet from the top '+' button on Hoy.
      await tester.tap(find.byTooltip('Crear rutina o tarea'));
      await tester.pumpAndSettle();

      expect(find.text('Crear nuevo'), findsOneWidget);
      expect(find.text('Nueva tarea'), findsOneWidget);

      // Tapping "Nueva tarea" (positioned at the bottom of the sheet) must hit
      // the sheet itself and NOT be obstructed by the floating bottom nav bar.
      await tester.tap(find.text('Nueva tarea'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva tarea'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
    },
  );
}
