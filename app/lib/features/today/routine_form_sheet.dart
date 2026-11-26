// Hoja modal Soft Glass Minimal para crear y editar rutinas o tareas puntuales.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/frequency.dart';
import '../../core/providers.dart';
import '../../data/db.dart';
import '../../design/glass.dart';
import '../../design/tokens.dart';

/// Abre el formulario inferior Soft Glass para crear o editar una rutina/tarea.
Future<Routine?> showRoutineFormSheet(
  BuildContext context, {
  Routine? existing,
  String defaultItemType = 'routine',
  DateTime? initialDate,
  Future<void> Function(Routine)? onSaved,
  Future<void> Function(String)? onDeleted,
}) {
  final isEditing = existing != null;
  final effectiveType = existing?.itemType ?? defaultItemType;
  final title = isEditing
      ? (effectiveType == 'task' ? 'Editar tarea' : 'Editar rutina')
      : (effectiveType == 'task' ? 'Nueva tarea' : 'Nueva rutina');

  return showPowerSheet<Routine?>(
    context: context,
    title: title,
    builder: (_) => _RoutineFormBody(
      existing: existing,
      defaultItemType: defaultItemType,
      initialDate: initialDate,
      onSaved: onSaved,
      onDeleted: onDeleted,
    ),
  );
}

class _RoutineFormBody extends ConsumerStatefulWidget {
  const _RoutineFormBody({
    this.existing,
    required this.defaultItemType,
    this.initialDate,
    this.onSaved,
    this.onDeleted,
  });

  final Routine? existing;
  final String defaultItemType;
  final DateTime? initialDate;
  final Future<void> Function(Routine)? onSaved;
  final Future<void> Function(String)? onDeleted;

  @override
  ConsumerState<_RoutineFormBody> createState() => _RoutineFormBodyState();
}

class _RoutineFormBodyState extends ConsumerState<_RoutineFormBody> {
  late final TextEditingController _titleCtrl;
  late String _itemType;
  late String _contextType;
  late String _frequencyType;
  late Set<int> _selectedWeekdays;
  late String _timeSlot;
  late DateTime _anchorDate;
  late List<String> _reminders;
  late bool _allowQuickNote;

  String? _titleError;
  String? _weekdaysError;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _itemType = e?.itemType ?? widget.defaultItemType;
    _contextType = e?.context ?? 'personal';
    _frequencyType = e != null
        ? e.frequencyType
        : (_itemType == 'task' ? 'once' : 'daily');
    final parsedMask = e != null
        ? parseWeekdaysMask(e.weekdaysMask)
        : <int>{1, 3, 5};
    _selectedWeekdays = parsedMask.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : parsedMask;
    _timeSlot = e?.timeSlot ?? 'morning';
    _anchorDate = e != null
        ? parseDayStr(e.anchorDate)
        : dateOnly(widget.initialDate ?? DateTime.now());
    _reminders = e != null ? parseReminderTimes(e.reminderTimes) : <String>[];
    _allowQuickNote = e?.allowQuickNote ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _onTypeChanged(String nextType) {
    setState(() {
      _itemType = nextType;
      if (nextType == 'task') {
        _frequencyType = 'once';
        _weekdaysError = null;
      } else if (_frequencyType == 'once') {
        _frequencyType = 'daily';
      }
    });
  }

  void _toggleWeekday(int isoDay) {
    setState(() {
      if (_selectedWeekdays.contains(isoDay)) {
        _selectedWeekdays.remove(isoDay);
      } else {
        _selectedWeekdays.add(isoDay);
      }
      if (_selectedWeekdays.isNotEmpty) {
        _weekdaysError = null;
      }
    });
  }

