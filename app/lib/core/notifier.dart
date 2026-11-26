// Recordatorios locales con flutter_local_notifications (^22.3.3) y timezone (^0.11.0).
// Soporta múltiples horas diarias por rutina/tarea y acciones rápidas en Android (Hecho / Posponer 30 min).
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/db.dart';
import 'dates.dart';
import 'frequency.dart';

const String kReminderChannelId = 'power_habits_reminders';
const String kReminderChannelName = 'Recordatorios de Power Habits';
const String kReminderChannelDesc =
    'Avisos diarios para tus rutinas y tareas programadas.';

const String kActionDone = 'done';
const String kActionSnooze = 'snooze';

@pragma('vm:entry-point')
Future<void> onBackgroundNotificationResponse(
  NotificationResponse response,
) async {
  if (response.actionId == kActionSnooze) {
    final parsed = _ReminderPayload.decode(response.payload);
    if (parsed != null) {
      await PhoneNotifier.instance.snoozeRoutine(
        routineId: parsed.routineId,
        title: parsed.title,
      );
    }
  }
}

class _ReminderPayload {
  const _ReminderPayload({required this.routineId, required this.title});

  final String routineId;
  final String title;

  String encode() => jsonEncode({'routineId': routineId, 'title': title});

  static _ReminderPayload? decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final id = (decoded['routineId'] as String? ?? '').trim();
        if (id.isEmpty) return null;
        final title = (decoded['title'] as String? ?? 'Rutina pendiente').trim();
        return _ReminderPayload(
          routineId: id,
          title: title.isEmpty ? 'Rutina pendiente' : title,
        );
      }
    } catch (_) {
      // Fallback para payloads planos con solo routineId.
      return _ReminderPayload(
        routineId: raw.trim(),
        title: 'Rutina pendiente',
      );
    }
    return null;
  }
}

class PhoneNotifier {
  PhoneNotifier._();

  static final PhoneNotifier instance = PhoneNotifier._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _tzInitialized = false;

  /// Callback opcional invocado cuando el usuario pulsa "Marcar hecho" en una notificación.
  Future<void> Function(String routineId)? onMarkDoneFromNotification;

  bool get _isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _ensureTimeZone() {
    if (_tzInitialized) return;
    tzdata.initializeTimeZones();
    final now = DateTime.now();
    final targetOffsetMs = now.timeZoneOffset.inMilliseconds;
    final tzName = now.timeZoneName;

    tz.Location? matched;
    for (final loc in tz.timeZoneDatabase.locations.values) {
      final current = tz.TZDateTime.now(loc);
      if (current.timeZoneOffset.inMilliseconds == targetOffsetMs) {
        if (current.timeZoneName == tzName ||
            loc.name == 'America/Caracas' && targetOffsetMs == -14400000) {
          matched = loc;
          break;
        }
        matched ??= loc;
      }
    }
    tz.setLocalLocation(matched ?? tz.UTC);
    _tzInitialized = true;
  }

