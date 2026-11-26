// Pantalla 4 — Progreso (Soft Glass Minimal):
// Constancia mensual (C), Estadísticas Personal vs. Laboral (D) y Línea de logros (automáticos + manuales).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/providers.dart';
import '../../data/db.dart';
import '../../design/glass.dart';
import '../../design/tokens.dart';
import 'achievement_form_sheet.dart';
import 'progress_metrics.dart';

class _ProgressMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void previousMonth() => state = DateTime(state.year, state.month - 1, 1);

  void nextMonth() => state = DateTime(state.year, state.month + 1, 1);
}

final progressMonthProvider =
    NotifierProvider<_ProgressMonthNotifier, DateTime>(
  _ProgressMonthNotifier.new,
);

class _SelectedProgressRoutineNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? routineId) => state = routineId;
}

final selectedProgressRoutineIdProvider =
    NotifierProvider<_SelectedProgressRoutineNotifier, String?>(
  _SelectedProgressRoutineNotifier.new,
);

final logsForProgressMonthProvider = StreamProvider<List<RoutineLog>>((ref) {
  final month = ref.watch(progressMonthProvider);
  final (from, to) = monthDateRange(month);
  return ref.watch(routineRepoProvider).watchLogsInRange(from, to);
});

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(progressMonthProvider);
    final selectedRoutineId = ref.watch(selectedProgressRoutineIdProvider);
    final routinesAsync = ref.watch(routinesStreamProvider);
    final logsAsync = ref.watch(logsForProgressMonthProvider);
    final achievementsAsync = ref.watch(achievementsStreamProvider);

    final routines = routinesAsync.asData?.value ?? const <Routine>[];
    final logs = logsAsync.asData?.value ?? const <RoutineLog>[];
    final today = dateOnly(DateTime.now());

    // Prioriza rutinas recurrentes en el selector de constancia; si solo hay tareas, las muestra.
    final recurring = routines.where((r) => r.itemType == 'routine').toList();
    final selectableRoutines = recurring.isNotEmpty ? recurring : routines;

    Routine? activeRoutine;
    if (selectableRoutines.isNotEmpty) {
      activeRoutine = selectableRoutines.firstWhere(
        (r) => r.id == selectedRoutineId,
        orElse: () => selectableRoutines.first,
      );
    }

    final stats = computeContextMonthlyStats(
      routines: routines,
      logs: logs,
      month: month,
      today: today,
    );

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Sp.x5, Sp.x4, Sp.x5, Sp.x4),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text('Progreso', style: context.tt.headlineMedium),
                  ),
                  _AddAchievementPill(
                    onPressed: () => showAchievementFormSheet(context),
                  ),
                  if (onOpenSettings != null) ...[
                    const SizedBox(width: Sp.x2),
                    GlassIconButton(
                      icon: LucideIcons.settings,
                      tooltip: 'Ajustes',
                      onPressed: onOpenSettings!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.x5),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MonthlyConsistencyCard(
                    month: month,
                    today: today,
                    routines: selectableRoutines,
                    selectedRoutine: activeRoutine,
                    logs: logs,
                    onPreviousMonth: () => ref
                        .read(progressMonthProvider.notifier)
                        .previousMonth(),
                    onNextMonth: () =>
                        ref.read(progressMonthProvider.notifier).nextMonth(),
                    onSelectRoutine: (id) => ref
                        .read(selectedProgressRoutineIdProvider.notifier)
                        .select(id),
                  ),
                  const SizedBox(height: Sp.x4),
                  _MonthlyContextStatsCard(month: month, stats: stats),
                  const SizedBox(height: Sp.x6),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Sp.x5, 0, Sp.x5, 120),
            sliver: SliverToBoxAdapter(
              child: _AchievementsTimelineSection(
                achievementsAsync: achievementsAsync,
                onAddManual: () => showAchievementFormSheet(context),
                onDeleteManual: (achievement) =>
                    _confirmDeleteAchievement(context, ref, achievement),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteAchievement(
    BuildContext context,
    WidgetRef ref,
    Achievement achievement,
  ) async {
    final pc = context.pc;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: pc.glassFillStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rad.lg),
        ),
        title: Text('¿Eliminar logro?', style: ctx.tt.titleLarge),
        content: Text(
          'Se eliminará "${achievement.title}" de tu línea de logros.',
          style: ctx.tt.bodyMedium?.copyWith(color: pc.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: TextStyle(color: pc.inkMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Eliminar',
              style: TextStyle(
                color: pc.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(achievementRepoProvider).softDelete(achievement.id);
      return true;
    }
    return false;
  }
}

class _AddAchievementPill extends StatelessWidget {
  const _AddAchievementPill({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return Semantics(
      button: true,
      label: 'Registrar logro',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: pc.neon,
            foregroundColor: pc.onNeon,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.x4,
              vertical: Sp.x3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Rad.pill),
            ),
            textStyle: const TextStyle(
              fontFamily: kFontDisplay,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Logro'),
        ),
      ),
    );
  }
}

