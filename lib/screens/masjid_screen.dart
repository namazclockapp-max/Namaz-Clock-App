// screens/masjid_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../main.dart';
import 'request_representative_screen.dart';
import 'request_masjid_screen.dart';
import 'masjids_near_me_screen.dart';

// --- MasjidController to handle business logic and state ---
class MasjidController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController searchController = TextEditingController();

  final ValueNotifier<String?> _selectedMasjidId = ValueNotifier(null);
  final ValueNotifier<Map<String, dynamic>?> _selectedMasjidData =
      ValueNotifier(null);
  final ValueNotifier<bool> _isSubscribed = ValueNotifier(false);
  final ValueNotifier<bool> _isLoadingSubscription = ValueNotifier(false);
  final ValueNotifier<List<Map<String, dynamic>>> _masjids = ValueNotifier([]);
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  final ValueNotifier<String?> _errorMessage = ValueNotifier(null);

  StreamSubscription<List<Map<String, dynamic>>>? _masjidsSubscription;
  Timer? _searchDebouncer;

  String? get userId => _authService.getCurrentUser()?.uid;
  ValueNotifier<String?> get selectedMasjidId => _selectedMasjidId;
  ValueNotifier<Map<String, dynamic>?> get selectedMasjidData =>
      _selectedMasjidData;
  ValueNotifier<bool> get isSubscribed => _isSubscribed;
  ValueNotifier<bool> get isLoadingSubscription => _isLoadingSubscription;
  ValueNotifier<List<Map<String, dynamic>>> get masjids => _masjids;
  ValueNotifier<String> get searchQuery => _searchQuery;
  ValueNotifier<String?> get errorMessage => _errorMessage;

  MasjidController() {
    _init();
  }

  void _init() {
    _listenToMasjids();
    searchController.addListener(_onSearchChanged);
  }

  void _listenToMasjids() {
    _masjidsSubscription?.cancel();
    _masjidsSubscription = _firestoreService.getMasjids().listen(
      (masjidsList) {
        _masjids.value = masjidsList;
        _updateSelectedMasjidData();
        _updateSubscriptionStatus();
      },
      onError: (error) {
        print('Error listening to masjids stream: $error');
        _errorMessage.value = 'Failed to load masjids: $error';
      },
    );
  }

  void _onSearchChanged() {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery.value = searchController.text.toLowerCase();
    });
  }

  List<Map<String, dynamic>> getFilteredMasjids() {
    if (_searchQuery.value.isEmpty) {
      return _masjids.value;
    } else {
      return _masjids.value.where((masjid) {
        final name = (masjid['name'] as String? ?? '').toLowerCase();
        final address = (masjid['address'] as String? ?? '').toLowerCase();
        return name.contains(_searchQuery.value) ||
            address.contains(_searchQuery.value);
      }).toList();
    }
  }

  void selectMasjid(Map<String, dynamic> masjid) {
    if (masjid['id'] == _selectedMasjidId.value) {
      // Unselect if already selected
      _selectedMasjidId.value = null;
      _selectedMasjidData.value = null;
    } else {
      _selectedMasjidId.value = masjid['id'];
      _selectedMasjidData.value = masjid;
    }
    _updateSubscriptionStatus();
    notifyListeners();
  }

  Future<void> _updateSubscriptionStatus() async {
    final selectedData = _selectedMasjidData.value;
    final userId = this.userId;
    if (userId != null && selectedData != null) {
      final List<dynamic> subscribers = selectedData['subscribers'] ?? [];
      _isSubscribed.value = subscribers.contains(userId);
    } else {
      _isSubscribed.value = false;
    }
  }

  void _updateSelectedMasjidData() {
    if (_selectedMasjidId.value != null) {
      _selectedMasjidData.value = _masjids.value.firstWhere(
        (m) => m['id'] == _selectedMasjidId.value,
        orElse: () => {},
      );
    }
  }

  // Modified to return true on success or false on failure
  Future<bool> toggleSubscription() async {
    final userId = this.userId;
    final masjidId = _selectedMasjidId.value;
    if (userId == null || masjidId == null) {
      return false;
    }

    _isLoadingSubscription.value = true;
    bool success = false;
    try {
      final subscribing = !_isSubscribed.value;
      await _firestoreService.toggleMasjidSubscription(
        masjidId,
        userId,
        subscribing,
      );

      HapticFeedback.lightImpact();

      if (subscribing) {
        _scheduleMasjidNotifications(_selectedMasjidData.value!);
      } else {
        _cancelMasjidNotifications(masjidId);
      }
      success = true;
    } catch (e) {
      print('Error toggling subscription: $e');
      _errorMessage.value = 'Failed to update subscription: $e';
      success = false;
    } finally {
      _isLoadingSubscription.value = false;
    }
    return success;
  }

  // Notification Scheduling and Cancelling remain the same, but they are now methods of the controller
  Future<void> _scheduleMasjidNotifications(
    Map<String, dynamic> masjidData,
  ) async {
    final String masjidName = masjidData['name'] ?? 'Unknown Masjid';
    final String masjidId = masjidData['id'];

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    Map<String, String?> prayerTimes = {
      'Fajr': masjidData['fajrJammat'],
      'Dhuhr': masjidData['dhuhrJammat'],
      'Asr': masjidData['asrJammat'],
      'Maghrib': masjidData['maghribJammat'],
      'Isha': masjidData['ishaJammat'],
    };

    for (var entry in prayerTimes.entries) {
      final prayerName = entry.key;
      final timeString = entry.value;

      if (timeString != null && timeString.isNotEmpty) {
        try {
          final parts = timeString.split(':');
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);

          DateTime scheduledTime = DateTime(
            today.year,
            today.month,
            today.day,
            hour,
            minute,
          );

          if (scheduledTime.isBefore(now)) {
            scheduledTime = scheduledTime.add(const Duration(days: 1));
          }

          scheduledTime = scheduledTime.subtract(const Duration(minutes: 5));

          final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
            scheduledTime,
            tz.local,
          );

          int baseId = masjidId.hashCode % 10000;
          int prayerOffset = {
            'Fajr': 1,
            'Dhuhr': 2,
            'Asr': 3,
            'Maghrib': 4,
            'Isha': 5,
          }[prayerName]!;
          int notificationId = baseId + prayerOffset;

          await flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            '$masjidName - $prayerName Prayer',
            'It\'s time for $prayerName prayer at $masjidName.',
            tzScheduledTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'prayer_time_channel',
                'Prayer Times',
                channelDescription: 'Notifications for daily prayer times',
                importance: Importance.high,
                priority: Priority.high,
                ticker: 'ticker',
                sound: RawResourceAndroidNotificationSound('adhan_sound'),
              ),
              iOS: DarwinNotificationDetails(sound: 'adhan_sound.aiff'),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: 'masjid_prayer_time_$masjidId',
          );
          print(
            'Scheduled notification for $prayerName at $timeString: $masjidName (ID: $notificationId)',
          );
        } catch (e) {
          print(
            'Error scheduling notification for $prayerName at $timeString: $e',
          );
        }
      }
    }
  }

  Future<void> _cancelMasjidNotifications(String masjidId) async {
    int baseId = masjidId.hashCode % 10000;
    for (int i = 1; i <= 5; i++) {
      int notificationId = baseId + i;
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      print(
        'Cancelled notification with ID: $notificationId for masjid: $masjidId',
      );
    }
  }

  @override
  void dispose() {
    _masjidsSubscription?.cancel();
    _searchDebouncer?.cancel();
    searchController.dispose();
    _selectedMasjidId.dispose();
    _selectedMasjidData.dispose();
    _isSubscribed.dispose();
    _isLoadingSubscription.dispose();
    _masjids.dispose();
    _searchQuery.dispose();
    _errorMessage.dispose();
    super.dispose();
  }
}

