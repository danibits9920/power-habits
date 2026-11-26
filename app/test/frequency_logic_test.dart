import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:power_habits/core/dates.dart';
import 'package:power_habits/core/frequency.dart';
import 'package:power_habits/core/providers.dart';
import 'package:power_habits/data/db.dart';
import 'package:power_habits/data/repos.dart';
import 'package:power_habits/design/glass.dart';
import 'package:power_habits/design/tokens.dart';
import 'package:power_habits/features/today/today_page.dart';

Routine _buildRoutine({
  String id = 'r-1',
  String title = 'Rutina de prueba',
  String itemType = 'routine',
  String context = 'personal',
  String timeSlot = 'morning',
  String frequencyType = 'daily',
  String weekdaysMask = '1,2,3,4,5,6,7',
  String anchorDate = '2026-11-02', // Lunes 2 Nov 2026
  String reminderTimes = '',
  bool allowQuickNote = true,
}) =>
    Routine(
      id: id,
      title: title,
      itemType: itemType,
      context: context,
      timeSlot: timeSlot,
      frequencyType: frequencyType,
      weekdaysMask: weekdaysMask,
      anchorDate: anchorDate,
      reminderTimes: reminderTimes,
      allowQuickNote: allowQuickNote,
      sortOrder: 0,
      createdAt: '2026-11-02T00:00:00Z',
      updatedAt: '2026-11-02T00:00:00Z',
      deletedAt: null,
    );

