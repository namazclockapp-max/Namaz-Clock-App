// lib/screens/prayer_times_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/prayer_times_widget.dart'; // Re-use the existing widget
import 'masjids_near_me_screen.dart'; // Import the new screen

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Prayer Times Details'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            PrayerTimesWidget(), // Display your existing prayer times widget
            SizedBox(height: 10),
            // You can add more detailed prayer time info here,
            // like a full 7-day schedule, calculation methods, etc.
            // Card(
            //   margin: EdgeInsets.all(8.0),
            //   child: Padding(
            //     padding: EdgeInsets.all(16.0),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       // children: [
            //       //   Text(
            //       //     'Upcoming Features:',
            //       //     style: TextStyle(
            //       //       fontSize: 18,
            //       //       fontWeight: FontWeight.bold,
            //       //       color: primaryGreen,
            //       //     ),
            //       //   ),
            //       //   SizedBox(height: 8),
            //       //   Text('• Customizable Prayer Alerts'),
            //       //   Text('• Qibla Direction'),
            //       //   Text('• Monthly Prayer Schedule'),
            //       // ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
      // --- Floating Action Button ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact(); // Add a subtle haptic feedback
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MasjidsNearMeScreen(),
            ),
          );
        },
        label: const Text(
          'Masjids Near Me',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.location_searching, color: Colors.white),
        backgroundColor: primaryGreen,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
