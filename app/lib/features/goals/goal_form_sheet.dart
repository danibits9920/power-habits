// Hoja modal para crear una meta basada en unidades y pasos nombrados opcionales.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../design/glass.dart';
import '../../design/tokens.dart';

/// Abre la hoja modal para crear una nueva meta por unidades.
Future<String?> showGoalFormSheet(BuildContext context) {
  return showPowerSheet<String>(
    context: context,
    title: 'Nueva meta',
    builder: (_) => const _GoalFormSheetBody(),
  );
}

class _GoalFormSheetBody extends ConsumerStatefulWidget {
  const _GoalFormSheetBody();

  @override
  ConsumerState<_GoalFormSheetBody> createState() => _GoalFormSheetBodyState();
}

class _GoalFormSheetBodyState extends ConsumerState<_GoalFormSheetBody> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'clases');
  final _targetCtrl = TextEditingController(text: '10');
  final _stepsCtrl = TextEditingController();

  String _contextType = 'personal';
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _unitCtrl.dispose();
    _targetCtrl.dispose();
    _stepsCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    String? helper,
  }) {
    final pc = context.pc;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Rad.md),
      borderSide: BorderSide(color: pc.divider),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 2,
      filled: true,
      fillColor: pc.glassFill,
      labelStyle: context.tt.bodySmall?.copyWith(color: pc.inkMuted),
      hintStyle: context.tt.bodyMedium?.copyWith(
        color: pc.inkMuted.withValues(alpha: 0.72),
      ),
      helperStyle: context.tt.bodySmall?.copyWith(color: pc.inkMuted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Sp.x4,
        vertical: Sp.x3,
      ),
      border: border,
      enabledBorder: border,
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
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final rawSteps = _stepsCtrl.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      final parsedTarget = int.tryParse(_targetCtrl.text.trim()) ?? 10;
      final target = parsedTarget < 1 ? 1 : parsedTarget;

      final id = await ref.read(goalRepoProvider).create(
            title: _titleCtrl.text.trim(),
            context: _contextType,
            unitLabel: _unitCtrl.text.trim().isEmpty
                ? 'pasos'
                : _unitCtrl.text.trim(),
            targetValue: target,
            stepTitles: rawSteps,
          );
      if (mounted) {
        Navigator.of(context).pop(id);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Sp.x5, Sp.x2, Sp.x5, Sp.x6),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              style: context.tt.bodyLarge,
              decoration: _fieldDecoration(
                context,
                label: 'Título de la meta',
                hint: 'Ej. Curso de desarrollo',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Escribe un título para tu meta';
                }
                return null;
              },
            ),
            const SizedBox(height: Sp.x4),
            Text(
              'Contexto',
              style: context.tt.labelMedium?.copyWith(color: pc.inkMuted),
            ),
            const SizedBox(height: Sp.x2),
            GlassSegmented<String>(
              value: _contextType,
              items: const [
                ('personal', 'Personal'),
                ('work', 'Laboral'),
              ],
              onChanged: (next) => setState(() => _contextType = next),
            ),
            const SizedBox(height: Sp.x4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _unitCtrl,
                    textInputAction: TextInputAction.next,
                    style: context.tt.bodyLarge,
                    decoration: _fieldDecoration(
                      context,
                      label: 'Unidad',
                      hint: 'clases, salidas, módulos',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Indica la unidad';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: Sp.x3),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _targetCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: context.tt.bodyLarge?.copyWith(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontFeatures: kTabular,
                    ),
                    decoration: _fieldDecoration(
                      context,
                      label: 'Total',
                      hint: '30',
                    ),
                    validator: (val) {
                      final n = int.tryParse((val ?? '').trim());
                      if (n == null || n < 1) {
                        return 'Mín. 1';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sp.x4),
            TextFormField(
              controller: _stepsCtrl,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              style: context.tt.bodyMedium,
              decoration: _fieldDecoration(
                context,
                label: 'Pasos nombrados (opcional)',
                hint: 'Clase 1: Fundamentos\nClase 2: Estado\nClase 3: Práctica',
                helper:
                    'Un paso por línea. Podrás marcar cada paso individualmente desde la meta.',
              ),
            ),
            const SizedBox(height: Sp.x6),
            PrimaryNeonButton(
              label: _saving ? 'Guardando...' : 'Crear meta',
              icon: LucideIcons.check,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
