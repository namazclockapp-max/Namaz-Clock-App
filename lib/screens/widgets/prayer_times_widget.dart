import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:namaz_clock_app/screens/language_manager.dart';

class PrayerTimesWidget extends StatelessWidget {
  final PrayerTimes prayerTimes;
  final Prayer currentPrayer;
  final Prayer nextPrayer;
  final Duration timeUntilNextPrayer;
  final dynamic languageManager;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);

  const PrayerTimesWidget({
    super.key,
    required this.prayerTimes,
    required this.currentPrayer,
    required this.nextPrayer,
    required this.timeUntilNextPrayer,
    required this.languageManager,
  });

  Widget _buildPrayerTimeRow(BuildContext context, String prayerName, DateTime? time) {
    final bool isCurrentOrNext =
        (prayerName.toLowerCase() == currentPrayer.name) ||
        (prayerName.toLowerCase() == nextPrayer.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentOrNext
            ? lightGreen.withOpacity(0.1)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentOrNext
              ? primaryGreen.withOpacity(0.3)
              : lightGreen.withOpacity(0.2),
          width: isCurrentOrNext ? 1.5 : 1,
        ),
        boxShadow: isCurrentOrNext
            ? [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCurrentOrNext
                      ? primaryGreen.withOpacity(0.2)
                      : primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPrayerIcon(prayerName),
                  color: primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                prayerName,
                style: TextStyle(
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
                colors: isCurrentOrNext
                    ? [secondaryGreen, primaryGreen]
                    : [
                        primaryGreen.withOpacity(0.1),
                        secondaryGreen.withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time != null
                  ? DateFormat('hh:mm a').format(time)
                  : 'N/A',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCurrentOrNext ? Colors.white : darkGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lightGreen.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [darkGreen, primaryGreen],
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
                  Icons.access_time_filled,
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
                      'Upcoming Prayer',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                    ),
                    Text(
                      '${nextPrayer.name.capitalize()} in ${_formatDuration(timeUntilNextPrayer)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: primaryGreen.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPrayerTimeRow(context, 'Fajr', prayerTimes.fajr),
          _buildPrayerTimeRow(context, 'Dhuhr', prayerTimes.dhuhr),
          _buildPrayerTimeRow(context, 'Asr', prayerTimes.asr),
          _buildPrayerTimeRow(context, 'Maghrib', prayerTimes.maghrib),
          _buildPrayerTimeRow(context, 'Isha', prayerTimes.isha),
        ],
      ),
    );
  }
}

extension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
