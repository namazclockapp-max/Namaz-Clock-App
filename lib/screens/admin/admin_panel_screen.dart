import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namaz_clock_app/screens/admin/masjid_request_management_tab.dart';
import 'package:namaz_clock_app/screens/admin/representative_requests_tab.dart';
import 'package:namaz_clock_app/screens/auth/login_screen.dart';
import 'package:namaz_clock_app/screens/language_manager.dart';
import 'package:namaz_clock_app/services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'masjid_management_tab.dart';
import 'user_management_tab.dart';
import 'feedback_management_tab.dart';
import 'package:provider/provider.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedIndex = 0;
  bool _isLoading = false;

  // Green gradient color scheme
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);

  final List<IconData> _tabIcons = [
    Icons.dashboard_outlined,
    Icons.mosque_outlined,
    Icons.group_outlined,
    Icons.feedback_outlined,
    Icons.add_location_alt_outlined,
    Icons.person_add_alt_1_outlined, // New icon for Representative Requests
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Stream<int> _getPendingMasjidRequestsCount() {
    return _firestoreService.getPendingMasjidRequests().map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _getTotalFeedbackCount() {
    return _firestoreService.getAllFeedback().map((feedbackList) => feedbackList.length);
  }

  // New stream for pending representative requests
  Stream<int> _getPendingRepresentativeRequestsCount() {
    return _firestoreService.getPendingRepresentativeRequestsCount();
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageManager = Provider.of<LanguageManager>(context);

    final List<Widget> _pages = <Widget>[
      _buildAdminDashboardContent(languageManager),
      const MasjidManagementTab(),
      const UserManagementTab(),
      const FeedbackManagementTab(),
      const MasjidRequestManagementTab(),
      const RepresentativeRequestsTab(), // New tab
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 82,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BottomAppBar(
            elevation: 0,
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Expanded(
                  child: _buildNavItem(
                    index: 0,
                    icon: _tabIcons[0],
                    label: languageManager.getTranslatedString('Dashboard'),
                    isSelected: _selectedIndex == 0,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 1,
                    icon: _tabIcons[1],
                    label: languageManager.getTranslatedString('Masjid'),
                    isSelected: _selectedIndex == 1,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 2,
                    icon: _tabIcons[2],
                    label: languageManager.getTranslatedString('Users'),
                    isSelected: _selectedIndex == 2,
                  ),
                ),
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _getTotalFeedbackCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _buildNavItem(
                        index: 3,
                        icon: _tabIcons[3],
                        label: languageManager.getTranslatedString('Feedback'),
                        isSelected: _selectedIndex == 3,
                        badgeCount: count,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _getPendingMasjidRequestsCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _buildNavItem(
                        index: 4,
                        icon: _tabIcons[4],
                        label: languageManager.getTranslatedString('Masjid Req'),
                        isSelected: _selectedIndex == 4,
                        badgeCount: count,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _getPendingRepresentativeRequestsCount(), // New stream
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _buildNavItem(
                        index: 5, // New index
                        icon: _tabIcons[5], // New icon
                        label: languageManager.getTranslatedString('Rep Req'), // Shortened label
                        isSelected: _selectedIndex == 5,
                        badgeCount: count,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    int badgeCount = 0,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(12),
        splashColor: lightGreen.withOpacity(0.3),
        highlightColor: lightGreen.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          decoration: BoxDecoration(
            color: isSelected ? primaryGreen.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? primaryGreen : Colors.grey[700],
                    size: 26,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? primaryGreen : Colors.grey[700],
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminDashboardContent(LanguageManager languageManager) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          elevation: 0,
          backgroundColor: primaryGreen,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            titlePadding: const EdgeInsets.only(bottom: 16),
            title: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                languageManager.getTranslatedString('Admin Panel'),
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
                      scale: _fadeAnimation,
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
                          Icons.admin_panel_settings,
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
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildListDelegate(
              [
                _buildDashboardCard(
                  context,
                  languageManager.getTranslatedString('Masjid'),
                  Icons.mosque,
                  Colors.blue,
                  1,
                  languageManager,
                ),
                _buildDashboardCard(
                  context,
                  languageManager.getTranslatedString('Users'),
                  Icons.group,
                  Colors.orange,
                  2,
                  languageManager,
                ),
                _buildDashboardCard(
                  context,
                  languageManager.getTranslatedString('Feedback'),
                  Icons.feedback,
                  Colors.deepPurple,
                  3,
                  languageManager,
                ),
                _buildDashboardCard(
                  context,
                  languageManager.getTranslatedString('Masjid Req'),
                  Icons.add_location_alt,
                  Colors.teal,
                  4,
                  languageManager,
                ),
                _buildDashboardCard(
                  context,
                  languageManager.getTranslatedString('Representative Requests'), // New card
                  Icons.person_add_alt_1,
                  Colors.indigo,
                  5, // New index
                  languageManager,
                ),
                _buildDashboardCard(
                  context,
                  languageManager.getTranslatedString('Logout'),
                  Icons.logout,
                  Colors.red,
                  6,
                  languageManager,
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    int index,
    LanguageManager languageManager,
    {VoidCallback? onTap}
  ) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutBack),
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap ?? () => _onItemTapped(index),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 50,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}