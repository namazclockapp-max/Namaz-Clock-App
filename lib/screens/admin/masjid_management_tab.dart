import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/firestore_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MasjidManagementTab extends StatefulWidget {
  const MasjidManagementTab({super.key});

  @override
  State<MasjidManagementTab> createState() => _MasjidManagementTabState();
}

class _MasjidManagementTabState extends State<MasjidManagementTab>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _masjidNameController = TextEditingController();
  final TextEditingController _masjidAddressController =
      TextEditingController();
  final TextEditingController _masjidLatController = TextEditingController();
  final TextEditingController _masjidLngController = TextEditingController();
  final TextEditingController _searchMasjidController = TextEditingController();

  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  LatLng? _selectedLocation;

  String _masjidSearchQuery = '';
  bool _isAddingMasjid = false;

  // Green gradient colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);
  // static const String mapTilerApiKey = String.fromEnvironment('eAFhpGQWoZDvsE7eWaFX');
  static const String mapTilerApiKey = "eAFhpGQWoZDvsE7eWaFX";

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );

    _searchMasjidController.addListener(() {
      setState(() {
        _masjidSearchQuery = _searchMasjidController.text;
      });
    });

    _cardController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _masjidNameController.dispose();
    _masjidAddressController.dispose();
    _masjidLatController.dispose();
    _masjidLngController.dispose();
    _searchMasjidController.dispose();
    super.dispose();
  }

  Future<void> _addMasjid() async {
    if (_masjidNameController.text.isEmpty ||
        _masjidAddressController.text.isEmpty) {
      _showErrorSnackBar('Please fill all required fields');
      return;
    }

    setState(() {
      _isAddingMasjid = true;
    });

    try {
      await _firestoreService.addMasjid({
        'name': _masjidNameController.text,
        'address': _masjidAddressController.text,
        'latitude': double.tryParse(_masjidLatController.text) ?? 0.0,
        'longitude': double.tryParse(_masjidLngController.text) ?? 0.0,
        'representativeId': null,
        'fajrJammat': '00:00 AM',
        'dhuhrJammat': '00:00 AM',
        'asrJammat': '00:00 AM',
        'maghribJammat': '00:00 AM',
        'ishaJammat': '00:00 AM',
        'subscribers': [],
      });

      _clearForm();
      _showSuccessSnackBar('Masjid added successfully!');
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showErrorSnackBar('Failed to add masjid');
    } finally {
      setState(() {
        _isAddingMasjid = false;
      });
    }
  }

  void _clearForm() {
    _masjidNameController.clear();
    _masjidAddressController.clear();
    _masjidLatController.clear();
    _masjidLngController.clear();
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

  Widget _buildAnimatedCard({required Widget child, double delay = 0}) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _cardController,
              curve: Interval(delay, 1.0, curve: Curves.easeOutBack),
            ),
          ),
      child: FadeTransition(opacity: _cardAnimation, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnimatedCard(child: _buildAddMasjidSection()),
          const SizedBox(height: 32),
          _buildAnimatedCard(delay: 0.2, child: _buildMasjidListSection()),
        ],
      ),
    );
  }

  Widget _buildAddMasjidSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9), Color(0xFFE8F5E8)],
          stops: [0.0, 0.5, 1.0],
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                    Icons.add_location_alt,
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
                        'Add New Masjid',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                      ),
                      Text(
                        'Create a new masjid entry',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: primaryGreen.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔹 Masjid Name
            TextField(
              controller: _masjidNameController,
              decoration: const InputDecoration(
                labelText: 'Masjid Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Address
            TextField(
              controller: _masjidAddressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Map Picker (Updated with MapTiler & Auto Address Fill)
            SizedBox(
              height: 250,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(33.6844, 73.0479), // Islamabad default
                  initialZoom: 14,
                  onTap: (tapPosition, LatLng pos) async {
                    setState(() {
                      _selectedLocation = pos;
                      _masjidLatController.text = pos.latitude.toString();
                      _masjidLngController.text = pos.longitude.toString();
                    });

                    // ⬇️ GeoCoding: Address auto fill
                    try {
                      List<Placemark> placemarks =
                          await placemarkFromCoordinates(
                            pos.latitude,
                            pos.longitude,
                          );
                      if (placemarks.isNotEmpty) {
                        final place = placemarks.first;
                        setState(() {
                          _masjidAddressController.text =
                              "${place.street}, ${place.locality}, ${place.country}";
                        });
                      }
                    } catch (e) {
                      debugPrint("Error fetching address: $e");
                    }
                  },
                ),
                children: [
                  // ⬇️ MapTiler tiles
                  TileLayer(
                    urlTemplate:
                        "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$mapTilerApiKey",
                    userAgentPackageName: 'com.example.namaz_clock_app',
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

            const SizedBox(height: 16),

            // 🔹 Latitude
            TextField(
              controller: _masjidLatController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Latitude (auto from map)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Longitude
            TextField(
              controller: _masjidLngController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Longitude (auto from map)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // 🔹 Add Masjid Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addMasjid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'Save Masjid',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: primaryGreen.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightGreen.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightGreen.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMasjidListSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lightGreen.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.08),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [secondaryGreen, lightGreen],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: secondaryGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.list_alt,
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
                        'All Masjids',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                      ),
                      Text(
                        'Manage existing masjids',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: primaryGreen.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _searchMasjidController,
                decoration: InputDecoration(
                  labelText: 'Search Masjids',
                  labelStyle: TextStyle(color: primaryGreen.withOpacity(0.7)),
                  prefixIcon: Icon(Icons.search, color: primaryGreen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: lightGreen.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: lightGreen.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryGreen, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getMasjids(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState('No masjids available', Icons.mosque);
                }

                final masjids = snapshot.data!;
                final filteredMasjids = masjids.where((masjid) {
                  final nameLower = masjid['name'].toLowerCase();
                  final addressLower = masjid['address'].toLowerCase();
                  final queryLower = _masjidSearchQuery.toLowerCase();
                  return nameLower.contains(queryLower) ||
                      addressLower.contains(queryLower);
                }).toList();

                if (filteredMasjids.isEmpty) {
                  return _buildEmptyState(
                    'No matching masjids found',
                    Icons.search_off,
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredMasjids.length,
                  itemBuilder: (context, index) {
                    final masjid = filteredMasjids[index];
                    return _buildMasjidCard(masjid, index);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasjidCard(Map<String, dynamic> masjid, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, lightGreen.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lightGreen.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryGreen.withOpacity(0.1),
                          lightGreen.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryGreen.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(Icons.mosque, color: primaryGreen, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          masjid['name'],
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: darkGreen,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          masjid['address'],
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: primaryGreen.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: masjid['representativeId'] != null
                            ? [
                                secondaryGreen.withOpacity(0.1),
                                lightGreen.withOpacity(0.1),
                              ]
                            : [
                                Colors.grey.withOpacity(0.1),
                                Colors.grey.withOpacity(0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: masjid['representativeId'] != null
                            ? secondaryGreen.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      masjid['representativeId'] != null
                          ? Icons.person
                          : Icons.person_off,
                      color: masjid['representativeId'] != null
                          ? secondaryGreen
                          : Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    icon: Icons.edit,
                    color: Colors.blue,
                    onPressed: () => _updateMasjid(masjid['id'], masjid),
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.delete,
                    color: Colors.red,
                    onPressed: () =>
                        _deleteMasjid(masjid['id'], masjid['name']),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
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
            child: Icon(icon, size: 64, color: primaryGreen.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: primaryGreen.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _updateMasjid(
    String masjidId,
    Map<String, dynamic> currentData,
  ) async {
    final TextEditingController editNameController = TextEditingController(
      text: currentData['name'],
    );
    final TextEditingController editAddressController = TextEditingController(
      text: currentData['address'],
    );
    final TextEditingController editLatController = TextEditingController(
      text: currentData['latitude'].toString(),
    );
    final TextEditingController editLngController = TextEditingController(
      text: currentData['longitude'].toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryGreen, secondaryGreen],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Edit Masjid'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: editNameController,
                label: 'Masjid Name',
                icon: Icons.mosque,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: editAddressController,
                label: 'Address',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: editLatController,
                      label: 'Latitude',
                      icon: Icons.my_location,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: editLngController,
                      label: 'Longitude',
                      icon: Icons.place,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryGreen, secondaryGreen],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await _firestoreService.updateMasjid(masjidId, {
                    'name': editNameController.text,
                    'address': editAddressController.text,
                    'latitude': double.tryParse(editLatController.text) ?? 0.0,
                    'longitude': double.tryParse(editLngController.text) ?? 0.0,
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  _showSuccessSnackBar('Masjid updated successfully!');
                } catch (e) {
                  _showErrorSnackBar('Failed to update masjid');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Update'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMasjid(String masjidId, String masjidName) async {
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
                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Delete Masjid'),
              ],
            ),
            content: Text('Are you sure you want to delete $masjidName?'),
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
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await _firestoreService.deleteMasjid(masjidId);
        _showSuccessSnackBar('$masjidName deleted successfully!');
      } catch (e) {
        _showErrorSnackBar('Failed to delete masjid');
      }
    }
  }
}
