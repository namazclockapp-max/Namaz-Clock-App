import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:namaz_clock_app/firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';

import 'screens/home_screen.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'screens/representative/masjid_representative_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/language_manager.dart';

import 'services/storage_service.dart';
import 'services/notification_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('background notification payload: ${notificationResponse.payload}');
}

/// WorkManager background task
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      tz.initializeTimeZones();
      final String? timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(
          timeZoneName != null ? tz.getLocation(timeZoneName) : tz.UTC);

      final masjids = await StorageService.getSubscribedMasjids();
      for (var masjid in masjids) {
        final masjidName = masjid['name'] ?? 'Unknown Masjid';
        final prayerTimes = masjid['prayerTimes'] ?? {};

        for (var entry in prayerTimes.entries) {
          final prayerName = entry.key;
          final timeString = entry.value;
          if (timeString != null && timeString != 'N/A') {
            final now = DateTime.now();
            final parsedTime = DateFormat('hh:mm a').parse(timeString);
            final prayerDateTime = DateTime(
              now.year,
              now.month,
              now.day,
              parsedTime.hour,
              parsedTime.minute,
            );

            if (prayerDateTime.isAfter(now)) {
              await NotificationService.schedulePrayerNotification(
                masjidName: masjidName,
                prayerName: prayerName,
                prayerTime: prayerDateTime,
              );
            }
          }
        }
      }
      debugPrint("Background task executed successfully.");
      return Future.value(true);
    } catch (e) {
      debugPrint("Background task failed: $e");
      return Future.value(false);
    }
  });
}

/// Local notifications setup
Future<void> setupLocalNotifications() async {
  tz.initializeTimeZones();
  final String? timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(timeZoneName != null ? tz.getLocation(timeZoneName) : tz.UTC);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/prayer_logo');
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      debugPrint('notification payload: ${response.payload}');
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
}

/// Location request function
Future<void> requestAndFetchLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    debugPrint("⚠ Location services disabled");
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    debugPrint("❌ Location permissions permanently denied");
    return;
  }

  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
  debugPrint("📍 Current Location: Lat=${position.latitude}, Lng=${position.longitude}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // **App ko jaldi launch karo with splash**
  runApp(
    ChangeNotifierProvider(
      create: (context) => LanguageManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageManager>(
      builder: (context, languageManager, child) {
        return MaterialApp(
          title: 'Namaz Clock App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.green,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          locale: languageManager.currentLocale,
          supportedLocales: languageManager.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home:  SplashScreen(), // Always show Splash first
        );
      },
    );
  }
}

class RoleBasedRedirector extends StatelessWidget {
  final String uid;
  const RoleBasedRedirector({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
              'email': currentUser.email,
              'name': currentUser.displayName ?? 'New User',
              'role': 'user',
            }, SetOptions(merge: true));
          }
          return const HomeScreen();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final role = userData?['role'] as String?;

        if (role == 'admin') {
          return const AdminPanelScreen();
        } else if (role == 'representative') {
          return const MasjidRepresentativeScreen(masjidId: '');
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}
