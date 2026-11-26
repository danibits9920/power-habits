// Actualizador automático desde GitHub Releases (main): verifica nueva versión,
// descarga el APK arm64 con progreso y lanza el instalador de Android vía FileProvider.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../design/brand_logo.dart';
import '../design/glass.dart';
import '../design/tokens.dart';

const kAppVersion = '0.3.2';
const kReleasesRepo = 'danibits9920/power-habits';
const kReleaseNotes = <String>[
  'Nueva Identidad de Marca "Calm Voltage": sistema tipográfico Kinetic Precision con Bricolage Grotesque ExtraBold en titulares, Plus Jakarta Sans en lectura diaria y JetBrains Mono en métricas y horas.',
  'Isotipo oficial "Volt-Check" fiel 1:1 en el ícono nativo de Android (Adaptive Icon + HyperOS), splash animado y variantes Porcelain Daylight (claro) / Carbon Night (oscuro).',
  'Pesos tipográficos estáticos reales (.ttf offline 400–800) para máxima nitidez y carácter visual en Android.',
];

const _updaterChannel = MethodChannel('com.daltex.power_habits/updater');

List<String> parseReleaseNotes(String raw) => raw
    .split('\n')
    .map((l) => l.trim())
    .where((l) => l.isNotEmpty)
    .map((l) => l.replaceFirst(RegExp(r'^(?:[-*•]+|\d+[.)])\s+'), '').trim())
    .where((l) => l.isNotEmpty)
    .toList();

List<int> parseSemver(String raw) {
  final clean = raw
      .trim()
      .replaceFirst(RegExp(r'^[vV]'), '')
      .split('+')
      .first
      .split('-')
      .first;
  final parts = clean.split('.');
  int part(int i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0;
  return [part(0), part(1), part(2)];
}

bool isNewerVersion(String current, String latest) {
  final a = parseSemver(current);
  final b = parseSemver(latest);
  for (var i = 0; i < 3; i++) {
    if (b[i] != a[i]) return b[i] > a[i];
  }
  return false;
}

class AppRelease {
  const AppRelease({
    required this.version,
    required this.tagName,
    required this.title,
    required this.notes,
    required this.apkUrl,
    required this.apkName,
    required this.sizeBytes,
  });

  final String version;
  final String tagName;
  final String title;
  final String notes;
  final String apkUrl;
  final String apkName;
  final int sizeBytes;

  factory AppRelease.fromGithubJson(Map<String, dynamic> json) {
    final tag = (json['tag_name'] as String? ?? '').trim();
    if (tag.isEmpty) {
      throw const FormatException('Release sin tag_name');
    }
    final version = tag.replaceFirst(RegExp(r'^[vV]'), '').split('+').first;
    final assets = (json['assets'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((a) {
          final name = (a['name'] as String? ?? '').toLowerCase();
          final url = (a['browser_download_url'] as String? ?? '').trim();
          return name.endsWith('.apk') && url.isNotEmpty;
        })
        .toList();
    if (assets.isEmpty) {
      throw const FormatException('Release sin archivo APK');
    }
    final preferred = assets.firstWhere(
      (a) => (a['name'] as String? ?? '').toLowerCase().contains('arm64'),
      orElse: () => assets.first,
    );
    return AppRelease(
      version: version,
      tagName: tag,
      title: (json['name'] as String? ?? '').trim(),
      notes: (json['body'] as String? ?? '').trim(),
      apkUrl: (preferred['browser_download_url'] as String).trim(),
      apkName: (preferred['name'] as String? ?? 'power-habits.apk').trim(),
      sizeBytes: (preferred['size'] as num?)?.toInt() ?? 0,
    );
  }
}

Future<AppRelease?> fetchLatestRelease({
  Dio? dio,
  bool throwOnError = false,
}) async {
  final client =
      dio ??
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {
            'Accept': 'application/vnd.github+json',
            'User-Agent': 'PowerHabits-Android',
          },
        ),
      );
  try {
    final res = await client.get<Map<String, dynamic>>(
      'https://api.github.com/repos/$kReleasesRepo/releases/latest',
    );
    final data = res.data;
    if (data == null) return null;
    final release = AppRelease.fromGithubJson(data);
    return isNewerVersion(kAppVersion, release.version) ? release : null;
  } catch (_) {
    if (throwOnError) rethrow;
    return null;
  }
}

Future<String> installApkFile(String path) async {
  final res = await _updaterChannel.invokeMethod<String>('installApk', {
    'path': path,
  });
  return res ?? 'LAUNCHED';
}

Future<bool> canInstallPackages() async {
  final res = await _updaterChannel.invokeMethod<bool>('canInstall');
  return res ?? true;
}

final availableUpdateProvider = FutureProvider<AppRelease?>(
  (ref) => fetchLatestRelease(),
);

bool _promptedThisSession = false;
bool _checkingStartup = false;

Future<void> maybePromptForUpdate(
  BuildContext context,
  WidgetRef ref, {
  bool waitForSplash = true,
}) async {
  if (_promptedThisSession || _checkingStartup) return;
  _checkingStartup = true;
  try {
    await Future<void>.delayed(
      Duration(milliseconds: waitForSplash ? 1600 : 250),
    );
    if (!context.mounted) return;
    _promptedThisSession = true;
    final release = await ref.read(availableUpdateProvider.future);
    if (release != null && context.mounted) {
      await showUpdateSheet(context, release);
    }
  } finally {
    _checkingStartup = false;
  }
}

Future<void> showUpdateSheet(BuildContext context, AppRelease release) =>
    showPowerSheet<void>(
      context: context,
      title: 'Nueva actualización',
      builder: (_) => _UpdateSheetBody(release: release),
    );

Future<void> showWhatsNewSheet(BuildContext context) => showPowerSheet<void>(
  context: context,
  title: 'Qué hay de nuevo',
  builder: (ctx) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(Sp.x5, 0, Sp.x5, Sp.x6),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _UpdateHeroBanner(
          title: 'Power Habits',
          subtitle: 'Resumen de esta versión',
          pillText: 'Versión $kAppVersion',
        ),
        const SizedBox(height: Sp.x4),
        const _ReleaseNotesCard(items: kReleaseNotes),
        const SizedBox(height: Sp.x5),
        PrimaryNeonButton(
          label: 'Entendido',
          icon: LucideIcons.check,
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ],
    ),
  ),
);

