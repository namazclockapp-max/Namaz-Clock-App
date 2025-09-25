import 'dart:convert';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const String DAILY_TASK = "daily_prayer_reschedule";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == DAILY_TASK) {
      // Load saved masjid data
      final prefs = await SharedPreferences.getInstance();
      final masjidsData = prefs.getString('subscribed_masjids');

      if (masjidsData != null) {
        final List masjids = jsonDecode(masjidsData);
        for (var masjid in masjids) {
          final name = masjid['name'] ?? 'Masjid';
          final times = masjid['prayerTimes'] ?? {};

          // Schedule notifications for each prayer
          times.forEach((prayer, timeStr) {
            if (timeStr != null && timeStr.toString().isNotEmpty) {
              _schedulePrayerNotification(
                masjidName: name,
                prayerName: prayer,
                prayerTimeString: timeStr,
              );
            }
          });
        }
      }
    }
    return Future.value(true);
  });
}

Future<void> _schedulePrayerNotification({
  required String masjidName,
  required String prayerName,
  required String prayerTimeString,
}) async {
  final now = DateTime.now();
  final timeParts = prayerTimeString.split(':');
  final int hour = int.parse(timeParts[0]);
  final int minute = int.parse(timeParts[1]);

  final prayerTime = DateTime(now.year, now.month, now.day, hour, minute);
  final reminderTime = prayerTime.subtract(const Duration(minutes: 5));

  if (reminderTime.isBefore(DateTime.now())) return;

  await flutterLocalNotificationsPlugin.zonedSchedule(
    prayerTime.hashCode,
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
