// Vista Hoy — Power Habits (Soft Glass Minimal · UI/UX Pro Max).
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/frequency.dart';
import '../../core/providers.dart';
import '../../data/db.dart';
import '../../design/glass.dart';
import '../../design/motion.dart';
import '../../design/tokens.dart';
import 'note_sheet.dart';
import 'routine_form_sheet.dart';

const List<String> _kOrderedSlots = ['morning', 'afternoon', 'night', 'anytime'];

class TodayPage extends ConsumerWidget {
  const TodayPage({
    super.key,
    this.onOpenSettings,
    this.onRoutineSaved,
    this.onRoutineDeleted,
    this.onDataChanged,
  });

  final VoidCallback? onOpenSettings;
  final Future<void> Function(Routine routine)? onRoutineSaved;
  final Future<void> Function(String routineId)? onRoutineDeleted;
  final VoidCallback? onDataChanged;

  bool _matchesFilter(Routine routine, ContextFilter filter) => switch (filter) {
        ContextFilter.all => true,
        ContextFilter.personal => routine.context == 'personal',
        ContextFilter.work => routine.context == 'work',
      };

  String _headerTitle(DateTime selectedDate, DateTime today) {
    final diff = daysBetween(today, selectedDate);
    return switch (diff) {
      0 => 'Hoy',
      -1 => 'Ayer',
      1 => 'Mañana',
      _ => shortWeekday(selectedDate),
    };
  }

