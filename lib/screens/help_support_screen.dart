import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with TickerProviderStateMixin {
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

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
    _messageController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: isError ? Colors.red : secondaryGreen,
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
                    _buildQuickHelp(),
                    const SizedBox(height: 24),
                    _buildFAQSection(),
                    const SizedBox(height: 24),
                    _buildContactSupport(),
                    const SizedBox(height: 24),
                    _buildAppInfo(),
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
                lightGreen.withValues(alpha: 0.1),
                accentGreen.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: lightGreen.withValues(alpha: 0.2),
              width: 1,
            ),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryGreen, secondaryGreen],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.help,
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
                'Help & Support',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              Text(
                'Get help and contact support',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: primaryGreen.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickHelp() {
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
          color: lightGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.1),
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
                      colors: [primaryGreen.withValues(alpha: 0.1), lightGreen.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.flash_on, color: primaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Quick Help',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildQuickHelpCard(
                    icon: Icons.location_on,
                    title: 'Location Issues',
                    subtitle: 'Fix prayer time location',
                    onTap: () => _showLocationHelp(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickHelpCard(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Setup prayer alerts',
                    onTap: () => _showNotificationHelp(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickHelpCard(
                    icon: Icons.mosque,
                    title: 'Masjid Setup',
                    subtitle: 'Subscribe to masjids',
                    onTap: () => _showMasjidHelp(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickHelpCard(
                    icon: Icons.account_circle,
                    title: 'Account Help',
                    subtitle: 'Profile & settings',
                    onTap: () => _showAccountHelp(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickHelpCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            lightGreen.withValues(alpha: 0.05),
            accentGreen.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lightGreen.withValues(alpha: 0.2),
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
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryGreen, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: darkGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: primaryGreen.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
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
          color: lightGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.1),
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
                      colors: [secondaryGreen.withValues(alpha: 0.1), lightGreen.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.quiz, color: secondaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Frequently Asked Questions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFAQItem(
              question: 'How do I subscribe to a masjid?',
              answer: 'Select a masjid from the list on the home screen and tap the notification icon to subscribe.',
            ),
            _buildFAQItem(
              question: 'Why are my prayer times incorrect?',
              answer: 'Make sure location access is enabled in your device settings and the app has permission to use your location.',
            ),
            _buildFAQItem(
              question: 'How do I become a masjid representative?',
              answer: 'Select your masjid and tap "Request to be Representative". Your request will be reviewed by the admin.',
            ),
            _buildFAQItem(
              question: 'Can I change notification sounds?',
              answer: 'Yes, go to Profile > Notifications > Notification Sound to choose from available options.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkGreen,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: primaryGreen.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ),
      ],
      iconColor: primaryGreen,
      collapsedIconColor: primaryGreen.withValues(alpha: 0.7),
    );
  }

  Widget _buildContactSupport() {
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
          color: lightGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.1),
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
                      colors: [accentGreen.withValues(alpha: 0.1), lightGreen.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.support_agent, color: accentGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Contact Support',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.email,
                    title: 'Email Support',
                    subtitle: 'namazclockapp@gmail.com.com',
                    onTap: () => _launchEmail(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.phone,
                    title: 'Phone Support',
                    subtitle: 'N/A',
                    onTap: () => _launchPhone(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.chat,
                    title: 'Live Chat',
                    subtitle: 'Chat with support',
                    onTap: () => _showLiveChat(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.bug_report,
                    title: 'Report Bug',
                    subtitle: 'Report an issue',
                    onTap: () => _showBugReport(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            lightGreen.withValues(alpha: 0.05),
            accentGreen.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lightGreen.withValues(alpha: 0.2),
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
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryGreen, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: darkGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: primaryGreen.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
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
          color: lightGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.1),
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
                      colors: [primaryGreen.withValues(alpha: 0.1), lightGreen.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info, color: primaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'App Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow('Version', '1.0.0'),
            _buildInfoRow('Build', '100'),
            _buildInfoRow('Developer', 'Namaz Clock Team'),
            _buildInfoRow('Last Updated', 'December 2024'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryGreen, secondaryGreen],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _checkForUpdates(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Check for Updates',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: primaryGreen.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for actions
  void _showLocationHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location Help'),
        content: const Text(
          'To fix location issues:\n\n'
          '1. Go to device Settings\n'
          '2. Find Namaz Clock app\n'
          '3. Enable Location permission\n'
          '4. Restart the app\n\n'
          'If issues persist, try manually refreshing your location in the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: primaryGreen)),
          ),
        ],
      ),
    );
  }

  void _showNotificationHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notification Help'),
        content: const Text(
          'To setup prayer notifications:\n\n'
          '1. Subscribe to a masjid from home screen\n'
          '2. Go to Profile > Notifications\n'
          '3. Enable Prayer Time Reminders\n'
          '4. Choose your notification sound\n\n'
          'Make sure notifications are enabled in device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: primaryGreen)),
          ),
        ],
      ),
    );
  }

  void _showMasjidHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Masjid Setup Help'),
        content: const Text(
          'To subscribe to masjids:\n\n'
          '1. Browse masjids on the home screen\n'
          '2. Tap on a masjid to select it\n'
          '3. Tap the notification bell icon\n'
          '4. You\'ll receive prayer time updates\n\n'
          'You can subscribe to multiple masjids.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: primaryGreen)),
          ),
        ],
      ),
    );
  }

  void _showAccountHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Account Help'),
        content: const Text(
          'Account management:\n\n'
          '1. Update profile in Profile screen\n'
          '2. Change notification preferences\n'
          '3. Manage privacy settings\n'
          '4. Request representative access\n\n'
          'Contact support if you need to delete your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: primaryGreen)),
          ),
        ],
      ),
    );
  }

  void _launchEmail() {
    _showSnackBar('Opening email app to contact');
  }

  void _launchPhone() {
    _showSnackBar('Opening phone app to call ');
  }

  void _showLiveChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Live Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
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
              _showSnackBar('Message sent to support team');
              _messageController.clear();
              _subjectController.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showBugReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Report Bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Your Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Describe the bug',
                border: OutlineInputBorder(),
              ),
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
              _showSnackBar('Bug report submitted');
              _messageController.clear();
              _emailController.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _checkForUpdates() {
    _showSnackBar('You have the latest version');
  }
}
