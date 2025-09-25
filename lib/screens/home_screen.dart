// lib/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:namaz_clock_app/screens/admin/admin_panel_screen.dart';
import 'package:namaz_clock_app/screens/language_manager.dart';
import 'package:namaz_clock_app/screens/masjid_screen.dart';

import 'package:namaz_clock_app/screens/representative/masjid_representative_screen.dart';
import 'package:namaz_clock_app/screens/user_learning_videos.dart';
import 'package:namaz_clock_app/screens/user_notifications_screen.dart';
import 'package:namaz_clock_app/screens/prayer_times_screen.dart';
import 'package:namaz_clock_app/screens/profile_screen.dart';
import 'package:namaz_clock_app/screens/qibla_direction_screen.dart';
import 'package:namaz_clock_app/services/auth_service.dart';
import 'package:namaz_clock_app/services/firestore_service.dart';
import 'package:namaz_clock_app/screens/subscribed_masjids_screen.dart'; // ADD THIS IMPORT
// Corrected import: No 'hide' clause needed now that CustomBottomNavigationBar is standalone
import 'widgets/custom_bottom_navigation_bar.dart';
import 'widgets/prayer_times_widget.dart';
import 'package:provider/provider.dart';
import 'package:namaz_clock_app/screens/masjids_near_me_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  User? _currentUser;
  String? _userRole;
  int _unreadNotificationsCount = 0;

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  int _currentIndex = 0;

  // Prayer time calculation variables for home screen display
  Coordinates? _userCoordinates;
  late CalculationParameters _params;
  PrayerTimes? _authenticPrayerTimes;
  final HijriCalendar _islamicDate = HijriCalendar.now();
  // Changed types from String? to Prayer?
  Prayer? _currentPrayerEnum;
  Prayer? _nextPrayerEnum;
  Duration? _timeUntilNextPrayer;

  // Defined colors once here for consistency and easy access by children
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);

  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  StreamSubscription<DocumentSnapshot>? _userRoleSubscription;

  @override
  void initState() {
    super.initState();
    _setupFCM();
    _initAnimations();
    _initPrayerTimes();
    _determinePosition();

    _currentUser = _auth.currentUser;
    _listenToAuthChanges();
    _listenForNotifications();

    // Update prayer timer every minute
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _updatePrayerTimer();
      }
    });
  }

  // FCM se related ye dono functions yahan add karein
  Future<void> _setupFCM() async {
    // Token ko request karein
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print("FCM Token: $token");
      // Token ko Firestore mein save karein
      _saveFCMTokenToFirestore(token);
    }

    // Token change hone par ye function call hoga
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print("FCM Token refreshed: $newToken");
      _saveFCMTokenToFirestore(newToken);
    });
  }

  Future<void> _saveFCMTokenToFirestore(String token) async {
    if (_currentUser != null) {
      try {
        await _firestore.collection('users').doc(_currentUser!.uid).update({
          'fcmToken': token,
        });
        print('FCM Token successfully saved to Firestore.');
      } catch (e) {
        print('Error saving FCM Token: $e');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _listenToAuthChanges() {
    _auth.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          if (_currentUser != null) {
            _listenForNotifications();
            _listenForUserRole();
          } else {
            _notificationSubscription?.cancel();
            _userRoleSubscription?.cancel();
            _unreadNotificationsCount = 0;
            _userRole = null;
          }
        });
      }
    });
  }

  void _listenForUserRole() {
    _userRoleSubscription?.cancel();

    if (_currentUser == null) {
      setState(() {
        _userRole = null;
      });
      return;
    }

    _userRoleSubscription =
        _firestoreService.getUserDocumentStream(_currentUser!.uid).listen((
          snapshot,
        ) {
          if (mounted) {
            if (snapshot.exists && snapshot.data() != null) {
              final data = snapshot.data()!;
              setState(() {
                _userRole = data['role'] as String? ?? 'user';
                print(
                  'User role updated to: $_userRole for user ${_currentUser!.uid}',
                );
              });
            } else {
              setState(() {
                _userRole = 'user';
                print(
                  'User document not found or role not set, defaulting to user for ${_currentUser!.uid}',
                );
              });
            }
          }
        })..onError((error) {
          print('Error listening to user role stream: $error');
          setState(() {
            _userRole = 'user';
          });
        });
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _listenForNotifications() {
    _notificationSubscription?.cancel();
    if (_currentUser == null) {
      setState(() {
        _unreadNotificationsCount = 0;
      });
      return;
    }

    _notificationSubscription = _firestore
        .collection('feedback')
        .where('userId', isEqualTo: _currentUser!.uid)
        .where('isReplied', isEqualTo: true)
        .where('userAcknowledgedReply', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _unreadNotificationsCount = snapshot.docs.length;
            });
          }
        });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _notificationSubscription?.cancel();
    _userRoleSubscription?.cancel();
    super.dispose();
  }

  // --- Location Services ---
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _userCoordinates = Coordinates(position.latitude, position.longitude);
    });
    _calculateAuthenticPrayerTimes();
  }

  // --- Authentic Prayer Time Calculation ---
  void _initPrayerTimes() {
    _params = CalculationMethod.karachi.getParameters();
    _params.madhab = Madhab.hanafi;
  }

  void _calculateAuthenticPrayerTimes() {
    if (_userCoordinates == null) return;

    setState(() {
      _authenticPrayerTimes = PrayerTimes(
        _userCoordinates!,
        DateComponents(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ),
        _params,
      );
    });
    _updatePrayerTimer();
  }

  void _updatePrayerTimer() {
    if (_authenticPrayerTimes == null) return;

    final now = DateTime.now();
    // Assigning Prayer enum directly
    _currentPrayerEnum = _authenticPrayerTimes!.currentPrayer();
    _nextPrayerEnum = _authenticPrayerTimes!.nextPrayer();

    DateTime? nextPrayerTime;
    // Using the Prayer enum in the switch statement
    switch (_nextPrayerEnum) {
      case Prayer.fajr:
        nextPrayerTime = _authenticPrayerTimes!.fajr;
        break;
      case Prayer.dhuhr:
        nextPrayerTime = _authenticPrayerTimes!.dhuhr;
        break;
      case Prayer.asr:
        nextPrayerTime = _authenticPrayerTimes!.asr;
        break;
      case Prayer.maghrib:
        nextPrayerTime = _authenticPrayerTimes!.maghrib;
        break;
      case Prayer.isha:
        nextPrayerTime = _authenticPrayerTimes!.isha;
        break;
      case Prayer.none: // Handle the case where nextPrayer is Prayer.none
      default:
        // If no next prayer for today, set to Fajr of tomorrow
        // This might happen late at night after Isha
        final tomorrowAuthenticPrayerTimes = PrayerTimes(
          _userCoordinates!,
          DateComponents(
            DateTime.now().add(const Duration(days: 1)).year,
            DateTime.now().add(const Duration(days: 1)).month,
            DateTime.now().add(const Duration(days: 1)).day,
          ),
          _params,
        );
        nextPrayerTime = tomorrowAuthenticPrayerTimes.fajr;
        break;
    }

    if (nextPrayerTime != null) {
      _timeUntilNextPrayer = nextPrayerTime.difference(now);
      if (_timeUntilNextPrayer!.isNegative) {
        // This case should ideally not happen if logic for nextPrayer is sound,
        // but adding a safeguard.
        // If the calculated next prayer time is in the past, consider it for the next day.
        nextPrayerTime = nextPrayerTime.add(const Duration(days: 1));
        _timeUntilNextPrayer = nextPrayerTime.difference(now);
      }
      // Namaz ke waqt se 5 minutes pehle notification dikhane ka code
      if (_timeUntilNextPrayer!.inMinutes <= 5 &&
          _timeUntilNextPrayer!.inMinutes >= 0) {
        final prayerName = _nextPrayerEnum.toString().split('.').last;
        // Apne notification service function ko yahan call karein
        // misal ke taur par:
        // NotificationService.showPrayerNotification(prayerName);
      }
    } else {
      _timeUntilNextPrayer = null;
    }

    setState(() {});
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    HapticFeedback.lightImpact();
  }

  void _onNotificationIconTapped() async {
    // Asynchronous function banaya
    HapticFeedback.lightImpact();
    print('Notification icon tapped!');

    // 1. Check karein ke user logged in hai
    if (_currentUser != null) {
      // 2. Firestore se subscribed masjids ka data fetch karein
      final subscribedMasjids = await _firestoreService.getSubscribedMasjids(
        _currentUser!.uid,
      );

      // 3. UserNotificationsScreen ko data ke saath navigate karein
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserNotificationsScreen(
            subscribedMasjids:
                subscribedMasjids, // Data yahan pass kiya gaya hai
          ),
        ),
      );
    } else {
      // Agar user logged in nahi hai to handle karein
      print('User not logged in.');
      // Misaal ke tor par, login screen par navigate karein ya message dikhayein
    }
  }

  void _onQiblaIconTapped() {
    HapticFeedback.lightImpact();
    print('Qibla icon tapped!');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QiblaDirectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access LanguageManager via Provider
    final languageManager = Provider.of<LanguageManager>(context);

    // Show a loading indicator if the user role is not yet determined
    if (_currentUser != null && _userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    // Determine the list of pages based on the user's role
    List<Widget> pages;
    if (_userRole == 'admin') {
      pages = [
        _buildHomePageContent(languageManager),
        const SubscribedMasjidsScreen(), // ADDED: New subscribed masjids screen
        const MasjidScreen(),
        const PrayerTimesScreen(),
        const AdminPanelScreen(),
      ];
    } else if (_userRole == 'representative') {
      pages = [
        _buildHomePageContent(languageManager),
        const SubscribedMasjidsScreen(), // ADDED: New subscribed masjids screen
        const MasjidScreen(),
        const PrayerTimesScreen(),
        const MasjidRepresentativeScreen(masjidId: ''),
      ];
    } else {
      // Default to 'user' or if _userRole is null (not logged in)
      pages = [
        _buildHomePageContent(languageManager),
        const SubscribedMasjidsScreen(), // ADDED: New subscribed masjids screen
        const MasjidScreen(),
        const PrayerTimesScreen(),
        const ProfileScreen(),
      ];
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        primaryGreen: primaryGreen, // Pass colors
        lightGreen: lightGreen, // Pass colors
        languageManager: languageManager,
        userRole: _userRole, // Pass user role to the nav bar
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MasjidsNearMeScreen(),
                  ),
                );
              },
              label: Text(
                languageManager.getTranslatedString('Masjids Near Me'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.location_searching, color: Colors.white),
              backgroundColor: primaryGreen,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Extract the main home screen content into a separate method
  Widget _buildHomePageContent(LanguageManager languageManager) {
    // UPDATED: Check for null prayer times and show a loading indicator
    if (_authenticPrayerTimes == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: primaryGreen),
            const SizedBox(height: 16),
            Text(
              languageManager.getTranslatedString(
                'Calculating prayer times...',
              ),
              style: const TextStyle(color: darkGreen),
            ),
            const SizedBox(height: 8),
            Text(
              languageManager.getTranslatedString(
                'Please ensure location services are enabled.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: darkGreen.withOpacity(0.6), fontSize: 12),
            ),
          ],
        ),
      );
    }

    // ORIGINAL: Rest of the widget tree, which will now only be built if _authenticPrayerTimes is not null
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          elevation: 0,
          backgroundColor: primaryGreen,
          leadingWidth: 100,
          leading: Row(
            children: [
              // Apply the Hero widget here with a unique tag
              Hero(
                tag: 'notification-icon-hero',
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                      tooltip: languageManager.getTranslatedString(
                        'Notifications',
                      ),
                      onPressed: _onNotificationIconTapped,
                    ),
                    if (_unreadNotificationsCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '$_unreadNotificationsCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.lightbulb, color: Colors.white),
                tooltip: 'Learning',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserLearningVideos(),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            // Language Selection Dropdown
            // PopupMenuButton<String>(
            //   icon: const Icon(Icons.language, color: Colors.white),
            //   tooltip: languageManager.getTranslatedString('Select Language'),
            //   onSelected: (String languageCode) {
            //     languageManager.changeLanguage(languageCode);
            //   },
            //   itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            //     PopupMenuItem<String>(
            //       value: 'en',
            //       child: Text(languageManager.getTranslatedString('English')),
            //     ),
            //     PopupMenuItem<String>(
            //       value: 'ur',
            //       child: Text(languageManager.getTranslatedString('Urdu')),
            //     ),
            //     PopupMenuItem<String>(
            //       value: 'ar',
            //       child: Text(languageManager.getTranslatedString('Arabic')),
            //     ),
            //   ],
            // ),
            IconButton(
              icon: const Icon(Icons.explore, color: Colors.white),
              tooltip: languageManager.getTranslatedString('Qibla Direction'),
              onPressed: _onQiblaIconTapped,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                languageManager.getTranslatedString('Namaz Clock'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryGreen, secondaryGreen, lightGreen],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(
                              'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="20" cy="20" r="2" fill="white"/><circle cx="80" cy="20" r="2" fill="white"/><circle cx="20" cy="80" r="2" fill="white"/><circle cx="80" cy="80" r="2" fill="white"/><circle cx="50" cy="50" r="2" fill="white"/></svg>',
                            ),
                            repeat: ImageRepeat.repeat,
                          ),
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
                          Icons.access_time,
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
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildIslamicDateCard(languageManager),
                ),
              ),
              const SizedBox(height: 20),
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _slideController,
                        curve: const Interval(
                          0.2,
                          1.0,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                    ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: PrayerTimesWidget(
                    prayerTimes: _authenticPrayerTimes!,
                    nextPrayer: _nextPrayerEnum ?? Prayer.none,
                    currentPrayer: _currentPrayerEnum ?? Prayer.none,
                    timeUntilNextPrayer: _timeUntilNextPrayer ?? Duration.zero,
                    languageManager: languageManager,
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildIslamicDateCard(LanguageManager languageManager) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9), Color(0xFFE8F5E8)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lightGreen.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryGreen, secondaryGreen],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageManager.getTranslatedString('Islamic Date'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: primaryGreen.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_islamicDate.toFormat("dd MMMM")} ${_islamicDate.hYear} AH',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
