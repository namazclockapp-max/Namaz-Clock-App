import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  /// Masjids ko save karein
  static Future<void> saveSubscribedMasjids(List<Map<String, dynamic>> masjids) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('subscribed_masjids', jsonEncode(masjids));
  }

  /// Masjids ko load karein
  static Future<List<Map<String, dynamic>>> getSubscribedMasjids() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('subscribed_masjids');
    if (data != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    }
    return [];
  }

  /// Masjids ko clear karein
  static Future<void> clearSubscribedMasjids() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('subscribed_masjids');
  }
}
