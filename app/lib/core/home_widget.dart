// Puente con el widget nativo 4x2 de la pantalla de inicio de Android (Soft Glass Minimal).
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../data/db.dart';
import 'dates.dart';
import 'frequency.dart';

const _widgetChannel = MethodChannel('com.daltex.power_habits/widget');

const _slotRank = <String, int>{
  'morning': 0,
  'afternoon': 1,
  'night': 2,
  'anytime': 3,
};

String? _lastSignature;

/// Calcula el progreso real de hoy desde SQLite y sincroniza el widget 4x2 de Android.
Future<void> syncTodayWidgetFromDb(AppDb db, {DateTime? now}) async {
  final today = dateOnly(now ?? DateTime.now());
  final todayKey = dayStr(today);

  final active = await (db.select(db.routines)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.createdAt),
        ]))
      .get();

  final applicable = active
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

  final totalCount = applicable.length;
  final doneCount = applicable.where((r) => doneIds.contains(r.id)).length;
  final pct = totalCount == 0 ? 0 : ((doneCount / totalCount) * 100).round();
  final pendingTitles = applicable
      .where((r) => !doneIds.contains(r.id))
      .map((r) => r.title)
      .take(3)
      .toList();

  await syncPowerWidget(
    pct: pct,
    doneCount: doneCount,
    totalCount: totalCount,
    pendingTitles: pendingTitles,
  );
}

/// Sincroniza el progreso del día y hasta 3 rutinas pendientes hacia el widget Android.
/// Silencioso fuera de Android o en pruebas unitarias.
Future<void> syncPowerWidget({
  required int pct,
  required int doneCount,
  required int totalCount,
  required List<String> pendingTitles,
}) async {
  final safePct = pct.clamp(0, 100);
  final topPending = pendingTitles
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .take(3)
      .toList();
  final sig = '$safePct|$doneCount|$totalCount|${topPending.join('||')}';
  if (sig == _lastSignature) return;
  _lastSignature = sig;

  try {
    await _widgetChannel.invokeMethod<void>('update', {
      'pct': safePct,
      'doneCount': doneCount,
      'totalCount': totalCount,
      'pendingTitles': topPending,
    });
  } on MissingPluginException {
    // Pruebas unitarias o plataforma sin widget nativo.
  } on PlatformException {
    // Ignorar fallo pasajero del launcher.
  }
}

/// Escucha toques desde el widget de Android para abrir rutas directas (/hoy o /hoy?new=1).
void setupHomeWidgetNavigation(void Function(String route) onNavigate) {
  _widgetChannel.setMethodCallHandler((call) async {
    if (call.method == 'navigate' && call.arguments is String) {
      final route = (call.arguments as String).trim();
      if (route.isNotEmpty) onNavigate(route);
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
