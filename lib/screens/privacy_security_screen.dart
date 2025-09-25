import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namaz_clock_app/services/auth_service.dart'; // Import your AuthService

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Privacy Settings
  bool _locationAccess = true;

  // Green gradient color scheme
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);

  // Instance of your AuthService
  final AuthService _authService = AuthService();

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color? color, IconData? icon}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon ?? Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color ?? secondaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- New function to handle password change ---
  Future<void> _showChangePasswordDialog() async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null || currentUser.email == null) {
      _showSnackBar('User not logged in or no email found.', color: Colors.red, icon: Icons.error);
      return;
    }

    final userEmail = currentUser.email!;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Change Password'),
          content: Text('A password reset link will be sent to your email address:\n\n$userEmail'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Send Link'),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _authService.sendPasswordResetEmail(userEmail);
                  _showSnackBar(
                    'Password reset link sent to your email!',
                    color: secondaryGreen,
                    icon: Icons.email,
                  );
                } catch (e) {
                  _showSnackBar(
                    'Failed to send password reset link. Please try again.',
                    color: Colors.red,
                    icon: Icons.error,
                  );
                  print('Error sending password reset email: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }
  // --- End of new function ---

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
                    _buildPrivacySettings(),
                    const SizedBox(height: 24),
                    _buildSecuritySettings(),
                    const SizedBox(height: 24),
                    _buildDataManagement(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
            border: Border.all(
              color: lightGreen.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: primaryGreen),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        const SizedBox(width: 16),
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
            Icons.security,
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
                'Privacy & Security',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
              ),
              Text(
                'Manage your privacy settings',
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

  Widget _buildPrivacySettings() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFFAFDFA),
          ],
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryGreen.withOpacity(0.1), lightGreen.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.privacy_tip, color: primaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Privacy Controls',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSwitchTile(
              title: 'Location Access',
              subtitle: 'Allow app to access your location for prayer times',
              value: _locationAccess,
              onChanged: (value) {
                setState(() {
                  _locationAccess = value;
                });
                _showSnackBar('Location access ${value ? 'enabled' : 'disabled'}');
              },
              icon: Icons.location_on,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFFAFDFA),
          ],
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [secondaryGreen.withOpacity(0.1), lightGreen.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield, color: secondaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Security Features',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              icon: Icons.lock_reset,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: _showChangePasswordDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagement() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFFAFDFA),
          ],
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentGreen.withOpacity(0.1), lightGreen.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storage, color: accentGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Data Management',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              icon: Icons.delete_forever,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and data',
              onTap: () {
                _showDeleteAccountDialog();
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            lightGreen.withOpacity(0.05),
            accentGreen.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lightGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
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
                  style: const TextStyle(
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
            activeColor: Colors.white,
            activeTrackColor: primaryGreen,
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDestructive
              ? [Colors.red.withOpacity(0.05), Colors.red.withOpacity(0.02)]
              : [lightGreen.withOpacity(0.05), accentGreen.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDestructive
              ? Colors.red.withOpacity(0.2)
              : lightGreen.withOpacity(0.2),
          width: 1,
        ),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withOpacity(0.1)
                      : primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? Colors.red : primaryGreen,
                  size: 20,
                ),
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
                        color: isDestructive ? Colors.red : darkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDestructive
                            ? Colors.red.withOpacity(0.7)
                            : primaryGreen.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDestructive
                    ? Colors.red.withOpacity(0.5)
                    : primaryGreen.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Account'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Account deletion coming soon');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}