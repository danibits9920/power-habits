// Pantalla 3 — Metas (Soft Glass Minimal): progreso por unidades, línea de hitos 0/25/50/75/100 % y pasos nombrados.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../data/db.dart';
import '../../design/glass.dart';
import '../../design/tokens.dart';
import 'goal_form_sheet.dart';

/// Stream reactivo de pasos nombrados por meta.
final goalStepsProvider = StreamProvider.family<List<GoalStep>, String>(
  (ref, goalId) => ref.watch(goalRepoProvider).watchSteps(goalId),
);

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pc = context.pc;
    final filter = ref.watch(contextFilterProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Sp.x5, Sp.x4, Sp.x5, Sp.x3),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Metas', style: context.tt.headlineMedium),
                      ),
                      if (onOpenSettings != null) ...[
                        GlassIconButton(
                          icon: LucideIcons.settings,
                          tooltip: 'Ajustes',
                          onPressed: onOpenSettings!,
                        ),
                        const SizedBox(width: Sp.x2),
                      ],
                      GlassIconButton(
                        icon: LucideIcons.plus,
                        tooltip: 'Nueva meta',
                        onPressed: () => showGoalFormSheet(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sp.x4),
                  GlassSegmented<ContextFilter>(
                    value: filter,
                    items: const [
                      (ContextFilter.all, 'Todo'),
                      (ContextFilter.personal, 'Personal'),
                      (ContextFilter.work, 'Laboral'),
                    ],
                    onChanged: (next) =>
                        ref.read(contextFilterProvider.notifier).setFilter(next),
                  ),
                ],
              ),
            ),
          ),
          goalsAsync.when(
            loading: () => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                  color: pc.ink,
                  strokeWidth: 2.2,
                ),
              ),
            ),
            error: (err, _) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.x5),
              sliver: SliverToBoxAdapter(
                child: GlassCard(
                  child: Text(
                    'No se pudieron cargar las metas.',
                    style: context.tt.bodyMedium?.copyWith(color: pc.danger),
                  ),
                ),
              ),
            ),
            data: (goals) {
              final filtered = goals.where((g) {
                return switch (filter) {
                  ContextFilter.all => true,
                  ContextFilter.personal => g.context == 'personal',
                  ContextFilter.work => g.context == 'work',
                };
              }).toList();

              if (filtered.isEmpty) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(Sp.x5, Sp.x4, Sp.x5, 120),
                  sliver: SliverToBoxAdapter(
                    child: _EmptyGoalsCard(
                      isFiltered: filter != ContextFilter.all && goals.isNotEmpty,
                      onCreate: () => showGoalFormSheet(context),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(Sp.x5, Sp.x1, Sp.x5, 120),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Sp.x4),
                  itemBuilder: (_, index) => _GoalCard(goal: filtered[index]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyGoalsCard extends StatelessWidget {
  const _EmptyGoalsCard({
    required this.isFiltered,
    required this.onCreate,
  });

  final bool isFiltered;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return GlassCard(
      padding: const EdgeInsets.all(Sp.x6),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: pc.pinkSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.target, size: 26, color: pc.onPinkSoft),
          ),
          const SizedBox(height: Sp.x4),
          Text(
            isFiltered ? 'Sin metas en este contexto' : 'Aún no tienes metas',
            style: context.tt.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Sp.x2),
          Text(
            isFiltered
                ? 'Crea una meta para esta vista o cambia el filtro superior.'
                : 'Divide cursos, proyectos o retos en unidades claras y sigue tus hitos del 25 % al 100 %.',
            style: context.tt.bodyMedium?.copyWith(color: pc.inkMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Sp.x5),
          PrimaryNeonButton(
            label: 'Crear meta',
            icon: LucideIcons.plus,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerStatefulWidget {
  const _GoalCard({required this.goal});

  final Goal goal;

  @override
  ConsumerState<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends ConsumerState<_GoalCard> {
  bool _expanded = false;
  bool _addingStep = false;
  final _stepCtrl = TextEditingController();

  @override
  void dispose() {
    _stepCtrl.dispose();
    super.dispose();
  }

  void _showMilestoneSnackBar(int milestone) {
    if (!mounted) return;
    final pc = context.pc;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: pc.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Rad.md),
          ),
          content: Row(
            children: [
              Icon(LucideIcons.award, size: 18, color: pc.bgBottom),
              const SizedBox(width: Sp.x2),
              Expanded(
                child: Text(
                  'Hito desbloqueado: $milestone % en ${widget.goal.title}',
                  style: context.tt.bodyMedium?.copyWith(
                    color: pc.bgBottom,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _adjust(int delta) async {
    final unlocked = await ref
        .read(goalRepoProvider)
        .adjustProgress(widget.goal.id, delta);
    if (unlocked != null) {
      _showMilestoneSnackBar(unlocked);
    }
  }

  Future<void> _toggleStep(GoalStep step) async {
    final unlocked = await ref.read(goalRepoProvider).toggleStep(step);
    if (unlocked != null) {
      _showMilestoneSnackBar(unlocked);
    }
  }

  Future<void> _submitInlineStep() async {
    final text = _stepCtrl.text.trim();
    if (text.isEmpty) return;
    await ref.read(goalRepoProvider).addStep(widget.goal.id, text);
    _stepCtrl.clear();
    if (mounted) {
      setState(() => _addingStep = false);
    }
  }

  Future<void> _confirmDelete() async {
    final pc = context.pc;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pc.glassFillStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rad.lg),
        ),
        title: Text('¿Eliminar meta?', style: ctx.tt.titleLarge),
        content: Text(
          'Se archivará "${widget.goal.title}" de tu lista activa.',
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
      await ref.read(goalRepoProvider).softDelete(widget.goal.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final goal = widget.goal;
    final isWork = goal.context == 'work';
    final safeTarget = goal.targetValue < 1 ? 1 : goal.targetValue;
    final progress = (goal.currentValue / safeTarget).clamp(0.0, 1.0);
    final pct = (progress * 100).round();
    final isCompleted = goal.currentValue >= safeTarget;
    final stepsAsync = ref.watch(goalStepsProvider(goal.id));
    final steps = stepsAsync.asData?.value ?? const <GoalStep>[];

    return GlassCard(
      padding: const EdgeInsets.all(Sp.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: context.tt.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Sp.x2),
                    ContextBadge(contextType: goal.context),
                  ],
                ),
              ),
              const SizedBox(width: Sp.x2),
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: 'Eliminar meta',
                  onPressed: _confirmDelete,
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 18,
                    color: pc.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.x4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${goal.currentValue}',
                        style: context.tt.titleLarge?.copyWith(
                          fontSize: 22,
                          fontFeatures: kTabular,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${goal.targetValue} ${goal.unitLabel}',
                        style: context.tt.bodyMedium?.copyWith(
                          color: pc.inkMuted,
                          fontWeight: FontWeight.w500,
                          fontFeatures: kTabular,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: context.tt.titleLarge?.copyWith(
                  fontSize: 20,
                  fontFeatures: kTabular,
                  color: pc.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.x4),
          _MilestoneProgressLine(
            progress: progress,
            pct: pct,
            isWork: isWork,
          ),
          const SizedBox(height: Sp.x5),
          Row(
            children: [
              Semantics(
                button: true,
                label: 'Restar 1 ${goal.unitLabel}',
                child: Tooltip(
                  message: 'Deshacer (-1)',
                  child: InkWell(
                    onTap: goal.currentValue > 0 ? () => _adjust(-1) : null,
                    borderRadius: BorderRadius.circular(Rad.pill),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: pc.glassFillStrong,
                        shape: BoxShape.circle,
                        border: Border.all(color: pc.divider),
                      ),
                      child: Icon(
                        LucideIcons.minus,
                        size: 18,
                        color: goal.currentValue > 0
                            ? pc.ink
                            : pc.inkMuted.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Sp.x3),
              Expanded(
                child: PrimaryNeonButton(
                  label: isCompleted
                      ? 'Meta completada'
                      : '+1 ${goal.unitLabel}',
                  icon: isCompleted ? LucideIcons.check : LucideIcons.plus,
                  onPressed: isCompleted ? null : () => _adjust(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.x3),
          Divider(height: 1, color: pc.divider),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(Rad.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.listChecks,
                    size: 17,
                    color: pc.inkMuted,
                  ),
                  const SizedBox(width: Sp.x2),
                  Expanded(
                    child: Text(
                      steps.isEmpty
                          ? 'Pasos opcionales'
                          : 'Pasos (${steps.where((s) => s.completed).length}/${steps.length})',
                      style: context.tt.bodySmall?.copyWith(
                        color: pc.ink,
                        fontWeight: FontWeight.w600,
                        fontFeatures: kTabular,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 18,
                    color: pc.inkMuted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: Sp.x2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final step in steps)
                    _GoalStepTile(
                      step: step,
                      isWork: isWork,
                      onTap: () => _toggleStep(step),
                    ),
                  if (_addingStep)
                    Padding(
                      padding: const EdgeInsets.only(top: Sp.x2),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _stepCtrl,
                              autofocus: true,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _submitInlineStep(),
                              style: context.tt.bodyMedium,
                              decoration: InputDecoration(
                                hintText: 'Nombre del paso o clase',
                                hintStyle: context.tt.bodySmall?.copyWith(
                                  color: pc.inkMuted,
                                ),
                                filled: true,
                                fillColor: pc.glassFillStrong,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: Sp.x3,
                                  vertical: Sp.x3,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(Rad.sm),
                                  borderSide: BorderSide(color: pc.divider),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(Rad.sm),
                                  borderSide: BorderSide(color: pc.divider),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(Rad.sm),
                                  borderSide: BorderSide(color: pc.ink),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: Sp.x2),
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: IconButton(
                              tooltip: 'Guardar paso',
                              onPressed: _submitInlineStep,
                              style: IconButton.styleFrom(
                                backgroundColor: pc.neon,
                                foregroundColor: pc.onNeon,
                              ),
                              icon: const Icon(LucideIcons.check, size: 18),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _addingStep = true),
                        style: TextButton.styleFrom(
                          foregroundColor: pc.ink,
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(horizontal: Sp.x2),
                        ),
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: Text(
                          'Añadir paso',
                          style: context.tt.bodySmall?.copyWith(
                            color: pc.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalStepTile extends StatelessWidget {
  const _GoalStepTile({
    required this.step,
    required this.isWork,
    required this.onTap,
  });

  final GoalStep step;
  final bool isWork;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final fillColor = isWork ? pc.onWorkSoft : pc.neon;
    final checkColor = isWork ? pc.bgBottom : pc.onNeon;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Rad.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Sp.x2),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: step.completed ? fillColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: step.completed ? fillColor : pc.divider,
                    width: 1.6,
                  ),
                ),
                child: step.completed
                    ? Icon(LucideIcons.check, size: 14, color: checkColor)
                    : null,
              ),
              const SizedBox(width: Sp.x3),
              Expanded(
                child: Text(
                  step.title,
                  style: context.tt.bodyMedium?.copyWith(
                    color: step.completed ? pc.inkMuted : pc.ink,
                    decoration:
                        step.completed ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Línea horizontal de progreso con nodos de hitos 0%, 25%, 50%, 75% y 100%.
class _MilestoneProgressLine extends StatelessWidget {
  const _MilestoneProgressLine({
    required this.progress,
    required this.pct,
    required this.isWork,
  });

  final double progress;
  final int pct;
  final bool isWork;

  static const List<int> _milestones = [0, 25, 50, 75, 100];

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final activeColor = isWork ? pc.onWorkSoft : pc.neon;
    final clamped = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          height: 22,
          child: LayoutBuilder(
            builder: (_, constraints) {
              final width = constraints.maxWidth;
              const nodeSize = 14.0;
              final trackWidth = (width - nodeSize).clamp(0.0, double.infinity);

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: nodeSize / 2,
                    right: nodeSize / 2,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: pc.trackBg,
                        borderRadius: BorderRadius.circular(Rad.pill),
                      ),
                    ),
                  ),
                  Positioned(
                    left: nodeSize / 2,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: clamped),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, _) => Container(
                        width: trackWidth * val,
                        height: 5,
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: BorderRadius.circular(Rad.pill),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final m in _milestones)
                        _MilestoneNode(
                          reached: pct >= m,
                          activeColor: activeColor,
                          isWork: isWork,
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: Sp.x1),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final m in _milestones)
              Text(
                '$m%',
                style: context.tt.labelMedium?.copyWith(
                  fontSize: 11,
                  fontFamily: 'Outfit',
                  fontFeatures: kTabular,
                  fontWeight: pct >= m ? FontWeight.w700 : FontWeight.w500,
                  color: pct >= m ? pc.ink : pc.inkMuted,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MilestoneNode extends StatelessWidget {
  const _MilestoneNode({
    required this.reached,
    required this.activeColor,
    required this.isWork,
  });

  final bool reached;
  final Color activeColor;
  final bool isWork;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: reached ? activeColor : pc.glassFillStrong,
        shape: BoxShape.circle,
        border: Border.all(
          color: reached
              ? (isWork ? pc.onWorkSoft : pc.ink.withValues(alpha: 0.25))
              : pc.divider,
          width: reached ? 1.5 : 1.5,
        ),
      ),
    );
  }
}
