// lib/screens/qibla_direction_screen.dart
import 'dart:async';
import 'dart:math' as math; // Import dart:math with an alias 'math'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:flutter_compass/flutter_compass.dart';

class QiblaDirectionScreen extends StatefulWidget {
  const QiblaDirectionScreen({super.key});

  @override
  State<QiblaDirectionScreen> createState() => _QiblaDirectionScreenState();
}

class _QiblaDirectionScreenState extends State<QiblaDirectionScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color lightGreen = Color(0xFF81C784);

  double? _qiblaDirection;
  double? _compassHeading;
  String _locationMessage = 'Fetching location...';
  bool _isLoading = true;
  StreamSubscription<CompassEvent>? _compassSubscription;
  Coordinates? _userCoordinates;

  @override
  void initState() {
    super.initState();
    _determinePositionAndCalculateQibla();
    _initCompassListener();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  void _initCompassListener() {
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() {
          _compassHeading = event.heading;
        });
      }
    });
  }

  Future<void> _determinePositionAndCalculateQibla() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _isLoading = true;
      _locationMessage = 'Checking location services...';
    });

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
        _locationMessage =
            'Location services are disabled. Please enable them to get Qibla direction.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      setState(() {
        _locationMessage = 'Location permissions denied. Requesting...';
      });
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _locationMessage =
              'Location permissions are denied. Cannot determine Qibla direction.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        _locationMessage =
            'Location permissions are permanently denied. Please enable them in app settings.';
      });
      return;
    }

    setState(() {
      _locationMessage = 'Getting your current location...';
    });
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _userCoordinates = Coordinates(position.latitude, position.longitude);

      // FIX 1: Call Qibla.qibla instead of just qibla
      _qiblaDirection = Qibla(_userCoordinates!).direction;
      setState(() {
        _isLoading = false;
        _locationMessage =
            'Location: ${_userCoordinates!.latitude.toStringAsFixed(2)}, ${_userCoordinates!.longitude.toStringAsFixed(2)}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _locationMessage =
            'Failed to get location: $e. Please ensure GPS is active.';
      });
      print('Error getting location or calculating Qibla: $e');
    }
  }

  double _getQiblaRotationAngle() {
    if (_qiblaDirection == null || _compassHeading == null) {
      return 0.0;
    }
    double angle = (_qiblaDirection! - _compassHeading! + 360) % 360;

    // FIX 2: Use math.pi
    return angle * (math.pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Qibla Direction'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      _locationMessage,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : _qiblaDirection == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 100,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      _locationMessage,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _determinePositionAndCalculateQibla,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              lightGreen.withOpacity(0.3),
                              primaryGreen.withOpacity(0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: primaryGreen, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: primaryGreen.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _CompassPainter(primaryGreen, darkGreen),
                        ),
                      ),
                      Transform.rotate(
                        // FIX 2: Use math.pi
                        angle: (_compassHeading ?? 0) * (math.pi / 180) * -1,
                        child: Icon(
                          Icons.north,
                          size: 200,
                          color: darkGreen.withOpacity(0.7),
                        ),
                      ),
                      Transform.rotate(
                        angle: _getQiblaRotationAngle(),
                        child: Icon(
                          Icons.arrow_upward,
                          size: 100,
                          color: Colors.redAccent,
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryGreen,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Qibla Direction: ${_qiblaDirection!.toStringAsFixed(2)}°',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Current Heading: ${(_compassHeading ?? 0).toStringAsFixed(2)}°',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Point your device towards the red arrow for Qibla. Ensure you are away from magnetic interference.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final Color majorColor;
  final Color minorColor;

  _CompassPainter(this.majorColor, this.minorColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final majorTickPaint = Paint()
      ..color = majorColor
      ..strokeWidth = 2;
    final minorTickPaint = Paint()
      ..color = minorColor.withOpacity(0.5)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      // FIX 2: Use math.pi and math.cos/sin
      final angle = i * math.pi / 2;
      final p1 = Offset(
        center.dx + radius * 0.8 * math.cos(angle),
        center.dy + radius * 0.8 * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(p1, p2, majorTickPaint);
    }

    for (int i = 0; i < 12; i++) {
      if (i % 3 != 0) {
        // FIX 2: Use math.pi and math.cos/sin
        final angle = i * math.pi / 6;
        final p1 = Offset(
          center.dx + radius * 0.9 * math.cos(angle),
          center.dy + radius * 0.9 * math.sin(angle),
        );
        final p2 = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
        canvas.drawLine(p1, p2, minorTickPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
