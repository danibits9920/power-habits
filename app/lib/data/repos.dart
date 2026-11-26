// Repositorios desacoplados sobre Drift (listos para añadir SupabaseSyncService en Fase 3).
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/dates.dart';
import 'db.dart';

const _uuid = Uuid();

class RoutineRepo {
  RoutineRepo(this.db);
  final AppDb db;

  Stream<List<Routine>> watchActive() => (db.select(db.routines)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.createdAt),
        ]))
      .watch();

  Future<List<Routine>> getActive() => (db.select(db.routines)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.createdAt),
        ]))
      .get();

  Stream<List<RoutineLog>> watchLogsForDate(String dateKey) =>
      (db.select(db.routineLogs)
            ..where((t) => t.deletedAt.isNull() & t.logDate.equals(dateKey)))
          .watch();

  Stream<List<RoutineLog>> watchLogsInRange(String fromDate, String toDate) =>
      (db.select(db.routineLogs)
            ..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.logDate.isBiggerOrEqualValue(fromDate) &
                  t.logDate.isSmallerOrEqualValue(toDate),
            ))
          .watch();

  Stream<List<RoutineLog>> watchLogsForRoutine(String routineId) =>
      (db.select(db.routineLogs)
            ..where(
              (t) => t.deletedAt.isNull() & t.routineId.equals(routineId),
            ))
          .watch();

  Future<String> create({
    required String title,
    String itemType = 'routine',
    String context = 'personal',
    String timeSlot = 'anytime',
    String frequencyType = 'daily',
    String weekdaysMask = '1,2,3,4,5,6,7',
    String? anchorDate,
    List<String> reminderTimes = const [],
    bool allowQuickNote = true,
  }) async {
    final id = _uuid.v4();
    final now = nowUtcIso();
    await db.into(db.routines).insert(
          RoutinesCompanion.insert(
            id: id,
            title: title.trim(),
            itemType: Value(itemType),
            context: Value(context),
            timeSlot: Value(timeSlot),
            frequencyType: Value(frequencyType),
            weekdaysMask: Value(weekdaysMask),
            anchorDate: anchorDate ?? dayStr(DateTime.now()),
            reminderTimes: Value(reminderTimes.join(',')),
            allowQuickNote: Value(allowQuickNote),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> updateRoutine({
    required String id,
    required String title,
    required String context,
    required String timeSlot,
    required String frequencyType,
    required String weekdaysMask,
    required List<String> reminderTimes,
    required bool allowQuickNote,
  }) async {
    await (db.update(db.routines)..where((t) => t.id.equals(id))).write(
      RoutinesCompanion(
        title: Value(title.trim()),
        context: Value(context),
        timeSlot: Value(timeSlot),
        frequencyType: Value(frequencyType),
        weekdaysMask: Value(weekdaysMask),
        reminderTimes: Value(reminderTimes.join(',')),
        allowQuickNote: Value(allowQuickNote),
        updatedAt: Value(nowUtcIso()),
      ),
    );
  }

  Future<void> softDelete(String id) async {
    final now = nowUtcIso();
    await (db.update(db.routines)..where((t) => t.id.equals(id))).write(
      RoutinesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<bool> toggleCompletion({
    required String routineId,
    required String dateKey,
    bool? forceValue,
  }) async {
    final existing = await (db.select(db.routineLogs)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.routineId.equals(routineId) &
                t.logDate.equals(dateKey),
          ))
        .getSingleOrNull();
    final now = nowUtcIso();
    final nextVal = forceValue ?? !(existing?.completed ?? false);
    if (existing == null) {
      await db.into(db.routineLogs).insert(
            RoutineLogsCompanion.insert(
              id: _uuid.v4(),
              routineId: routineId,
              logDate: dateKey,
              completed: Value(nextVal),
              completedAt: Value(nextVal ? now : null),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (db.update(db.routineLogs)..where((t) => t.id.equals(existing.id)))
          .write(
        RoutineLogsCompanion(
          completed: Value(nextVal),
          completedAt: Value(nextVal ? now : null),
          updatedAt: Value(now),
        ),
      );
    }
    return nextVal;
  }

  Future<void> saveNote({
    required String routineId,
    required String dateKey,
    required String note,
  }) async {
    final existing = await (db.select(db.routineLogs)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.routineId.equals(routineId) &
                t.logDate.equals(dateKey),
          ))
        .getSingleOrNull();
    final now = nowUtcIso();
    final cleaned = note.trim();
    if (existing == null) {
      await db.into(db.routineLogs).insert(
            RoutineLogsCompanion.insert(
              id: _uuid.v4(),
              routineId: routineId,
              logDate: dateKey,
              completed: const Value(false),
              note: Value(cleaned.isEmpty ? null : cleaned),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (db.update(db.routineLogs)..where((t) => t.id.equals(existing.id)))
          .write(
        RoutineLogsCompanion(
          note: Value(cleaned.isEmpty ? null : cleaned),
          updatedAt: Value(now),
        ),
      );
    }
  }

  Future<int> countCompletedLogs(String routineId) async {
    final rows = await (db.select(db.routineLogs)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.routineId.equals(routineId) &
                t.completed.equals(true),
          ))
        .get();
    return rows.length;
  }
}

class GoalRepo {
  GoalRepo(this.db, this.achievements);
  final AppDb db;
  final AchievementRepo achievements;

  Stream<List<Goal>> watchActive() => (db.select(db.goals)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Stream<List<GoalStep>> watchSteps(String goalId) =>
      (db.select(db.goalSteps)
            ..where((t) => t.deletedAt.isNull() & t.goalId.equals(goalId))
            ..orderBy([(t) => OrderingTerm.asc(t.stepIndex)]))
          .watch();

  Future<String> create({
    required String title,
    required String context,
    required String unitLabel,
    required int targetValue,
    int initialValue = 0,
    List<String> stepTitles = const [],
  }) async {
    final id = _uuid.v4();
    final now = nowUtcIso();
    final safeTarget = targetValue < 1 ? 1 : targetValue;
    final safeCurrent = initialValue.clamp(0, safeTarget);
    await db.into(db.goals).insert(
          GoalsCompanion.insert(
            id: id,
            title: title.trim(),
            context: Value(context),
            unitLabel: Value(unitLabel.trim().isEmpty ? 'pasos' : unitLabel.trim()),
            currentValue: Value(safeCurrent),
            targetValue: Value(safeTarget),
            createdAt: now,
            updatedAt: now,
          ),
        );
    for (var i = 0; i < stepTitles.length; i++) {
      final st = stepTitles[i].trim();
      if (st.isEmpty) continue;
      await db.into(db.goalSteps).insert(
            GoalStepsCompanion.insert(
              id: _uuid.v4(),
              goalId: id,
              stepIndex: i + 1,
              title: st,
              completed: Value(i < safeCurrent),
              completedAt: Value(i < safeCurrent ? now : null),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    return id;
  }

  Future<void> addStep(String goalId, String title) async {
    final existing = await (db.select(db.goalSteps)
          ..where((t) => t.deletedAt.isNull() & t.goalId.equals(goalId)))
        .get();
    final now = nowUtcIso();
    await db.into(db.goalSteps).insert(
          GoalStepsCompanion.insert(
            id: _uuid.v4(),
            goalId: goalId,
            stepIndex: existing.length + 1,
            title: title.trim(),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  /// Incrementa o decrementa una meta por delta (+1 / -1) y devuelve el hito desbloqueado (25/50/75/100) si hubo.
  Future<int?> adjustProgress(String goalId, int delta) async {
    final goal = await (db.select(db.goals)
          ..where((t) => t.id.equals(goalId) & t.deletedAt.isNull()))
        .getSingleOrNull();
    if (goal == null) return null;

    final nextVal = (goal.currentValue + delta).clamp(0, goal.targetValue);
    if (nextVal == goal.currentValue) return null;

    final pct = ((nextVal / goal.targetValue) * 100).round();
    final unlockedSet = goal.milestonesUnlocked
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toSet();

    int? newlyUnlocked;
    for (final m in const [25, 50, 75, 100]) {
      if (pct >= m && !unlockedSet.contains(m)) {
        unlockedSet.add(m);
        newlyUnlocked = m;
        await achievements.unlockAuto(
          sourceKey: 'goal:${goal.id}:$m',
          title: '$m % completado — ${goal.title}',
          detail: 'Hito automático ($nextVal/${goal.targetValue} ${goal.unitLabel})',
          context: goal.context,
        );
      }
    }

    final sortedMilestones = unlockedSet.toList()..sort();
    await (db.update(db.goals)..where((t) => t.id.equals(goalId))).write(
      GoalsCompanion(
        currentValue: Value(nextVal),
        milestonesUnlocked: Value(sortedMilestones.join(',')),
        updatedAt: Value(nowUtcIso()),
      ),
    );
    return newlyUnlocked;
  }

  Future<int?> toggleStep(GoalStep step) async {
    final now = nowUtcIso();
    final nextDone = !step.completed;
    await (db.update(db.goalSteps)..where((t) => t.id.equals(step.id))).write(
      GoalStepsCompanion(
        completed: Value(nextDone),
        completedAt: Value(nextDone ? now : null),
        updatedAt: Value(now),
      ),
    );
    return adjustProgress(step.goalId, nextDone ? 1 : -1);
  }

  Future<void> softDelete(String goalId) async {
    final now = nowUtcIso();
    await (db.update(db.goals)..where((t) => t.id.equals(goalId))).write(
      GoalsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }
}

class AchievementRepo {
  AchievementRepo(this.db);
  final AppDb db;

  Stream<List<Achievement>> watchAll() => (db.select(db.achievements)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm.desc(t.achievedDate),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
      .watch();

  Future<String> addManual({
    required String title,
    String detail = 'Logro personal registrado',
    String context = 'personal',
    String? achievedDate,
  }) async {
    final id = _uuid.v4();
    final now = nowUtcIso();
    await db.into(db.achievements).insert(
          AchievementsCompanion.insert(
            id: id,
            kind: const Value('manual'),
            title: title.trim(),
            detail: Value(detail.trim()),
            context: Value(context),
            achievedDate: achievedDate ?? dayStr(DateTime.now()),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<bool> unlockAuto({
    required String sourceKey,
    required String title,
    required String detail,
    required String context,
  }) async {
    final existing = await (db.select(db.achievements)
          ..where(
            (t) => t.deletedAt.isNull() & t.sourceKey.equals(sourceKey),
          ))
        .getSingleOrNull();
    if (existing != null) return false;
    final now = nowUtcIso();
    await db.into(db.achievements).insert(
          AchievementsCompanion.insert(
            id: _uuid.v4(),
            kind: const Value('auto'),
            title: title,
            detail: Value(detail),
            context: Value(context),
            sourceKey: Value(sourceKey),
            achievedDate: dayStr(DateTime.now()),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return true;
  }

  Future<void> softDelete(String id) async {
    final now = nowUtcIso();
    await (db.update(db.achievements)..where((t) => t.id.equals(id))).write(
      AchievementsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }
}

class SettingsRepo {
  SettingsRepo(this.db);
  final AppDb db;

  Future<String?> get(String key) async {
    final row = await (db.select(db.appSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) async {
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: nowUtcIso(),
          ),
        );
  }

  Stream<String?> watch(String key) => (db.select(db.appSettings)
        ..where((t) => t.key.equals(key)))
      .watchSingleOrNull()
      .map((r) => r?.value);
}
