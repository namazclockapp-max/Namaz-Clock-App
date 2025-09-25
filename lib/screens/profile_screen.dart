// profile_screen.dart
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:namaz_clock_app/screens/auth/login_screen.dart';
import 'package:namaz_clock_app/services/auth_service.dart';
import 'dart:typed_data'; // Add this import for Uint8List
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/firestore_service.dart';
import 'notifications_screen.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';
import 'feedback_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  XFile? _profileImage;
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _isEditing = false;
  Map<String, dynamic>? _userProfile;
  bool _isRepresentative = false;

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
    _loadUserProfile();
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      final profile = await _firestoreService.getUserProfile(user.uid);
      if (profile != null && mounted) {
        setState(() {
          _userProfile = profile;
          _nameController.text = profile['name'] ?? '';
          _emailController.text = profile['email'] ?? user.email ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _profileImageUrl = profile['profileImageUrl'];
          _isRepresentative = profile['role'] == 'representative';
        });
      }
    }
  }

Future<void> _pickImage(ImageSource source) async {
  try {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _profileImage = image;
      });
      HapticFeedback.lightImpact();

      // 🔹 Upload to Cloudinary
      final cloudinary = CloudinaryPublic(
        'dfuev7yxo',        // 👉 Replace with your cloud name
        'flutter_unsigned', // 👉 Replace with your unsigned preset
        cache: false,
      );

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      final uploadedUrl = response.secureUrl;

      // 🔹 Save URL to Firestore
      final user = _authService.getCurrentUser();
      if (user != null) {
        await _firestoreService.updateUserProfile(user.uid, {
          'profileImageUrl': uploadedUrl,
        });

        setState(() {
          _profileImageUrl = uploadedUrl;
        });
      }
    }
  } catch (e) {
    print("❌ Upload failed: $e");
    _showErrorSnackBar('Failed to pick or upload image');
  }
}


Future<void> _saveProfile() async {
  if (_nameController.text.trim().isEmpty) {
    _showErrorSnackBar('Name cannot be empty');
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final user = _authService.getCurrentUser();
    if (user != null) {
      String? imageUrl = _profileImageUrl;

      if (_profileImage != null) {
  // 🔹 Upload to Cloudinary
  final cloudinary = CloudinaryPublic(
    'dfuev7yxo',        // Your cloud name
    'flutter_unsigned', // Your unsigned preset
    cache: false,
  );

  final response = await cloudinary.uploadFile(
    CloudinaryFile.fromFile(
      _profileImage!.path,
      resourceType: CloudinaryResourceType.Image,
    ),
  );

  imageUrl = response.secureUrl;
}

      // 🔹 Save profile data to Firestore
      await _firestoreService.updateUserProfile(user.uid, {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profileImageUrl': imageUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      setState(() {
        _isEditing = false;
        _profileImageUrl = imageUrl;
        _profileImage = null;
      });

      _showSuccessSnackBar('Profile updated successfully!');
      HapticFeedback.mediumImpact();
    }
  } catch (e) {
    _showErrorSnackBar('Failed to update profile: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _signOut() async {
    final bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Sign Out'),
              ],
            ),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        _showErrorSnackBar('Failed to sign out: $e');
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
        backgroundColor: const Color.fromARGB(0, 207, 117, 117),
        elevation: 0,
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back_ios, color: darkGreen),
        //   onPressed: () {
        //     Navigator.pop(context);
        //     HapticFeedback.lightImpact();
        //   },
        // ),
        title: Text(
          'My Profile',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
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
                icon: Icon(
                  _isEditing ? Icons.close : Icons.edit,
                  color: primaryGreen,
                ),
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                  HapticFeedback.lightImpact();
                },
              ),
            ),
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
                  children: [
                    const SizedBox(height: 16),
                    _buildProfileCard(),
                    const SizedBox(height: 24),
                    if (_isRepresentative) ...[
                      _buildRepresentativePanel(),
                      const SizedBox(height: 24),
                    ],
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFDFA)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lightGreen.withOpacity(0.3), width: 1.5),
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
          children: [
            _buildProfileImage(),
            const SizedBox(height: 24),
            _buildProfileForm(),
          ],
        ),
      ),
    );
  }

Widget _buildProfileImage() {
  return Stack(
    children: [
      Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              primaryGreen.withOpacity(0.1),
              lightGreen.withOpacity(0.1),
            ],
          ),
          border: Border.all(color: lightGreen.withOpacity(0.3), width: 3),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipOval(
          child: _profileImage != null
              ? kIsWeb
                  // On web, use `Image.network` with the XFile path
                  ? Image.network(
                      _profileImage!.path,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    )
                  // On mobile, use File
                  : Image.file(
                      File(_profileImage!.path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    )
              : _profileImageUrl != null
                  ? Image.network(
                      _profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
        ),
      ),
      if (_isEditing)
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryGreen, secondaryGreen],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo),
                        title: const Text("Pick from Gallery"),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text("Take a Photo"),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
    ],
  );
}

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen.withOpacity(0.1), lightGreen.withOpacity(0.1)],
        ),
      ),
      child: Icon(Icons.person, size: 60, color: primaryGreen.withOpacity(0.5)),
    );
  }

  Widget _buildProfileForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          icon: Icons.person_outline,
          enabled: _isEditing,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          enabled: false,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          enabled: _isEditing,
          keyboardType: TextInputType.phone,
        ),
        if (_isEditing) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
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
              onPressed: _isLoading ? null : _saveProfile,
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
                        Icon(Icons.save, color: Colors.white, size: 22),
                        SizedBox(width: 12),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
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
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(
          color: enabled ? darkGreen : Colors.grey[600],
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? primaryGreen.withOpacity(0.7) : Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: enabled
                    ? [
                        primaryGreen.withOpacity(0.1),
                        lightGreen.withOpacity(0.1),
                      ]
                    : [
                        Colors.grey.withOpacity(0.1),
                        Colors.grey.withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: enabled ? primaryGreen : Colors.grey[500],
              size: 20,
            ),
          ),
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
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildRepresentativePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Representative Panel',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: lightGreen.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // _buildActionTile(
              //   icon: Icons.mosque_outlined,
              //   title: 'Manage Masjids',
              //   subtitle: 'Add, edit, or remove masjids',
              //   onTap: () {
              //     // Navigator.push(context, MaterialPageRoute(builder: (context) => const MasjidManagementScreen()));
              //     _showErrorSnackBar('Masjid Management Screen Coming Soon!');
              //   },
              // ),
              // _buildDivider(),
              // _buildActionTile(
              //   icon: Icons.event_note_outlined,
              //   title: 'Manage Events',
              //   subtitle: 'Create and manage community events',
              //   onTap: () {
              //     _showErrorSnackBar('Event Management Screen Coming Soon!');
              //   },
              // ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lightGreen.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySecurityScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.feedback_outlined,
            title: 'Feedback',
            subtitle: 'Share your thoughts and suggestions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            onTap: _signOut,
            isDestructive: true,
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
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDestructive
                      ? [
                          Colors.red.withOpacity(0.1),
                          Colors.red.withOpacity(0.05),
                        ]
                      : [
                          primaryGreen.withOpacity(0.1),
                          lightGreen.withOpacity(0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDestructive
                      ? Colors.red.withOpacity(0.2)
                      : primaryGreen.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : primaryGreen,
                size: 24,
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
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            lightGreen.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
