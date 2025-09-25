// screens/subscribed_masjids_screen.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'masjid_events_screen.dart';

class SubscribedMasjidsScreen extends StatefulWidget {
  const SubscribedMasjidsScreen({super.key});

  @override
  State<SubscribedMasjidsScreen> createState() =>
      _SubscribedMasjidsScreenState();
}

class _SubscribedMasjidsScreenState extends State<SubscribedMasjidsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _subscribedMasjids = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSubscribedMasjids();
  }

  Future<void> _fetchSubscribedMasjids() async {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User not logged in.';
      });
      return;
    }

    try {
      final rawMasjids = await _firestoreService.getSubscribedMasjids(userId);
      final masjids = rawMasjids.map((masjid) {
        return {
          'id': masjid['id'] ?? masjid['masjidId'] ?? '',
          'name': masjid['name'] ?? '',
          'address': masjid['address'] ?? '',
        };
      }).toList();

      setState(() {
        _subscribedMasjids = masjids;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load subscribed masjids.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscribed Masjids'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _subscribedMasjids.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_off,
                              size: 80,
                              color: Color(0xFF81C784),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'You have not subscribed to any masjids yet.',
                              style: TextStyle(fontSize: 18, color: Color(0xFF1B5E20)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _subscribedMasjids.length,
                      itemBuilder: (context, index) {
                        final masjid = _subscribedMasjids[index];

                        final masjidId = masjid['id'] as String?;
                        final masjidName = masjid['name'] as String?;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: const Icon(Icons.mosque, color: Color(0xFF2E7D32)),
                            title: Text(masjidName ?? 'Unknown Masjid'),
                            subtitle: Text(masjid['address'] ?? 'No Address'),
                            onTap: () {
                              print('Tapped masjid: $masjid');
                              print('masjidId: $masjidId');
                              print('masjidName: $masjidName');

                              if (masjidId != null &&
                                  masjidName != null &&
                                  masjidId.isNotEmpty &&
                                  masjidName.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MasjidEventsScreen(
                                      masjidId: masjidId,
                                      masjidName: masjidName,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Masjid data is incomplete. Cannot show events.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
