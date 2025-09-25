// lib/screens/representative/widgets/prayer_times_management_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namaz_clock_app/screens/language_manager.dart';

class PrayerTimesManagementCard extends StatelessWidget {
  final String masjidId;
  final Map<String, dynamic> prayerTimes;
  final Map<String, dynamic> iqamaTimes;
  final GlobalKey<FormState> formKey;
  final Function onUpdateIqamaTimes;
  final bool isUpdating;
  final TextEditingController fajrController;
  final TextEditingController dhuhrController;
  final TextEditingController asrController;
  final TextEditingController maghribController;
  final TextEditingController ishaController;
  final TextEditingController jummahController;
  final Function(TextEditingController) onSelectTime;
  final Animation<double> fadeAnimation;

  // Define colors locally for this widget for self-containment
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);

  const PrayerTimesManagementCard({
    super.key,
    required this.masjidId,
    required this.prayerTimes,
    required this.iqamaTimes,
    required this.formKey,
    required this.onUpdateIqamaTimes,
    required this.isUpdating,
    required this.fajrController,
    required this.dhuhrController,
    required this.asrController,
    required this.maghribController,
    required this.ishaController,
    required this.jummahController,
    required this.onSelectTime,
    required this.fadeAnimation,
  });

  Widget _buildTimeInputField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightGreen.withOpacity(0.05), accentGreen.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGreen.withOpacity(0.2), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => onSelectTime(controller),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkGreen,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: primaryGreen.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryGreen, size: 20),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryGreen.withOpacity(0.1),
                  lightGreen.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.edit, color: primaryGreen, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
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
                        Icons.edit_calendar,
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
                            LanguageManager.instance.getTranslatedString(
                              'Update Prayer Times',
                            ),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                          ),
                          Text(
                            LanguageManager.instance.getTranslatedString(
                              'Tap on any time to update',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: primaryGreen.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTimeInputField(
                  LanguageManager.instance.getTranslatedString('Jumuʿah'),
                  jummahController,
                  Icons.wb_sunny_outlined,
                ),
                _buildTimeInputField(
                  LanguageManager.instance.getTranslatedString('Fajr Jammat'),
                  fajrController,
                  Icons.wb_twilight,
                ),
                _buildTimeInputField(
                  LanguageManager.instance.getTranslatedString('Dhuhr Jammat'),
                  dhuhrController,
                  Icons.wb_sunny,
                ),
                _buildTimeInputField(
                  LanguageManager.instance.getTranslatedString('Asr Jammat'),
                  asrController,
                  Icons.wb_sunny_outlined,
                ),
                _buildTimeInputField(
                  LanguageManager.instance.getTranslatedString('Maghrib Jammat'),
                  maghribController,
                  Icons.nightlight_round,
                ),
                _buildTimeInputField(
                  LanguageManager.instance.getTranslatedString('Isha Jammat'),
                  ishaController,
                  Icons.nightlight_round,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isUpdating ? null : () => onUpdateIqamaTimes(),
                    icon: isUpdating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                    label: Text(
                      isUpdating
                          ? LanguageManager.instance.getTranslatedString(
                              'Updating...',
                            )
                          : LanguageManager.instance.getTranslatedString(
                              'Submit Updates',
                            ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}