import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/responsibility.dart';

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'life_admin_deadlines';
  static const _channelName = 'Scadenze';
  static const _channelDescription = 'Promemoria per scadenze e rinnovi';

  Future<void> initialize() async {
    tz.initializeTimeZones();
    final deviceZone = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(deviceZone.identifier));
    } on tz.LocationNotFoundException {
      tz.setLocalLocation(tz.UTC);
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showTestNotification() async {
    await _plugin.show(
      id: 900001,
      title: 'LifeAdmin',
      body: 'Le notifiche funzionano correttamente.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> sync(
    List<Responsibility> responsibilities, {
    required List<int> reminderDays,
  }) async {
    await _plugin.cancelAll();

    final uniqueDays = reminderDays.toSet().toList()..sort((a, b) => b.compareTo(a));
    for (final item in responsibilities) {
      if (item.status != ResponsibilityStatus.pending) continue;
      for (final daysBefore in uniqueDays) {
        await _schedule(item, daysBefore);
      }
    }
  }

  Future<void> _schedule(Responsibility item, int daysBefore) async {
    final reminderDate = item.dueDate.subtract(Duration(days: daysBefore));
    final scheduled = tz.TZDateTime(
      tz.local,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9,
    );

    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;

    final when = daysBefore == 0
        ? 'Scade oggi'
        : daysBefore == 1
            ? 'Scade domani'
            : 'Scade tra $daysBefore giorni';

    await _plugin.zonedSchedule(
      id: _notificationId(item.id, daysBefore),
      title: item.title,
      body: when,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: item.id,
    );
  }

  int _notificationId(String id, int daysBefore) {
    var hash = 0x811c9dc5;
    for (final codeUnit in '$id:$daysBefore'.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
