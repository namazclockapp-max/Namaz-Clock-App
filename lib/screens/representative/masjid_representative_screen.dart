// screens/representative/masjid_representative_screen.dart
// Complete Masjid Representative's dashboard with all home screen widgets

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:namaz_clock_app/screens/auth/login_screen.dart';
import 'package:namaz_clock_app/screens/representative/widgets/representative_learning_videos.dart';
import 'package:namaz_clock_app/services/auth_service.dart';
import 'package:namaz_clock_app/services/firestore_service.dart';
import 'package:namaz_clock_app/widgets/prayer_times_widget.dart';
import 'package:namaz_clock_app/screens/language_manager.dart';

// Your specifically requested separated widgets
import 'package:namaz_clock_app/screens/representative/widgets/current_masjid_times_card.dart';
import 'package:namaz_clock_app/screens/representative/widgets/prayer_times_management_card.dart';
import 'package:namaz_clock_app/screens/representative/widgets/masjid_statistics_card.dart';

import '../profile_screen.dart';
import '../qibla_direction_screen.dart';
import '../prayer_times_screen.dart';
import '../../main.dart'; // To navigate to MasjidScreen after logout

// AppColors class defined within the same file as requested
class AppColors {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color darkGrey = Color(0xFF424242);
}

// MasjidRepresentativeBottomNavBar class defined here as requested
class MasjidRepresentativeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MasjidRepresentativeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryGreen,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: LanguageManager.instance.getTranslatedString('Dashboard'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.manage_accounts),
          label: LanguageManager.instance.getTranslatedString('Manage'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.analytics),
          label: LanguageManager.instance.getTranslatedString('Statistics'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.account_circle),
          label: LanguageManager.instance.getTranslatedString('Profile'),
        ),
      ],
    );
  }
}

class MasjidRepresentativeScreen extends StatefulWidget {
  final String masjidId;
  const MasjidRepresentativeScreen({super.key, required this.masjidId});

  @override
  State<MasjidRepresentativeScreen> createState() =>
      _MasjidRepresentativeScreenState();
}

