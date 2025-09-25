import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Firestore Service
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> _subscribedMasjids = []; // masjid data list
  bool _isLoading = true;

  // Notification Settings
  bool _prayerReminders = true;
  bool _masjidUpdates = true;
  bool _generalNotifications = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _quietHours = false;
  bool _priorityNotifications = true;

  String _selectedRingtone = 'Default';
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 6, minute: 0);

  // Green gradient color scheme
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchSubscribedMasjidTimings(); // 🔥 firestore data load
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

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _fetchSubscribedMasjidTimings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final subscribedMasjids = await _firestoreService.getSubscribedMasjids(uid);

    List<Map<String, dynamic>> masjidList = [];

    for (var masjid in subscribedMasjids) {
      final masjidData = await _firestoreService.getMasjidById(masjid["id"]);
      if (masjidData != null) {
        masjidList.add({
          "name": masjidData["name"] ?? "Unknown",
          "address": masjidData["address"] ?? "",
          "prayerTimes": masjidData["prayerTimes"] ?? {},
        });
      }
    }

    setState(() {
      _subscribedMasjids = masjidList;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: secondaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5E8),
              Color(0xFFF1F8E9),
              Color(0xFFE8F5E8),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      _buildSubscribedMasjidsSection(),
                    const SizedBox(height: 24),
                    _buildNotificationSettings(),
                    const SizedBox(height: 24),
                    _buildSoundSettings(),
                    const SizedBox(height: 24),
                    _buildAdvancedSettings(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 Show Subscribed Masjids Section
  Widget _buildSubscribedMasjidsSection() {
    if (_subscribedMasjids.isEmpty) {
      return const Text("No subscribed masjids found.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _subscribedMasjids.map((masjid) {
        return ListTile(
          leading: const Icon(Icons.mosque, color: primaryGreen),
          title: Text(masjid["name"]),
          subtitle: Text(masjid["address"]),
        );
      }).toList(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                lightGreen.withOpacity(0.1),
                accentGreen.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lightGreen.withOpacity(0.2), width: 1),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: primaryGreen),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        const SizedBox(width: 16),
        // Add the Hero widget here with the same tag as in home_screen.dart
        Hero(
          tag:
              'notification-icon-hero', // Ensure this tag is unique and matches the one in home_screen.dart
          child: Container(
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
              Icons.notifications,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              Text(
                'Manage your notification preferences',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: primaryGreen.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFDFA)],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryGreen.withOpacity(0.1),
                        lightGreen.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Notification Types',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildNotificationTile(
              icon: Icons.access_time,
              title: 'Prayer Time Reminders',
              subtitle: 'Get notified before prayer times',
              value: _prayerReminders,
              onChanged: (value) {
                setState(() {
                  _prayerReminders = value;
                });
                _showSnackBar(
                  'Prayer reminders ${value ? 'enabled' : 'disabled'}',
                );
              },
            ),
            _buildNotificationTile(
              icon: Icons.mosque,
              title: 'Masjid Updates',
              subtitle: 'Updates from subscribed masjids',
              value: _masjidUpdates,
              onChanged: (value) {
                setState(() {
                  _masjidUpdates = value;
                });
                _showSnackBar(
                  'Masjid updates ${value ? 'enabled' : 'disabled'}',
                );
              },
            ),
            _buildNotificationTile(
              icon: Icons.info,
              title: 'General Notifications',
              subtitle: 'App updates and announcements',
              value: _generalNotifications,
              onChanged: (value) {
                setState(() {
                  _generalNotifications = value;
                });
                _showSnackBar(
                  'General notifications ${value ? 'enabled' : 'disabled'}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundSettings() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFDFA)],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        secondaryGreen.withOpacity(0.1),
                        lightGreen.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.volume_up, color: secondaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Sound & Vibration',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildNotificationTile(
              icon: Icons.volume_up,
              title: 'Sound',
              subtitle: 'Play notification sounds',
              value: _soundEnabled,
              onChanged: (value) {
                setState(() {
                  _soundEnabled = value;
                });
                _showSnackBar('Sound ${value ? 'enabled' : 'disabled'}');
              },
            ),
            _buildNotificationTile(
              icon: Icons.vibration,
              title: 'Vibration',
              subtitle: 'Vibrate on notifications',
              value: _vibrationEnabled,
              onChanged: (value) {
                setState(() {
                  _vibrationEnabled = value;
                });
                _showSnackBar('Vibration ${value ? 'enabled' : 'disabled'}');
                if (value) HapticFeedback.mediumImpact();
              },
            ),
            const SizedBox(height: 16),
            _buildRingtoneSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFDFA)],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentGreen.withOpacity(0.1),
                        lightGreen.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.settings, color: accentGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Advanced Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildNotificationTile(
              icon: Icons.bedtime,
              title: 'Quiet Hours',
              subtitle: 'Silence notifications during set hours',
              value: _quietHours,
              onChanged: (value) {
                setState(() {
                  _quietHours = value;
                });
                if (value) {
                  _showQuietHoursDialog();
                }
                _showSnackBar('Quiet hours ${value ? 'enabled' : 'disabled'}');
              },
            ),
            _buildNotificationTile(
              icon: Icons.priority_high,
              title: 'Priority Notifications',
              subtitle: 'Show important notifications even in quiet hours',
              value: _priorityNotifications,
              onChanged: (value) {
                setState(() {
                  _priorityNotifications = value;
                });
                _showSnackBar(
                  'Priority notifications ${value ? 'enabled' : 'disabled'}',
                );
              },
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              icon: Icons.history,
              title: 'Notification History',
              subtitle: 'View recent notifications',
              onTap: () => _showNotificationHistory(),
            ),
            const SizedBox(height: 16), // Added spacing between action buttons
            _buildActionButton(
              icon: Icons.science,
              title: 'Test Notification',
              subtitle: 'Send a test notification',
              onTap: () => _sendTestNotification(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightGreen.withOpacity(0.05), accentGreen.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGreen.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryGreen, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryGreen.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (newValue) {
                HapticFeedback.lightImpact();
                onChanged(newValue);
              },
              activeColor: secondaryGreen,
              activeTrackColor: lightGreen.withOpacity(0.3),
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingtoneSelector() {
    final ringtones = ['Default', 'Adhan', 'Bell', 'Chime', 'Gentle'];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightGreen.withOpacity(0.05), accentGreen.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGreen.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.music_note, color: primaryGreen, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Sound',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedRingtone,
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryGreen.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: PopupMenuButton<String>(
                icon: Icon(Icons.arrow_drop_down, color: primaryGreen),
                onSelected: (String value) {
                  setState(() {
                    _selectedRingtone = value;
                  });
                  _showSnackBar('Ringtone changed to $value');
                  HapticFeedback.lightImpact();
                },
                itemBuilder: (BuildContext context) {
                  return ringtones.map((String ringtone) {
                    return PopupMenuItem<String>(
                      value: ringtone,
                      child: Row(
                        children: [
                          Icon(
                            _selectedRingtone == ringtone
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: primaryGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(ringtone),
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightGreen.withOpacity(0.05), accentGreen.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGreen.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryGreen, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryGreen.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: primaryGreen.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuietHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set Quiet Hours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bedtime),
              title: const Text('Start Time'),
              subtitle: Text(_quietStart.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _quietStart,
                );
                if (time != null) {
                  // Rebuild the dialog content to show the new time
                  Navigator.of(context).pop();
                  setState(() {
                    _quietStart = time;
                  });
                  _showQuietHoursDialog();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny),
              title: const Text('End Time'),
              subtitle: Text(_quietEnd.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _quietEnd,
                );
                if (time != null) {
                  // Rebuild the dialog content to show the new time
                  Navigator.of(context).pop();
                  setState(() {
                    _quietEnd = time;
                  });
                  _showQuietHoursDialog();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar(
                'Quiet hours set from ${_quietStart.format(context)} to ${_quietEnd.format(context)}',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNotificationHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notification History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              _buildHistoryItem(
                'Prayer Time Reminder',
                'Maghrib in 10 minutes',
                '2 hours ago',
              ),
              _buildHistoryItem(
                'Masjid Update',
                'Prayer times updated for Al-Noor Masjid',
                '1 day ago',
              ),
              _buildHistoryItem(
                'Prayer Time Reminder',
                'Asr in 10 minutes',
                '1 day ago',
              ),
              _buildHistoryItem(
                'App Update',
                'New features available',
                '3 days ago',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: primaryGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String message, String time) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.notifications, color: primaryGreen, size: 16),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(fontSize: 12)),
          Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
      dense: true,
    );
  }

  void _sendTestNotification() {
    _showSnackBar('Test notification sent!');
    HapticFeedback.mediumImpact();
  }
}
