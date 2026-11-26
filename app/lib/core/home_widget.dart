// Puente bidireccional con los 3 widgets nativos de Android (Hoy 4x3, Metas 4x2 y Mini 2x2).
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../data/db.dart';
import '../data/repos.dart';
import 'dates.dart';
import 'frequency.dart';

const _widgetChannel = MethodChannel('com.daltex.power_habits/widget');

const _slotRank = <String, int>{
  'morning': 0,
  'afternoon': 1,
  'night': 2,
  'anytime': 3,
};

String? _lastSnapshotSignature;
bool _syncInFlight = false;

class WidgetSnapshotPayload {
  const WidgetSnapshotPayload({
    required this.dateKey,
    required this.todayItemsJson,
    required this.goalsItemsJson,
  });

  final String dateKey;
  final String todayItemsJson;
  final String goalsItemsJson;

  String get signature => '$dateKey|$todayItemsJson|$goalsItemsJson';
}

/// Aplica en Drift SQLite la cola JSON de acciones ejecutadas desde los widgets fuera de la app.
/// Devuelve la cantidad de acciones aplicadas.
Future<int> applyPendingWidgetActionsJson(AppDb db, String rawJson) async {
  final trimmed = rawJson.trim();
  if (trimmed.isEmpty || trimmed == '[]') return 0;

  final dynamic decoded;
  try {
    decoded = jsonDecode(trimmed);
  } catch (_) {
    return 0;
  }
  if (decoded is! List || decoded.isEmpty) return 0;

  final routineRepo = RoutineRepo(db);
  final achievementRepo = AchievementRepo(db);
  final goalRepo = GoalRepo(db, achievementRepo);
  var applied = 0;

  for (final entry in decoded) {
    if (entry is! Map) continue;
    final type = (entry['type'] as String? ?? '').trim();
    final id = (entry['id'] as String? ?? '').trim();
    if (id.isEmpty) continue;

    if (type == 'toggle_routine') {
      final dateKey = (entry['dateKey'] as String? ?? '').trim();
      final effectiveDate =
          dateKey.isEmpty ? dayStr(DateTime.now()) : dateKey;
      final completedVal = entry['completed'] is bool
          ? entry['completed'] as bool
          : null;
      final nowCompleted = await routineRepo.toggleCompletion(
        routineId: id,
        dateKey: effectiveDate,
        forceValue: completedVal,
      );
      applied++;

      if (nowCompleted) {
        final totalDone = await routineRepo.countCompletedLogs(id);
        if (totalDone >= 7) {
          final active = await routineRepo.getActive();
          for (final r in active) {
            if (r.id == id) {
              await achievementRepo.unlockAuto(
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
    } else if (type == 'inc_goal') {
      final delta = (entry['delta'] as num?)?.toInt() ?? 1;
      await goalRepo.adjustProgress(id, delta);
      applied++;
    }
  }

  return applied;
}

/// Construye el snapshot JSON de rutinas de hoy y metas activas desde SQLite.
Future<WidgetSnapshotPayload> buildWidgetSnapshotPayload(
  AppDb db, {
  DateTime? now,
}) async {
  final today = dateOnly(now ?? DateTime.now());
  final todayKey = dayStr(today);

  final activeRoutines = await (db.select(db.routines)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.createdAt),
        ]))
      .get();

  final applicable = activeRoutines
      .where((r) => routineAppliesOnDate(r, today))
      .toList()
    ..sort((a, b) {
      final ra = _slotRank[a.timeSlot] ?? 3;
      final rb = _slotRank[b.timeSlot] ?? 3;
      if (ra != rb) return ra.compareTo(rb);
      return a.sortOrder.compareTo(b.sortOrder);
    });

  final logs = await (db.select(db.routineLogs)
        ..where(
          (t) =>
              t.deletedAt.isNull() &
              t.logDate.equals(todayKey) &
              t.completed.equals(true),
        ))
      .get();
  final doneIds = {for (final l in logs) l.routineId};

  // Pendientes primero, completadas al final para acceso inmediato en widget.
  final orderedToday = [
    ...applicable.where((r) => !doneIds.contains(r.id)),
    ...applicable.where((r) => doneIds.contains(r.id)),
  ];

  final todayJson = jsonEncode([
    for (final r in orderedToday)
      {
        'id': r.id,
        'title': r.title,
        'context': r.context,
        'completed': doneIds.contains(r.id),
      },
  ]);

  final activeGoals = await (db.select(db.goals)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  final goalsJson = jsonEncode([
    for (final g in activeGoals)
      {
        'id': g.id,
        'title': g.title,
        'context': g.context,
        'unitLabel': g.unitLabel,
        'current': g.currentValue,
        'target': g.targetValue,
      },
  ]);

  return WidgetSnapshotPayload(
    dateKey: todayKey,
    todayItemsJson: todayJson,
    goalsItemsJson: goalsJson,
  );
}

/// Consume y aplica en SQLite cualquier acción ejecutada en los widgets mientras la app estaba cerrada.
Future<int> flushPendingWidgetActions(AppDb db) async {
  try {
    final raw =
        await _widgetChannel.invokeMethod<String>('consumePendingActions') ??
            '[]';
    return await applyPendingWidgetActionsJson(db, raw);
  } on MissingPluginException {
    return 0;
  } on PlatformException {
    return 0;
  }
}

/// Sincroniza bidireccionalmente los 3 widgets nativos de Android:
/// 1) Primero aplica acciones pendientes hechas desde el escritorio.
/// 2) Luego empuja el estado autorizado de rutinas de hoy y metas activas.
Future<void> syncTodayWidgetFromDb(
  AppDb db, {
  DateTime? now,
  bool force = false,
}) async {
  if (_syncInFlight) return;
  _syncInFlight = true;
  try {
    final applied = await flushPendingWidgetActions(db);
    final payload = await buildWidgetSnapshotPayload(db, now: now);
    if (!force && applied == 0 && payload.signature == _lastSnapshotSignature) {
      return;
    }
    _lastSnapshotSignature = payload.signature;
    await _widgetChannel.invokeMethod<void>('syncAll', {
      'dateKey': payload.dateKey,
      'todayItemsJson': payload.todayItemsJson,
      'goalsItemsJson': payload.goalsItemsJson,
    });
  } on MissingPluginException {
    // Pruebas unitarias o plataforma sin widgets nativos.
  } on PlatformException {
    // Ignorar fallo pasajero del launcher.
  } finally {
    _syncInFlight = false;
  }
}

/// Escucha toques de navegación y avisos de acciones pendientes desde los widgets Android.
void setupHomeWidgetNavigation(
  void Function(String route) onNavigate, {
  VoidCallback? onPendingActions,
}) {
  _widgetChannel.setMethodCallHandler((call) async {
    if (call.method == 'navigate' && call.arguments is String) {
      final route = (call.arguments as String).trim();
      if (route.isNotEmpty) onNavigate(route);
    } else if (call.method == 'syncPending') {
      onPendingActions?.call();
    }
  });
  _widgetChannel
      .invokeMethod<String>('initialRoute')
      .then((route) {
        if (route != null && route.trim().isNotEmpty) {
          onNavigate(route.trim());
        }
      })
      .catchError((_) {});
}
