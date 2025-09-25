// lib/screens/request_masjid_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart'; // ✅ reverse geocoding

class RequestMasjidScreen extends StatefulWidget {
  const RequestMasjidScreen({super.key});

  @override
  State<RequestMasjidScreen> createState() => _RequestMasjidScreenState();
}

class _RequestMasjidScreenState extends State<RequestMasjidScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  final TextEditingController _masjidNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkGreen = Color(0xFF1B5E20);

  bool _isLoading = false;
  LatLng? _selectedLocation;

  /// 🔑 Apna MapTiler API key yaha daalo
  final String mapTilerApiKey = "eAFhpGQWoZDvsE7eWaFX";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _masjidNameController.dispose();
    _addressController.dispose();
    _longitudeController.dispose();
    _latitudeController.dispose();
    super.dispose();
  }

  /// ✅ Convert LatLng → Human-readable Address
  Future<void> _getAddressFromLatLng(LatLng pos) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String fullAddress =
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        setState(() {
          _addressController.text = fullAddress;
        });
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location services are disabled. Please enable them.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are denied.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      LatLng pos = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = pos;
        _latitudeController.text = pos.latitude.toString();
        _longitudeController.text = pos.longitude.toString();
      });

      await _getAddressFromLatLng(pos); // ✅ auto fill address
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate() && _selectedLocation != null) {
      setState(() => _isLoading = true);

      final user = _authService.getCurrentUser();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to submit a request.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final requestData = {
        'masjidName': _masjidNameController.text.trim(),
        'address': _addressController.text.trim(),
        'longitude': _selectedLocation!.longitude,
        'latitude': _selectedLocation!.latitude,
        'userId': user.uid,
        'userName': user.displayName ?? user.email,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'requestType': 'new_masjid',
      };

      try {
        await _firestoreService.addMasjidRequest(requestData);
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masjid request submitted successfully!'),
            backgroundColor: primaryGreen,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error submitting request: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        validator: validator,
        readOnly: readOnly,
        style: const TextStyle(color: darkGreen, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: primaryGreen.withOpacity(0.7)),
          hintStyle: TextStyle(color: primaryGreen.withOpacity(0.4)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Request New Masjid'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation, // ✅ manual refresh
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildSectionTitle('Masjid Details', Icons.mosque),
              _buildTextField(
                controller: _masjidNameController,
                label: 'Masjid Name',
                hint: 'e.g., Al-Farooq Masjid',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                hint: 'Auto-filled from map',
                readOnly: true,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('Select Location on Map', Icons.location_on),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Tap on the map to select Masjid's location",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              SizedBox(
                height: 300,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FlutterMap(
                        options: MapOptions(
                          initialCenter: _selectedLocation ??
                              LatLng(33.6844, 73.0479), // Default Islamabad
                          initialZoom: 15,
                          onTap: (tapPosition, pos) async {
                            setState(() {
                              _selectedLocation = pos;
                              _latitudeController.text =
                                  pos.latitude.toString();
                              _longitudeController.text =
                                  pos.longitude.toString();
                            });
                            await _getAddressFromLatLng(pos);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$mapTilerApiKey",
                            userAgentPackageName: 'com.example.app',
                          ),
                          if (_selectedLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _selectedLocation!,
                                  width: 80,
                                  height: 80,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
              ),

              const SizedBox(height: 30),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              primaryGreen)),
                    )
                  : ElevatedButton.icon(
                      onPressed: _submitRequest,
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: const Text(
                        'Submit Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryGreen, size: 28),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
      ],
    );
  }
}