class _UpdateHeroBanner extends StatelessWidget {
  const _UpdateHeroBanner({
    required this.title,
    required this.subtitle,
    required this.pillText,
    this.trailingBadge,
  });

  final String title;
  final String subtitle;
  final String pillText;
  final String? trailingBadge;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final tt = context.tt;
    return GlassCard(
      strong: true,
      padding: const EdgeInsets.all(Sp.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PowerHabitsLogo(size: 48),
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
            ],
          ),
          const SizedBox(height: Sp.x3),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.x3,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: pc.neon,
                  borderRadius: BorderRadius.circular(Rad.pill),
                ),
                child: Text(
                  pillText,
                  style: tt.labelMedium?.copyWith(
                    color: pc.onNeon,
                    fontWeight: FontWeight.w700,
                    fontFeatures: kTabular,
                  ),
                ),
              ),
              if (trailingBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Sp.x3,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: pc.workSoft,
                    borderRadius: BorderRadius.circular(Rad.pill),
                  ),
                  child: Text(
                    trailingBadge!,
                    style: tt.labelMedium?.copyWith(
                      color: pc.onWorkSoft,
                      fontWeight: FontWeight.w600,
                      fontFeatures: kTabular,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReleaseNotesCard extends StatelessWidget {
  const _ReleaseNotesCard({required this.items, this.maxHeight});

  final List<String> items;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final tt = context.tt;
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: Sp.x3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: pc.neon,
                  borderRadius: BorderRadius.circular(Rad.sm),
                ),
                child: Icon(
                  LucideIcons.check,
                  size: 14,
                  color: pc.onNeon,
                ),
              ),
              const SizedBox(width: Sp.x3),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    items[i],
                    style: tt.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    return GlassCard(
      padding: const EdgeInsets.all(Sp.x4),
      child: maxHeight == null
          ? body
          : ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight!),
              child: SingleChildScrollView(child: body),
            ),
    );
  }
}

class _UpdateSheetBody extends StatefulWidget {
  const _UpdateSheetBody({required this.release});
  final AppRelease release;

  @override
  State<_UpdateSheetBody> createState() => _UpdateSheetBodyState();
}