  Future<void> _pickAnchorDate() async {
    final now = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null && mounted) {
      setState(() => _anchorDate = dateOnly(picked));
    }
  }

  Future<void> _addReminder() async {
    final defaultHour = switch (_timeSlot) {
      'morning' => 7,
      'afternoon' => 15,
      'night' => 21,
      _ => 9,
    };
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: defaultHour, minute: 0),
    );
    if (picked == null || !mounted) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (_reminders.contains(formatted)) return;
    setState(() {
      _reminders = [..._reminders, formatted]..sort();
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    final trimmed = _titleCtrl.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _titleError = 'Escribe un nombre para continuar');
      return;
    }
    if (_itemType == 'routine' &&
        _frequencyType == 'weekdays' &&
        _selectedWeekdays.isEmpty) {
      setState(() => _weekdaysError = 'Selecciona al menos un día');
      return;
    }

    setState(() {
      _titleError = null;
      _weekdaysError = null;
      _saving = true;
    });

    try {
      final repo = ref.read(routineRepoProvider);
      final effectiveFreq = _itemType == 'task' ? 'once' : _frequencyType;
      final sortedDays = _selectedWeekdays.toList()..sort();
      final mask = effectiveFreq == 'weekdays'
          ? sortedDays.join(',')
          : '1,2,3,4,5,6,7';
      final sortedReminders = [..._reminders]..sort();

      final String savedId;
      if (_isEditing) {
        savedId = widget.existing!.id;
        await repo.updateRoutine(
          id: savedId,
          title: trimmed,
          context: _contextType,
          timeSlot: _timeSlot,
          frequencyType: effectiveFreq,
          weekdaysMask: mask,
          reminderTimes: sortedReminders,
          allowQuickNote: _allowQuickNote,
        );
      } else {
        savedId = await repo.create(
          title: trimmed,
          itemType: _itemType,
          context: _contextType,
          timeSlot: _timeSlot,
          frequencyType: effectiveFreq,
          weekdaysMask: mask,
          anchorDate: dayStr(_anchorDate),
          reminderTimes: sortedReminders,
          allowQuickNote: _allowQuickNote,
        );
      }

      final active = await repo.getActive();
      Routine? savedRoutine;
      for (final item in active) {
        if (item.id == savedId) {
          savedRoutine = item;
          break;
        }
      }

      if (savedRoutine != null && widget.onSaved != null) {
        await widget.onSaved!(savedRoutine);
      }
      if (mounted) {
        Navigator.of(context).pop(savedRoutine);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existing;
    if (existing == null || _saving) return;
    final isTask = existing.itemType == 'task';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final pc = ctx.pc;
        return AlertDialog(
          backgroundColor: pc.glassFillStrong,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Rad.lg),
          ),
          title: Text(
            isTask ? 'Eliminar tarea' : 'Eliminar rutina',
            style: ctx.tt.titleLarge,
          ),
          content: Text(
            'Se ocultará "${existing.title}" de tus próximos días. Tu historial previo se conservará.',
            style: ctx.tt.bodyMedium,
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
        );
      },
    );

    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(routineRepoProvider).softDelete(existing.id);
      if (widget.onDeleted != null) {
        await widget.onDeleted!(existing.id);
      }
      if (mounted) {
        Navigator.of(context).pop(null);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final tt = context.tt;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Sp.x5, Sp.x2, Sp.x5, Sp.x6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isEditing) ...[
            GlassSegmented<String>(
              value: _itemType,
              items: const [
                ('routine', 'Rutina'),
                ('task', 'Tarea puntual'),
              ],
              onChanged: _onTypeChanged,
            ),
            const SizedBox(height: Sp.x5),
          ],

          // Nombre
          Text('Nombre', style: tt.labelMedium),
          const SizedBox(height: Sp.x2),
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
            style: tt.bodyLarge,
            decoration: InputDecoration(
              hintText: _itemType == 'task'
                  ? 'Ej. Enviar reporte semanal'
                  : 'Ej. Skincare mañana',
              hintStyle: tt.bodyMedium?.copyWith(color: pc.inkMuted),
              errorText: _titleError,
              filled: true,
              fillColor: pc.glassFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Sp.x4,
                vertical: Sp.x4,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Rad.md),
                borderSide: BorderSide(color: pc.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Rad.md),
                borderSide: BorderSide(color: pc.ink, width: 1.4),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Rad.md),
                borderSide: BorderSide(color: pc.danger),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Rad.md),
                borderSide: BorderSide(color: pc.danger, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: Sp.x5),

          // Contexto
          Text('Contexto', style: tt.labelMedium),
          const SizedBox(height: Sp.x2),
          Row(
            children: [
              Expanded(
                child: _ContextOptionTile(
                  label: 'Personal',
                  icon: LucideIcons.user,
                  selected: _contextType == 'personal',
                  selectedFill: pc.pinkSoft,
                  selectedBorder: pc.pink,
                  selectedInk: pc.onPinkSoft,
                  onTap: () => setState(() => _contextType = 'personal'),
                ),
              ),
              const SizedBox(width: Sp.x3),
              Expanded(
                child: _ContextOptionTile(
                  label: 'Laboral',
                  icon: LucideIcons.briefcase,
                  selected: _contextType == 'work',
                  selectedFill: pc.workSoft,
                  selectedBorder: pc.onWorkSoft.withValues(alpha: 0.45),
                  selectedInk: pc.onWorkSoft,
                  onTap: () => setState(() => _contextType = 'work'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.x5),

          // Frecuencia (rutinas) o Fecha puntual (tareas)
          if (_itemType == 'routine') ...[
            Text('Frecuencia', style: tt.labelMedium),
            const SizedBox(height: Sp.x2),
            Row(
              children: [
                for (final (code, label) in const [
                  ('daily', 'Diaria'),
                  ('alternate', 'Interdiaria'),
                  ('weekdays', 'Días fijos'),
                ]) ...[
                  Expanded(
                    child: _SelectablePill(
                      label: label,
                      selected: _frequencyType == code,
                      useNeon: true,
                      onTap: () => setState(() {
                        _frequencyType = code;
                        _weekdaysError = null;
                      }),
                    ),
                  ),
                  if (code != 'weekdays') const SizedBox(width: Sp.x2),
                ],
              ],
            ),
            if (_frequencyType == 'weekdays') ...[
              const SizedBox(height: Sp.x3),
              Row(
                children: [
                  for (var day = 1; day <= 7; day++) ...[
                    Expanded(
                      child: _WeekdayChip(
                        label: kInitialWeekdays[day - 1],
                        tooltip: kShortWeekdays[day - 1],
                        selected: _selectedWeekdays.contains(day),
                        onTap: () => _toggleWeekday(day),
                      ),
                    ),
                    if (day < 7) const SizedBox(width: 6),
                  ],
                ],
              ),
              if (_weekdaysError != null) ...[
                const SizedBox(height: Sp.x2),
                Text(
                  _weekdaysError!,
                  style: tt.bodySmall?.copyWith(color: pc.danger),
                ),
              ],
            ],
            if (_frequencyType == 'alternate') ...[
              const SizedBox(height: Sp.x3),
              _DateInfoPill(
                icon: LucideIcons.repeat,
                label: 'Cada 2 días desde ${shortDateEs(_anchorDate)}',
                editable: !_isEditing,
                onTap: _isEditing ? null : _pickAnchorDate,
              ),
            ],
            const SizedBox(height: Sp.x5),
          ] else ...[
            Text('Fecha de la tarea', style: tt.labelMedium),
            const SizedBox(height: Sp.x2),
            _DateInfoPill(
              icon: LucideIcons.calendar,
              label: shortDateEs(_anchorDate),
              editable: !_isEditing,
              onTap: _isEditing ? null : _pickAnchorDate,
            ),
            const SizedBox(height: Sp.x5),
          ],

          // Bloque del día
          Text('Bloque del día', style: tt.labelMedium),
          const SizedBox(height: Sp.x2),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TimeSlotButton(
                      label: 'Mañana',
                      icon: LucideIcons.sunrise,
                      selected: _timeSlot == 'morning',
                      onTap: () => setState(() => _timeSlot = 'morning'),
                    ),
                  ),
                  const SizedBox(width: Sp.x2),
                  Expanded(
                    child: _TimeSlotButton(
                      label: 'Tarde',
                      icon: LucideIcons.sun,
                      selected: _timeSlot == 'afternoon',
                      onTap: () => setState(() => _timeSlot = 'afternoon'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.x2),
              Row(
                children: [
                  Expanded(
                    child: _TimeSlotButton(
                      label: 'Noche',
                      icon: LucideIcons.moon,
                      selected: _timeSlot == 'night',
                      onTap: () => setState(() => _timeSlot = 'night'),
                    ),
                  ),
                  const SizedBox(width: Sp.x2),
                  Expanded(
                    child: _TimeSlotButton(
                      label: 'Cualquier hora',
                      icon: LucideIcons.clock,
                      selected: _timeSlot == 'anytime',
                      onTap: () => setState(() => _timeSlot = 'anytime'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Sp.x5),

          // Recordatorios múltiples
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recordatorios', style: tt.labelMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Agrega una o varias horas si deseas aviso local',
                      style: tt.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.x2),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final time in _reminders)
                Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.only(left: Sp.x3, right: 2),
                  decoration: BoxDecoration(
                    color: pc.glassFill,
                    borderRadius: BorderRadius.circular(Rad.pill),
                    border: Border.all(color: pc.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.bell, size: 14, color: pc.inkMuted),
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: tt.bodyMedium?.copyWith(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontFeatures: kTabular,
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          tooltip: 'Quitar $time',
                          onPressed: () => setState(
                            () => _reminders =
                                _reminders.where((t) => t != time).toList(),
                          ),
                          icon: Icon(
                            LucideIcons.x,
                            size: 15,
                            color: pc.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              InkWell(
                onTap: _addReminder,
                borderRadius: BorderRadius.circular(Rad.pill),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: Sp.x4),
                  decoration: BoxDecoration(
                    color: pc.glassFill,
                    borderRadius: BorderRadius.circular(Rad.pill),
                    border: Border.all(color: pc.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.plus, size: 16, color: pc.ink),
                      const SizedBox(width: 6),
                      Text(
                        'Hora',
                        style: tt.labelMedium?.copyWith(
                          color: pc.ink,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.x5),

          // Nota rápida al completar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.x4,
              vertical: Sp.x2,
            ),
            decoration: BoxDecoration(
              color: pc.glassFill,
              borderRadius: BorderRadius.circular(Rad.md),
              border: Border.all(color: pc.divider),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.fileText, size: 18, color: pc.inkMuted),
                const SizedBox(width: Sp.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nota rápida al completar', style: tt.bodyLarge),
                      Text(
                        'Habilita el acceso rápido para notas diarias',
                        style: tt.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _allowQuickNote,
                  onChanged: (v) => setState(() => _allowQuickNote = v),
                  activeThumbColor: pc.onNeon,
                  activeTrackColor: pc.neon,
                ),
              ],
            ),
          ),
          const SizedBox(height: Sp.x6),

          // Guardar
          PrimaryNeonButton(
            label: _saving
                ? 'Guardando...'
                : (_isEditing ? 'Guardar cambios' : 'Guardar'),
            icon: LucideIcons.check,
            onPressed: _saving ? null : _submit,
          ),

          if (_isEditing) ...[
            const SizedBox(height: Sp.x2),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: TextButton.icon(
                onPressed: _saving ? null : _confirmDelete,
                style: TextButton.styleFrom(
                  foregroundColor: pc.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Rad.pill),
                  ),
                ),
                icon: const Icon(LucideIcons.trash2, size: 17),
                label: Text(
                  _itemType == 'task' ? 'Eliminar tarea' : 'Eliminar rutina',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContextOptionTile extends StatelessWidget {
  const _ContextOptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedFill,
    required this.selectedBorder,
    required this.selectedInk,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedFill;
  final Color selectedBorder;
  final Color selectedInk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Rad.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
        decoration: BoxDecoration(
          color: selected ? selectedFill : pc.glassFill,
          borderRadius: BorderRadius.circular(Rad.md),
          border: Border.all(
            color: selected ? selectedBorder : pc.divider,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? selectedInk : pc.inkMuted),
            const SizedBox(width: Sp.x2),
            Text(
              label,
              style: context.tt.bodyMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? selectedInk : pc.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectablePill extends StatelessWidget {
  const _SelectablePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.useNeon = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool useNeon;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final fill = selected
        ? (useNeon ? pc.neon : pc.ink)
        : pc.glassFill;
    final ink = selected
        ? (useNeon ? pc.onNeon : pc.bgBottom)
        : pc.inkMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Rad.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: Sp.x2),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(Rad.pill),
          border: Border.all(
            color: selected ? Colors.transparent : pc.divider,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.tt.labelMedium?.copyWith(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: ink,
          ),
        ),
      ),
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return Semantics(
      button: true,
      selected: selected,
      label: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Rad.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? pc.neon : pc.glassFill,
            borderRadius: BorderRadius.circular(Rad.md),
            border: Border.all(
              color: selected ? Colors.transparent : pc.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? pc.onNeon : pc.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeSlotButton extends StatelessWidget {
  const _TimeSlotButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Rad.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
        decoration: BoxDecoration(
          color: selected ? pc.glassFillStrong : pc.glassFill,
          borderRadius: BorderRadius.circular(Rad.md),
          border: Border.all(
            color: selected ? pc.ink : pc.divider,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: selected ? pc.ink : pc.inkMuted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.tt.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? pc.ink : pc.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateInfoPill extends StatelessWidget {
  const _DateInfoPill({
    required this.icon,
    required this.label,
    required this.editable,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool editable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Rad.md),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
        decoration: BoxDecoration(
          color: pc.glassFill,
          borderRadius: BorderRadius.circular(Rad.md),
          border: Border.all(color: pc.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: pc.inkMuted),
            const SizedBox(width: Sp.x3),
            Expanded(
              child: Text(label, style: context.tt.bodyMedium),
            ),
            if (editable)
              Text(
                'Cambiar',
                style: context.tt.labelMedium?.copyWith(color: pc.ink),
              ),
          ],
        ),
      ),
    );
  }
}
