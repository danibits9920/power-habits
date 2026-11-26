// Pantalla de Ajustes (Soft Glass Minimal · UI/UX Pro Max):
// Apariencia, recordatorios locales, respaldo JSON y auto-actualizaciones desde GitHub.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/notifier.dart';
import '../../core/providers.dart';
import '../../core/updater.dart';
import '../../data/backup.dart';
import '../../design/glass.dart';
import '../../design/tokens.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pc = context.pc;
    final tt = context.tt;
    final themeMode = ref.watch(themeModeProvider);

    return SoftGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Sp.x5, Sp.x4, Sp.x5, Sp.x8),
            children: [
              Row(
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    GlassIconButton(
                      icon: LucideIcons.arrowLeft,
                      tooltip: 'Volver',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: Sp.x3),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ajustes', style: tt.headlineMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Preferencias, respaldos y actualizaciones',
                          style: tt.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.x6),

              // 1. Apariencia
              _SectionTitle(
                icon: LucideIcons.sunMedium,
                label: 'Apariencia',
              ),
              const SizedBox(height: Sp.x2),
              GlassCard(
                padding: const EdgeInsets.all(Sp.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Tema de la interfaz', style: tt.titleMedium),
                    const SizedBox(height: Sp.x1),
                    Text(
                      'Elige entre vidrio diurno claro, modo oscuro o el ajuste del sistema.',
                      style: tt.bodySmall,
                    ),
                    const SizedBox(height: Sp.x3),
                    GlassSegmented<ThemeMode>(
                      value: themeMode,
                      items: const [
                        (ThemeMode.light, 'Claro'),
                        (ThemeMode.dark, 'Oscuro'),
                        (ThemeMode.system, 'Sistema'),
                      ],
                      onChanged: (next) =>
                          ref.read(themeModeProvider.notifier).setMode(next),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.x5),

              // 2. Recordatorios locales
              _SectionTitle(
                icon: LucideIcons.bell,
                label: 'Recordatorios locales',
              ),
              const SizedBox(height: Sp.x2),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.x4,
                  vertical: Sp.x2,
                ),
                child: Column(
                  children: [
                    _SettingsActionRow(
                      icon: LucideIcons.bellRing,
                      title: 'Permitir notificaciones',
                      subtitle: 'Solicita permiso de avisos y alarmas exactas',
                      onTap: () async {
                        final ok = await PhoneNotifier.instance
                            .requestPermissions();
                        if (!context.mounted) return;
                        _showNotice(
                          context,
                          ok
                              ? 'Permisos de recordatorios activados.'
                              : 'Revisa los permisos de notificaciones en ajustes del teléfono.',
                        );
                      },
                    ),
                    Divider(height: 1, color: pc.divider),
                    _SettingsActionRow(
                      icon: LucideIcons.refreshCw,
                      title: 'Reprogramar recordatorios',
                      subtitle:
                          'Sincroniza los avisos de todas tus rutinas activas',
                      onTap: () async {
                        final routines = await ref
                            .read(routineRepoProvider)
                            .getActive();
                        final count = await PhoneNotifier.instance
                            .rescheduleAll(routines);
                        if (!context.mounted) return;
                        _showNotice(
                          context,
                          count > 0
                              ? 'Se reprogramaron $count recordatorios activos.'
                              : 'No hay rutinas con recordatorios configurados.',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.x5),

              // 3. Respaldo local JSON
              _SectionTitle(
                icon: LucideIcons.hardDrive,
                label: 'Respaldo local JSON',
              ),
              const SizedBox(height: Sp.x2),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.x4,
                  vertical: Sp.x2,
                ),
                child: Column(
                  children: [
                    _SettingsActionRow(
                      icon: LucideIcons.upload,
                      title: 'Exportar respaldo',
                      subtitle:
                          'Guarda rutinas, historial, metas y logros en JSON',
                      onTap: () async {
                        try {
                          await shareBackupFile(ref.read(dbProvider));
                        } catch (_) {
                          if (!context.mounted) return;
                          _showNotice(
                            context,
                            'No se pudo exportar el respaldo local.',
                          );
                        }
                      },
                    ),
                    Divider(height: 1, color: pc.divider),
                    _SettingsActionRow(
                      icon: LucideIcons.download,
                      title: 'Importar respaldo',
                      subtitle:
                          'Restaura o combina datos desde un archivo .json',
                      onTap: () async {
                        try {
                          final db = ref.read(dbProvider);
                          final res = await pickAndImportBackup(db);
                          if (res == null || !context.mounted) return;
                          final routines = await ref
                              .read(routineRepoProvider)
                              .getActive();
                          await PhoneNotifier.instance.rescheduleAll(routines);
                          if (!context.mounted) return;
                          _showNotice(
                            context,
                            'Respaldo importado (${res.totalRecords} registros actualizados).',
                          );
                        } on FormatException catch (e) {
                          if (!context.mounted) return;
                          _showNotice(context, e.message);
                        } catch (_) {
                          if (!context.mounted) return;
                          _showNotice(
                            context,
                            'No se pudo leer el archivo seleccionado.',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.x5),

              // 4. Actualizaciones
              _SectionTitle(
                icon: LucideIcons.packageCheck,
                label: 'Actualizaciones',
              ),
              const SizedBox(height: Sp.x2),
              GlassCard(
                padding: const EdgeInsets.all(Sp.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Versión actual', style: tt.titleMedium),
                              const SizedBox(height: 2),
                              Text(
                                'Power Habits para Android',
                                style: tt.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Sp.x3,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: pc.pinkSoft,
                            borderRadius: BorderRadius.circular(Rad.pill),
                          ),
                          child: Text(
                            'v$kAppVersion',
                            style: tt.labelMedium?.copyWith(
                              color: pc.onPinkSoft,
                              fontWeight: FontWeight.w700,
                              fontFeatures: kTabular,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.x4),
                    _CheckUpdateButton(
                      onMessage: (msg) => _showNotice(context, msg),
                    ),
                    const SizedBox(height: Sp.x2),
                    Divider(height: 1, color: pc.divider),
                    _SettingsActionRow(
                      icon: LucideIcons.sparkles,
                      title: 'Qué hay de nuevo',
                      subtitle: 'Resumen de novedades de la versión $kAppVersion',
                      onTap: () => showWhatsNewSheet(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotice(BuildContext context, String message) {
    final pc = context.pc;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: pc.ink,
          content: Text(
            message,
            style: context.tt.bodyMedium?.copyWith(color: pc.bgBottom),
          ),
        ),
      );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    return Row(
      children: [
        Icon(icon, size: 15, color: pc.inkMuted),
        const SizedBox(width: Sp.x2),
        Text(
          label.toUpperCase(),
          style: context.tt.labelMedium?.copyWith(
            letterSpacing: 0.7,
            color: pc.inkMuted,
          ),
        ),
      ],
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Rad.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Sp.x3),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: pc.workSoft,
                  borderRadius: BorderRadius.circular(Rad.md),
                ),
                child: Icon(icon, size: 18, color: pc.onWorkSoft),
              ),
              const SizedBox(width: Sp.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tt.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: tt.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Sp.x2),
              Icon(LucideIcons.chevronRight, size: 18, color: pc.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckUpdateButton extends StatefulWidget {
  const _CheckUpdateButton({required this.onMessage});

  final ValueChanged<String> onMessage;

  @override
  State<_CheckUpdateButton> createState() => _CheckUpdateButtonState();
}

class _CheckUpdateButtonState extends State<_CheckUpdateButton> {
  bool _checking = false;

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final release = await fetchLatestRelease(throwOnError: true);
      if (!mounted) return;
      if (release != null) {
        await showUpdateSheet(context, release);
      } else {
        widget.onMessage('Ya tienes la última versión (v$kAppVersion).');
      }
    } catch (_) {
      if (!mounted) return;
      widget.onMessage(
        'No se pudo comprobar actualizaciones. Revisa tu conexión.',
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryNeonButton(
      label: _checking
          ? 'Buscando actualizaciones...'
          : 'Buscar actualizaciones ahora',
      icon: LucideIcons.refreshCw,
      onPressed: _checking ? null : _check,
    );
  }
}
