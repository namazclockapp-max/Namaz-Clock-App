// lib/screens/representative/widgets/current_masjid_times_card.dart

import 'package:flutter/material.dart';
// Note: AppColors is now defined in masjid_representative_screen.dart
// You'll need to pass the colors or use direct color values if you want to keep this completely separate
// For now, I'm assuming AppColors is accessible, but for strict separation, you'd define them here or pass them.
// For this example, I will assume AppColors are imported from the main screen's scope,
// or that the specific color values are used directly.
// To keep it clean, I'll pass the colors explicitly or use the hardcoded ones if they are consistent.
// Let's use direct color values here for self-containment.
// If you prefer to access AppColors, ensure it's made global or passed down.

class CurrentMasjidTimesCard extends StatelessWidget {
  final Map<String, dynamic>? masjidData;
  final Animation<double> fadeAnimation;

  // Define colors locally for this widget to avoid dependency on AppColors file
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);

  const CurrentMasjidTimesCard({
    super.key,
    required this.masjidData,
    required this.fadeAnimation,
  });

  IconData _getPrayerIcon(String prayer) {
    switch (prayer.toLowerCase()) {
      case 'fajr':
        return Icons.wb_twilight;
      case 'dhuhr':
        return Icons.wb_sunny;
      case 'asr':
        return Icons.wb_sunny_outlined;
      case 'maghrib':
        return Icons.wb_twilight;
      case 'isha':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }

  Widget _buildPrayerTimeRow(String prayer, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: lightGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPrayerIcon(prayer),
                  color: primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                prayer,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: darkGreen,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGreen.withOpacity(0.1), secondaryGreen.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (masjidData == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5E8),
              Color(0xFFF1F8E9),
              Color(0xFFE8F5E8),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: lightGreen.withOpacity(0.3),
            width: 1.5,
          ),
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
                      Icons.access_time,
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
                          'Current Prayer Times',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                        Text(
                          'Active jammat times for your masjid',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: primaryGreen.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPrayerTimeRow('Fajr', masjidData!['fajrJammat'] ?? '05:00 AM'),
              _buildPrayerTimeRow('Dhuhr', masjidData!['dhuhrJammat'] ?? '12:30 PM'),
              _buildPrayerTimeRow('Asr', masjidData!['asrJammat'] ?? '04:00 PM'),
              _buildPrayerTimeRow('Maghrib', masjidData!['maghribJammat'] ?? '06:30 PM'),
              _buildPrayerTimeRow('Isha', masjidData!['ishaJammat'] ?? '08:00 PM'),
            ],
          ),
        ),
      ),
    );
  }
}