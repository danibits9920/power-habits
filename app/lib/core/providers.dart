// Providers compartidos (Riverpod 3) para toda la app Power Habits.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import '../data/repos.dart';
import 'dates.dart';

/// Filtro de contexto global: 'all' | 'personal' | 'work'
enum ContextFilter { all, personal, work }

final dbProvider = Provider<AppDb>((ref) {
  final db = AppDb();
  ref.onDispose(db.close);
  return db;
});

final settingsRepoProvider = Provider<SettingsRepo>(
  (ref) => SettingsRepo(ref.watch(dbProvider)),
);

final achievementRepoProvider = Provider<AchievementRepo>(
  (ref) => AchievementRepo(ref.watch(dbProvider)),
);

final routineRepoProvider = Provider<RoutineRepo>(
  (ref) => RoutineRepo(ref.watch(dbProvider)),
);

final goalRepoProvider = Provider<GoalRepo>(
  (ref) => GoalRepo(
    ref.watch(dbProvider),
    ref.watch(achievementRepoProvider),
  ),
);

class ContextFilterNotifier extends Notifier<ContextFilter> {
  @override
  ContextFilter build() => ContextFilter.all;

  void setFilter(ContextFilter next) => state = next;
}

final contextFilterProvider =
    NotifierProvider<ContextFilterNotifier, ContextFilter>(
  ContextFilterNotifier.new,
);

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(DateTime.now());

  void setDate(DateTime next) => state = dateOnly(next);
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadSaved();
    return ThemeMode.light;
  }

  Future<void> _loadSaved() async {
    final saved = await ref.read(settingsRepoProvider).get('theme_mode');
    if (saved == 'dark') {
      state = ThemeMode.dark;
    } else if (saved == 'system') {
      state = ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final val = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };
    await ref.read(settingsRepoProvider).set('theme_mode', val);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

final routinesStreamProvider = StreamProvider<List<Routine>>(
  (ref) => ref.watch(routineRepoProvider).watchActive(),
);

final logsForSelectedDateProvider = StreamProvider<List<RoutineLog>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(routineRepoProvider).watchLogsForDate(dayStr(date));
});

final goalsStreamProvider = StreamProvider<List<Goal>>(
  (ref) => ref.watch(goalRepoProvider).watchActive(),
);

final achievementsStreamProvider = StreamProvider<List<Achievement>>(
  (ref) => ref.watch(achievementRepoProvider).watchAll(),
);
