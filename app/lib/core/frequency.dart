// Lógica pura y determinista de frecuencias flexibles (Diaria, Interdiaria, Días específicos, Puntual).
import '../data/db.dart';
import 'dates.dart';

/// Devuelve los días de semana ISO (1=Lun..7=Dom) configurados en [weekdaysMask].
Set<int> parseWeekdaysMask(String mask) => mask
    .split(',')
    .map((e) => int.tryParse(e.trim()))
    .whereType<int>()
    .where((d) => d >= 1 && d <= 7)
    .toSet();

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

  switch (routine.frequencyType) {
    case 'daily':
      return !target.isBefore(anchor);
    case 'alternate':
      final diff = daysBetween(anchor, target);
      return diff >= 0 && diff % 2 == 0;
    case 'weekdays':
      if (target.isBefore(anchor)) return false;
      final days = parseWeekdaysMask(routine.weekdaysMask);
      return days.contains(target.weekday);
    default:
      return !target.isBefore(anchor);
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
      return 'Interdiaria';
    case 'weekdays':
      final days = parseWeekdaysMask(routine.weekdaysMask).toList()..sort();
      if (days.isEmpty) return 'Días fijos';
      return days.map((d) => kShortWeekdays[d - 1]).join(' · ');
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
