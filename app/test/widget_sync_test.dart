import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_habits/core/dates.dart';
import 'package:power_habits/core/home_widget.dart';
import 'package:power_habits/data/db.dart';
import 'package:power_habits/data/repos.dart';

void main() {
  group('Interactive widgets bidirectional sync', () {
    test(
      'applyPendingWidgetActionsJson applies routine toggles, 7-day achievement, and goal +1 milestones',
      () async {
        final db = AppDb.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        final routineRepo = RoutineRepo(db);
        final achRepo = AchievementRepo(db);
        final goalRepo = GoalRepo(db, achRepo);

        final rId = await routineRepo.create(
          title: 'Skincare mañana',
          context: 'personal',
          timeSlot: 'morning',
          frequencyType: 'daily',
          anchorDate: '2026-11-01',
        );
        // Pre-seed 6 completed days so widget toggle on day 7 unlocks achievement.
        for (var d = 20; d <= 25; d++) {
          await routineRepo.toggleCompletion(
            routineId: rId,
            dateKey: '2026-11-$d',
            forceValue: true,
          );
        }

        final gId = await goalRepo.create(
          title: 'Curso de desarrollo',
          context: 'personal',
          unitLabel: 'clases',
          targetValue: 10,
          initialValue: 4,
        );

        final pendingJson = jsonEncode([
          {
            'type': 'toggle_routine',
            'id': rId,
            'dateKey': '2026-11-26',
            'completed': true,
            'ts': 1700000000000,
          },
          {
            'type': 'inc_goal',
            'id': gId,
            'delta': 1,
            'ts': 1700000000001,
          },
        ]);

        final applied = await applyPendingWidgetActionsJson(db, pendingJson);
        expect(applied, 2);

        // Verify routine log & 7-day consistency achievement.
        expect(await routineRepo.countCompletedLogs(rId), 7);
        final goals = await goalRepo.watchActive().first;
        expect(goals.single.currentValue, 5);

        final achievements = await achRepo.watchAll().first;
        final keys = achievements.map((a) => a.sourceKey).toSet();
        expect(keys.contains('routine:$rId:7days'), isTrue);
        expect(keys.contains('goal:$gId:50'), isTrue);
      },
    );

    test(
      'buildWidgetSnapshotPayload sorts pending routines first and includes goals',
      () async {
        final db = AppDb.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        final routineRepo = RoutineRepo(db);
        final achRepo = AchievementRepo(db);
        final goalRepo = GoalRepo(db, achRepo);

        final today = DateTime(2026, 11, 26);
        final r1 = await routineRepo.create(
          title: 'Skincare',
          context: 'personal',
          timeSlot: 'morning',
          frequencyType: 'daily',
          anchorDate: dayStr(today),
        );
        final r2 = await routineRepo.create(
          title: 'Sprint laboral',
          context: 'work',
          timeSlot: 'afternoon',
          frequencyType: 'daily',
          anchorDate: dayStr(today),
        );
        await routineRepo.toggleCompletion(
          routineId: r1,
          dateKey: dayStr(today),
          forceValue: true,
        );

        await goalRepo.create(
          title: 'Curso 30 clases',
          context: 'personal',
          unitLabel: 'clases',
          targetValue: 30,
          initialValue: 14,
        );

        final snap = await buildWidgetSnapshotPayload(db, now: today);
        expect(snap.dateKey, '2026-11-26');

        final todayList = jsonDecode(snap.todayItemsJson) as List<dynamic>;
        expect(todayList.length, 2);
        // Pending routine r2 comes first, completed r1 comes second.
        expect((todayList[0] as Map)['id'], r2);
        expect((todayList[0] as Map)['completed'], isFalse);
        expect((todayList[1] as Map)['id'], r1);
        expect((todayList[1] as Map)['completed'], isTrue);

        final goalsList = jsonDecode(snap.goalsItemsJson) as List<dynamic>;
        expect(goalsList.length, 1);
        expect((goalsList[0] as Map)['current'], 14);
        expect((goalsList[0] as Map)['target'], 30);
      },
    );
  });
}
