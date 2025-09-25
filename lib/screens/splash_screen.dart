import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler

import '../main.dart'; // for RoleBasedRedirector (assuming RoleBasedRedirector is still in main.dart)
import 'auth/login_screen.dart'; // Your login screen

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late AnimationController _loadingController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _floatAnimation;

  // Define a minimum duration for the splash screen animations and logic
  final int _minimumSplashAndSetupDurationMs = 5000; // 5 seconds (matching your original delay)

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _loadingController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeController.forward();

    // Start the combined setup and navigation process immediately
    _initializeAppAndPermissionsAndNavigate();
  }

  // --- New permission and navigation logic combined ---
  Future<void> _initializeAppAndPermissionsAndNavigate() async {
    final startTime = DateTime.now();

    // 1. Request location permission
    await _requestLocationPermission();

    // 2. Determine next route based on authentication
    final user = FirebaseAuth.instance.currentUser; // Get current user
    Widget nextScreen;
    if (user != null) {
      nextScreen = RoleBasedRedirector(uid: user.uid);
    } else {
      nextScreen = const LoginScreen();
    }

    // Calculate elapsed time for animations and setup
    final endTime = DateTime.now();
    final elapsedDuration = endTime.difference(startTime);

    // Ensure the splash screen is displayed for at least the minimum duration
    if (elapsedDuration.inMilliseconds < _minimumSplashAndSetupDurationMs) {
      await Future.delayed(Duration(milliseconds: _minimumSplashAndSetupDurationMs - elapsedDuration.inMilliseconds));
    }

    // Navigate to the determined screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    }
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print("Location permission granted!");
    } else if (status.isDenied) {
      print("Location permission denied.");
      // Show a dialog if denied, but allow user to proceed potentially with limited features
      await _showPermissionDeniedDialog('Location permission denied. Prayer times may not be accurate without location access.', false);
    } else if (status.isPermanentlyDenied) {
      print("Location permission permanently denied. Open settings.");
      // Show a dialog and guide user to settings if permanently denied
      await _showPermissionDeniedDialog('Location permission permanently denied. Please enable it in app settings.', true);
    }
  }

  Future<void> _showPermissionDeniedDialog(String message, bool isPermanentlyDenied) async {
    if (!mounted) return; // Ensure widget is still mounted

    await showDialog(
      context: context,
      barrierDismissible: false, // User must interact with the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: Text(message),
          actions: <Widget>[
            if (isPermanentlyDenied)
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog immediately
                  openAppSettings(); // Opens app settings for the user
                  // Note: User interaction with app settings is outside our control.
                  // The app will continue the _initializeAppAndPermissionsAndNavigate flow
                  // after this dialog is dismissed.
                },
              ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
  // --- End new logic ---

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF064e3b),
              Color(0xFF0f766e),
              Color(0xFF166534),
            ],
          ),
        ),
        child: Stack(
          children: [
            ...List.generate(4, (index) => _buildFloatingShape(index)),
            _buildIslamicPattern(Alignment.topLeft, -50, -50),
            _buildIslamicPattern(Alignment.bottomRight, -50, -50),
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(_fadeAnimation),
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAppTitle(),
                        SizedBox(height: 40),
                        _buildVerseCard(),
                        SizedBox(height: 40),
                        _buildLoadingAnimation(),
                        SizedBox(height: 16),
                        Text(
                          'Preparing your prayer companion...',
                          style: TextStyle(
                            color: Color(0xFFa7f3d0),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppTitle() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: Text(
                'نماز کلاک',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black26,
                    ),
                  ],
                ),
                textDirection: TextDirection.rtl,
              ),
            );
          },
        ),
        SizedBox(height: 8),
        Text(
          'Namaz Clock',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFFa7f3d0),
          ),
        ),
      ],
    );
  }

  Widget _buildVerseCard() {
    return Container(
      padding: EdgeInsets.all(32),
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'وَأَقِيمُوا الصَّلَاةَ وَآتُوا الزَّكَاةَ وَارْكَعُوا مَعَ الرَّاكِعِينَ',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              height: 1.8,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 24),
          Text(
            '"And establish prayer and give zakah and bow with those who bow [in worship and obedience]."',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFa7f3d0),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            '— Surah Al-Baqarah (2:43)',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFbbf7d0),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _loadingController,
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(
                  0,
                  math.sin((_loadingController.value * 2 * math.pi) +
                      (index * math.pi / 3)) * 8,
                ),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildFloatingShape(int index) {
    final positions = [
      Offset(50, 100),
      Offset(300, 200),
      Offset(80, 400),
      Offset(280, 350),
    ];

    final colors = [
      Color(0xFFd4af37),
      Color(0xFF2d5016),
      Color(0xFF8b4513),
      Color(0xFFd4af37),
    ];

    return Positioned(
      left: positions[index].dx,
      top: positions[index].dy,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              math.sin(_floatController.value * 2 * math.pi + index) * 20,
              math.cos(_floatController.value * 2 * math.pi + index) * 15,
            ),
            child: Transform.rotate(
              angle: _floatController.value * 2 * math.pi,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colors[index],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors[index].withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIslamicPattern(Alignment alignment, double left, double top) {
    return Positioned(
      left: alignment == Alignment.topLeft ? left : null,
      right: alignment == Alignment.bottomRight ? left : null,
      top: alignment == Alignment.topLeft ? top : null,
      bottom: alignment == Alignment.bottomRight ? top : null,
      child: Transform.rotate(
        angle: alignment == Alignment.bottomRight ? math.pi / 4 : 0,
        child: Opacity(
          opacity: 0.2,
          child: Container(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: IslamicPatternPainter(),
            ),
          ),
        ),
      ),
    );
  }
}

class IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final patternSize = 20.0;
    final rows = (size.height / patternSize).ceil();
    final cols = (size.width / patternSize).ceil();

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final x = j * patternSize;
        final y = i * patternSize;

        final path = Path();
        path.moveTo(x + patternSize / 2, y);
        path.lineTo(x + patternSize, y + patternSize / 2);
        path.lineTo(x + patternSize / 2, y + patternSize);
        path.lineTo(x, y + patternSize / 2);
        path.close();

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}