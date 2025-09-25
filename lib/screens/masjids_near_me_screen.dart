// lib/screens/masjids_near_me_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geodesy/geodesy.dart'; // For distance calculation
import 'package:namaz_clock_app/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class MasjidsNearMeScreen extends StatefulWidget {
  const MasjidsNearMeScreen({super.key});

  @override
  State<MasjidsNearMeScreen> createState() => _MasjidsNearMeScreenState();
}

class _MasjidsNearMeScreenState extends State<MasjidsNearMeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Position? _currentPosition;
  List<Map<String, dynamic>> _nearbyMasjids = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color lightGreen = Color(0xFF81C784);

  @override
  void initState() {
    super.initState();
    _fetchNearbyMasjids();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchNearbyMasjids() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Get user's current location
      Position position = await _determinePosition();
      _currentPosition = position;
      print('User current location: Lat: ${position.latitude}, Lon: ${position.longitude}');

      // 2. Fetch all masjids from Firestore
      List<Map<String, dynamic>> allMasjids = await _firestoreService.getMasjids().first;
      print('Fetched ${allMasjids.length} masjids from Firestore.');

      // 3. Filter masjids based on distance
      List<Map<String, dynamic>> nearby = [];
      final Geodesy geodesy = Geodesy();
      // Increased search radius for debugging purposes
      const double searchRadiusKm = 50.0; // Define your search radius in kilometers

      for (var masjid in allMasjids) {
        final double? masjidLat = masjid['latitude'];
        final double? masjidLon = masjid['longitude'];
        final String masjidName = masjid['name'] ?? 'Unnamed Masjid';

        print('Processing Masjid: $masjidName (ID: ${masjid['id']})');
        print('   Masjid Lat: $masjidLat, Lon: $masjidLon');

        if (masjidLat != null && masjidLon != null) {
          final LatLng userLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude); // Use _currentPosition here
          final LatLng masjidLatLng = LatLng(masjidLat, masjidLon);

          // Cast the result to double to resolve the type error
          final double distanceInMeters = geodesy.distanceBetweenTwoGeoPoints(userLatLng, masjidLatLng).toDouble();
          final double distanceInKm = distanceInMeters / 1000;

          print('   Distance to $masjidName: ${distanceInKm.toStringAsFixed(2)} km');

          if (distanceInKm <= searchRadiusKm) {
            nearby.add({
              ...masjid,
              'distance': distanceInKm, // Add distance for display/sorting
            });
            print('   Added $masjidName to nearby list.');
          } else {
            print('   $masjidName is outside the ${searchRadiusKm} km radius.');
          }
        } else {
          print('   Masjid $masjidName has null latitude or longitude. Skipping.');
        }
      }

      // Sort nearby masjids by distance
      nearby.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      setState(() {
        _nearbyMasjids = nearby;
        _isLoading = false;
      });
      print('Nearby Masjids found: ${_nearbyMasjids.length}');
    } catch (e) {
      print('Error fetching nearby masjids: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $_errorMessage'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled.
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could ask for permissions again
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied.
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _launchMapsDirections(double lat, double lon) async {
    // This URL opens Google Maps with directions from current location to the specified lat/lon.
    // 'q' parameter is for the destination. If you also want to specify the origin, you can use 'saddr' and 'daddr'.
    final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps application.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildEmptyState(String message, IconData icon) {
    String displayMessage = message;
    bool showSettingsButton = false;

    if (_errorMessage != null) {
      if (_errorMessage!.contains('Location services are disabled')) {
        displayMessage = 'Location services are disabled on your device. Please enable them.';
        showSettingsButton = true;
      } else if (_errorMessage!.contains('Location permissions are denied')) {
        displayMessage = 'Location permissions are denied for this app. Please grant them in settings.';
        showSettingsButton = true;
      } else if (_errorMessage!.contains('Location permissions are permanently denied')) {
        displayMessage = 'Location permissions are permanently denied. Please enable them in your device settings.';
        showSettingsButton = true;
      } else {
        displayMessage = 'An unexpected error occurred: $_errorMessage';
      }
    } else if (_nearbyMasjids.isEmpty && !_isLoading) {
      // This message will only show if _errorMessage is null and no masjids are found
      displayMessage = 'No masjids found near your location within 50 km. Try adding a new masjid or check your location accuracy.';
    }

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  lightGreen.withOpacity(0.1),
                  primaryGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 64,
              color: primaryGreen.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            displayMessage,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: primaryGreen.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (showSettingsButton)
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Geolocator.openAppSettings();
                  },
                  icon: const Icon(Icons.settings, color: Colors.white),
                  label: const Text(
                    'Open Settings',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ElevatedButton.icon(
            onPressed: _fetchNearbyMasjids,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Masjids Near Me'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryGreen)),
            )
          : _nearbyMasjids.isEmpty
              ? _buildEmptyState('', Icons.location_off) // Let _buildEmptyState determine the message
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _nearbyMasjids.length,
                  itemBuilder: (context, index) {
                    final masjid = _nearbyMasjids[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              masjid['name'] ?? 'Unknown Masjid',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: darkGreen,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              masjid['address'] ?? 'Address not available',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Distance: ${masjid['distance']?.toStringAsFixed(2) ?? 'N/A'} km',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final double? masjidLat = masjid['latitude'];
                                  final double? masjidLon = masjid['longitude'];
                                  if (masjidLat != null && masjidLon != null) {
                                    _launchMapsDirections(masjidLat, masjidLon);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Masjid location not available.'), backgroundColor: Colors.red),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.directions, color: Colors.white),
                                label: const Text(
                                  'Directions',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}