void main() {
  group('routineAppliesOnDate', () {
    test('daily applies on anchor and future dates, never before anchor', () {
      final routine = _buildRoutine(
        frequencyType: 'daily',
        anchorDate: '2026-11-05',
      );

      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 4)), isFalse);
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 5)), isTrue);
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 6)), isTrue);
      expect(routineAppliesOnDate(routine, DateTime(2026, 12, 1)), isTrue);
    });

    test('alternate applies only on even day offsets >= 0 from anchor', () {
      final routine = _buildRoutine(
        frequencyType: 'alternate',
        anchorDate: '2026-11-10',
      );

      // Before anchor (even if offset is -2) must be false
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 8)), isFalse);
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 9)), isFalse);

      // Offset 0, 1, 2, 3, 4
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 10)), isTrue);
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 11)), isFalse);
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 12)), isTrue);
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 13)), isFalse);
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 14)), isTrue);
    });

    test('weekdays applies only on configured ISO weekdays >= anchor', () {
      // 2026-11-02 is Monday (ISO 1)
      final routine = _buildRoutine(
        frequencyType: 'weekdays',
        weekdaysMask: '1,3,5', // Lun, Mié, Vie
        anchorDate: '2026-11-02',
      );

      // Previous Friday (2026-10-30) is before anchor -> false
      expect(routineAppliesOnDate(routine, DateTime(2026, 10, 30)), isFalse);

      // Mon..Sun of week 2026-11-02..2026-11-08
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 2)), isTrue); // Lun
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 3)), isFalse); // Mar
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 4)), isTrue); // Mié
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 5)), isFalse); // Jue
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 6)), isTrue); // Vie
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 7)), isFalse); // Sáb
      expect(routineAppliesOnDate(routine, DateTime(2026, 11, 8)), isFalse); // Dom
    });

    test('once task applies strictly on anchor date only', () {
      final task = _buildRoutine(
        itemType: 'task',
        frequencyType: 'once',
        anchorDate: '2026-11-15',
      );

      expect(routineAppliesOnDate(task, DateTime(2026, 11, 14)), isFalse);
      expect(routineAppliesOnDate(task, DateTime(2026, 11, 15)), isTrue);
      expect(routineAppliesOnDate(task, DateTime(2026, 11, 16)), isFalse);
    });
  });

  group('parseReminderTimes & parseWeekdaysMask', () {
    test('parseReminderTimes trims, filters malformed tokens, and sorts', () {
      expect(
        parseReminderTimes(' 21:30, 06:45, invalid, 7:05, 17:15 , '),
        equals(['06:45', '17:15', '21:30']),
      );
      expect(parseReminderTimes(''), isEmpty);
    });

    test('parseWeekdaysMask extracts valid ISO weekdays 1..7 only', () {
      expect(parseWeekdaysMask('1, 3, 5, 0, 8, x'), equals({1, 3, 5}));
    });
  });

  group('frequencyLabel & timeSlotLabel', () {
    test('returns expected Spanish labels for each frequency type', () {
      expect(frequencyLabel(_buildRoutine(frequencyType: 'daily')), 'Diaria');
      expect(
        frequencyLabel(_buildRoutine(frequencyType: 'alternate')),
        'Interdiaria',
      );
      expect(
        frequencyLabel(
          _buildRoutine(frequencyType: 'weekdays', weekdaysMask: '5,1,3'),
        ),
        'Lun · Mié · Vie',
      );
      expect(
        frequencyLabel(
          _buildRoutine(frequencyType: 'weekdays', weekdaysMask: ''),
        ),
        'Días fijos',
      );
      expect(
        frequencyLabel(_buildRoutine(itemType: 'task', frequencyType: 'once')),
        'Tarea puntual',
      );
    });

    test('timeSlotLabel maps all slots cleanly', () {
      expect(timeSlotLabel('morning'), 'Mañana');
      expect(timeSlotLabel('afternoon'), 'Tarde');
      expect(timeSlotLabel('night'), 'Noche');
      expect(timeSlotLabel('anytime'), 'Cualquier hora');
    });
  });

  group('RoutineRepo (Drift in-memory)', () {
    late AppDb db;
    late RoutineRepo routineRepo;
    late AchievementRepo achievementRepo;

    setUp(() {
      db = AppDb.forTesting(NativeDatabase.memory());
      routineRepo = RoutineRepo(db);
      achievementRepo = AchievementRepo(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('create, updateRoutine, and softDelete lifecycle', () async {
      final id = await routineRepo.create(
        title: '  Skincare mañana  ',
        itemType: 'routine',
        context: 'personal',
        timeSlot: 'morning',
        frequencyType: 'daily',
        anchorDate: '2026-11-10',
        reminderTimes: const ['07:00', '07:30'],
        allowQuickNote: true,
      );

      final created = await routineRepo.getActive();
      expect(created, hasLength(1));
      expect(created.first.id, id);
      expect(created.first.title, 'Skincare mañana');
      expect(created.first.reminderTimes, '07:00,07:30');

      await routineRepo.updateRoutine(
        id: id,
        title: 'Skincare noche',
        context: 'personal',
        timeSlot: 'night',
        frequencyType: 'alternate',
        weekdaysMask: '1,2,3,4,5,6,7',
        reminderTimes: const ['21:30'],
        allowQuickNote: false,
      );

      final updated = await routineRepo.getActive();
      expect(updated.first.title, 'Skincare noche');
      expect(updated.first.timeSlot, 'night');
      expect(updated.first.frequencyType, 'alternate');
      expect(updated.first.reminderTimes, '21:30');
      expect(updated.first.allowQuickNote, isFalse);

      await routineRepo.softDelete(id);
      expect(await routineRepo.getActive(), isEmpty);

      // Soft-deleted row stays in DB with deletedAt populated (Supabase-ready)
      final rawRows = await db.select(db.routines).get();
      expect(rawRows, hasLength(1));
      expect(rawRows.first.deletedAt, isNotNull);
    });

    test('toggleCompletion, countCompletedLogs, and 7-day auto achievement', () async {
      final id = await routineRepo.create(
        title: 'Salir a caminar',
        anchorDate: '2026-11-01',
      );

      // Toggle on -> off -> on
      final first = await routineRepo.toggleCompletion(
        routineId: id,
        dateKey: '2026-11-01',
      );
      expect(first, isTrue);
      expect(await routineRepo.countCompletedLogs(id), 1);

      final second = await routineRepo.toggleCompletion(
        routineId: id,
        dateKey: '2026-11-01',
      );
      expect(second, isFalse);
      expect(await routineRepo.countCompletedLogs(id), 0);

      // Complete 7 distinct days
      for (var day = 1; day <= 7; day++) {
        final key = '2026-11-${day.toString().padLeft(2, '0')}';
        await routineRepo.toggleCompletion(
          routineId: id,
          dateKey: key,
          forceValue: true,
        );
      }
      expect(await routineRepo.countCompletedLogs(id), 7);

      // Unlock automatic 7-day achievement (deduplicated by sourceKey)
      final unlockedFirst = await achievementRepo.unlockAuto(
        sourceKey: 'routine:$id:7days',
        title: '7 días constantes — Salir a caminar',
        detail: 'Completaste esta rutina 7 veces',
        context: 'personal',
      );
      final unlockedDuplicate = await achievementRepo.unlockAuto(
        sourceKey: 'routine:$id:7days',
        title: '7 días constantes — Salir a caminar',
        detail: 'Completaste esta rutina 7 veces',
        context: 'personal',
      );
      expect(unlockedFirst, isTrue);
      expect(unlockedDuplicate, isFalse);

      final achievements = await achievementRepo.watchAll().first;
      expect(achievements, hasLength(1));
      expect(achievements.first.sourceKey, 'routine:$id:7days');
    });

    test('saveNote creates, updates, and clears note without altering completion', () async {
      final id = await routineRepo.create(
        title: 'Ejercicio',
        anchorDate: '2026-11-02',
      );

      // Save note before completing -> creates uncompleted log with note
      await routineRepo.saveNote(
        routineId: id,
        dateKey: '2026-11-02',
        note: '  35 min de cardio  ',
      );
      var logs = await routineRepo.watchLogsForDate('2026-11-02').first;
      expect(logs, hasLength(1));
      expect(logs.first.completed, isFalse);
      expect(logs.first.note, '35 min de cardio');

      // Toggle completion preserves note
      await routineRepo.toggleCompletion(routineId: id, dateKey: '2026-11-02');
      logs = await routineRepo.watchLogsForDate('2026-11-02').first;
      expect(logs.first.completed, isTrue);
      expect(logs.first.note, '35 min de cardio');

      // Clear note with whitespace -> sets note to null while keeping completed
      await routineRepo.saveNote(
        routineId: id,
        dateKey: '2026-11-02',
        note: '   ',
      );
      logs = await routineRepo.watchLogsForDate('2026-11-02').first;
      expect(logs.first.completed, isTrue);
      expect(logs.first.note, isNull);
    });
  });

  group('TodayPage widget integration', () {
    testWidgets(
      'empty state seeds examples, filters context, and toggles completion',
      timeout: const Timeout(Duration(seconds: 15)),
      (tester) async {
        final db = AppDb.forTesting(NativeDatabase.memory());

        var dataChangedCalls = 0;
        var savedCallbacks = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [dbProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: buildPowerTheme(Brightness.light),
              home: Scaffold(
                body: SoftGlassBackground(
                  child: TodayPage(
                    onRoutineSaved: (_) async => savedCallbacks++,
                    onDataChanged: () => dataChangedCalls++,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Empty state visible with both CTAs
        expect(find.text('Crear primera rutina'), findsOneWidget);
        expect(find.text('Cargar ejemplos iniciales'), findsOneWidget);

        // Tap "Cargar ejemplos iniciales"
        await tester.tap(find.text('Cargar ejemplos iniciales'));
        await tester.pumpAndSettle();

        expect(savedCallbacks, 5);
        expect(dataChangedCalls, greaterThanOrEqualTo(1));
        expect(find.text('Progreso de hoy'), findsOneWidget);
        expect(find.text('Skincare mañana'), findsOneWidget);

        // Toggle completion on "Skincare mañana"
        final beforeCalls = dataChangedCalls;
        await tester.tap(find.bySemanticsLabel('Completar Skincare mañana'));
        await tester.pumpAndSettle();

        expect(dataChangedCalls, greaterThan(beforeCalls));
        expect(
          find.bySemanticsLabel('Desmarcar Skincare mañana'),
          findsOneWidget,
        );

        // Filter by Laboral
        await tester.tap(
          find.descendant(
            of: find.byType(GlassSegmented<ContextFilter>),
            matching: find.text('Laboral'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Skincare mañana'), findsNothing);

        // Unmount and flush Drift's zero-duration stream cleanup timers before closing
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await db.close();
      },
    );

    test('RoutineRepo.updateRoutine persists updated anchorDate', () async {
      final db = AppDb.forTesting(NativeDatabase.memory());
      final repo = RoutineRepo(db);
      final id = await repo.create(
        title: 'Enviar reporte',
        itemType: 'task',
        context: 'work',
        frequencyType: 'once',
        anchorDate: '2026-11-26',
      );

      await repo.updateRoutine(
        id: id,
        title: 'Enviar reporte final',
        context: 'work',
        timeSlot: 'morning',
        frequencyType: 'once',
        weekdaysMask: '1,2,3,4,5,6,7',
        anchorDate: '2026-11-28',
        reminderTimes: const ['09:00'],
        allowQuickNote: true,
      );

      final items = await repo.getActive();
      expect(items.single.title, 'Enviar reporte final');
      expect(items.single.anchorDate, '2026-11-28');
      await db.close();
    });

    test(
      'interdiaria con limite semanal, cada 3 dias y modo flexible X veces/semana',
      () {
        final now = DateTime(2026, 11, 23).toIso8601String(); // Lunes 23 Nov
        final alt3DaysPerWeek = Routine(
          id: 'alt-3d',
          title: 'Skincare noche',
          itemType: 'routine',
          context: 'personal',
          timeSlot: 'night',
          frequencyType: 'alternate',
          weekdaysMask: '1,3,5',
          anchorDate: '2026-11-23',
          reminderTimes: '',
          allowQuickNote: true,
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
        );
        expect(routineAppliesOnDate(alt3DaysPerWeek, DateTime(2026, 11, 23)), isTrue); // Lun
        expect(routineAppliesOnDate(alt3DaysPerWeek, DateTime(2026, 11, 24)), isFalse); // Mar
        expect(routineAppliesOnDate(alt3DaysPerWeek, DateTime(2026, 11, 25)), isTrue); // Mié
        expect(routineAppliesOnDate(alt3DaysPerWeek, DateTime(2026, 11, 27)), isTrue); // Vie
        expect(routineAppliesOnDate(alt3DaysPerWeek, DateTime(2026, 11, 29)), isFalse); // Dom
        expect(frequencyLabel(alt3DaysPerWeek), contains('3d/sem'));

        final every3Days = Routine(
          id: 'e3d',
          title: 'Exfoliante',
          itemType: 'routine',
          context: 'personal',
          timeSlot: 'night',
          frequencyType: 'every_3_days',
          weekdaysMask: '1,2,3,4,5,6,7',
          anchorDate: '2026-11-23',
          reminderTimes: '',
          allowQuickNote: true,
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
        );
        expect(routineAppliesOnDate(every3Days, DateTime(2026, 11, 23)), isTrue);
        expect(routineAppliesOnDate(every3Days, DateTime(2026, 11, 24)), isFalse);
        expect(routineAppliesOnDate(every3Days, DateTime(2026, 11, 25)), isFalse);
        expect(routineAppliesOnDate(every3Days, DateTime(2026, 11, 26)), isTrue);

        final weeklyFlex = Routine(
          id: 'wx',
          title: 'Salir a correr',
          itemType: 'routine',
          context: 'personal',
          timeSlot: 'afternoon',
          frequencyType: 'weekly_x',
          weekdaysMask: '4',
          anchorDate: '2026-11-23',
          reminderTimes: '',
          allowQuickNote: true,
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
        );
        expect(weeklyTargetCount(weeklyFlex), 4);
        expect(frequencyLabel(weeklyFlex), '4 veces/semana');
        expect(routineAppliesOnDate(weeklyFlex, DateTime(2026, 11, 26)), isTrue);
        expect(alternateDaysPreset(3), {1, 3, 5});
        final (mon, sun) = isoWeekBounds(DateTime(2026, 11, 26));
        expect(dayStr(mon), '2026-11-23');
        expect(dayStr(sun), '2026-11-29');
      },
    );
  });
}
