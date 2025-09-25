import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';  // <-- Add this import

class UserNotificationsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> subscribedMasjids;

  const UserNotificationsScreen({
    super.key,
    required this.subscribedMasjids,
  });

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;

    /// Save masjid data locally
    _saveMasjidsToLocal();

    /// Schedule notifications for all prayer times
    _scheduleAllPrayerNotifications();
  }

  /// Save subscribed masjids to SharedPreferences
  Future<void> _saveMasjidsToLocal() async {
    if (widget.subscribedMasjids.isNotEmpty) {
      await StorageService.saveSubscribedMasjids(widget.subscribedMasjids);
      debugPrint("Masjid data saved locally!");
    }
  }

  /// Schedule notifications for each prayer time
  Future<void> _scheduleAllPrayerNotifications() async {
    for (var masjid in widget.subscribedMasjids) {
      final masjidName = masjid['name'] ?? 'Unknown Masjid';
      final prayerTimes = masjid['prayerTimes'] ?? {};

      prayerTimes.forEach((prayerName, timeString) async {
        if (timeString != null && timeString != 'N/A') {
          try {
            final format = DateFormat('hh:mm a');
            final parsedTime = format.parse(timeString);
            final now = DateTime.now();

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
          } catch (e) {
            debugPrint(
                'Error scheduling $prayerName notification for $masjidName: $e');
          }
        }
      });
    }
  }

  /// Mark admin feedback as acknowledged
  Future<void> _markAsAcknowledged(String docId) async {
    try {
      await _firestore.collection('feedback').doc(docId).update({
        'userAcknowledgedReply': true,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification marked as read.')),
      );
    } catch (e) {
      debugPrint('Error marking reply as acknowledged: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as read: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Notifications'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view your notifications.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscriptions & Notifications'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.subscribedMasjids.isNotEmpty) ...[
                const Text(
                  'Subscribed Masjids',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.subscribedMasjids.length,
                  itemBuilder: (context, index) {
                    final masjid = widget.subscribedMasjids[index];
                    final prayerTimes = masjid['prayerTimes'] ?? {};
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text(
                          masjid['name'] ?? 'Unknown Masjid',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fajr: ${prayerTimes['fajr'] ?? 'N/A'}'),
                            Text('Dhuhr: ${prayerTimes['dhuhr'] ?? 'N/A'}'),
                            Text('Asr: ${prayerTimes['asr'] ?? 'N/A'}'),
                            Text('Maghrib: ${prayerTimes['maghrib'] ?? 'N/A'}'),
                            Text('Isha: ${prayerTimes['isha'] ?? 'N/A'}'),
                            Text('Jummah: ${prayerTimes['jummah'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              const Text(
                'Admin Replies',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('feedback')
                    .where('userId', isEqualTo: _currentUser!.uid)
                    .where('isReplied', isEqualTo: true)
                    .where('userAcknowledgedReply', isEqualTo: false)
                    .orderBy('repliedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error.toString()}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('You have no new replies.');
                  }

                  final notifications = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final doc = notifications[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final feedbackText =
                          data['feedback'] ?? 'No feedback text';
                      final adminReply =
                          data['adminReply'] ?? 'No reply text';
                      final repliedAt =
                          (data['repliedAt'] as Timestamp?)?.toDate();
                      String formattedReplyDate = repliedAt != null
                          ? DateFormat('MMM dd, yyyy - hh:mm a')
                              .format(repliedAt)
                          : 'N/A';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Admin Reply to your Feedback:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your feedback: "$feedbackText"',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Reply: "$adminReply"',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Replied on: $formattedReplyDate',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: TextButton.icon(
                                  onPressed: () => _markAsAcknowledged(doc.id),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Mark as Read'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
