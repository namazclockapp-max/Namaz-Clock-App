// lib/services/permission_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';

enum LocationPermissionStatus {
  notDetermined,
  granted,
  denied,
  permanentlyDenied,
}

class LocationPermissionService with ChangeNotifier {
  LocationPermissionStatus _status = LocationPermissionStatus.notDetermined;

  LocationPermissionStatus get status => _status;

  /// Request location permission
  Future<void> requestLocationPermission() async {
    var permissionStatus = await Permission.location.request();

    if (permissionStatus.isGranted) {
      _status = LocationPermissionStatus.granted;
      print("Location permission granted!");
    } else if (permissionStatus.isDenied) {
      _status = LocationPermissionStatus.denied;
      print("Location permission denied.");
    } else if (permissionStatus.isPermanentlyDenied) {
      _status = LocationPermissionStatus.permanentlyDenied;
      print("Location permission permanently denied. Open settings.");
    }
    notifyListeners();
  }

  /// Check current location permission without prompting
  Future<void> checkLocationPermission() async {
    var permissionStatus = await Permission.location.status;
    if (permissionStatus.isGranted) {
      _status = LocationPermissionStatus.granted;
    } else if (permissionStatus.isDenied) {
      _status = LocationPermissionStatus.denied;
    } else if (permissionStatus.isPermanentlyDenied) {
      _status = LocationPermissionStatus.permanentlyDenied;
    } else {
      _status = LocationPermissionStatus.notDetermined;
    }
    notifyListeners();
  }

  /// Request exact alarm permission for Android 13+
  static Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        const intent = AndroidIntent(
          action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        );
        await intent.launch();
        debugPrint("Exact Alarm permission intent launched.");
      } catch (e) {
        debugPrint("Failed to request exact alarm permission: $e");
      }
    }
  }
}