class _MasjidRepresentativeScreenState extends State<MasjidRepresentativeScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDescriptionController =
      TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _eventDayController = TextEditingController();
  final TextEditingController _announcementTitleController =
      TextEditingController();
  final TextEditingController _announcementBodyController =
      TextEditingController();
  final GlobalKey<FormState> _eventFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _announcementFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _prayerTimesFormKey = GlobalKey<FormState>();

  // Add the missing TextEditingControllers
  final TextEditingController fajrController = TextEditingController();
  final TextEditingController dhuhrController = TextEditingController();
  final TextEditingController asrController = TextEditingController();
  final TextEditingController maghribController = TextEditingController();
  final TextEditingController ishaController = TextEditingController();
  final TextEditingController jummahController = TextEditingController();

  bool isUpdating = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String? _userMasjidId;
  String? _userMasjidName;
  Map<String, dynamic>? _userMasjidData;
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isAddingEvent = false;
  bool _isAddingAnnouncement = false;
  bool _isUpdatingPrayerTimes = false;
  List<Map<String, dynamic>> _masjidEvents = [];
  late HijriCalendar _islamicDate;

  @override
  void initState() {
    super.initState();
    _islamicDate = HijriCalendar.now();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(_fadeController);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(_slideController);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      reverseDuration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    _fetchRepresentativeMasjid();
    // _setMaghribAutomatically();
  }

  // The method needs to be placed inside the State class, not globally.
  // This is an example of how to implement it correctly.

  // void _setMaghribAutomatically() {
  //   final data = _userMasjidData;
  //   if (data == null) return;

  //   final loc = data['location'];
  //   if (loc == null || loc['latitude'] == null || loc['longitude'] == null) {
  //     // location or lat/lng missing – do nothing
  //     return;
  //   }

  //   final coords = Coordinates(
  //     (loc['latitude'] as num).toDouble(),
  //     (loc['longitude'] as num).toDouble(),
  //   );
  //   final params = CalculationMethod.karachi.getParameters();
  //   final date = DateComponents.from(DateTime.now());
  //   final prayerTimes = PrayerTimes(coords, date, params);

  //   maghribController.text = DateFormat.jm().format(prayerTimes.maghrib);
  // }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    _eventDateController.dispose();
    _eventDayController.dispose();
    _announcementTitleController.dispose();
    _announcementBodyController.dispose();
    fajrController.dispose();
    dhuhrController.dispose();
    asrController.dispose();
    maghribController.dispose();
    ishaController.dispose();
    jummahController.dispose();
    super.dispose();
  }

  Future<void> _fetchRepresentativeMasjid() async {
    print('[_fetchRepresentativeMasjid] - Method started.');
    final user = _authService.currentUser;
    if (user == null) {
      print('[_fetchRepresentativeMasjid] - User is null. Exiting.');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    print('[_fetchRepresentativeMasjid] - User found: ${user.uid}');
    try {
      final userData = await _firestoreService.getUserData(user.uid);
      if (userData != null && userData.containsKey('masjidId')) {
        print(
          '[_fetchRepresentativeMasjid] - User has masjidId: ${userData['masjidId']}',
        );
        _userMasjidId = userData['masjidId'];
        final masjidData = await _firestoreService.getMasjidById(
          _userMasjidId!,
        );
        if (masjidData != null) {
          print('[_fetchRepresentativeMasjid] - Masjid data found.');
          _userMasjidName = masjidData['name'];
          _userMasjidData = masjidData;

          // ✅ NEW (flat fields in your DB)
          fajrController.text = _userMasjidData?['fajr'] ?? '';
          dhuhrController.text = _userMasjidData?['dhuhr'] ?? '';
          asrController.text = _userMasjidData?['asr'] ?? '';
          maghribController.text = _userMasjidData?['maghrib'] ?? '';
          ishaController.text = _userMasjidData?['isha'] ?? '';
          jummahController.text = _userMasjidData?['jummah'] ?? '';

          // _setMaghribAutomatically(); may overwrite maghrib if no manual value saved
          await _fetchMasjidEvents();
          _slideController.forward();
          _fadeController.forward();
        } else {
          print(
            '[_fetchRepresentativeMasjid] - Masjid data is null for ID: $_userMasjidId',
          );
        }
      } else {
        print(
          '[_fetchRepresentativeMasjid] - User data does not contain masjidId or is null.',
        );
      }
    } catch (e) {
      print('[_fetchRepresentativeMasjid] - Caught an error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchMasjidEvents() async {
    if (_userMasjidId == null) return;
    try {
      final eventsStream = _firestoreService.getMasjidEvents(_userMasjidId!);
      final events =
          await eventsStream.first; // get first emitted list from the stream
      if (mounted) {
        setState(() {
          _masjidEvents = events;
        });
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  Future<void> _updatePrayerTimes() async {
    if (_userMasjidId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('masjids')
          .doc(_userMasjidId)
          .update({
            'fajr': fajrController.text,
            'dhuhr': dhuhrController.text,
            'asr': asrController.text,
            'maghrib': maghribController.text,
            'isha': ishaController.text,
            'jummah': jummahController.text,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prayer times updated successfully!')),
        );
      }
    } catch (e) {
      print('Error updating prayer times: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.darkGreen,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primaryGreen,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColors.darkGreen,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        final formattedDate = DateFormat(
          'dd-MM-yyyy HH:mm',
        ).format(selectedDateTime);
        final formattedDay = DateFormat('EEEE').format(selectedDateTime);
        controller.text = formattedDate;
        _eventDayController.text = formattedDay;
      }
    }
  }

  // New method to select time for prayer times
  Future<void> _selectTime(TextEditingController controller) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.darkGreen,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && mounted) {
      final now = DateTime.now();
      final selectedTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      controller.text = DateFormat.jm().format(selectedTime);
    }
  }

  Future<void> _addMasjidEvent() async {
    if (_eventFormKey.currentState!.validate() && _userMasjidId != null) {
      setState(() {
        _isAddingEvent = true;
      });

      try {
        await _firestoreService.addMasjidEvent(
          masjidId: _userMasjidId!,
          eventName: _eventNameController.text,
          description: _eventDescriptionController.text,
          dateTime: _eventDateController.text,
          day: _eventDayController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event added successfully!')),
          );
          _eventNameController.clear();
          _eventDescriptionController.clear();
          _eventDateController.clear();
          _eventDayController.clear();
          await _fetchMasjidEvents(); // Refresh the list after adding an event
        }
      } catch (e) {
        print('Error adding event: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to add event: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isAddingEvent = false;
          });
        }
      }
    }
  }
  Future<void> _updateIqamaTimes() async {
    if (_prayerTimesFormKey.currentState!.validate() && _userMasjidId != null) {
      setState(() => _isUpdatingPrayerTimes = true);

      // Create update map with flat field structure
      final Map<String, dynamic> updates = {};

      if (fajrController.text.isNotEmpty) updates['fajr'] = fajrController.text;
      if (dhuhrController.text.isNotEmpty)
        updates['dhuhr'] = dhuhrController.text;
      if (asrController.text.isNotEmpty) updates['asr'] = asrController.text;
      if (maghribController.text.isNotEmpty)
        updates['maghrib'] = maghribController.text;
      if (ishaController.text.isNotEmpty) updates['isha'] = ishaController.text;
      if (jummahController.text.isNotEmpty)
        updates['jummah'] = jummahController.text;

      try {
        // Update flat fields directly in Firestore
        await FirebaseFirestore.instance
            .collection('masjids')
            .doc(_userMasjidId!)
            .update(updates);

        if (mounted) {
          // Refresh local data
          final fresh = await _firestoreService.getMasjidById(_userMasjidId!);
          setState(() => _userMasjidData = fresh);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prayer times updated!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
        }
      } finally {
        if (mounted) setState(() => _isUpdatingPrayerTimes = false);
      }
    }
  }

  void _showLogoutDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(LanguageManager.instance.getTranslatedString('Sign Out')),
          content: Text(
            LanguageManager.instance.getTranslatedString(
              'Are you sure you want to sign out?',
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                LanguageManager.instance.getTranslatedString('Cancel'),
                style: const TextStyle(color: AppColors.primaryGreen),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                LanguageManager.instance.getTranslatedString('Sign Out'),
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _onBottomNavTap(int index) {
    HapticFeedback.lightImpact();
    if (index == 3) {
      // Profile tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SlideTransition(
          position: _slideAnimation,
          // child: IslamicDateCard(
          //   islamicDate: _islamicDate,
          //   fadeAnimation: _fadeAnimation,
          // ),
        ),
        const SizedBox(height: 20),
        SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.1, 1.0, curve: Curves.easeOutBack),
                ),
              ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: const PrayerTimesWidget(),
          ),
        ),
        const SizedBox(height: 20),
        SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
                ),
              ),
          // child: MasjidInfoCard(
          //   masjidName: _userMasjidName,
          //   fadeAnimation: _fadeAnimation,
          // ),
        ),
        const SizedBox(height: 20),
        SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
                ),
              ),
          child: CurrentMasjidTimesCard(
            masjidData: _userMasjidData,
            fadeAnimation: _fadeAnimation,
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildManageContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        SlideTransition(
          position: _slideAnimation,
          child: PrayerTimesManagementCard(
            masjidId: _userMasjidId!,
            prayerTimes: _userMasjidData?['prayerTimes'] ?? {},
            iqamaTimes: _userMasjidData?['iqamaTimes'] ?? {},
            fadeAnimation: _fadeAnimation,
            formKey: _prayerTimesFormKey,
            onUpdateIqamaTimes: _updateIqamaTimes,
            isUpdating: _isUpdatingPrayerTimes,
            // Pass the new controllers
            fajrController: fajrController,
            dhuhrController: dhuhrController,
            asrController: asrController,
            maghribController: maghribController,
            ishaController: ishaController,
            jummahController: jummahController,
            onSelectTime: _selectTime,
          ),
        ),
        const SizedBox(height: 30),
        SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
                ),
              ),
          child: EventManagementCard(
            formKey: _eventFormKey,
            eventNameController: _eventNameController,
            eventDescriptionController: _eventDescriptionController,
            eventDateController: _eventDateController,
            eventDayController: _eventDayController,
            onSelectDate: _selectDate,
            onAddEvent: _addMasjidEvent,
            isAddingEvent: _isAddingEvent,
            fadeAnimation: _fadeAnimation,
          ),
        ),
        const SizedBox(height: 30),
        SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
                ),
              ),
          child: EventListCard(
            events: _masjidEvents,
            fadeAnimation: _fadeAnimation,
          ),
        ),
        const SizedBox(height: 30),
        SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
                ),
              ),
          // child: AnnouncementCard(
          //   formKey: _announcementFormKey,
          //   announcementTitleController: _announcementTitleController,
          //   announcementBodyController: _announcementBodyController,
          //   onAddAnnouncement: _addMasjidAnnouncement,
          //   isAddingAnnouncement: _isAddingAnnouncement,
          //   fadeAnimation: _fadeAnimation,
          // ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildStatisticsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        SlideTransition(
          position: _slideAnimation,
          child: MasjidStatisticsCard(
            masjidData: _userMasjidData,
            fadeAnimation: _fadeAnimation,
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }
    if (_userMasjidId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            LanguageManager.instance.getTranslatedString(
              'You are not a representative of any masjid.',
            ),
            style: const TextStyle(fontSize: 18, color: AppColors.darkGrey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    switch (_currentIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildManageContent();
      case 2:
        return _buildStatisticsContent();
      default:
        return _buildDashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primaryGreen,
            leading: IconButton(
              icon: const Icon(Icons.lightbulb, color: Colors.white),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RepresentativeLearningVideos(),
                  ),
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _showLogoutDialog,
                tooltip: 'Sign Out',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  LanguageManager.instance.getTranslatedString(
                    'Representative Panel',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.secondaryGreen,
                      AppColors.lightGreen,
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: RotationTransition(
                          turns: Tween(
                            begin: 0.0,
                            end: 1.0,
                          ).animate(_pulseController),
                          child: const Icon(
                            Icons.mosque,
                            size: 200,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(child: _buildBody()),
          ),
        ],
      ),
      bottomNavigationBar: MasjidRepresentativeBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}

// New widget to display the list of events
class EventListCard extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final Animation<double> fadeAnimation;

  const EventListCard({
    super.key,
    required this.events,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: fadeAnimation,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.list_alt,
                    color: AppColors.primaryGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      LanguageManager.instance.getTranslatedString(
                        'Upcoming Events',
                      ),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                    ),
                  ),
                ],
              ),
              const Divider(
                height: 30,
                thickness: 1,
                color: AppColors.lightGreen,
              ),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.event_available,
                      color: AppColors.accentGreen,
                    ),
                    title: Text(
                      event['eventName'] ?? 'No Name',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${event['dateTime']} on ${event['day']}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        Text(
                          event['description'] ?? '',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Existing widgets from your original code (updated for full functionality)

class EventManagementCard extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController eventNameController;
  final TextEditingController eventDescriptionController;
  final TextEditingController eventDateController;
  final TextEditingController eventDayController;
  final Function(TextEditingController) onSelectDate;
  final Function() onAddEvent;
  final bool isAddingEvent;
  final Animation<double> fadeAnimation;

  const EventManagementCard({
    super.key,
    required this.formKey,
    required this.eventNameController,
    required this.eventDescriptionController,
    required this.eventDateController,
    required this.eventDayController,
    required this.onSelectDate,
    required this.onAddEvent,
    required this.isAddingEvent,
    required this.fadeAnimation,
  });

  @override
  State<EventManagementCard> createState() => _EventManagementCardState();
}

class _EventManagementCardState extends State<EventManagementCard> {
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: widget.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event_note,
                      color: AppColors.primaryGreen,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        LanguageManager.instance.getTranslatedString(
                          'Event Management',
                        ),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGreen,
                            ),
                      ),
                    ),
                  ],
                ),
                const Divider(
                  height: 30,
                  thickness: 1,
                  color: AppColors.lightGreen,
                ),
                _buildTextField(
                  controller: widget.eventNameController,
                  label: LanguageManager.instance.getTranslatedString(
                    'Event Name',
                  ),
                  icon: Icons.title,
                ),
                _buildTextField(
                  controller: widget.eventDescriptionController,
                  label: LanguageManager.instance.getTranslatedString(
                    'Description',
                  ),
                  icon: Icons.description,
                  maxLines: 3,
                ),
                _buildDateTimeFields(),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: widget.isAddingEvent
                      ? null
                      : () => widget.onAddEvent(),
                  icon: widget.isAddingEvent
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                        ),
                  label: Text(
                    widget.isAddingEvent
                        ? LanguageManager.instance.getTranslatedString(
                            'Adding Event...',
                          )
                        : LanguageManager.instance.getTranslatedString(
                            'Add Event',
                          ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryGreen,
              width: 2,
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return LanguageManager.instance.getTranslatedString(
              'This field is required',
            );
          }
          return null;
        },
        style: const TextStyle(color: AppColors.darkGreen),
      ),
    );
  }

  Widget _buildDateTimeFields() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: widget.eventDateController,
              readOnly: true,
              onTap: () => widget.onSelectDate(widget.eventDateController),
              decoration: InputDecoration(
                labelText: LanguageManager.instance.getTranslatedString(
                  'Date/Time',
                ),
                prefixIcon: const Icon(
                  Icons.calendar_today,
                  color: AppColors.primaryGreen,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.lightGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryGreen,
                    width: 2,
                  ),
                ),
              ),
              style: const TextStyle(color: AppColors.darkGreen),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: widget.eventDayController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: LanguageManager.instance.getTranslatedString('Day'),
                prefixIcon: const Icon(
                  Icons.event_note,
                  color: AppColors.primaryGreen,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.lightGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryGreen,
                    width: 2,
                  ),
                ),
              ),
              style: const TextStyle(color: AppColors.darkGreen),
            ),
          ),
        ),
      ],
    );
  }
}

