// lib/screens/representative/widgets/masjid_statistics_card.dart

import 'package:flutter/material.dart';
// Note: AppColors is now defined in masjid_representative_screen.dart
// I'll define colors locally for this widget to avoid dependency.

class MasjidStatisticsCard extends StatelessWidget {
  final Map<String, dynamic>? masjidData;
  final Animation<double> fadeAnimation;

  // Define colors locally for this widget for self-containment
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);

  const MasjidStatisticsCard({
    super.key,
    required this.masjidData,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final subscriberCount = masjidData?['subscribers']?.length ?? 0;

    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: lightGreen.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.08),
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
                        colors: [secondaryGreen, lightGreen],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: secondaryGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.analytics,
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
                          'Masjid Statistics',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                        Text(
                          'Current engagement metrics',
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
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            lightGreen.withOpacity(0.1),
                            accentGreen.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: lightGreen.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.people,
                            color: primaryGreen,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$subscriberCount',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                          Text(
                            'Subscribers',
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryGreen.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            secondaryGreen.withOpacity(0.1),
                            lightGreen.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: secondaryGreen.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.update,
                            color: secondaryGreen,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryGreen.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}