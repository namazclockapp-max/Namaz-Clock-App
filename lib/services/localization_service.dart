// lib/services/localization_service.dart
import 'package:flutter/material.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();

  factory LocalizationService() {
    return _instance;
  }

  LocalizationService._internal();

  Locale _currentLocale = const Locale('en', 'US'); // Default to English

  Locale get currentLocale => _currentLocale;

  void setLocale(Locale locale) {
    _currentLocale = locale;
    // In a real app, you might want to save this preference to SharedPreferences
    // and notify listeners for immediate UI updates.
  }

  // A simplified map for translations.
  // In a real app, you would load these from JSON files or similar.
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'namaz_clock': 'Namaz Clock',
      'notifications': 'Notifications',
      'qibla_direction': 'Qibla Direction',
      'islamic_date': 'Islamic Date',
      'fajr': 'Fajr',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
      'current_prayer': 'Current Prayer',
      'next_prayer': 'Next Prayer',
      'time_until_next_prayer': 'Time Until Next Prayer',
      'hours': 'hours',
      'minutes': 'minutes',
      'and': 'and',
      'seconds': 'seconds',
      'loading_role': 'Determining user role...',
      'home': 'Home',
      'masjid': 'Masjid',
      'prayer_times': 'Prayer Times',
      'profile': 'Profile',
      'admin_panel': 'Admin Panel',
      'masjid_representative': 'Masjid Representative',
    },
    'ur': {
      'namaz_clock': 'نماز کلک',
      'notifications': 'اطلاعات',
      'qibla_direction': 'قبلہ کی سمت',
      'islamic_date': 'اسلامی تاریخ',
      'fajr': 'فجر',
      'dhuhr': 'ظہر',
      'asr': 'عصر',
      'maghrib': 'مغرب',
      'isha': 'عشاء',
      'current_prayer': 'موجودہ نماز',
      'next_prayer': 'اگلی نماز',
      'time_until_next_prayer': 'اگلی نماز تک کا وقت',
      'hours': 'گھنٹے',
      'minutes': 'منٹ',
      'and': 'اور',
      'seconds': 'سیکنڈ',
      'loading_role': 'صارف کا کردار معلوم کیا جا رہا ہے...',
      'home': 'ہوم',
      'masjid': 'مسجد',
      'prayer_times': 'نماز کے اوقات',
      'profile': 'پروفائل',
      'admin_panel': 'ایڈمن پینل',
      'masjid_representative': 'مسجد نمائندہ',
    },
    'ar': {
      'namaz_clock': 'ساعة الصلاة',
      'notifications': 'الإشعارات',
      'qibla_direction': 'اتجاه القبلة',
      'islamic_date': 'التاريخ الهجري',
      'fajr': 'الفجر',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
      'current_prayer': 'الصلاة الحالية',
      'next_prayer': 'الصلاة التالية',
      'time_until_next_prayer': 'الوقت المتبقي للصلاة التالية',
      'hours': 'ساعات',
      'minutes': 'دقائق',
      'and': 'و',
      'seconds': 'ثواني',
      'loading_role': 'جار تحديد دور المستخدم...',
      'home': 'الرئيسية',
      'masjid': 'المسجد',
      'prayer_times': 'أوقات الصلاة',
      'profile': 'الملف الشخصي',
      'admin_panel': 'لوحة الإدارة',
      'masjid_representative': 'مندوب المسجد',
    },
  };

  String translate(String key) {
    return _localizedValues[_currentLocale.languageCode]?[key] ?? key;
  }
}