  Future<void> _openCreatePicker(
    BuildContext context,
    DateTime selectedDate,
  ) async {
    final pickedType = await showPowerSheet<String>(
      context: context,
      title: 'Crear nuevo',
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(Sp.x5, Sp.x2, Sp.x5, Sp.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CreateOptionCard(
              icon: LucideIcons.repeat,
              title: 'Nueva rutina',
              subtitle: 'Diario, interdiario, días fijos o X veces/sem',
              onTap: () => Navigator.of(ctx).pop('routine'),
            ),
            const SizedBox(height: Sp.x3),
            _CreateOptionCard(
              icon: LucideIcons.squareCheck,
              title: 'Nueva tarea',
              subtitle: 'Pendiente puntual para una fecha concreta',
              onTap: () => Navigator.of(ctx).pop('task'),
            ),
          ],
        ),
      ),
    );
    if (pickedType == null || !context.mounted) return;
    await _openRoutineForm(
      context,
      defaultItemType: pickedType,
      initialDate: selectedDate,
    );
  }

  Future<void> _openRoutineForm(
    BuildContext context, {
    Routine? existing,
    String defaultItemType = 'routine',
    DateTime? initialDate,
  }) async {
    await showRoutineFormSheet(
      context,
      existing: existing,
      defaultItemType: defaultItemType,
      initialDate: initialDate,
      onSaved: (routine) async {
        await onRoutineSaved?.call(routine);
        onDataChanged?.call();
      },
      onDeleted: (id) async {
        await onRoutineDeleted?.call(id);
        onDataChanged?.call();
      },
    );
  }

  Future<void> _toggleRoutine(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
    String dateKey,
  ) async {
    HapticFeedback.lightImpact();
    final routineRepo = ref.read(routineRepoProvider);
    final completed = await routineRepo.toggleCompletion(
      routineId: routine.id,
      dateKey: dateKey,
    );

    if (completed) {
      final totalCompleted = await routineRepo.countCompletedLogs(routine.id);
      if (totalCompleted >= 7) {
        final unlocked = await ref.read(achievementRepoProvider).unlockAuto(
              sourceKey: 'routine:${routine.id}:7days',
              title: '7 días constantes — ${routine.title}',
              detail: 'Completaste esta rutina 7 veces',
              context: routine.context,
            );
        if (unlocked && context.mounted) {
          final pc = context.pc;
          final tt = context.tt;
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: pc.neon,
              content: Row(
                children: [
                  Icon(LucideIcons.award, color: pc.onNeon, size: 18),
                  const SizedBox(width: Sp.x2),
                  Expanded(
                    child: Text(
                      'Logro desbloqueado: 7 días constantes — ${routine.title}',
                      style: tt.bodyMedium?.copyWith(
                        color: pc.onNeon,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    onDataChanged?.call();
  }

  Future<void> _openQuickNote(
    BuildContext context,
    Routine routine,
    String dateKey,
    String? existingNote,
  ) async {
    final saved = await showQuickNoteSheet(
      context,
      routine: routine,
      dateKey: dateKey,
      existingNote: existingNote,
    );
    if (saved) {
      onDataChanged?.call();
    }
  }

  Future<void> _seedInitialExamples(
    BuildContext context,
    WidgetRef ref,
    DateTime anchorDate,
  ) async {
    final repo = ref.read(routineRepoProvider);
    final anchorStr = dayStr(anchorDate);
    final specs = <({
      String title,
      String context,
      String timeSlot,
      String frequencyType,
      String weekdaysMask,
      List<String> reminders,
    })>[
      (
        title: 'Skincare mañana',
        context: 'personal',
        timeSlot: 'morning',
        frequencyType: 'daily',
        weekdaysMask: '1,2,3,4,5,6,7',
        reminders: const ['07:00'],
      ),
      (
        title: 'Ejercicio',
        context: 'personal',
        timeSlot: 'afternoon',
        frequencyType: 'weekdays',
        weekdaysMask: '1,3,5',
        reminders: const ['18:00'],
      ),
      (
        title: 'Salir a caminar',
        context: 'personal',
        timeSlot: 'afternoon',
        frequencyType: 'daily',
        weekdaysMask: '1,2,3,4,5,6,7',
        reminders: const ['17:30'],
      ),
      (
        title: 'Skincare noche',
        context: 'personal',
        timeSlot: 'night',
        frequencyType: 'alternate',
        weekdaysMask: '1,2,3,4,5,6,7',
        reminders: const ['21:30'],
      ),
      (
        title: 'Revisar sprint laboral',
        context: 'work',
        timeSlot: 'morning',
        frequencyType: 'weekdays',
        weekdaysMask: '1,2,3,4,5',
        reminders: const ['09:00'],
      ),
    ];

    final createdIds = <String>[];
    for (final s in specs) {
      final id = await repo.create(
        title: s.title,
        itemType: 'routine',
        context: s.context,
        timeSlot: s.timeSlot,
        frequencyType: s.frequencyType,
        weekdaysMask: s.weekdaysMask,
        anchorDate: anchorStr,
        reminderTimes: s.reminders,
        allowQuickNote: true,
      );
      createdIds.add(id);
    }

    if (onRoutineSaved != null) {
      final active = await repo.getActive();
      for (final r in active.where((r) => createdIds.contains(r.id))) {
        await onRoutineSaved!(r);
      }
    }
    onDataChanged?.call();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pc = context.pc;
    final tt = context.tt;

    final today = dateOnly(DateTime.now());
    final selectedDate = ref.watch(selectedDateProvider);
    final filter = ref.watch(contextFilterProvider);
    final routinesAsync = ref.watch(routinesStreamProvider);
    final logsAsync = ref.watch(logsForSelectedDateProvider);
    final weekLogsAsync = ref.watch(logsForSelectedWeekProvider);

    final dateKey = dayStr(selectedDate);
    final isToday = daysBetween(today, selectedDate) == 0;

    final allRoutines = routinesAsync.value ?? const <Routine>[];
    final logsList = logsAsync.value ?? const <RoutineLog>[];
    final weekLogs = weekLogsAsync.value ?? const <RoutineLog>[];
    final logsByRoutineId = {
      for (final log in logsList) log.routineId: log,
    };
    final weeklyDoneCounts = <String, int>{};
    for (final wl in weekLogs) {
      if (wl.completed) {
        weeklyDoneCounts[wl.routineId] =
            (weeklyDoneCounts[wl.routineId] ?? 0) + 1;
      }
    }

    final contextMatched =
        allRoutines.where((r) => _matchesFilter(r, filter)).toList();
    final applicable = contextMatched
        .where((r) => routineAppliesOnDate(r, selectedDate))
        .toList();
    final skippedCount = contextMatched
        .where(
          (r) =>
              r.itemType == 'routine' &&
              !routineAppliesOnDate(r, selectedDate),
        )
        .length;

    final completedCount = applicable
        .where((r) => logsByRoutineId[r.id]?.completed ?? false)
        .length;
    final totalCount = applicable.length;
    final progressRatio = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final progressPct = (progressRatio * 100).round();

    final grouped = <String, List<Routine>>{
      for (final slot in _kOrderedSlots) slot: <Routine>[],
    };
    for (final routine in applicable) {
      final key = grouped.containsKey(routine.timeSlot)
          ? routine.timeSlot
          : 'anytime';
      grouped[key]!.add(routine);
    }

    final isLoading = routinesAsync.isLoading && !routinesAsync.hasValue;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Encabezado
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Sp.x5, Sp.x4, Sp.x5, Sp.x3),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _headerTitle(selectedDate, today),
                              style: tt.headlineMedium,
                            ),
                            if (!isToday) ...[
                              const SizedBox(width: Sp.x2),
                              InkWell(
                                onTap: () => ref
                                    .read(selectedDateProvider.notifier)
                                    .setDate(today),
                                borderRadius: BorderRadius.circular(Rad.pill),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Sp.x3,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: pc.glassFillStrong,
                                    borderRadius:
                                        BorderRadius.circular(Rad.pill),
                                    border: Border.all(color: pc.glassBorder),
                                  ),
                                  child: Text(
                                    'Ir a hoy',
                                    style: tt.labelMedium?.copyWith(
                                      color: pc.ink,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          shortDateEs(selectedDate),
                          style: tt.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  GlassIconButton(
                    icon: LucideIcons.settings,
                    tooltip: 'Ajustes',
                    onPressed: onOpenSettings ?? () {},
                  ),
                  const SizedBox(width: Sp.x2),
                  GlassIconButton(
                    icon: LucideIcons.plus,
                    tooltip: 'Crear rutina o tarea',
                    onPressed: () => _openCreatePicker(context, selectedDate),
                  ),
                ],
              ),
            ),
          ),

          // Filtro Todo | Personal | Laboral
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.x5),
            sliver: SliverToBoxAdapter(
              child: GlassSegmented<ContextFilter>(
                value: filter,
                items: const [
                  (ContextFilter.all, 'Todo'),
                  (ContextFilter.personal, 'Personal'),
                  (ContextFilter.work, 'Laboral'),
                ],
                onChanged: (next) =>
                    ref.read(contextFilterProvider.notifier).setFilter(next),
              ),
            ),
          ),

          // Tira horizontal de 7 días centrada en hoy
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Sp.x5, Sp.x4, Sp.x5, Sp.x4),
            sliver: SliverToBoxAdapter(
              child: _WeekDateStrip(
                today: today,
                selectedDate: selectedDate,
                onSelectDate: (d) =>
                    ref.read(selectedDateProvider.notifier).setDate(d),
              ),
            ),
          ),

          // Tarjeta de progreso del día
          if (!isLoading && allRoutines.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Sp.x5, 0, Sp.x5, Sp.x5),
              sliver: SliverToBoxAdapter(
                child: _DailyProgressCard(
                  isToday: isToday,
                  completedCount: completedCount,
                  totalCount: totalCount,
                  skippedCount: skippedCount,
                  progressRatio: progressRatio,
                  progressPct: progressPct,
                ),
              ),
            ),

          // Contenido principal: cargando, estado vacío o bloques horarios
          if (isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (allRoutines.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Sp.x5, Sp.x2, Sp.x5, 120),
              sliver: SliverToBoxAdapter(
                child: _FirstTimeEmptyState(
                  onCreateFirst: () => _openRoutineForm(
                    context,
                    defaultItemType: 'routine',
                    initialDate: selectedDate,
                  ),
                  onSeedExamples: () =>
                      _seedInitialExamples(context, ref, today),
                ),
              ),
            )
          else if (applicable.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Sp.x5, Sp.x1, Sp.x5, 120),
              sliver: SliverToBoxAdapter(
                child: _FilteredEmptyState(
                  filter: filter,
                  skippedCount: skippedCount,
                  onResetFilter: () => ref
                      .read(contextFilterProvider.notifier)
                      .setFilter(ContextFilter.all),
                  onCreate: () => _openCreatePicker(context, selectedDate),
                ),
              ),
            )
          else ...[
            for (final slot in _kOrderedSlots)
              if (grouped[slot]!.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Sp.x5,
                    Sp.x1,
                    Sp.x5,
                    Sp.x2,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _TimeSlotHeader(
                      slot: slot,
                      completedCount: grouped[slot]!
                          .where(
                            (r) => logsByRoutineId[r.id]?.completed ?? false,
                          )
                          .length,
                      totalCount: grouped[slot]!.length,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(Sp.x5, 0, Sp.x5, Sp.x4),
                  sliver: SliverList.separated(
                    itemCount: grouped[slot]!.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Sp.x3),
                    itemBuilder: (ctx, index) {
                      final routine = grouped[slot]![index];
                      final log = logsByRoutineId[routine.id];
                      return _RoutineItemCard(
                        routine: routine,
                        isCompleted: log?.completed ?? false,
                        note: log?.note,
                        weeklyDoneCount: weeklyDoneCounts[routine.id] ?? 0,
                        onToggle: () =>
                            _toggleRoutine(context, ref, routine, dateKey),
                        onTapCard: () => _openRoutineForm(
                          context,
                          existing: routine,
                        ),
                        onTapNote: routine.allowQuickNote
                            ? () => _openQuickNote(
                                  context,
                                  routine,
                                  dateKey,
                                  log?.note,
                                )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            const SliverToBoxAdapter(child: SizedBox(height: 112)),
          ],
        ],
      ),
    );
  }
}

