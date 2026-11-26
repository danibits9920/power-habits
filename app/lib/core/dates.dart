// Utilidades de fechas locales y etiquetas en español.
DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String dayStr(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime parseDayStr(String s) {
  final parts = s.split('-');
  if (parts.length != 3) return dateOnly(DateTime.now());
  final y = int.tryParse(parts[0]) ?? DateTime.now().year;
  final m = int.tryParse(parts[1]) ?? DateTime.now().month;
  final d = int.tryParse(parts[2]) ?? DateTime.now().day;
  return DateTime(y, m, d);
}

int daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

const List<String> kShortWeekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const List<String> kInitialWeekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
const List<String> kShortMonths = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];
const List<String> kFullMonths = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

String shortWeekday(DateTime dt) => kShortWeekdays[dt.weekday - 1];

String shortDateEs(DateTime dt) =>
    '${shortWeekday(dt)} ${dt.day} ${kShortMonths[dt.month - 1]}';

String monthYearEs(DateTime dt) => '${kFullMonths[dt.month - 1]} ${dt.year}';

String nowUtcIso() => DateTime.now().toUtc().toIso8601String();
