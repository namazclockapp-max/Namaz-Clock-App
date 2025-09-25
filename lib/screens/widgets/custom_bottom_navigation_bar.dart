// lib/widgets/custom_bottom_navigation_bar.dart
import 'package:flutter/material.dart';
import 'package:namaz_clock_app/screens/language_manager.dart';
// No need for provider import here, as languageManager is passed directly.

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap; // Changed from Function(int) to ValueChanged<int> for consistency
  final Color primaryGreen;
  final Color lightGreen;
  final LanguageManager languageManager;
  final String? userRole; // ADDED: userRole parameter

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.primaryGreen,
    required this.lightGreen,
    required this.languageManager,
    this.userRole, // INITIALIZED: userRole in constructor
  });

  // Helper method to build a BottomNavigationBarItem with consistent styling
  BottomNavigationBarItem _buildItem(
    IconData iconData,
    IconData activeIconData,
    String labelKey, // Use a key for translation
    int itemIndex,
  ) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: currentIndex == itemIndex
              ? LinearGradient(
                  colors: [
                    primaryGreen.withOpacity(0.1),
                    lightGreen.withOpacity(0.1),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(iconData, size: 24),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryGreen.withOpacity(0.15),
              lightGreen.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(activeIconData, size: 24),
      ),
      label: languageManager.getTranslatedString(labelKey),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<BottomNavigationBarItem> items;

    // Define the items list based on user role
    if (userRole == 'admin') {
      items = [
        _buildItem(Icons.home_outlined, Icons.home, 'Home', 0),
        _buildItem(Icons.notifications_active_outlined, Icons.notifications_active, 'Subscribed', 1), // New tab
        _buildItem(Icons.mosque_outlined, Icons.mosque, 'Masjids', 2),
        _buildItem(Icons.access_time, Icons.access_time, 'Prayer Times', 3),
        _buildItem(Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, 'Admin', 4),
      ];
    } else if (userRole == 'representative') {
      items = [
        _buildItem(Icons.home_outlined, Icons.home, 'Home', 0),
        _buildItem(Icons.notifications_active_outlined, Icons.notifications_active, 'Subscribed', 1), // New tab
        _buildItem(Icons.mosque_outlined, Icons.mosque, 'Masjids', 2),
        _buildItem(Icons.access_time, Icons.access_time, 'Prayer Times', 3),
        _buildItem(Icons.handshake_outlined, Icons.handshake, 'My Masjid', 4),
      ];
    } else {
      // Default to 'user' role
      items = [
        _buildItem(Icons.home_outlined, Icons.home, 'Home', 0),
        _buildItem(Icons.notifications_active_outlined, Icons.notifications_active, 'Subscribed', 1), // New tab
        _buildItem(Icons.mosque_outlined, Icons.mosque, 'Masjids', 2),
        _buildItem(Icons.access_time, Icons.access_time, 'Prayer Times', 3),
        _buildItem(Icons.person_outlined, Icons.person, 'Profile', 4),
      ];
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black12,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFFAFDFA),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border.all(
            color: lightGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: primaryGreen,
            unselectedItemColor: Colors.grey[600],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            items: items,
          ),
        ),
      ),
    );
  }
}