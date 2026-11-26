// Base de datos SQLite local (Drift) diseñada Supabase-ready desde el día 1:
// UUID v4 como clave primaria + createdAt/updatedAt UTC + deletedAt (soft delete).
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'db.g.dart';

class Routines extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  // 'routine' | 'task'
  TextColumn get itemType => text().withDefault(const Constant('routine'))();
  // 'personal' | 'work'
  TextColumn get context => text().withDefault(const Constant('personal'))();
  // 'morning' | 'afternoon' | 'night' | 'anytime'
  TextColumn get timeSlot => text().withDefault(const Constant('anytime'))();
  // 'daily' | 'alternate' | 'weekdays' | 'once'
  TextColumn get frequencyType => text().withDefault(const Constant('daily'))();
  // CSV of ISO weekdays 1..7 (e.g. '1,3,5')
  TextColumn get weekdaysMask => text().withDefault(const Constant('1,2,3,4,5,6,7'))();
  // YYYY-MM-DD anchor for alternate frequency or single-day task
  TextColumn get anchorDate => text()();
  // CSV of HH:mm reminders (e.g. '06:45,17:30')
  TextColumn get reminderTimes => text().withDefault(const Constant(''))();
  BoolColumn get allowQuickNote => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RoutineLogs extends Table {
  TextColumn get id => text()();
  TextColumn get routineId => text()();
  TextColumn get logDate => text()(); // YYYY-MM-DD
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
  TextColumn get completedAt => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  // 'personal' | 'work'
  TextColumn get context => text().withDefault(const Constant('personal'))();
  TextColumn get unitLabel => text().withDefault(const Constant('pasos'))();
  IntColumn get currentValue => integer().withDefault(const Constant(0))();
  IntColumn get targetValue => integer().withDefault(const Constant(10))();
  // CSV of unlocked percentages e.g. '25,50'
  TextColumn get milestonesUnlocked => text().withDefault(const Constant(''))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class GoalSteps extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text()();
  IntColumn get stepIndex => integer()();
  TextColumn get title => text()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
  TextColumn get completedAt => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Achievements extends Table {
  TextColumn get id => text()();
  // 'auto' | 'manual'
  TextColumn get kind => text().withDefault(const Constant('manual'))();
  TextColumn get title => text()();
  TextColumn get detail => text().withDefault(const Constant(''))();
  // 'personal' | 'work'
  TextColumn get context => text().withDefault(const Constant('personal'))();
  // Deduplication key for auto milestones e.g. 'goal:<id>:50'
  TextColumn get sourceKey => text().nullable()();
  TextColumn get achievedDate => text()(); // YYYY-MM-DD
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Routines,
    RoutineLogs,
    Goals,
    GoalSteps,
    Achievements,
    AppSettings,
  ],
)
class AppDb extends _$AppDb {
  AppDb() : super(driftDatabase(name: 'power_habits_db'));

  AppDb.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}