class AnnouncementCard extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController announcementTitleController;
  final TextEditingController announcementBodyController;
  final Function() onAddAnnouncement;
  final bool isAddingAnnouncement;
  final Animation<double> fadeAnimation;

  const AnnouncementCard({
    super.key,
    required this.formKey,
    required this.announcementTitleController,
    required this.announcementBodyController,
    required this.onAddAnnouncement,
    required this.isAddingAnnouncement,
    required this.fadeAnimation,
  });

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: widget.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.campaign,
                      color: AppColors.primaryGreen,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        LanguageManager.instance.getTranslatedString(
                          'Announcements',
                        ),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGreen,
                            ),
                      ),
                    ),
                  ],
                ),
                const Divider(
                  height: 30,
                  thickness: 1,
                  color: AppColors.lightGreen,
                ),
                _buildTextField(
                  controller: widget.announcementTitleController,
                  label: LanguageManager.instance.getTranslatedString('Title'),
                  icon: Icons.subject,
                ),
                _buildTextField(
                  controller: widget.announcementBodyController,
                  label: LanguageManager.instance.getTranslatedString('Body'),
                  icon: Icons.text_snippet,
                  maxLines: 5,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: widget.isAddingAnnouncement
                      ? null
                      : () => widget.onAddAnnouncement(),
                  icon: widget.isAddingAnnouncement
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  label: Text(
                    widget.isAddingAnnouncement
                        ? LanguageManager.instance.getTranslatedString(
                            'Adding Announcement...',
                          )
                        : LanguageManager.instance.getTranslatedString(
                            'Send Announcement',
                          ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryGreen,
              width: 2,
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return LanguageManager.instance.getTranslatedString(
              'This field is required',
            );
          }
          return null;
        },
        style: const TextStyle(color: AppColors.darkGreen),
      ),
    );
  }
}
