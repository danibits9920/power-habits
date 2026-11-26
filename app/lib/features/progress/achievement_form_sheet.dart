// Hoja modal para registrar un logro manual en la línea de tiempo.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../design/glass.dart';
import '../../design/tokens.dart';

/// Abre la hoja modal para registrar un logro manual.
Future<String?> showAchievementFormSheet(BuildContext context) {
  return showPowerSheet<String>(
    context: context,
    title: 'Nuevo logro',
    builder: (_) => const _AchievementFormSheetBody(),
  );
}

class _AchievementFormSheetBody extends ConsumerStatefulWidget {
  const _AchievementFormSheetBody();

  @override
  ConsumerState<_AchievementFormSheetBody> createState() =>
      _AchievementFormSheetBodyState();
}

class _AchievementFormSheetBodyState
    extends ConsumerState<_AchievementFormSheetBody> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();

  String _contextType = 'personal';
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required String hint,
  }) {
    final pc = context.pc;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Rad.md),
      borderSide: BorderSide(color: pc.divider),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: pc.glassFill,
      labelStyle: context.tt.bodySmall?.copyWith(color: pc.inkMuted),
      hintStyle: context.tt.bodyMedium?.copyWith(
        color: pc.inkMuted.withValues(alpha: 0.72),
      ),
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
      final rawDetail = _detailCtrl.text.trim();
      final fallbackDetail = _contextType == 'work'
          ? 'Logro laboral registrado'
          : 'Logro personal registrado';

      final id = await ref.read(achievementRepoProvider).addManual(
            title: _titleCtrl.text.trim(),
            detail: rawDetail.isEmpty ? fallbackDetail : rawDetail,
            context: _contextType,
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
                label: 'Título del logro',
                hint: 'Ej. Completé mi primera semana constante',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Escribe un título para este logro';
                }
                return null;
              },
            ),
            const SizedBox(height: Sp.x4),
            TextFormField(
              controller: _detailCtrl,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: context.tt.bodyMedium,
              decoration: _fieldDecoration(
                context,
                label: 'Detalle breve (opcional)',
                hint: 'Ej. Logré mantener el ritmo sin saltar sesiones',
              ),
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
            const SizedBox(height: Sp.x6),
            PrimaryNeonButton(
              label: _saving ? 'Guardando...' : 'Guardar logro',
              icon: LucideIcons.bookmarkCheck,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
