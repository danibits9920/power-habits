import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:power_habits/core/dates.dart';
import 'package:power_habits/core/providers.dart';
import 'package:power_habits/data/db.dart';
import 'package:power_habits/data/repos.dart';
import 'package:power_habits/design/glass.dart';
import 'package:power_habits/design/tokens.dart';
import 'package:power_habits/features/goals/goals_page.dart';
import 'package:power_habits/features/progress/progress_metrics.dart';
import 'package:power_habits/features/progress/progress_page.dart';

void main() {
  group('GoalRepo & logros automáticos', () {
    late AppDb db;
    late AchievementRepo achievementRepo;
    late GoalRepo goalRepo;

    setUp(() {
      db = AppDb.forTesting(NativeDatabase.memory());
      achievementRepo = AchievementRepo(db);
      goalRepo = GoalRepo(db, achievementRepo);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'create + adjustProgress desbloquea hitos 25/50/75/100 sin duplicados',
      () async {
        final goalId = await goalRepo.create(
          title: 'Curso de desarrollo',
          context: 'personal',
          unitLabel: 'clases',
          targetValue: 4,
        );

        // 1/4 = 25%
        expect(await goalRepo.adjustProgress(goalId, 1), 25);
        // Retrocede a 0/4 y vuelve a 1/4 -> NO debe duplicar el hito de 25%
        expect(await goalRepo.adjustProgress(goalId, -1), isNull);
        expect(await goalRepo.adjustProgress(goalId, 1), isNull);

        // 2/4 = 50%
        expect(await goalRepo.adjustProgress(goalId, 1), 50);
        // 3/4 = 75%
        expect(await goalRepo.adjustProgress(goalId, 1), 75);
        // 4/4 = 100%
        expect(await goalRepo.adjustProgress(goalId, 1), 100);
        // Exceder targetValue no hace cambios ni duplica
        expect(await goalRepo.adjustProgress(goalId, 1), isNull);

        final goals = await goalRepo.watchActive().first;
        expect(goals, hasLength(1));
        expect(goals.first.currentValue, 4);
        expect(goals.first.milestonesUnlocked, '25,50,75,100');

        final achievements = await achievementRepo.watchAll().first;
        expect(achievements, hasLength(4));
        expect(
          achievements.map((a) => a.sourceKey).toSet(),
          {
            'goal:$goalId:25',
            'goal:$goalId:50',
            'goal:$goalId:75',
            'goal:$goalId:100',
          },
        );
        expect(achievements.every((a) => a.kind == 'auto'), isTrue);
      },
    );

    test(
      'toggleStep sincroniza currentValue y desbloquea hitos correctamente',
      () async {
        final goalId = await goalRepo.create(
          title: 'Lectura técnica',
          context: 'work',
          unitLabel: 'módulos',
          targetValue: 4,
          stepTitles: const [
            'Módulo 1: Arquitectura',
            'Módulo 2: Persistencia',
            'Módulo 3: Pruebas',
            'Módulo 4: Despliegue',
          ],
        );

        var steps = await goalRepo.watchSteps(goalId).first;
        expect(steps, hasLength(4));
        expect(steps.every((s) => !s.completed), isTrue);

        // Marcar paso 1 -> currentValue = 1 (25%)
        final m1 = await goalRepo.toggleStep(steps[0]);
        expect(m1, 25);

        var goal = (await goalRepo.watchActive().first).first;
        expect(goal.currentValue, 1);

        // Marcar paso 2 -> currentValue = 2 (50%)
        steps = await goalRepo.watchSteps(goalId).first;
        final m2 = await goalRepo.toggleStep(steps[1]);
        expect(m2, 50);

        goal = (await goalRepo.watchActive().first).first;
        expect(goal.currentValue, 2);

        // Desmarcar paso 2 -> currentValue regresa a 1
        steps = await goalRepo.watchSteps(goalId).first;
        final undo = await goalRepo.toggleStep(steps[1]);
        expect(undo, isNull);

        goal = (await goalRepo.watchActive().first).first;
        expect(goal.currentValue, 1);

        // Volver a marcar paso 2 -> currentValue = 2, sin duplicar logro 50%
        steps = await goalRepo.watchSteps(goalId).first;
        final redo = await goalRepo.toggleStep(steps[1]);
        expect(redo, isNull);

        goal = (await goalRepo.watchActive().first).first;
        expect(goal.currentValue, 2);

        final achievements = await achievementRepo.watchAll().first;
        expect(achievements, hasLength(2));
      },
    );
  });

  group('progress_metrics — estadísticas Personal vs Laboral y calendario', () {
    Routine makeRoutine({
      required String id,
      required String title,
      required String context,
      required String frequencyType,
      required String anchorDate,
      String weekdaysMask = '1,2,3,4,5,6,7',
    }) {
      return Routine(
        id: id,
        title: title,
        itemType: 'routine',
        context: context,
        timeSlot: 'morning',
        frequencyType: frequencyType,
        weekdaysMask: weekdaysMask,
        anchorDate: anchorDate,
        reminderTimes: '',
        allowQuickNote: true,
        sortOrder: 0,
        createdAt: '2026-06-01T00:00:00Z',
        updatedAt: '2026-06-01T00:00:00Z',
      );
    }

    RoutineLog makeLog({
      required String id,
      required String routineId,
      required String logDate,
      bool completed = true,
    }) {
      return RoutineLog(
        id: id,
        routineId: routineId,
        logDate: logDate,
        completed: completed,
        createdAt: '2026-06-01T00:00:00Z',
        updatedAt: '2026-06-01T00:00:00Z',
      );
    }

    test(
      'rutinas interdiarias y de días específicos NO penalizan días de descanso y calculan % exactos Personal vs Laboral',
      () {
        // Junio 2026: 1 Jun 2026 es Lunes.
        // Analizamos hasta today = 2026-06-10 (10 días transcurridos: Lun 1 .. Mié 10).
        final month = DateTime(2026, 6, 1);
        final today = DateTime(2026, 6, 10);

        // Personal interdiaria desde 2026-06-01:
        // Días programados en Jun 1..10 -> 1, 3, 5, 7, 9 (5 días exactos; días 2,4,6,8,10 son descanso).
        final personalAlt = makeRoutine(
          id: 'r-personal',
          title: 'Entrenar',
          context: 'personal',
          frequencyType: 'alternate',
          anchorDate: '2026-06-01',
        );

        // Laboral L-X-V (1,3,5) desde 2026-06-01:
        // En Jun 1..10: Lun 1, Mié 3, Vie 5, Lun 8, Mié 10 (5 días exactos; Mar/Jue/Sáb/Dom son descanso).
        final workWeekdays = makeRoutine(
          id: 'r-work',
          title: 'Revisión de sprint',
          context: 'work',
          frequencyType: 'weekdays',
          weekdaysMask: '1,3,5',
          anchorDate: '2026-06-01',
        );

        // Personal: cumple 4 de 5 programados -> 80%
        // Laboral: cumple 3 de 5 programados -> 60%
        final logs = [
          makeLog(id: 'l1', routineId: 'r-personal', logDate: '2026-06-01'),
          makeLog(id: 'l2', routineId: 'r-personal', logDate: '2026-06-03'),
          makeLog(id: 'l3', routineId: 'r-personal', logDate: '2026-06-05'),
          makeLog(id: 'l4', routineId: 'r-personal', logDate: '2026-06-09'),
          makeLog(id: 'l5', routineId: 'r-work', logDate: '2026-06-01'),
          makeLog(id: 'l6', routineId: 'r-work', logDate: '2026-06-05'),
          makeLog(id: 'l7', routineId: 'r-work', logDate: '2026-06-08'),
          // Registro con completed=false no debe sumar
          makeLog(
            id: 'l8',
            routineId: 'r-work',
            logDate: '2026-06-10',
            completed: false,
          ),
        ];

        final stats = computeContextMonthlyStats(
          routines: [personalAlt, workWeekdays],
          logs: logs,
          month: month,
          today: today,
        );

        expect(stats.personalScheduled, 5);
        expect(stats.personalCompleted, 4);
        expect(stats.personalPct, 80);

        expect(stats.workScheduled, 5);
        expect(stats.workCompleted, 3);
        expect(stats.workPct, 60);
      },
    );

    test(
      'buildMonthCalendarStatus clasifica completed, missed, notScheduled y future con precisión',
      () {
        // Junio 2026: Lun 1 .. Mar 30. today = 2026-06-05 (Vie).
        final month = DateTime(2026, 6, 1);
        final today = DateTime(2026, 6, 5);

        final altRoutine = makeRoutine(
          id: 'r-alt',
          title: 'Correr',
          context: 'personal',
          frequencyType: 'alternate',
          anchorDate: '2026-06-01',
        );

        final logs = [
          makeLog(id: 'c1', routineId: 'r-alt', logDate: '2026-06-01'),
          // 2026-06-03 tocaba pero no se completó -> missed
        ];

        final status = buildMonthCalendarStatus(altRoutine, logs, month, today);

        expect(status.length, 30);
        // Día 1: programado y cumplido
        expect(status[1], RoutineMonthDayStatus.completed);
        // Día 2: descanso interdiario
        expect(status[2], RoutineMonthDayStatus.notScheduled);
        // Día 3: programado en el pasado sin completar -> missed
        expect(status[3], RoutineMonthDayStatus.missed);
        // Día 4: descanso interdiario
        expect(status[4], RoutineMonthDayStatus.notScheduled);
        // Día 5 (hoy): programado pero aún pendiente -> future (no penaliza antes de acabar el día)
        expect(status[5], RoutineMonthDayStatus.future);
        // Día 6: descanso futuro
        expect(status[6], RoutineMonthDayStatus.notScheduled);
        // Día 7: programado futuro
        expect(status[7], RoutineMonthDayStatus.future);

        expect(countCompletedDays(status), 1);
      },
    );
  });

  group('Widget smoke tests (390x844)', () {
    testWidgets(
      'GoalsPage renderiza metas, línea de hitos y filtro sin desbordes',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        const sampleGoal = Goal(
          id: 'g-1',
          title: 'Curso de Flutter',
          context: 'personal',
          unitLabel: 'clases',
          currentValue: 14,
          targetValue: 30,
          milestonesUnlocked: '25',
          createdAt: '2026-06-01T00:00:00Z',
          updatedAt: '2026-06-01T00:00:00Z',
        );
        const sampleSteps = [
          GoalStep(
            id: 's-1',
            goalId: 'g-1',
            stepIndex: 1,
            title: 'Clase 1: Fundamentos',
            completed: true,
            createdAt: '2026-06-01T00:00:00Z',
            updatedAt: '2026-06-01T00:00:00Z',
          ),
          GoalStep(
            id: 's-2',
            goalId: 'g-1',
            stepIndex: 2,
            title: 'Clase 2: Estado',
            completed: false,
            createdAt: '2026-06-01T00:00:00Z',
            updatedAt: '2026-06-01T00:00:00Z',
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              goalsStreamProvider.overrideWith((_) => Stream.value([sampleGoal])),
              goalStepsProvider('g-1')
                  .overrideWith((_) => Stream.value(sampleSteps)),
            ],
            child: MaterialApp(
              theme: buildPowerTheme(Brightness.light),
              home: Scaffold(
                body: SoftGlassBackground(
                  child: GoalsPage(onOpenSettings: () {}),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Metas'), findsOneWidget);
        expect(find.text('Curso de Flutter'), findsOneWidget);
        expect(find.text('+1 clases'), findsOneWidget);
        expect(find.text('47%'), findsOneWidget);
        expect(find.text('Pasos (1/2)'), findsOneWidget);
      },
    );

    testWidgets(
      'ProgressPage renderiza constancia mensual, estadísticas y línea de logros sin desbordes',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final todayKey = dayStr(DateTime.now());
        final sampleRoutine = Routine(
          id: 'r-1',
          title: 'Lectura matutina',
          itemType: 'routine',
          context: 'personal',
          timeSlot: 'morning',
          frequencyType: 'daily',
          weekdaysMask: '1,2,3,4,5,6,7',
          anchorDate: todayKey,
          reminderTimes: '',
          allowQuickNote: true,
          sortOrder: 0,
          createdAt: '2026-06-01T00:00:00Z',
          updatedAt: '2026-06-01T00:00:00Z',
        );
        final sampleLog = RoutineLog(
          id: 'log-1',
          routineId: 'r-1',
          logDate: todayKey,
          completed: true,
          createdAt: '2026-06-01T00:00:00Z',
          updatedAt: '2026-06-01T00:00:00Z',
        );
        final sampleAchievement = Achievement(
          id: 'a-1',
          kind: 'manual',
          title: 'Primera semana constante',
          detail: 'Sin interrupciones',
          context: 'personal',
          achievedDate: todayKey,
          createdAt: '2026-06-01T00:00:00Z',
          updatedAt: '2026-06-01T00:00:00Z',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              routinesStreamProvider
                  .overrideWith((_) => Stream.value([sampleRoutine])),
              logsForProgressMonthProvider
                  .overrideWith((_) => Stream.value([sampleLog])),
              achievementsStreamProvider
                  .overrideWith((_) => Stream.value([sampleAchievement])),
            ],
            child: MaterialApp(
              theme: buildPowerTheme(Brightness.light),
              home: Scaffold(
                body: SoftGlassBackground(
                  child: ProgressPage(onOpenSettings: () {}),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Progreso'), findsOneWidget);
        expect(find.text('Constancia mensual'), findsOneWidget);
        expect(find.text('Lectura matutina'), findsOneWidget);
        expect(find.text('1 día'), findsOneWidget);
        expect(find.text('Estadísticas del mes'), findsOneWidget);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
        await tester.pumpAndSettle();

        expect(find.text('Línea de logros'), findsOneWidget);
        expect(find.text('Primera semana constante'), findsOneWidget);
      },
    );
  });
}
