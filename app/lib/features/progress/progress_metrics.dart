// Motor analítico puro y testeable para Progreso:
// métricas mensuales Personal vs. Laboral sobre días programados y estado del calendario mensual.
import '../../core/dates.dart';
import '../../core/frequency.dart';
import '../../data/db.dart';

/// Estadísticas de cumplimiento separadas por contexto (Personal vs. Laboral),
/// calculadas únicamente sobre días programados para que los días de descanso nunca penalicen.
class ContextMonthlyStats {
  const ContextMonthlyStats({
    required this.personalCompleted,
    required this.personalScheduled,
    required this.personalPct,
    required this.workCompleted,
    required this.workScheduled,
    required this.workPct,
  });

  const ContextMonthlyStats.empty()
      : personalCompleted = 0,
        personalScheduled = 0,
        personalPct = 0,
        workCompleted = 0,
        workScheduled = 0,
        workPct = 0;

  final int personalCompleted;
  final int personalScheduled;
  final int personalPct;
  final int workCompleted;
  final int workScheduled;
  final int workPct;
}

/// Estado visual de cada día del mes en el calendario de constancia de una rutina.
enum RoutineMonthDayStatus {
  completed,
  missed,
  notScheduled,
  future,
}

/// Cantidad de días calendario en el mes de [month].
int daysInMonth(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

/// Devuelve las claves `(fromDate, toDate)` en formato `YYYY-MM-DD` para el mes completo.
(String, String) monthDateRange(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  final last = DateTime(month.year, month.month + 1, 0);
  return (dayStr(first), dayStr(last));
}

/// Calcula estadísticas Personal vs. Laboral para un rango de fechas `[from, to]`.
/// Si [today] se proporciona, los días futuros (`> today`) no se cuentan como programados ni penalizan.
ContextMonthlyStats computeContextRangeStats({
  required List<Routine> routines,
  required List<RoutineLog> logs,
  required DateTime from,
  required DateTime to,
  DateTime? today,
}) {
  final start = dateOnly(from);
  final rawEnd = dateOnly(to);
  final effectiveEnd = today != null && dateOnly(today).isBefore(rawEnd)
      ? dateOnly(today)
      : rawEnd;

  if (effectiveEnd.isBefore(start)) {
    return const ContextMonthlyStats.empty();
  }

  final completedKeys = <String>{};
  for (final log in logs) {
    if (log.deletedAt == null && log.completed) {
      completedKeys.add('${log.routineId}|${log.logDate}');
    }
  }

  final activeRoutines = routines.where((r) => r.deletedAt == null).toList();
  final totalDays = daysBetween(start, effectiveEnd) + 1;

  var personalScheduled = 0;
  var personalCompleted = 0;
  var workScheduled = 0;
  var workCompleted = 0;

  for (var i = 0; i < totalDays; i++) {
    final day = DateTime(start.year, start.month, start.day + i);
    final key = dayStr(day);
    for (final routine in activeRoutines) {
      if (!routineAppliesOnDate(routine, day)) continue;
      final isDone = completedKeys.contains('${routine.id}|$key');
      if (routine.context == 'work') {
        workScheduled++;
        if (isDone) workCompleted++;
      } else {
        personalScheduled++;
        if (isDone) personalCompleted++;
      }
    }
  }

  final personalPct = personalScheduled == 0
      ? 0
      : ((personalCompleted / personalScheduled) * 100).round().clamp(0, 100);
  final workPct = workScheduled == 0
      ? 0
      : ((workCompleted / workScheduled) * 100).round().clamp(0, 100);

  return ContextMonthlyStats(
    personalCompleted: personalCompleted,
    personalScheduled: personalScheduled,
    personalPct: personalPct,
    workCompleted: workCompleted,
    workScheduled: workScheduled,
    workPct: workPct,
  );
}

/// Calcula estadísticas mensuales Personal vs. Laboral estrictamente sobre días programados hasta [today].
ContextMonthlyStats computeContextMonthlyStats({
  required List<Routine> routines,
  required List<RoutineLog> logs,
  required DateTime month,
  required DateTime today,
}) {
  final first = DateTime(month.year, month.month, 1);
  final last = DateTime(month.year, month.month + 1, 0);
  return computeContextRangeStats(
    routines: routines,
    logs: logs,
    from: first,
    to: last,
    today: today,
  );
}

/// Construye el mapa `díaDelMes (1..31) -> RoutineMonthDayStatus` para el calendario mensual de [r].
Map<int, RoutineMonthDayStatus> buildMonthCalendarStatus(
  Routine r,
  List<RoutineLog> logs,
  DateTime month,
  DateTime today,
) {
  final total = daysInMonth(month);
  final todayOnly = dateOnly(today);

  final completedDates = <String>{};
  for (final log in logs) {
    if (log.deletedAt == null && log.routineId == r.id && log.completed) {
      completedDates.add(log.logDate);
    }
  }

  final result = <int, RoutineMonthDayStatus>{};
  for (var d = 1; d <= total; d++) {
    final date = DateTime(month.year, month.month, d);
    final key = dayStr(date);

    if (completedDates.contains(key)) {
      result[d] = RoutineMonthDayStatus.completed;
    } else if (!routineAppliesOnDate(r, date)) {
      result[d] = RoutineMonthDayStatus.notScheduled;
    } else if (date.isBefore(todayOnly)) {
      result[d] = RoutineMonthDayStatus.missed;
    } else {
      result[d] = RoutineMonthDayStatus.future;
    }
  }
  return result;
}

/// Cuenta cuántos días del mes aparecen marcados como cumplidos.
int countCompletedDays(Map<int, RoutineMonthDayStatus> statusMap) => statusMap
    .values
    .where((status) => status == RoutineMonthDayStatus.completed)
    .length;
