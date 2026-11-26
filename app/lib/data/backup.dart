// Respaldo completo JSON (exportar e importar) para las 6 tablas Drift de Power Habits.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/dates.dart';
import '../core/updater.dart';
import 'db.dart';

class BackupImportResult {
  const BackupImportResult({
    required this.routines,
    required this.routineLogs,
    required this.goals,
    required this.goalSteps,
    required this.achievements,
    required this.appSettings,
  });

  final int routines;
  final int routineLogs;
  final int goals;
  final int goalSteps;
  final int achievements;
  final int appSettings;

  int get totalRecords =>
      routines + routineLogs + goals + goalSteps + achievements + appSettings;
}

/// Exporta las 6 tablas locales a un documento JSON legible y versionado.
Future<String> exportBackupJson(AppDb db) async {
  final routines = await db.select(db.routines).get();
  final logs = await db.select(db.routineLogs).get();
  final goals = await db.select(db.goals).get();
  final steps = await db.select(db.goalSteps).get();
  final achievements = await db.select(db.achievements).get();
  final settings = await db.select(db.appSettings).get();

  final payload = <String, dynamic>{
    'app': 'power_habits',
    'schemaVersion': db.schemaVersion,
    'appVersion': kAppVersion,
    'exportedAt': nowUtcIso(),
    'tables': <String, dynamic>{
      'routines': [
        for (final r in routines)
          {
            'id': r.id,
            'title': r.title,
            'itemType': r.itemType,
            'context': r.context,
            'timeSlot': r.timeSlot,
            'frequencyType': r.frequencyType,
            'weekdaysMask': r.weekdaysMask,
            'anchorDate': r.anchorDate,
            'reminderTimes': r.reminderTimes,
            'allowQuickNote': r.allowQuickNote,
            'sortOrder': r.sortOrder,
            'createdAt': r.createdAt,
            'updatedAt': r.updatedAt,
            'deletedAt': r.deletedAt,
          },
      ],
      'routine_logs': [
        for (final l in logs)
          {
            'id': l.id,
            'routineId': l.routineId,
            'logDate': l.logDate,
            'completed': l.completed,
            'note': l.note,
            'completedAt': l.completedAt,
            'createdAt': l.createdAt,
            'updatedAt': l.updatedAt,
            'deletedAt': l.deletedAt,
          },
      ],
      'goals': [
        for (final g in goals)
          {
            'id': g.id,
            'title': g.title,
            'context': g.context,
            'unitLabel': g.unitLabel,
            'currentValue': g.currentValue,
            'targetValue': g.targetValue,
            'milestonesUnlocked': g.milestonesUnlocked,
            'createdAt': g.createdAt,
            'updatedAt': g.updatedAt,
            'deletedAt': g.deletedAt,
          },
      ],
      'goal_steps': [
        for (final s in steps)
          {
            'id': s.id,
            'goalId': s.goalId,
            'stepIndex': s.stepIndex,
            'title': s.title,
            'completed': s.completed,
            'note': s.note,
            'completedAt': s.completedAt,
            'createdAt': s.createdAt,
            'updatedAt': s.updatedAt,
            'deletedAt': s.deletedAt,
          },
      ],
      'achievements': [
        for (final a in achievements)
          {
            'id': a.id,
            'kind': a.kind,
            'title': a.title,
            'detail': a.detail,
            'context': a.context,
            'sourceKey': a.sourceKey,
            'achievedDate': a.achievedDate,
            'createdAt': a.createdAt,
            'updatedAt': a.updatedAt,
            'deletedAt': a.deletedAt,
          },
      ],
      'app_settings': [
        for (final s in settings)
          {
            'key': s.key,
            'value': s.value,
            'updatedAt': s.updatedAt,
          },
      ],
    },
  };

  return const JsonEncoder.withIndent('  ').convert(payload);
}

