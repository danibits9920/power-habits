import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:power_habits/app.dart';
import 'package:power_habits/core/providers.dart';
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
  testWidgets('PowerHabitsApp renders Hoy and switches to Metas, Progreso, and Ajustes', (
    WidgetTester tester,
  ) async {
    _setPhoneViewport(tester);

    var appReadyCount = 0;
    var readyContextHasNavigator = false;
    var readyContextHasSpanishLocale = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(
            () => _TestThemeModeNotifier(ThemeMode.light),
          ),
        ],
        child: PowerHabitsApp(
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

    // Initial tab is Hoy.
    expect(
      find.text('Tus rutinas y tareas del día aparecerán aquí.'),
      findsOneWidget,
    );

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

    // Switch to Metas.
    await tester.tap(find.text('Metas').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Define metas por unidades y sigue tu avance paso a paso.'),
      findsOneWidget,
    );

    // Switch to Progreso.
    await tester.tap(find.text('Progreso').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Consulta tu constancia mensual, balance y logros.'),
      findsOneWidget,
    );

    // Open Ajustes route and pop back.
    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    expect(
      find.text('Preferencias de apariencia, recordatorios y respaldo local.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(
      find.text('Consulta tu constancia mensual, balance y logros.'),
      findsOneWidget,
    );
  });

  testWidgets('PowerHabitsApp renders cleanly in Light and Dark modes without resetting tab', (
    WidgetTester tester,
  ) async {
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
  });

  testWidgets('Soft Glass primitives render and showPowerToast displays feedback', (
    WidgetTester tester,
  ) async {
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
  });
}
