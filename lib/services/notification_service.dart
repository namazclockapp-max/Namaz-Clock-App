import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static Future<void> schedulePrayerNotification({
    required String masjidName,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    final DateTime reminderTime = prayerTime.subtract(const Duration(minutes: 5));

    // Agar reminder ka time nikal chuka hai to schedule na karein
    if (reminderTime.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      prayerTime.hashCode, // unique ID
      'Prayer Reminder',
      '$masjidName: $prayerName in 5 minutes!',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel',
          'Prayer Reminders',
          channelDescription: 'Notification before prayer times',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