/// Card 1 — Constancia mensual (C) con vista de notas rápidas por día (F).
class _MonthlyConsistencyCard extends StatefulWidget {
  const _MonthlyConsistencyCard({
    required this.month,
    required this.today,
    required this.routines,
    required this.selectedRoutine,
    required this.logs,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectRoutine,
  });

  final DateTime month;
  final DateTime today;
  final List<Routine> routines;
  final Routine? selectedRoutine;
  final List<RoutineLog> logs;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<String?> onSelectRoutine;

  @override
  State<_MonthlyConsistencyCard> createState() =>
      _MonthlyConsistencyCardState();
}

class _MonthlyConsistencyCardState extends State<_MonthlyConsistencyCard> {
  int? _selectedNoteDay;

  @override
  void didUpdateWidget(covariant _MonthlyConsistencyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month ||
        oldWidget.selectedRoutine?.id != widget.selectedRoutine?.id) {
      _selectedNoteDay = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final selectedRoutine = widget.selectedRoutine;
    final month = widget.month;
    final today = widget.today;

    final statusMap = selectedRoutine == null
        ? const <int, RoutineMonthDayStatus>{}
        : buildMonthCalendarStatus(selectedRoutine, widget.logs, month, today);
    final completedCount = countCompletedDays(statusMap);

    final notesByDay = <int, String>{};
    if (selectedRoutine != null) {
      for (final log in widget.logs) {
        if (log.deletedAt != null || log.routineId != selectedRoutine.id) {
          continue;
        }
        final trimmed = log.note?.trim() ?? '';
        if (trimmed.isEmpty) continue;
        final d = parseDayStr(log.logDate);
        if (d.year == month.year && d.month == month.month) {
          notesByDay[d.day] = trimmed;
        }
      }
    }

    final activeNoteDay =
        _selectedNoteDay != null && notesByDay.containsKey(_selectedNoteDay)
            ? _selectedNoteDay
            : null;

    final totalDays = daysInMonth(month);
    final firstWeekdayOffset = DateTime(month.year, month.month, 1).weekday - 1;
    final totalCells =
        ((firstWeekdayOffset + totalDays + 6) ~/ 7) * 7;

    return GlassCard(
      padding: const EdgeInsets.all(Sp.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Constancia mensual',
                  style: context.tt.titleMedium,
                ),
              ),
              if (selectedRoutine != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Sp.x3,
                    vertical: Sp.x1 + 2,
                  ),
                  decoration: BoxDecoration(
                    color: selectedRoutine.context == 'work'
                        ? pc.workSoft
                        : pc.pinkSoft,
                    borderRadius: BorderRadius.circular(Rad.pill),
                  ),
                  child: Text(
                    completedCount == 1 ? '1 día' : '$completedCount días',
                    style: context.tt.labelMedium?.copyWith(
                      fontFamily: kFontMono,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      fontFeatures: kTabular,
                      color: selectedRoutine.context == 'work'
                          ? pc.onWorkSoft
                          : pc.onPinkSoft,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Sp.x2),
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: 'Mes anterior',
                  onPressed: widget.onPreviousMonth,
                  icon: Icon(LucideIcons.chevronLeft, size: 18, color: pc.ink),
                ),
              ),
              Expanded(
                child: Text(
                  monthYearEs(month),
                  textAlign: TextAlign.center,
                  style: context.tt.bodyMedium?.copyWith(
                    fontFamily: kFontDisplay,
                    color: pc.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: 'Mes siguiente',
                  onPressed: widget.onNextMonth,
                  icon: Icon(LucideIcons.chevronRight, size: 18, color: pc.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.x2),
          if (selectedRoutine == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.x4),
              child: Text(
                'Crea tu primera rutina en Hoy para visualizar tu constancia en el calendario mensual.',
                style: context.tt.bodyMedium?.copyWith(color: pc.inkMuted),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: Sp.x3),
              decoration: BoxDecoration(
                color: pc.glassFillStrong,
                borderRadius: BorderRadius.circular(Rad.md),
                border: Border.all(color: pc.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedRoutine.id,
                  isExpanded: true,
                  dropdownColor: pc.glassFillStrong,
                  borderRadius: BorderRadius.circular(Rad.md),
                  icon: Icon(
                    LucideIcons.chevronDown,
                    size: 18,
                    color: pc.inkMuted,
                  ),
                  style: context.tt.bodyMedium?.copyWith(
                    color: pc.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  items: [
                    for (final r in widget.routines)
                      DropdownMenuItem<String>(
                        value: r.id,
                        child: Text(
                          r.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: widget.onSelectRoutine,
                ),
              ),
            ),
            const SizedBox(height: Sp.x4),
            Row(
              children: [
                for (final initial in kInitialWeekdays)
                  Expanded(
                    child: Center(
                      child: Text(
                        initial,
                        style: context.tt.labelMedium?.copyWith(
                          color: pc.inkMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Sp.x2),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemBuilder: (_, index) {
                final dayNum = index - firstWeekdayOffset + 1;
                if (dayNum < 1 || dayNum > totalDays) {
                  return const SizedBox.shrink();
                }
                final date = DateTime(month.year, month.month, dayNum);
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final status =
                    statusMap[dayNum] ?? RoutineMonthDayStatus.notScheduled;
                final hasNote = notesByDay.containsKey(dayNum);

                return _CalendarDayCell(
                  day: dayNum,
                  status: status,
                  isToday: isToday,
                  hasNote: hasNote,
                  isNoteSelected: activeNoteDay == dayNum,
                  onTap: hasNote
                      ? () => setState(() {
                            _selectedNoteDay =
                                _selectedNoteDay == dayNum ? null : dayNum;
                          })
                      : null,
                );
              },
            ),
            const SizedBox(height: Sp.x4),
            Wrap(
              spacing: Sp.x4,
              runSpacing: Sp.x2,
              children: [
                _LegendDot(
                  label: 'Cumplido',
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: pc.neon,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                _LegendDot(
                  label: 'No toca',
                  child: CustomPaint(
                    size: const Size(12, 12),
                    painter: _DashedRoundedRectPainter(
                      color: pc.inkMuted.withValues(alpha: 0.45),
                      radius: 4,
                    ),
                  ),
                ),
                _LegendDot(
                  label: 'Hoy',
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: pc.ink, width: 1.8),
                    ),
                  ),
                ),
                if (notesByDay.isNotEmpty)
                  _LegendDot(
                    label: 'Nota',
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: pc.onPinkSoft,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            if (activeNoteDay != null) ...[
              const SizedBox(height: Sp.x3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.x3,
                  vertical: Sp.x2 + 2,
                ),
                decoration: BoxDecoration(
                  color: pc.glassFillStrong,
                  borderRadius: BorderRadius.circular(Rad.md),
                  border: Border.all(color: pc.divider),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.fileText, size: 15, color: pc.onPinkSoft),
                    const SizedBox(width: Sp.x2),
                    Expanded(
                      child: Text(
                        '${shortDateEs(DateTime(month.year, month.month, activeNoteDay))}: ${notesByDay[activeNoteDay]!}',
                        style: context.tt.bodySmall?.copyWith(color: pc.ink),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.status,
    required this.isToday,
    this.hasNote = false,
    this.isNoteSelected = false,
    this.onTap,
  });

  final int day;
  final RoutineMonthDayStatus status;
  final bool isToday;
  final bool hasNote;
  final bool isNoteSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;

    final Color bgColor;
    final Color textColor;
    final FontWeight weight;
    final bool useDashed;

    switch (status) {
      case RoutineMonthDayStatus.completed:
        bgColor = pc.neon;
        textColor = pc.onNeon;
        weight = FontWeight.w700;
        useDashed = false;
      case RoutineMonthDayStatus.missed:
        bgColor = pc.trackBg;
        textColor = pc.inkMuted;
        weight = FontWeight.w500;
        useDashed = false;
      case RoutineMonthDayStatus.notScheduled:
        bgColor = Colors.transparent;
        textColor = pc.inkMuted.withValues(alpha: 0.55);
        weight = FontWeight.w400;
        useDashed = true;
      case RoutineMonthDayStatus.future:
        bgColor = pc.glassFill;
        textColor = pc.ink;
        weight = FontWeight.w500;
        useDashed = false;
    }

    Widget cell = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(Rad.sm),
        border: isToday || isNoteSelected
            ? Border.all(
                color: isNoteSelected ? pc.onPinkSoft : pc.ink,
                width: 2,
              )
            : (status == RoutineMonthDayStatus.future
                ? Border.all(color: pc.divider, width: 1)
                : null),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontFamily: kFontMono,
              fontSize: 12.5,
              fontWeight: isToday ? FontWeight.w700 : weight,
              fontFeatures: kTabular,
              color: textColor,
            ),
          ),
          if (hasNote)
            Positioned(
              bottom: 3,
              child: Container(
                width: 4.5,
                height: 4.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: status == RoutineMonthDayStatus.completed
                      ? pc.onNeon
                      : pc.onPinkSoft,
                ),
              ),
            ),
        ],
      ),
    );

    if (useDashed && !isToday && !isNoteSelected) {
      cell = CustomPaint(
        painter: _DashedRoundedRectPainter(
          color: pc.divider,
          radius: Rad.sm,
        ),
        child: cell,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cell,
      );
    }
    return cell;
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.6, 0.6, size.width - 1.2, size.height - 1.2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 3.5;
    const dashSpace = 3.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(width: 6),
        Text(
          label,
          style: context.tt.bodySmall?.copyWith(color: pc.inkMuted),
        ),
      ],
    );
  }
}

/// Card 2 — Estadísticas del mes (D): Personal vs. Laboral.
class _MonthlyContextStatsCard extends StatelessWidget {
  const _MonthlyContextStatsCard({
    required this.month,
    required this.stats,
  });

  final DateTime month;
  final ContextMonthlyStats stats;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return GlassCard(
      padding: const EdgeInsets.all(Sp.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Estadísticas del mes',
                  style: context.tt.titleMedium,
                ),
              ),
              Text(
                monthYearEs(month),
                style: context.tt.bodySmall?.copyWith(color: pc.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: Sp.x4),
          _ContextStatBarRow(
            contextType: 'personal',
            completed: stats.personalCompleted,
            scheduled: stats.personalScheduled,
            pct: stats.personalPct,
            isWork: false,
          ),
          const SizedBox(height: Sp.x4),
          _ContextStatBarRow(
            contextType: 'work',
            completed: stats.workCompleted,
            scheduled: stats.workScheduled,
            pct: stats.workPct,
            isWork: true,
          ),
          const SizedBox(height: Sp.x3),
          Text(
            'Calculado solo sobre días programados; los descansos no penalizan.',
            style: context.tt.bodySmall?.copyWith(color: pc.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _ContextStatBarRow extends StatelessWidget {
  const _ContextStatBarRow({
    required this.contextType,
    required this.completed,
    required this.scheduled,
    required this.pct,
    required this.isWork,
  });

  final String contextType;
  final int completed;
  final int scheduled;
  final int pct;
  final bool isWork;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ContextBadge(contextType: contextType),
            const SizedBox(width: Sp.x2),
            Expanded(
              child: Text(
                scheduled == 0 ? 'Sin días programados' : '$completed / $scheduled días',
                style: context.tt.bodySmall?.copyWith(
                  color: pc.inkMuted,
                  fontFeatures: kTabular,
                ),
              ),
            ),
            Text(
              '$pct%',
              style: context.tt.titleMedium?.copyWith(
                fontFamily: kFontDisplay,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                fontFeatures: kTabular,
                color: pc.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: Sp.x2),
        NeonProgressBar(
          progress: pct / 100.0,
          height: 10,
          isWork: isWork,
        ),
      ],
    );
  }
}

/// Section 3 — Línea de logros (automáticos + manuales).
class _AchievementsTimelineSection extends StatelessWidget {
  const _AchievementsTimelineSection({
    required this.achievementsAsync,
    required this.onAddManual,
    required this.onDeleteManual,
  });

  final AsyncValue<List<Achievement>> achievementsAsync;
  final VoidCallback onAddManual;
  final Future<bool> Function(Achievement achievement) onDeleteManual;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Línea de logros', style: context.tt.titleLarge),
            ),
            if (achievementsAsync.asData?.value.isNotEmpty ?? false)
              Text(
                '${achievementsAsync.asData!.value.length}',
                style: context.tt.labelMedium?.copyWith(
                  fontFamily: kFontMono,
                  fontFeatures: kTabular,
                  color: pc.inkMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: Sp.x3),
        achievementsAsync.when(
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.all(Sp.x5),
              child: CircularProgressIndicator(
                color: pc.ink,
                strokeWidth: 2.2,
              ),
            ),
          ),
          error: (_, _) => GlassCard(
            child: Text(
              'No se pudo cargar la línea de logros.',
              style: context.tt.bodyMedium?.copyWith(color: pc.danger),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return GlassCard(
                padding: const EdgeInsets.all(Sp.x5),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: pc.pinkSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.award,
                        size: 24,
                        color: pc.onPinkSoft,
                      ),
                    ),
                    const SizedBox(height: Sp.x3),
                    Text(
                      'Aún sin logros registrados',
                      style: context.tt.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Sp.x1),
                    Text(
                      'Tus hitos automáticos de metas y los logros que registres aparecerán aquí en orden cronológico.',
                      style: context.tt.bodySmall?.copyWith(color: pc.inkMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Sp.x4),
                    PrimaryNeonButton(
                      label: 'Registrar logro',
                      icon: LucideIcons.plus,
                      compact: true,
                      onPressed: onAddManual,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  _TimelineAchievementRow(
                    achievement: items[i],
                    isLast: i == items.length - 1,
                    onDeleteManual: onDeleteManual,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TimelineAchievementRow extends StatelessWidget {
  const _TimelineAchievementRow({
    required this.achievement,
    required this.isLast,
    required this.onDeleteManual,
  });

  final Achievement achievement;
  final bool isLast;
  final Future<bool> Function(Achievement achievement) onDeleteManual;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final isAuto = achievement.kind == 'auto';
    final dotColor = isAuto ? pc.neon : pc.pink;
    final dateLabel = shortDateEs(parseDayStr(achievement.achievedDate));

    Widget card = GlassCard(
      padding: const EdgeInsets.fromLTRB(Sp.x4, Sp.x3, Sp.x3, Sp.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isAuto ? pc.neon : pc.pinkSoft,
              borderRadius: BorderRadius.circular(Rad.sm),
            ),
            child: Icon(
              isAuto ? LucideIcons.award : LucideIcons.bookmarkCheck,
              size: 18,
              color: isAuto ? pc.onNeon : pc.onPinkSoft,
            ),
          ),
          const SizedBox(width: Sp.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: context.tt.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Sp.x2),
                    ContextBadge(
                      contextType: achievement.context,
                      compact: true,
                    ),
                  ],
                ),
                if (achievement.detail.trim().isNotEmpty) ...[
                  const SizedBox(height: Sp.x1),
                  Text(
                    achievement.detail,
                    style: context.tt.bodySmall?.copyWith(color: pc.inkMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: Sp.x2),
                Text(
                  '$dateLabel · ${isAuto ? 'Hito automático' : 'Logro manual'}',
                  style: context.tt.bodySmall?.copyWith(
                    fontSize: 11.5,
                    color: pc.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          if (!isAuto)
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                tooltip: 'Eliminar logro',
                onPressed: () => onDeleteManual(achievement),
                icon: Icon(
                  LucideIcons.trash2,
                  size: 17,
                  color: pc.inkMuted,
                ),
              ),
            ),
        ],
      ),
    );

    if (!isAuto) {
      card = Dismissible(
        key: ValueKey('achievement_${achievement.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => onDeleteManual(achievement),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: Sp.x5),
          decoration: BoxDecoration(
            color: pc.danger.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(Rad.lg),
          ),
          child: Icon(LucideIcons.trash2, color: pc.danger, size: 20),
        ),
        child: card,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : Sp.x3),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isAuto
                            ? pc.ink.withValues(alpha: 0.25)
                            : pc.onPinkSoft.withValues(alpha: 0.35),
                        width: 1.4,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        margin: const EdgeInsets.only(top: Sp.x1),
                        color: pc.divider,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Sp.x2),
            Expanded(child: card),
          ],
        ),
      ),
    );
  }
}
