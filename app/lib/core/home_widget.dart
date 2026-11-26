// Puente con el widget nativo 4x2 de la pantalla de inicio de Android (Soft Glass Minimal).
import 'package:flutter/services.dart';

const _widgetChannel = MethodChannel('com.daltex.power_habits/widget');

String? _lastSignature;

/// Sincroniza el progreso del día y hasta 3 rutinas pendientes hacia el widget Android.
/// Silencioso fuera de Android o en pruebas unitarias.
Future<void> syncPowerWidget({
  required int pct,
  required int doneCount,
  required int totalCount,
  required List<String> pendingTitles,
}) async {
  final safePct = pct.clamp(0, 100);
  final topPending = pendingTitles
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .take(3)
      .toList();
  final sig = '$safePct|$doneCount|$totalCount|${topPending.join('||')}';
  if (sig == _lastSignature) return;
  _lastSignature = sig;

  try {
    await _widgetChannel.invokeMethod<void>('update', {
      'pct': safePct,
      'doneCount': doneCount,
      'totalCount': totalCount,
      'pendingTitles': topPending,
    });
  } on MissingPluginException {
    // Pruebas unitarias o plataforma sin widget nativo.
  } on PlatformException {
    // Ignorar fallo pasajero del launcher.
  }
}

/// Escucha toques desde el widget de Android para abrir rutas directas (/hoy o /hoy?new=1).
void setupHomeWidgetNavigation(void Function(String route) onNavigate) {
  _widgetChannel.setMethodCallHandler((call) async {
    if (call.method == 'navigate' && call.arguments is String) {
      final route = (call.arguments as String).trim();
      if (route.isNotEmpty) onNavigate(route);
    }
  });
  _widgetChannel
      .invokeMethod<String>('initialRoute')
      .then((route) {
        if (route != null && route.trim().isNotEmpty) {
          onNavigate(route.trim());
        }
      })
      .catchError((_) {});
}
