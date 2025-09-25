// lib/language_manager.dart
import 'package:flutter/material.dart';

class LanguageManager with ChangeNotifier {
  // Add the static instance getter
  static final LanguageManager instance = LanguageManager._internal();

  // Private constructor to prevent instantiation
  LanguageManager._internal();

  factory LanguageManager() {
    return instance;
  }

  // Store the current locale. Default to English.
  // This value will be used by MaterialApp to set the app's locale.
  Locale _currentLocale = const Locale('en');

  // This map serves as your temporary "translation database".
  // In a real API integration, the value for each key would be fetched
  // from the API when the language changes.
  final Map<String, Map<String, String>> _translations = {
    // Common App Texts
    'My Awesome App': {
      'en': 'My Awesome App',
      'es': 'Mi Impresionante Aplicación',
      'ur': 'میری زبردست ایپ', // Urdu
      'ar': 'تطبيقي الرائع', // Arabic
    },
    'Welcome to our app!': {
      'en': 'Welcome to our app!',
      'es': '¡Bienvenido a nuestra aplicación!',
      'ur': 'ہماری ایپ میں خوش آمدید!',
      'ar': 'مرحبًا بك في تطبيقنا!',
    },
    'Hello, User!': {
      'en': 'Hello, User!',
      'es': '¡Hola, Usuario!',
      'ur': 'ہیلو، صارف!',
      'ar': 'أهلاً بك، مستخدم!',
    },
    'Select Language': {
      'en': 'Select Language',
      'es': 'Seleccionar Idioma',
      'ur': 'زبان منتخب کریں',
      'ar': 'اختر اللغة',
    },
    'Home': {
      'en': 'Home',
      'es': 'Inicio',
      'ur': 'ہوم',
      'ar': 'الرئيسية',
    },
    'Masjid': {
      'en': 'Masjid',
      'es': 'Mezquita',
      'ur': 'مسجد',
      'ar': 'المسجد',
    },
    'Notifications': {
      'en': 'Notifications',
      'es': 'Notificaciones',
      'ur': 'اطلاعات',
      'ar': 'الإشعارات',
    },
    'Qibla': {
      'en': 'Qibla',
      'es': 'Qibla',
      'ur': 'قبلہ',
      'ar': 'القبلة',
    },
    'Profile': {
      'en': 'Profile',
      'es': 'Perfil',
      'ur': 'پروفائل',
      'ar': 'الملف الشخصي',
    },
    'Admin Panel': {
      'en': 'Admin Panel',
      'es': 'Panel de Administración',
      'ur': 'ایڈمن پینل',
      'ar': 'لوحة الإدارة',
    },
    'Logout': {
      'en': 'Logout',
      'es': 'Cerrar Sesión',
      'ur': 'لاگ آؤٹ',
      'ar': 'تسجيل الخروج',
    },
    'Dashboard': {
      'en': 'Dashboard',
      'es': 'Tablero',
      'ur': 'ڈیش بورڈ',
      'ar': 'لوحة القيادة',
    },
    'Requests': {
      'en': 'Requests',
      'es': 'Solicitudes',
      'ur': 'درخواستیں',
      'ar': 'الطلبات',
    },
    'Users': {
      'en': 'Users',
      'es': 'Usuarios',
      'ur': 'صارفین',
      'ar': 'المستخدمون',
    },
    'Feedback': {
      'en': 'Feedback',
      'es': 'Comentarios',
      'ur': 'فیڈ بیک',
      'ar': 'الملاحظات',
    },
    'Masjid Req': {
      'en': 'Masjid Req', // Original from admin_panel_screen.dart
      'es': 'Solicitudes de Mezquita',
      'ur': 'مسجد درخواستیں',
      'ar': 'طلبات المساجد',
    },
    // Masjid Representative Screen specific texts
    'Update Prayer Times': {
      'en': 'Update Prayer Times',
      'es': 'Actualizar Horarios de Oración',
      'ur': 'نماز کے اوقات کو اپ ڈیٹ کریں',
      'ar': 'تحديث أوقات الصلاة',
    },
    'Current Location': {
      'en': 'Current Location',
      'es': 'Ubicación Actual',
      'ur': 'موجودہ مقام',
      'ar': 'الموقع الحالي',
    },
    'Masjid Information': {
      'en': 'Masjid Information',
      'es': 'Información de la Mezquita',
      'ur': 'مسجد کی معلومات',
      'ar': 'معلومات المسجد',
    },
    'Prayer Times': {
      'en': 'Prayer Times',
      'es': 'Horarios de Oración',
      'ur': 'نماز کے اوقات',
      'ar': 'أوقات الصلاة',
    },
    'Submit Updates': {
      'en': 'Submit Updates',
      'es': 'Enviar Actualizaciones',
      'ur': 'اپ ڈیٹس جمع کرائیں',
      'ar': 'إرسال التحديثات',
    },
    'Updating...': {
      'en': 'Updating...',
      'es': 'Actualizando...',
      'ur': 'اپ ڈیٹ ہو رہا ہے...',
      'ar': 'جارٍ التحديث...',
    },
    'Fajr Jammat': {
      'en': 'Fajr Jammat',
      'es': 'Fajr en Congregación',
      'ur': 'فجر کی جماعت',
      'ar': 'جماعة الفجر',
    },
    'Dhuhr Jammat': {
      'en': 'Dhuhr Jammat',
      'es': 'Dhuhr en Congregación',
      'ur': 'ظہر کی جماعت',
      'ar': 'جماعة الظهر',
    },
    'Asr Jammat': {
      'en': 'Asr Jammat',
      'es': 'Asr en Congregación',
      'ur': 'عصر کی جماعت',
      'ar': 'جماعة العصر',
    },
    'Maghrib Jammat': {
      'en': 'Maghrib Jammat',
      'es': 'Maghrib en Congregación',
      'ur': 'مغرب کی جماعت',
      'ar': 'جماعة المغرب',
    },
    'Isha Jammat': {
      'en': 'Isha Jammat',
      'es': 'Isha en Congregación',
      'ur': 'عشاء کی جماعت',
      'ar': 'جماعة العشاء',
    },
    'Tap on any time to update': {
      'en': 'Tap on any time to update',
      'es': 'Toca cualquier hora para actualizar',
      'ur': 'وقت کو اپ ڈیٹ کرنے کے لیے کسی بھی وقت پر ٹیپ کریں',
      'ar': 'انقر على أي وقت للتحديث',
    },
    'Maghrib time is automatically synchronized with sunset time based on your location': {
      'en': 'Maghrib time is automatically synchronized with sunset time based on your location',
      'es': 'La hora de Maghrib se sincroniza automáticamente con la hora de la puesta del sol según tu ubicación',
      'ur': 'مغرب کا وقت آپ کے مقام کی بنیاد پر غروب آفتاب کے وقت کے ساتھ خود بخود ہم آہنگ ہو جاتا ہے',
      'ar': 'يتم مزامنة وقت المغرب تلقائيًا مع وقت غروب الشمس بناءً على موقعك',
    },
    // Home Screen specific texts
    'Islamic Date': {
      'en': 'Islamic Date',
      'es': 'Fecha Islámica',
      'ur': 'اسلامی تاریخ',
      'ar': 'التاريخ الهجري',
    },
    'Namaz Clock': {
      'en': 'Namaz Clock',
      'es': 'Reloj de Oración',
      'ur': 'نماز گھڑی',
      'ar': 'ساعة الصلاة',
    },
    'Qibla Direction': {
      'en': 'Qibla Direction',
      'es': 'Dirección de la Qibla',
      'ur': 'قبلہ کی سمت',
      'ar': 'اتجاه القبلة',
    },
    'Representative Panel': {
      'en': 'Representative Panel',
      'es': 'Panel de Representante',
      'ur': 'نمائندہ پینل',
      'ar': 'لوحة الممثل',
    },
    'Sign Out': {
      'en': 'Sign Out',
      'es': 'Cerrar Sesión',
      'ur': 'سائن آؤٹ کریں',
      'ar': 'تسجيل الخروج',
    },
    'Are you sure you want to sign out?': {
      'en': 'Are you sure you want to sign out?',
      'es': '¿Estás seguro de que quieres cerrar sesión?',
      'ur': 'کیا آپ واقعی سائن آؤٹ کرنا چاہتے ہیں؟',
      'ar': 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
    },
    'Cancel': {
      'en': 'Cancel',
      'es': 'Cancelar',
      'ur': 'منسوخ کریں',
      'ar': 'إلغاء',
    },
    'You are not a representative of any masjid.': {
      'en': 'You are not a representative of any masjid.',
      'es': 'No eres representante de ninguna mezquita.',
      'ur': 'آپ کسی بھی مسجد کے نمائندے نہیں ہیں۔',
      'ar': 'أنت لست ممثلاً لأي مسجد.',
    },
    'Manage': {
      'en': 'Manage',
      'es': 'Administrar',
      'ur': 'انتظام کریں',
      'ar': 'إدارة',
    },
    'Statistics': {
      'en': 'Statistics',
      'es': 'Estadísticas',
      'ur': 'شماریات',
      'ar': 'الإحصائيات',
    },
    'Upcoming Events': {
      'en': 'Upcoming Events',
      'es': 'Próximos Eventos',
      'ur': 'آنے والے واقعات',
      'ar': 'الأحداث القادمة',
    },
    'Event Management': {
      'en': 'Event Management',
      'es': 'Gestión de Eventos',
      'ur': 'واقعات کا انتظام',
      'ar': 'إدارة الأحداث',
    },
    'Event Name': {
      'en': 'Event Name',
      'es': 'Nombre del Evento',
      'ur': 'واقعہ کا نام',
      'ar': 'اسم الحدث',
    },
    'Description': {
      'en': 'Description',
      'es': 'Descripción',
      'ur': 'تفصیل',
      'ar': 'الوصف',
    },
    'Date/Time': {
      'en': 'Date/Time',
      'es': 'Fecha/Hora',
      'ur': 'تاریخ/وقت',
      'ar': 'التاريخ/الوقت',
    },
    'Day': {
      'en': 'Day',
      'es': 'Día',
      'ur': 'دن',
      'ar': 'اليوم',
    },
    'This field is required': {
      'en': 'This field is required',
      'es': 'Este campo es obligatorio',
      'ur': 'یہ فیلڈ ضروری ہے',
      'ar': 'هذا الحقل مطلوب',
    },
    'Adding Event...': {
      'en': 'Adding Event...',
      'es': 'Añadiendo Evento...',
      'ur': 'واقعہ شامل ہو رہا ہے...',
      'ar': 'جاري إضافة الحدث...',
    },
    'Add Event': {
      'en': 'Add Event',
      'es': 'Añadir Evento',
      'ur': 'واقعہ شامل کریں',
      'ar': 'إضافة حدث',
    },
    'Announcements': {
      'en': 'Announcements',
      'es': 'Anuncios',
      'ur': 'اعلانات',
      'ar': 'الإعلانات',
    },
    'Title': {
      'en': 'Title',
      'es': 'Título',
      'ur': 'عنوان',
      'ar': 'العنوان',
    },
    'Body': {
      'en': 'Body',
      'es': 'Cuerpo',
      'ur': 'متن',
      'ar': 'النص',
    },
    'Adding Announcement...': {
      'en': 'Adding Announcement...',
      'es': 'Añadiendo Anuncio...',
      'ur': 'اعلان شامل ہو رہا ہے...',
      'ar': 'جاري إضافة الإعلان...',
    },
    'Send Announcement': {
      'en': 'Send Announcement',
      'es': 'Enviar Anuncio',
      'ur': 'اعلان بھیجیں',
      'ar': 'إرسال الإعلان',
    },
    // Language names for dropdown
    'English': {'en': 'English', 'es': 'Inglés', 'ur': 'انگریزی', 'ar': 'الإنجليزية'},
    'Urdu': {'en': 'Urdu', 'es': 'Urdu', 'ur': 'اردو', 'ar': 'الأردية'},
    'Arabic': {'en': 'Arabic', 'es': 'Árabe', 'ur': 'عربی', 'ar': 'العربية'},
  };

  Locale get currentLocale => _currentLocale;

  String getTranslatedString(String originalText) {
    return _translations[originalText]?[_currentLocale.languageCode] ?? originalText;
  }

  // Use this to change the app's language
  void changeLanguage(String languageCode) {
    if (_currentLocale.languageCode != languageCode) {
      _currentLocale = Locale(languageCode);
      notifyListeners(); // This tells all listening widgets to rebuild
    }
  }

  // Helper to get display names for the languages in the dropdown
  String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'ur':
        return 'اردو'; // Urdu
      case 'ar':
        return 'العربية'; // Arabic
      default:
        return languageCode; // Fallback
    }
  }

  // Get a list of supported language codes from your translations map
  List<String> get supportedLanguageCodes {
    // For simplicity, hardcode the supported languages.
    // In a dynamic scenario, you might derive this from your API's supported languages.
    return ['en', 'ur', 'ar']; // Updated to include 'ar'
  }

  // Expose the list of supported Locales for MaterialApp
  List<Locale> get supportedLocales {
    return supportedLanguageCodes.map((code) => Locale(code)).toList();
  }
}