// --- MasjidScreen remains a StatefulWidget, but with a cleaner build method ---
class MasjidScreen extends StatefulWidget {
  const MasjidScreen({super.key});

  @override
  State<MasjidScreen> createState() => _MasjidScreenState();
}

class _MasjidScreenState extends State<MasjidScreen> {
  late final MasjidController _controller;

  // Define colors from your theme for consistency
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _controller = MasjidController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Masjids'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return Column(
              children: [
                _buildMasjidListSection(),
                const SizedBox(height: 20),
                ValueListenableBuilder<Map<String, dynamic>?>(
                  valueListenable: _controller.selectedMasjidData,
                  builder: (context, selectedMasjidData, child) {
                    if (selectedMasjidData != null &&
                        selectedMasjidData.isNotEmpty) {
                      return _buildSelectedMasjidCard(selectedMasjidData);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'requestMasjidFab',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RequestMasjidScreen(),
                ),
              );
            },
            label: const Text(
              'Request New Masjid',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            icon: const Icon(Icons.add_location_alt, color: Colors.white),
            backgroundColor: primaryGreen,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'masjidsNearMeFab',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MasjidsNearMeScreen(),
                ),
              );
            },
            label: const Text(
              'Masjids Near Me',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            icon: const Icon(Icons.location_searching, color: Colors.white),
            backgroundColor: primaryGreen,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildMasjidListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller.searchController,
          decoration: InputDecoration(
            labelText: 'Search Masjids',
            hintText: 'Enter masjid name or address',
            prefixIcon: const Icon(Icons.search, color: primaryGreen),
            suffixIcon: ValueListenableBuilder<String>(
              valueListenable: _controller.searchQuery,
              builder: (context, searchQuery, child) {
                if (searchQuery.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.clear, color: primaryGreen),
                    onPressed: () => _controller.searchController.clear(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: lightGreen.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: lightGreen.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGreen, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: const TextStyle(color: darkGreen),
          cursorColor: primaryGreen,
        ),
        const SizedBox(height: 16),
        Text(
          'Available Masjids',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: _controller.masjids,
          builder: (context, masjidsList, child) {
            if (masjidsList.isEmpty) {
              return _buildEmptyState(
                'No masjids available. Be the first to add one!',
                Icons.mosque,
              );
            }

            final filteredMasjids = _controller.getFilteredMasjids();

            if (filteredMasjids.isEmpty &&
                _controller.searchQuery.value.isNotEmpty) {
              return _buildEmptyState(
                'No masjids match your search.',
                Icons.search_off,
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredMasjids.length,
              itemBuilder: (context, index) {
                final masjid = filteredMasjids[index];
                return _buildMasjidCardItem(masjid);
              },
            );
          },
        ),
        ValueListenableBuilder<String?>(
          valueListenable: _controller.errorMessage,
          builder: (context, errorMessage, child) {
            if (errorMessage != null) {
              Future.microtask(() {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(errorMessage)));
                  _controller.errorMessage.value = null; // Clear the message
                }
              });
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildMasjidCardItem(Map<String, dynamic> masjid) {
    return ValueListenableBuilder<String?>(
      valueListenable: _controller.selectedMasjidId,
      builder: (context, selectedMasjidId, child) {
        final bool isSelected = selectedMasjidId == masjid['id'];
        return GestureDetector(
          onTap: () {
            _controller.selectMasjid(masjid);
            HapticFeedback.lightImpact();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? lightGreen.withOpacity(0.2)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? primaryGreen.withOpacity(0.5)
                    : lightGreen.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryGreen.withOpacity(0.2)
                        : primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.mosque,
                    color: primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        masjid['name'] ?? 'N/A',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        masjid['address'] ?? 'N/A',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: primaryGreen),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedMasjidCard(Map<String, dynamic> masjidData) {
    final bool hasRepresentative =
        masjidData['representativeId'] != null &&
        masjidData['representativeId'].isNotEmpty;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 20),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: primaryGreen, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    masjidData['name'] ?? 'Selected Masjid',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              masjidData['address']?.isNotEmpty == true
                  ? masjidData['address']
                  : 'Address not available',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
            const Divider(height: 30, thickness: 1, color: lightGreen),
            Text(
              'Jammat Times Today',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 10),
            _buildPrayerTimeRow(
              'Fajr',
              masjidData['fajr'] ?? 'N/A',
              isJammat: true,
            ),
            _buildPrayerTimeRow(
              'Dhuhr',
              masjidData['dhuhr'] ?? 'N/A',
              isJammat: true,
            ),
            _buildPrayerTimeRow(
              'Asr',
              masjidData['asr'] ?? 'N/A',
              isJammat: true,
            ),
            _buildPrayerTimeRow(
              'Maghrib',
              masjidData['maghrib'] ?? 'N/A',
              isJammat: true,
            ),
            _buildPrayerTimeRow(
              'Isha',
              masjidData['isha'] ?? 'N/A',
              isJammat: true,
            ),
            _buildPrayerTimeRow(
              'Jummah',
              masjidData['jummah'] ?? 'N/A',
              isJammat: true,
            ),

            const SizedBox(height: 20),
            Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.isLoadingSubscription,
                builder: (context, isLoading, child) {
                  if (isLoading) {
                    return const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                    );
                  }
                  return ValueListenableBuilder<bool>(
                    valueListenable: _controller.isSubscribed,
                    builder: (context, isSubscribed, child) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSubscribed
                                ? [Colors.red[400]!, Colors.red[700]!]
                                : [secondaryGreen, primaryGreen],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: isSubscribed
                                  ? Colors.red.withOpacity(0.3)
                                  : primaryGreen.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final success = await _controller
                                .toggleSubscription();
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isSubscribed
                                        ? 'Unsubscribed!'
                                        : 'Subscribed!',
                                  ),
                                  backgroundColor: isSubscribed
                                      ? Colors.red
                                      : primaryGreen,
                                ),
                              );
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Failed to update subscription.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            isSubscribed
                                ? Icons.notifications_off
                                : Icons.notifications_active,
                            color: Colors.white,
                          ),
                          label: Text(
                            isSubscribed
                                ? 'Unsubscribe for Notifications'
                                : 'Subscribe for Notifications',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: OutlinedButton.icon(
                onPressed: hasRepresentative
                    ? null
                    : () {
                        if (_controller.selectedMasjidId.value != null &&
                            _controller.selectedMasjidData.value != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RequestRepresentativeScreen(
                                masjidId: _controller.selectedMasjidId.value!,
                                masjidName: _controller
                                    .selectedMasjidData
                                    .value!['name'],
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select a masjid to request representative access.',
                              ),
                            ),
                          );
                        }
                      },
                icon: Icon(
                  Icons.person_add_alt_1,
                  color: hasRepresentative
                      ? const Color.fromARGB(255, 212, 14, 0)
                      : primaryGreen,
                ),
                label: Text(
                  hasRepresentative
                      ? 'Representative Already Assigned'
                      : 'Request Representative Access',
                  style: TextStyle(
                    color: hasRepresentative
                        ? const Color.fromARGB(255, 212, 14, 0)
                        : primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: hasRepresentative ? Colors.grey : primaryGreen,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimeRow(
    String prayerName,
    String time, {
    bool isJammat = false,
  }) {
    // This widget is part of the UI and does not require a state.
    // It's fine to keep it as a private method within the State class.
    IconData _getPrayerIcon(String prayer) {
      switch (prayer.toLowerCase()) {
        case 'fajr':
          return Icons.wb_twilight;
        case 'dhuhr':
          return Icons.wb_sunny;
        case 'asr':
          return Icons.wb_sunny_outlined;
        case 'maghrib':
          return Icons.nightlight_round;
        case 'isha':
          return Icons.nightlight_round;
        default:
          return Icons.access_time;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(_getPrayerIcon(prayerName), color: darkGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                prayerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: darkGreen,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isJammat
                  ? primaryGreen.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isJammat
                  ? Border.all(color: primaryGreen, width: 1)
                  : null,
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isJammat ? primaryGreen : darkGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  lightGreen.withOpacity(0.1),
                  primaryGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 64, color: primaryGreen.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: primaryGreen.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