/// Importa un respaldo JSON de forma transaccional usando insertOnConflictUpdate.
Future<BackupImportResult> importBackupJson(AppDb db, String rawJson) async {
  final decoded = jsonDecode(rawJson);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('El archivo no contiene un objeto JSON válido.');
  }
  final tables = decoded['tables'];
  if (tables is! Map<String, dynamic>) {
    throw const FormatException(
      'El archivo no tiene el formato de respaldo de Power Habits.',
    );
  }

  List<Map<String, dynamic>> readRows(String key) =>
      (tables[key] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();

  final routineRows = readRows('routines');
  final logRows = readRows('routine_logs');
  final goalRows = readRows('goals');
  final stepRows = readRows('goal_steps');
  final achievementRows = readRows('achievements');
  final settingRows = readRows('app_settings');

  final fallbackNow = nowUtcIso();
  final fallbackDay = dayStr(DateTime.now());

  await db.transaction(() async {
    for (final m in routineRows) {
      final id = _reqStr(m, 'id');
      await db.into(db.routines).insertOnConflictUpdate(
            RoutinesCompanion.insert(
              id: id,
              title: _reqStr(m, 'title'),
              itemType: Value(_optStr(m, 'itemType') ?? 'routine'),
              context: Value(_optStr(m, 'context') ?? 'personal'),
              timeSlot: Value(_optStr(m, 'timeSlot') ?? 'anytime'),
              frequencyType: Value(_optStr(m, 'frequencyType') ?? 'daily'),
              weekdaysMask: Value(
                _optStr(m, 'weekdaysMask') ?? '1,2,3,4,5,6,7',
              ),
              anchorDate: _optStr(m, 'anchorDate') ?? fallbackDay,
              reminderTimes: Value(_optStr(m, 'reminderTimes') ?? ''),
              allowQuickNote: Value(_optBool(m, 'allowQuickNote') ?? true),
              sortOrder: Value(_optInt(m, 'sortOrder') ?? 0),
              createdAt: _optStr(m, 'createdAt') ?? fallbackNow,
              updatedAt: _optStr(m, 'updatedAt') ?? fallbackNow,
              deletedAt: Value(_optStr(m, 'deletedAt')),
            ),
          );
    }

    for (final m in logRows) {
      await db.into(db.routineLogs).insertOnConflictUpdate(
            RoutineLogsCompanion.insert(
              id: _reqStr(m, 'id'),
              routineId: _reqStr(m, 'routineId'),
              logDate: _reqStr(m, 'logDate'),
              completed: Value(_optBool(m, 'completed') ?? false),
              note: Value(_optStr(m, 'note')),
              completedAt: Value(_optStr(m, 'completedAt')),
              createdAt: _optStr(m, 'createdAt') ?? fallbackNow,
              updatedAt: _optStr(m, 'updatedAt') ?? fallbackNow,
              deletedAt: Value(_optStr(m, 'deletedAt')),
            ),
          );
    }

    for (final m in goalRows) {
      await db.into(db.goals).insertOnConflictUpdate(
            GoalsCompanion.insert(
              id: _reqStr(m, 'id'),
              title: _reqStr(m, 'title'),
              context: Value(_optStr(m, 'context') ?? 'personal'),
              unitLabel: Value(_optStr(m, 'unitLabel') ?? 'pasos'),
              currentValue: Value(_optInt(m, 'currentValue') ?? 0),
              targetValue: Value(_optInt(m, 'targetValue') ?? 10),
              milestonesUnlocked: Value(_optStr(m, 'milestonesUnlocked') ?? ''),
              createdAt: _optStr(m, 'createdAt') ?? fallbackNow,
              updatedAt: _optStr(m, 'updatedAt') ?? fallbackNow,
              deletedAt: Value(_optStr(m, 'deletedAt')),
            ),
          );
    }

    for (final m in stepRows) {
      await db.into(db.goalSteps).insertOnConflictUpdate(
            GoalStepsCompanion.insert(
              id: _reqStr(m, 'id'),
              goalId: _reqStr(m, 'goalId'),
              stepIndex: _optInt(m, 'stepIndex') ?? 1,
              title: _reqStr(m, 'title'),
              completed: Value(_optBool(m, 'completed') ?? false),
              note: Value(_optStr(m, 'note')),
              completedAt: Value(_optStr(m, 'completedAt')),
              createdAt: _optStr(m, 'createdAt') ?? fallbackNow,
              updatedAt: _optStr(m, 'updatedAt') ?? fallbackNow,
              deletedAt: Value(_optStr(m, 'deletedAt')),
            ),
          );
    }

    for (final m in achievementRows) {
      await db.into(db.achievements).insertOnConflictUpdate(
            AchievementsCompanion.insert(
              id: _reqStr(m, 'id'),
              kind: Value(_optStr(m, 'kind') ?? 'manual'),
              title: _reqStr(m, 'title'),
              detail: Value(_optStr(m, 'detail') ?? ''),
              context: Value(_optStr(m, 'context') ?? 'personal'),
              sourceKey: Value(_optStr(m, 'sourceKey')),
              achievedDate: _optStr(m, 'achievedDate') ?? fallbackDay,
              createdAt: _optStr(m, 'createdAt') ?? fallbackNow,
              updatedAt: _optStr(m, 'updatedAt') ?? fallbackNow,
              deletedAt: Value(_optStr(m, 'deletedAt')),
            ),
          );
    }

    for (final m in settingRows) {
      await db.into(db.appSettings).insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              key: _reqStr(m, 'key'),
              value: _optStr(m, 'value') ?? '',
              updatedAt: _optStr(m, 'updatedAt') ?? fallbackNow,
            ),
          );
    }
  });

  return BackupImportResult(
    routines: routineRows.length,
    routineLogs: logRows.length,
    goals: goalRows.length,
    goalSteps: stepRows.length,
    achievements: achievementRows.length,
    appSettings: settingRows.length,
  );
}

/// Genera un archivo temporal .json y abre la hoja nativa para compartirlo.
Future<void> shareBackupFile(AppDb db) async {
  final raw = await exportBackupJson(db);
  final dir = await getTemporaryDirectory();
  final stamp = dayStr(DateTime.now());
  final file = File(p.join(dir.path, 'power-habits-backup-$stamp.json'));
  await file.writeAsString(raw, encoding: utf8);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/json')],
      subject: 'Respaldo Power Habits ($stamp)',
      text: 'Respaldo local de Power Habits del $stamp',
    ),
  );
}

/// Abre el selector nativo para elegir un .json e importarlo a la base local.
Future<BackupImportResult?> pickAndImportBackup(AppDb db) async {
  final picked = await FilePicker.pickFile(
    dialogTitle: 'Seleccionar respaldo JSON',
    type: FileType.custom,
    allowedExtensions: const ['json'],
  );
  if (picked == null) return null;
  final bytes = await picked.readAsBytes();
  final rawJson = utf8.decode(bytes);
  return importBackupJson(db, rawJson);
}

String _reqStr(Map<String, dynamic> map, String key) {
  final val = map[key];
  if (val is String && val.isNotEmpty) return val;
  throw FormatException('Campo requerido faltante o inválido: $key');
}

String? _optStr(Map<String, dynamic> map, String key) {
  final val = map[key];
  return val is String ? val : null;
}

bool? _optBool(Map<String, dynamic> map, String key) {
  final val = map[key];
  if (val is bool) return val;
  if (val is num) return val != 0;
  return null;
}

int? _optInt(Map<String, dynamic> map, String key) {
  final val = map[key];
  if (val is int) return val;
  if (val is num) return val.toInt();
  return null;
}
