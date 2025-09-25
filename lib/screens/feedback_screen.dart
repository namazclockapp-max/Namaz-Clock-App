import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namaz_clock_app/screens/my_feedback_screen.dart';
import 'package:namaz_clock_app/services/firestore_service.dart';
import 'package:namaz_clock_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore for FieldValue

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedFeedbackType = 'suggestion';
  bool _isLoading = false;

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
    _loadUserInfo();
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
    _nameController.dispose();
    _emailController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      final profile = await _firestoreService.getUserProfile(user.uid);
      if (profile != null && mounted) {
        setState(() {
          _nameController.text = profile['name'] ?? '';
          _emailController.text = profile['email'] ?? user.email ?? '';
        });
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      _showErrorSnackBar('Please provide your feedback');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your name');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your email');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.getCurrentUser();
      await _firestoreService.submitFeedback({
        'userId': user?.uid,
        'type': _selectedFeedbackType,
        'feedback': _feedbackController.text.trim(),
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // Initial status
      });

      _showSuccessSnackBar('Thank you for your feedback!');
      _feedbackController.clear();
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showErrorSnackBar('Failed to submit feedback. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: secondaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: secondaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Feedback',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.black87),
            tooltip: 'View My Feedback',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyFeedbackScreen()),
              );
            },
          ),
        ],
      ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildFeedbackTypeSection(),
                    const SizedBox(height: 32),
                    _buildFeedbackContentSection(),
                    const SizedBox(height: 32),
                    _buildContactInformationSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
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
    return Column(
      children: [
        Text(
          'We Value Your Feedback',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your feedback helps us improve our products and services. We appreciate your time!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeedbackTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen.withAlpha(25), lightGreen.withAlpha(25)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.feedback_outlined,
                color: primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Feedback Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildFeedbackTypeCard(
                'suggestion',
                'Suggestion',
                Icons.lightbulb_outline,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeedbackTypeCard(
                'complaint',
                'Complaint',
                Icons.thumb_down_outlined,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeedbackTypeCard(
                'praise',
                'Praise',
                Icons.thumb_up_outlined,
                primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFeedbackTypeCard(
                'bug_report',
                'Bug Report',
                Icons.bug_report_outlined,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeedbackTypeCard(
                'feature_request',
                'Feature Request',
                Icons.add_circle_outline,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()), // Empty Expanded to balance the row
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackTypeCard(String type, String title, IconData icon, Color color) {
    final isSelected = _selectedFeedbackType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFeedbackType = type;
        });
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(25) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : Colors.grey.withAlpha(76),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withAlpha(51)
                  : Colors.grey.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color.withAlpha(51) : color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackContentSection() {
    String title = '';
    String placeholder = '';
    IconData icon = Icons.feedback;
    Color sectionColor = primaryGreen;

    switch (_selectedFeedbackType) {
      case 'suggestion':
        title = 'Your Suggestion';
        placeholder = 'What would you like to suggest? How can we improve?';
        icon = Icons.lightbulb_outlined;
        sectionColor = Colors.orange;
        break;
      case 'complaint':
        title = 'Your Complaint';
        placeholder = 'Please describe your concern. What went wrong?';
        icon = Icons.thumb_down_outlined;
        sectionColor = Colors.red;
        break;
      case 'praise':
        title = 'Your Praise';
        placeholder = 'What did you like? Share your positive experience!';
        icon = Icons.thumb_up_outlined;
        sectionColor = primaryGreen;
        break;
      case 'bug_report':
        title = 'Your Bug Report';
        placeholder = 'Please describe the issue in detail. What happened? What did you expect to happen?';
        icon = Icons.bug_report_outlined;
        sectionColor = Colors.red;
        break;
      case 'feature_request':
        title = 'Your Feature Request';
        placeholder = 'What feature would you like to see added? How would it benefit you?';
        icon = Icons.add_circle_outline;
        sectionColor = Colors.blue;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: sectionColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: sectionColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: sectionColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: sectionColor.withAlpha(25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _feedbackController,
            maxLines: 6,
            style: TextStyle(
              color: darkGreen,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: sectionColor.withAlpha(76),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: sectionColor.withAlpha(76),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: sectionColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen.withAlpha(25), lightGreen.withAlpha(25)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.contact_mail_outlined,
                color: primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _nameController,
          label: 'Your Name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: darkGreen,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: primaryGreen.withAlpha(178),
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGreen.withAlpha(25), lightGreen.withAlpha(25)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: primaryGreen,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: lightGreen.withAlpha(76),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: lightGreen.withAlpha(76),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: primaryGreen,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryGreen, secondaryGreen, lightGreen],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withAlpha(102),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, color: Colors.white, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Submit Feedback',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}