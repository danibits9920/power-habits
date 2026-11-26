// Lógica pura y determinista de frecuencias flexibles:
// Diaria, Interdiaria (cada 2 o 3 días, continua o con límite de X días/sem),
// Días fijos (L-D), Flexible X veces por semana y Tarea puntual.
import '../data/db.dart';
import 'dates.dart';

/// Devuelve los días de semana ISO (1=Lun..7=Dom) configurados en [weekdaysMask].
Set<int> parseWeekdaysMask(String mask) => mask
    .split(',')
    .map((e) => int.tryParse(e.trim()))
    .whereType<int>()
    .where((d) => d >= 1 && d <= 7)
    .toSet();

/// Preselección equilibrada de días alternos según cuántos días a la semana elige el usuario.
Set<int> alternateDaysPreset(int daysPerWeek) => switch (daysPerWeek) {
  2 => {1, 4}, // Lun, Jue
  3 => {1, 3, 5}, // Lun, Mié, Vie
  4 => {1, 2, 4, 5}, // Lun, Mar, Jue, Vie
  5 => {1, 2, 3, 4, 5}, // Lun a Vie
  6 => {1, 2, 3, 4, 5, 6}, // Lun a Sáb
  _ => {1, 2, 3, 4, 5, 6, 7}, // Continua (toda la semana)
};

/// Meta semanal (1..6) para rutinas de tipo `weekly_x`.
int weeklyTargetCount(Routine routine) {
  final parsed = int.tryParse(routine.weekdaysMask.trim());
  if (parsed != null && parsed >= 1 && parsed <= 7) return parsed;
  final days = parseWeekdaysMask(routine.weekdaysMask);
  return days.isEmpty ? 3 : days.length.clamp(1, 6);
}

/// Límites (lunes, domingo) de la semana ISO que contiene a [date].
(DateTime, DateTime) isoWeekBounds(DateTime date) {
  final d = dateOnly(date);
  final monday = d.subtract(Duration(days: d.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  return (monday, sunday);
}

/// Devuelve la lista ordenada de horas HH:mm configuradas en [reminderTimes].
List<String> parseReminderTimes(String raw) => raw
    .split(',')
    .map((e) => e.trim())
    .where((e) => RegExp(r'^\d{2}:\d{2}$').hasMatch(e))
    .toList()
  ..sort();

/// Determina si una rutina o tarea puntual corresponde al día [date].
bool routineAppliesOnDate(Routine routine, DateTime date) {
  final target = dateOnly(date);
  final anchor = parseDayStr(routine.anchorDate);

  if (routine.itemType == 'task' || routine.frequencyType == 'once') {
    return daysBetween(anchor, target) == 0;
  }

  if (target.isBefore(anchor)) return false;

  switch (routine.frequencyType) {
    case 'daily':
      return true;
    case 'alternate':
      final days = parseWeekdaysMask(routine.weekdaysMask);
      if (days.isNotEmpty && days.length < 7) {
        return days.contains(target.weekday);
      }
      final diff = daysBetween(anchor, target);
      return diff >= 0 && diff % 2 == 0;
    case 'every_3_days':
      final days = parseWeekdaysMask(routine.weekdaysMask);
      if (days.isNotEmpty && days.length < 7) {
        return days.contains(target.weekday);
      }
      final diff = daysBetween(anchor, target);
      return diff >= 0 && diff % 3 == 0;
    case 'weekdays':
      final days = parseWeekdaysMask(routine.weekdaysMask);
      return days.contains(target.weekday);
    case 'weekly_x':
      return true;
    default:
      return true;
  }
}

/// Etiqueta breve legible de la frecuencia para tarjetas minimalistas.
String frequencyLabel(Routine routine) {
  if (routine.itemType == 'task' || routine.frequencyType == 'once') {
    return 'Tarea puntual';
  }
  switch (routine.frequencyType) {
    case 'daily':
      return 'Diaria';
    case 'alternate':
      final days = parseWeekdaysMask(routine.weekdaysMask).toList()..sort();
      if (days.isNotEmpty && days.length < 7) {
        final names = days.map((d) => kShortWeekdays[d - 1]).join(' · ');
        return 'Interdiaria · ${days.length}d/sem ($names)';
      }
      return 'Interdiaria';
    case 'every_3_days':
      final days = parseWeekdaysMask(routine.weekdaysMask).toList()..sort();
      if (days.isNotEmpty && days.length < 7) {
        final names = days.map((d) => kShortWeekdays[d - 1]).join(' · ');
        return 'Cada 3 días · ${days.length}d/sem ($names)';
      }
      return 'Cada 3 días';
    case 'weekdays':
      final days = parseWeekdaysMask(routine.weekdaysMask).toList()..sort();
      if (days.isEmpty) return 'Días fijos';
      return days.map((d) => kShortWeekdays[d - 1]).join(' · ');
    case 'weekly_x':
      final target = weeklyTargetCount(routine);
      return '$target ${target == 1 ? 'vez' : 'veces'}/semana';
    default:
      return 'Diaria';
  }
}

String timeSlotLabel(String slot) => switch (slot) {
  'morning' => 'Mañana',
  'afternoon' => 'Tarde',
  'night' => 'Noche',
  _ => 'Cualquier hora',
};
