import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:namaz_clock_app/screens/admin/admin_panel_screen.dart';
import 'package:namaz_clock_app/screens/home_screen.dart';
import 'package:namaz_clock_app/screens/representative/masjid_representative_screen.dart';
import 'package:namaz_clock_app/services/auth_service.dart';
import 'package:namaz_clock_app/services/firestore_service.dart';


// You might need a new screen for email verification or handle it within this screen
// For simplicity, let's assume a placeholder for now.
// import 'package:namaz_clock_app/screens/email_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final FirestoreService _firestoreService = FirestoreService(); // Initialize FirestoreService
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

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
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
    });
    HapticFeedback.lightImpact();

    // Animate the transition
    _rotationController.forward().then((_) {
      _rotationController.reverse();
    });
  }

  void _submitAuthForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.mediumImpact();

    User? user;
    try {
      if (_isSignUp) {
        user = await _auth.signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
        if (user != null) {
          // Send email verification after successful signup
          await user.sendEmailVerification();
          _showSuccessSnackBar('Account created! Please verify your email.');
          // Redirect to a screen informing the user to check their email
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EmailVerificationInfoScreen(email: _emailController.text.trim()),
              ),
            );
          }
          return; // Exit function after redirecting for verification
        }
      } else {
        user = await _auth.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (user != null) {
          // Reload user to get the latest email verification status
          await user.reload();
          user = FirebaseAuth.instance.currentUser; // Get the reloaded user

          if (user != null && !user.emailVerified) {
            _showErrorSnackBar('Please verify your email address to sign in.');
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EmailVerificationInfoScreen(email: _emailController.text.trim()),
                ),
              );
            }
            return; // Exit function if email is not verified
          }

          HapticFeedback.heavyImpact();
          _showSuccessSnackBar('Welcome back!');

          // --- Role-based Redirection Logic ---
          final userData = await _firestoreService.getUserData(user!.uid);
          final userRole = userData?['role'] as String?;

          if (mounted) { // Check if the widget is still mounted before navigating
            switch (userRole) {
              case 'admin':
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                );
                break;
              case 'representative':
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MasjidRepresentativeScreen(masjidId: '',)),
                );
                break;
              case 'user': // Default role for regular users
              default:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
                break;
            }
          }
          // --- End Role-based Redirection Logic ---
        } else {
          _showErrorSnackBar('Authentication failed. Please check your credentials.');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An authentication error occurred.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Invalid email or password.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The email address is already in use by another account.';
      } else if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      }
      _showErrorSnackBar(message);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
      print('Login/SignUp Error: $e'); // Log the actual error for debugging
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sendPasswordResetEmail() async {
    if (_emailController.text.isEmpty) {
      _showErrorSnackBar('Please enter your email to reset password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(_emailController.text.trim());
      _showSuccessSnackBar('Password reset link sent to your email.');
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send reset email.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      }
      _showErrorSnackBar(message);
    } catch (e) {
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        margin: const EdgeInsets.all(16),
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
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildAuthCard(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFFAFDFA),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: lightGreen.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 20,
            offset: const Offset(-10, -10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildFormFields(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 24),
              _buildToggleButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryGreen, secondaryGreen, lightGreen],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: RotationTransition(
            turns: _rotationAnimation,
            child: Icon(
              _isSignUp ? Icons.person_add : Icons.login,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isSignUp ? 'Create Your Account' : 'Welcome Back!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkGreen,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isSignUp
              ? 'Join our community and start your spiritual journey'
              : 'Sign in to continue your spiritual journey',
          style: TextStyle(
            fontSize: 16,
            color: primaryGreen.withOpacity(0.7),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        if (_isSignUp) ...[
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            keyboardType: TextInputType.name,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
        ],
        if (_isSignUp) // Add the warning message only for signup
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Please ensure that you have a Google account with this email',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email address';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            // New validation for Gmail account
            if (_isSignUp && !value.trim().toLowerCase().endsWith('@gmail.com')) {
              return 'Please use a Gmail account for signup.';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: primaryGreen.withOpacity(0.7),
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
              HapticFeedback.lightImpact();
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        if (!_isSignUp) // Add Forgot Password only for sign-in
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _sendPasswordResetEmail,
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: TextStyle(
          color: darkGreen,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: primaryGreen.withOpacity(0.7),
            fontSize: 16,
          ),
          prefixIcon: Container(
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
            child: Icon(
              icon,
              color: primaryGreen,
              size: 20,
            ),
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: lightGreen.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: lightGreen.withOpacity(0.3),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.red,
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
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [primaryGreen, secondaryGreen, lightGreen],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitAuthForm,
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSignUp ? Icons.person_add : Icons.login,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isSignUp ? 'Create Account' : 'Sign In',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Column(
      children: [
        Container(
          height: 1,
          width: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                lightGreen.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isSignUp
              ? 'Already have an account?'
              : 'Don\'t have an account?',
          style: TextStyle(
            color: primaryGreen.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
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
          child: TextButton(
            onPressed: _toggleAuthMode,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isSignUp ? 'Sign In Instead' : 'Create Account',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// A new screen to inform the user about email verification
class EmailVerificationInfoScreen extends StatelessWidget {
  final String email;

  const EmailVerificationInfoScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: _LoginScreenState.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email,
                size: 80,
                color: _LoginScreenState.primaryGreen,
              ),
              const SizedBox(height: 24),
              const Text(
                'A verification link has been sent to your email address.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _LoginScreenState.darkGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please check your inbox (and spam folder) for an email from Firebase and click the link to verify your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _LoginScreenState.primaryGreen.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  // Allow user to go back to login to try signing in again
                  // This will re-check the email verification status
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _LoginScreenState.secondaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  // Option to resend verification email
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    try {
                      await user.sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Verification email resent!'),
                          backgroundColor: _LoginScreenState.secondaryGreen,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to resend email: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'Resend Verification Email',
                  style: TextStyle(
                    color: _LoginScreenState.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