class _UpdateSheetBodyState extends State<_UpdateSheetBody> {
  CancelToken? _cancelToken;
  late final AppLifecycleListener _life;
  bool _downloading = false;
  int _received = 0;
  int _total = 0;
  String? _downloadedPath;
  bool _needsPermission = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _total = widget.release.sizeBytes;
    _life = AppLifecycleListener(
      onResume: () async {
        final path = _downloadedPath;
        if (!_needsPermission || path == null || !mounted) return;
        try {
          if (await canInstallPackages()) {
            await _launchInstaller(path);
          }
        } catch (_) {}
      },
    );
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _life.dispose();
    super.dispose();
  }

  String _fmtMb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  Future<void> _startDownload() async {
    final token = CancelToken();
    setState(() {
      _cancelToken = token;
      _downloading = true;
      _received = 0;
      _total = widget.release.sizeBytes;
      _error = null;
      _needsPermission = false;
    });
    try {
      final dir = await getTemporaryDirectory();
      final fileName = widget.release.apkName.isEmpty
          ? 'power-habits-v${widget.release.version}.apk'
          : widget.release.apkName;
      final finalPath = p.join(dir.path, fileName);
      final partPath = '$finalPath.part';
      final partFile = File(partPath);
      if (partFile.existsSync()) partFile.deleteSync();

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      await dio.download(
        widget.release.apkUrl,
        partPath,
        cancelToken: token,
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _received = received;
            if (total > 0) _total = total;
          });
        },
      );
      final dest = File(finalPath);
      if (dest.existsSync()) dest.deleteSync();
      await partFile.rename(finalPath);
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _downloadedPath = finalPath;
      });
      await _launchInstaller(finalPath);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || !mounted) return;
      setState(() {
        _downloading = false;
        _error =
            'No se pudo descargar el APK. Revisa tu conexión e intenta de nuevo.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _error = 'Ocurrió un error al descargar o abrir el instalador.';
      });
    }
  }

  Future<void> _launchInstaller(String path) async {
    try {
      final status = await installApkFile(path);
      if (!mounted) return;
      setState(() {
        _needsPermission = status == 'NEEDS_PERMISSION';
        _error = null;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message ?? 'No se pudo iniciar la instalación.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final tt = context.tt;
    final r = widget.release;
    final progress = _total > 0 ? (_received / _total).clamp(0.0, 1.0) : null;
    final sizeLabel = r.sizeBytes > 0 ? '${_fmtMb(r.sizeBytes)} MB' : null;
    final noteLines = parseReleaseNotes(r.notes);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Sp.x5, 0, Sp.x5, Sp.x6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UpdateHeroBanner(
            title: r.title.isNotEmpty ? r.title : 'Power Habits v${r.version}',
            subtitle: _downloadedPath != null
                ? 'Paquete listo para instalar'
                : 'Actualización disponible en GitHub',
            pillText: 'v$kAppVersion → v${r.version}',
            trailingBadge: sizeLabel,
          ),
          if (noteLines.isNotEmpty) ...[
            const SizedBox(height: Sp.x4),
            Text('Cambios incluidos', style: tt.titleMedium),
            const SizedBox(height: Sp.x2),
            _ReleaseNotesCard(items: noteLines, maxHeight: 190),
          ],
          if (_downloading) ...[
            const SizedBox(height: Sp.x4),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: pc.ink,
                        ),
                      ),
                      const SizedBox(width: Sp.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Descargando paquete...', style: tt.titleMedium),
                            Text(
                              progress == null
                                  ? '${_fmtMb(_received)} MB recibidos'
                                  : '${_fmtMb(_received)} de ${_fmtMb(_total)} MB',
                              style: tt.bodySmall?.copyWith(
                                fontFeatures: kTabular,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (progress != null)
                        Text(
                          '${(progress * 100).round()} %',
                          style: tt.titleLarge?.copyWith(
                            color: pc.ink,
                            fontFeatures: kTabular,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Sp.x3),
                  if (progress != null)
                    NeonProgressBar(progress: progress, height: 8)
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Rad.pill),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        backgroundColor: pc.trackBg,
                        color: pc.neon,
                      ),
                    ),
                  const SizedBox(height: Sp.x2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _cancelToken?.cancel();
                        setState(() => _downloading = false);
                      },
                      child: Text(
                        'Cancelar',
                        style: tt.bodyMedium?.copyWith(
                          color: pc.inkMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (_needsPermission) ...[
              const SizedBox(height: Sp.x4),
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: pc.warningSoft,
                        borderRadius: BorderRadius.circular(Rad.sm),
                      ),
                      child: Icon(
                        LucideIcons.shieldAlert,
                        color: pc.warning,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: Sp.x3),
                    Expanded(
                      child: Text(
                        'Activa "Permitir desde esta fuente" en los ajustes de Android y vuelve aquí para instalar.',
                        style: tt.bodySmall?.copyWith(
                          color: pc.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_downloadedPath != null && _error == null) ...[
              const SizedBox(height: Sp.x3),
              Text(
                'APK descargado. Abriendo el instalador de Android...',
                textAlign: TextAlign.center,
                style: tt.bodySmall,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: Sp.x3),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(
                  color: pc.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: Sp.x4),
            if (_downloadedPath != null)
              PrimaryNeonButton(
                label: 'Instalar ahora',
                icon: LucideIcons.packageCheck,
                onPressed: () => _launchInstaller(_downloadedPath!),
              )
            else
              PrimaryNeonButton(
                label: _error == null
                    ? 'Descargar y actualizar'
                    : 'Reintentar descarga',
                icon: LucideIcons.download,
                onPressed: _startDownload,
              ),
            const SizedBox(height: Sp.x2),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _downloadedPath != null ? 'Cerrar' : 'Más tarde',
                style: tt.bodyMedium?.copyWith(
                  color: pc.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
