// Hoja modal de nota rápida diaria (1 línea) asociada a una rutina/tarea y fecha.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/providers.dart';
import '../../data/db.dart';
import '../../design/glass.dart';
import '../../design/tokens.dart';

/// Abre la hoja modal para crear, editar o borrar una nota rápida de 1 línea.
/// Devuelve `true` si se guardó algún cambio en la base de datos.
Future<bool> showQuickNoteSheet(
  BuildContext context, {
  required Routine routine,
  required String dateKey,
  String? existingNote,
}) async {
  final result = await showPowerSheet<bool>(
    context: context,
    title: 'Nota rápida',
    builder: (_) => _QuickNoteSheetBody(
      routine: routine,
      dateKey: dateKey,
      existingNote: existingNote,
    ),
  );
  return result ?? false;
}

class _QuickNoteSheetBody extends ConsumerStatefulWidget {
  const _QuickNoteSheetBody({
    required this.routine,
    required this.dateKey,
    this.existingNote,
  });

  final Routine routine;
  final String dateKey;
  final String? existingNote;

  @override
  ConsumerState<_QuickNoteSheetBody> createState() =>
      _QuickNoteSheetBodyState();
}

class _QuickNoteSheetBodyState extends ConsumerState<_QuickNoteSheetBody> {
  late final TextEditingController _controller;
  bool _saving = false;

  bool get _hasExisting =>
      widget.existingNote != null && widget.existingNote!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existingNote ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(String value) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(routineRepoProvider).saveNote(
            routineId: widget.routine.id,
            dateKey: widget.dateKey,
            note: value,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
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
    final formattedDate = shortDateEs(parseDayStr(widget.dateKey));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Sp.x5, Sp.x1, Sp.x5, Sp.x6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.routine.title,
                      style: tt.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(formattedDate, style: tt.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: Sp.x2),
              ContextBadge(contextType: widget.routine.context),
            ],
          ),
          const SizedBox(height: Sp.x4),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 1,
            maxLength: 140,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: _save,
            style: tt.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Ej. 30 min sin pausas, buena energía',
              hintStyle: tt.bodyMedium?.copyWith(color: pc.inkMuted),
              filled: true,
              fillColor: pc.glassFill,
              counterStyle: tt.bodySmall,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Sp.x4,
                vertical: Sp.x4,
              ),
              prefixIcon: Icon(
                LucideIcons.fileText,
                size: 18,
                color: pc.inkMuted,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Rad.md),
                borderSide: BorderSide(color: pc.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Rad.md),
                borderSide: BorderSide(color: pc.ink, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: Sp.x4),
          Row(
            children: [
              if (_hasExisting) ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 50),
                  child: TextButton.icon(
                    onPressed: _saving ? null : () => _save(''),
                    style: TextButton.styleFrom(
                      foregroundColor: pc.danger,
                      padding: const EdgeInsets.symmetric(horizontal: Sp.x4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Rad.pill),
                      ),
                    ),
                    icon: const Icon(LucideIcons.trash2, size: 17),
                    label: const Text('Borrar'),
                  ),
                ),
                const SizedBox(width: Sp.x2),
              ],
              Expanded(
                child: PrimaryNeonButton(
                  label: _saving ? 'Guardando...' : 'Guardar nota',
                  icon: LucideIcons.check,
                  onPressed: _saving ? null : () => _save(_controller.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