class _WeekDateStrip extends StatelessWidget {
  const _WeekDateStrip({
    required this.today,
    required this.selectedDate,
    required this.onSelectDate,
  });

  final DateTime today;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final base =
        daysBetween(today, selectedDate).abs() > 3 ? selectedDate : today;
    final days = List<DateTime>.generate(
      7,
      (i) => base.add(Duration(days: i - 3)),
    );

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: Sp.x2, vertical: Sp.x2),
      radius: Rad.lg,
      child: Row(
        children: [
          for (final d in days)
            Expanded(
              child: _DayPill(
                date: d,
                isSelected: daysBetween(d, selectedDate) == 0,
                isToday: daysBetween(d, today) == 0,
                pc: pc,
                onTap: () => onSelectDate(d),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.pc,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final PowerColors pc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: shortDateEs(date),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Rad.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? pc.neon
                : (isToday ? pc.glassFillStrong : Colors.transparent),
            borderRadius: BorderRadius.circular(Rad.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                kShortWeekdays[date.weekday - 1],
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? pc.onNeon : pc.inkMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: kTabular,
                  color: isSelected ? pc.onNeon : pc.ink,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday
                      ? (isSelected ? pc.onNeon : pc.neon)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyProgressCard extends StatefulWidget {
  const _DailyProgressCard({
    required this.isToday,
    required this.completedCount,
    required this.totalCount,
    required this.skippedCount,
    required this.progressRatio,
    required this.progressPct,
  });

  final bool isToday;
  final int completedCount;
  final int totalCount;
  final int skippedCount;
  final double progressRatio;
  final int progressPct;

  @override
  State<_DailyProgressCard> createState() => _DailyProgressCardState();
}

class _DailyProgressCardState extends State<_DailyProgressCard> {
  int _celebrateCount = 0;

  @override
  void didUpdateWidget(covariant _DailyProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.totalCount > 0 &&
        widget.progressPct == 100 &&
        oldWidget.progressPct < 100) {
      PowerHaptics.celebrate();
      setState(() => _celebrateCount++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final tt = context.tt;

    final skippedLabel = widget.skippedCount == 1
        ? (widget.isToday ? '1 no toca hoy' : '1 no toca este día')
        : (widget.isToday
            ? '${widget.skippedCount} no tocan hoy'
            : '${widget.skippedCount} no tocan este día');

    return CelebrationBurst(
      triggerCount: _celebrateCount,
      child: GlassCard(
        padding: const EdgeInsets.all(Sp.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    widget.isToday ? 'Progreso de hoy' : 'Progreso del día',
                    style: tt.titleMedium,
                  ),
                ),
                AnimatedPercentText(
                  value: widget.progressPct,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFeatures: kTabular,
                    color: pc.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sp.x3),
            NeonProgressBar(progress: widget.progressRatio, height: 10),
            const SizedBox(height: Sp.x3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.completedCount} de ${widget.totalCount} completadas',
                    style: tt.bodySmall?.copyWith(fontFeatures: kTabular),
                  ),
                ),
                if (widget.skippedCount > 0)
                  Text(
                    skippedLabel,
                    style: tt.bodySmall?.copyWith(fontFeatures: kTabular),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSlotHeader extends StatelessWidget {
  const _TimeSlotHeader({
    required this.slot,
    required this.completedCount,
    required this.totalCount,
  });

  final String slot;
  final int completedCount;
  final int totalCount;

  IconData _slotIcon() => switch (slot) {
        'morning' => LucideIcons.sunrise,
        'afternoon' => LucideIcons.sun,
        'night' => LucideIcons.moon,
        _ => LucideIcons.clock,
      };

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final tt = context.tt;
    return Row(
      children: [
        Icon(_slotIcon(), size: 15, color: pc.inkMuted),
        const SizedBox(width: Sp.x2),
        Text(
          timeSlotLabel(slot),
          style: tt.labelMedium?.copyWith(
            fontSize: 13,
            color: pc.inkMuted,
          ),
        ),
        const Spacer(),
        Text(
          '$completedCount/$totalCount',
          style: tt.bodySmall?.copyWith(fontFeatures: kTabular),
        ),
      ],
    );
  }
}

class _RoutineItemCard extends StatelessWidget {
  const _RoutineItemCard({
    required this.routine,
    required this.isCompleted,
    required this.note,
    required this.weeklyDoneCount,
    required this.onToggle,
    required this.onTapCard,
    this.onTapNote,
  });

  final Routine routine;
  final bool isCompleted;
  final String? note;
  final int weeklyDoneCount;
  final VoidCallback onToggle;
  final VoidCallback onTapCard;
  final VoidCallback? onTapNote;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final tt = context.tt;
    final reduce = reduceMotionOf(context);

    final reminders = parseReminderTimes(routine.reminderTimes);
    final String freqText;
    if (routine.frequencyType == 'weekly_x') {
      final target = weeklyTargetCount(routine);
      freqText = weeklyDoneCount >= target
          ? '$weeklyDoneCount/$target esta semana · Meta cumplida'
          : '$weeklyDoneCount/$target esta semana';
    } else {
      freqText = frequencyLabel(routine);
    }
    final metaLine = reminders.isEmpty
        ? freqText
        : '$freqText · ${reminders.join(', ')}';
    final hasNote = note != null && note!.trim().isNotEmpty;

    final card = GlassCard(
      padding: const EdgeInsets.fromLTRB(Sp.x1, Sp.x2, Sp.x2, Sp.x2),
      onTap: onTapCard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Área táctil 48x48dp para completar con rebote spring
              Semantics(
                checked: isCompleted,
                button: true,
                label: isCompleted
                    ? 'Desmarcar ${routine.title}'
                    : 'Completar ${routine.title}',
                child: InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(Rad.md),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: AnimatedScale(
                        scale: isCompleted && !reduce ? 1.06 : 1.0,
                        duration: reduce
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: AnimatedContainer(
                          duration: reduce
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isCompleted ? pc.neon : pc.glassFillStrong,
                            borderRadius: BorderRadius.circular(Rad.sm),
                            border: Border.all(
                              color: isCompleted
                                  ? pc.neon
                                  : pc.inkMuted.withValues(alpha: 0.45),
                              width: 1.5,
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: reduce
                                ? Duration.zero
                                : const Duration(milliseconds: 150),
                            child: isCompleted
                                ? Icon(
                                    LucideIcons.check,
                                    key: const ValueKey('done'),
                                    size: 16,
                                    color: pc.onNeon,
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey('empty'),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Sp.x1),
              // Máximo 2 líneas de información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyLarge?.copyWith(
                        color: isCompleted ? pc.inkMuted : pc.ink,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: pc.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            metaLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall,
                          ),
                        ),
                        const SizedBox(width: Sp.x2),
                        ContextBadge(
                          contextType: routine.context,
                          compact: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTapNote != null)
                Semantics(
                  button: true,
                  label: hasNote ? 'Editar nota' : 'Agregar nota rápida',
                  child: Tooltip(
                    message: hasNote ? 'Editar nota' : 'Nota rápida',
                    child: InkWell(
                      onTap: onTapNote,
                      borderRadius: BorderRadius.circular(Rad.pill),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          LucideIcons.fileText,
                          size: 18,
                          color: hasNote ? pc.ink : pc.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (hasNote)
            Padding(
              padding: const EdgeInsets.only(
                left: 52,
                right: Sp.x2,
                top: 2,
                bottom: Sp.x1,
              ),
              child: InkWell(
                onTap: onTapNote,
                borderRadius: BorderRadius.circular(Rad.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Sp.x3,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: pc.glassFillStrong,
                    borderRadius: BorderRadius.circular(Rad.sm),
                    border: Border.all(color: pc.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.cornerDownRight,
                        size: 13,
                        color: pc.inkMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          note!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(color: pc.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Dismissible(
      key: ValueKey('swipe_${routine.id}'),
      direction: onTapNote != null
          ? DismissDirection.horizontal
          : DismissDirection.startToEnd,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.28,
        DismissDirection.endToStart: 0.28,
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onToggle();
        } else if (direction == DismissDirection.endToStart &&
            onTapNote != null) {
          PowerHaptics.tap();
          onTapNote!();
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: Sp.x5),
        decoration: BoxDecoration(
          color: pc.neon,
          borderRadius: BorderRadius.circular(Rad.lg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompleted ? LucideIcons.rotateCcw : LucideIcons.check,
              size: 18,
              color: pc.onNeon,
            ),
            const SizedBox(width: Sp.x2),
            Text(
              isCompleted ? 'Desmarcar' : 'Completar',
              style: tt.labelMedium?.copyWith(
                color: pc.onNeon,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Sp.x5),
        decoration: BoxDecoration(
          color: pc.pinkSoft,
          borderRadius: BorderRadius.circular(Rad.lg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nota rápida',
              style: tt.labelMedium?.copyWith(
                color: pc.onPinkSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: Sp.x2),
            Icon(LucideIcons.fileText, size: 18, color: pc.onPinkSoft),
          ],
        ),
      ),
      child: card,
    );
  }
}

class _CreateOptionCard extends StatelessWidget {
  const _CreateOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final tt = context.tt;
    return GlassCard(
      padding: const EdgeInsets.all(Sp.x4),
      radius: Rad.md,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: pc.pinkSoft,
              borderRadius: BorderRadius.circular(Rad.md),
            ),
            child: Icon(icon, size: 20, color: pc.onPinkSoft),
          ),
          const SizedBox(width: Sp.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tt.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: tt.bodySmall),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 18, color: pc.inkMuted),
        ],
      ),
    );
  }
}

class _FirstTimeEmptyState extends StatelessWidget {
  const _FirstTimeEmptyState({
    required this.onCreateFirst,
    required this.onSeedExamples,
  });

  final VoidCallback onCreateFirst;
  final VoidCallback onSeedExamples;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final tt = context.tt;
    return GlassCard(
      padding: const EdgeInsets.all(Sp.x6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: pc.pinkSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.calendarCheck,
              size: 26,
              color: pc.onPinkSoft,
            ),
          ),
          const SizedBox(height: Sp.x4),
          Text(
            'Tu día, claro y ligero',
            style: tt.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Sp.x2),
          Text(
            'Crea tu primera rutina o carga algunos ejemplos reales para empezar en segundos.',
            style: tt.bodyMedium?.copyWith(color: pc.inkMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Sp.x5),
          SizedBox(
            width: double.infinity,
            child: PrimaryNeonButton(
              label: 'Crear primera rutina',
              icon: LucideIcons.plus,
              onPressed: onCreateFirst,
            ),
          ),
          const SizedBox(height: Sp.x3),
          SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: OutlinedButton.icon(
                onPressed: onSeedExamples,
                style: OutlinedButton.styleFrom(
                  foregroundColor: pc.ink,
                  side: BorderSide(color: pc.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Rad.pill),
                  ),
                ),
                icon: const Icon(LucideIcons.sparkles, size: 17),
                label: const Text('Cargar ejemplos iniciales'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({
    required this.filter,
    required this.skippedCount,
    required this.onResetFilter,
    required this.onCreate,
  });

  final ContextFilter filter;
  final int skippedCount;
  final VoidCallback onResetFilter;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final tt = context.tt;
    final filterLabel = switch (filter) {
      ContextFilter.personal => 'Personal',
      ContextFilter.work => 'Laboral',
      ContextFilter.all => 'esta vista',
    };
    final subtitle = skippedCount > 0
        ? 'Tienes $skippedCount ${skippedCount == 1 ? 'rutina que no toca' : 'rutinas que no tocan'} este día.'
        : 'No hay rutinas ni tareas programadas en $filterLabel para esta fecha.';

    return GlassCard(
      padding: const EdgeInsets.all(Sp.x6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: pc.workSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.sun, size: 24, color: pc.onWorkSoft),
          ),
          const SizedBox(height: Sp.x4),
          Text(
            'Sin pendientes aquí',
            style: tt.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Sp.x2),
          Text(
            subtitle,
            style: tt.bodyMedium?.copyWith(color: pc.inkMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Sp.x5),
          if (filter != ContextFilter.all)
            SizedBox(
              width: double.infinity,
              child: PrimaryNeonButton(
                label: 'Ver todo',
                icon: LucideIcons.layers,
                onPressed: onResetFilter,
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: PrimaryNeonButton(
                label: 'Agregar rutina o tarea',
                icon: LucideIcons.plus,
                onPressed: onCreate,
              ),
            ),
        ],
      ),
    );
  }
}