  /// Inicializa zonas horarias, canal Android y handlers de acciones rápidas.
  Future<void> init({
    Future<void> Function(String routineId)? onMarkDone,
  }) async {
    if (onMarkDone != null) {
      onMarkDoneFromNotification = onMarkDone;
    }
    _ensureTimeZone();
    if (_initialized || !_isSupportedPlatform) return;

    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            onBackgroundNotificationResponse,
      );

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          kReminderChannelId,
          kReminderChannelName,
          description: kReminderChannelDesc,
          importance: Importance.high,
        ),
      );

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      final launchResponse = launchDetails?.notificationResponse;
      if ((launchDetails?.didNotificationLaunchApp ?? false) &&
          launchResponse != null) {
        await _handleNotificationResponse(launchResponse);
      }
      _initialized = true;
    } on MissingPluginException {
      // Sin implementación nativa (entorno de pruebas).
    } on PlatformException {
      // Ignorar fallo de inicialización fuera de Android.
    }
  }

  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final parsed = _ReminderPayload.decode(response.payload);
    if (parsed == null) return;

    if (response.actionId == kActionDone) {
      await onMarkDoneFromNotification?.call(parsed.routineId);
    } else if (response.actionId == kActionSnooze) {
      await snoozeRoutine(
        routineId: parsed.routineId,
        title: parsed.title,
      );
    }
  }

  /// Solicita permisos de notificaciones (Android 13+) y alarmas exactas (Android 14+).
  Future<bool> requestPermissions() async {
    await init();
    if (!_isSupportedPlatform) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final notifGranted = await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      return notifGranted ?? true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  NotificationDetails _details({String? subText}) => NotificationDetails(
    android: AndroidNotificationDetails(
      kReminderChannelId,
      kReminderChannelName,
      channelDescription: kReminderChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      subText: subText,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          kActionDone,
          'Marcar hecho',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          kActionSnooze,
          'Posponer 30 min',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    ),
  );

  /// ID determinista de 31 bits positivos para evitar colisiones entre rutinas.
  int _notifId(String routineId, int slotIndex) {
    var hash = 0x811c9dc5;
    for (final unit in routineId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return ((hash & 0x01FFFFFF) << 6) | (slotIndex & 0x3F);
  }

  /// Programa todos los recordatorios configurados para una rutina o tarea.
  Future<void> scheduleForRoutine(Routine routine) async {
    await init();
    if (!_isSupportedPlatform) return;

    await cancelForRoutine(routine.id);
    if (routine.deletedAt != null) return;

    final times = parseReminderTimes(routine.reminderTimes);
    if (times.isEmpty) return;

    final payload = _ReminderPayload(
      routineId: routine.id,
      title: routine.title,
    ).encode();
    final contextLabel = routine.context == 'work' ? 'Laboral' : 'Personal';
    final isOnce =
        routine.itemType == 'task' || routine.frequencyType == 'once';

    var slot = 0;
    for (final hhmm in times) {
      final parts = hhmm.split(':');
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;

      if (isOnce) {
        final anchor = parseDayStr(routine.anchorDate);
        final scheduled = tz.TZDateTime(
          tz.local,
          anchor.year,
          anchor.month,
          anchor.day,
          hour,
          minute,
        );
        if (scheduled.isAfter(tz.TZDateTime.now(tz.local))) {
          await _zonedScheduleSafe(
            id: _notifId(routine.id, slot++),
            title: routine.title,
            body: 'Recordatorio programado ($hhmm) · $contextLabel',
            scheduledDate: scheduled,
            payload: payload,
            subText: contextLabel,
          );
        }
        continue;
      }

      if (routine.frequencyType == 'weekdays') {
        final weekdays = parseWeekdaysMask(routine.weekdaysMask).toList()
          ..sort();
        for (final weekday in weekdays) {
          if (slot >= 60) break;
          final scheduled = _nextWeekdayTime(weekday, hour, minute);
          await _zonedScheduleSafe(
            id: _notifId(routine.id, slot++),
            title: routine.title,
            body: 'Tu rutina de las $hhmm · $contextLabel',
            scheduledDate: scheduled,
            payload: payload,
            subText: contextLabel,
            matchComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
        continue;
      }

      if (slot >= 60) break;
      final scheduled = _nextApplicableDailyTime(routine, hour, minute);
      await _zonedScheduleSafe(
        id: _notifId(routine.id, slot++),
        title: routine.title,
        body: 'Tu rutina de las $hhmm · $contextLabel',
        scheduledDate: scheduled,
        payload: payload,
        subText: contextLabel,
        matchComponents: DateTimeComponents.time,
      );
    }
  }

  /// Cancela todos los recordatorios pendientes asociados a [routineId].
  Future<void> cancelForRoutine(String routineId) async {
    await init();
    if (!_isSupportedPlatform) return;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final req in pending) {
        final parsed = _ReminderPayload.decode(req.payload);
        if (parsed?.routineId == routineId) {
          await _plugin.cancel(id: req.id);
        }
      }
    } on MissingPluginException {
      // Entorno sin plugin.
    } on PlatformException {
      // Ignorar fallo pasajero.
    }
  }

  /// Limpia y reprograma todos los recordatorios de las rutinas activas.
  Future<int> rescheduleAll(List<Routine> routines) async {
    await init();
    if (!_isSupportedPlatform) return 0;
    try {
      await _plugin.cancelAll();
    } on MissingPluginException {
      return 0;
    } on PlatformException {
      return 0;
    }

    var scheduledCount = 0;
    for (final routine in routines) {
      if (routine.deletedAt != null) continue;
      final times = parseReminderTimes(routine.reminderTimes);
      if (times.isEmpty) continue;
      await scheduleForRoutine(routine);
      scheduledCount += times.length;
    }
    return scheduledCount;
  }

  /// Pospone una rutina específica (por defecto 30 minutos).
  Future<void> snoozeRoutine({
    required String routineId,
    required String title,
    Duration delay = const Duration(minutes: 30),
  }) async {
    _ensureTimeZone();
    if (!_isSupportedPlatform) return;

    final scheduled = tz.TZDateTime.now(tz.local).add(delay);
    final payload = _ReminderPayload(
      routineId: routineId,
      title: title,
    ).encode();

    await _zonedScheduleSafe(
      id: _notifId(routineId, 63),
      title: title,
      body: 'Recordatorio pospuesto (${delay.inMinutes} min)',
      scheduledDate: scheduled,
      payload: payload,
      subText: 'Pospuesto',
    );
  }

  Future<void> _zonedScheduleSafe({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
    String? subText,
    DateTimeComponents? matchComponents,
  }) async {
    final details = _details(subText: subText);
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: matchComponents,
      );
    } on PlatformException {
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
          matchDateTimeComponents: matchComponents,
        );
      } catch (_) {
        // Silencioso si el sistema restringe alarmas en segundo plano.
      }
    } on MissingPluginException {
      // Entorno de pruebas.
    }
  }

  tz.TZDateTime _nextApplicableDailyTime(
    Routine routine,
    int hour,
    int minute,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    if (routine.frequencyType == 'alternate') {
      for (var i = 0; i < 7; i++) {
        if (routineAppliesOnDate(routine, candidate)) {
          return candidate;
        }
        candidate = candidate.add(const Duration(days: 1));
      }
    }
    return candidate;
  }

  tz.TZDateTime _nextWeekdayTime(int isoWeekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (candidate.weekday != isoWeekday || !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
