// screens/masjid_events_screen.dart

import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
// Import the EventListCard widget from the representative screen
import 'representative/masjid_representative_screen.dart';

class MasjidEventsScreen extends StatefulWidget {
  final String masjidId;
  final String masjidName;

  const MasjidEventsScreen({
    super.key,
    required this.masjidId,
    required this.masjidName,
  });

  @override
  State<MasjidEventsScreen> createState() => _MasjidEventsScreenState();
}

class _MasjidEventsScreenState extends State<MasjidEventsScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _masjidEvents = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Add animation controllers similar to the representative screen for a consistent look
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(_fadeController);

    _fetchMasjidEvents();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

 Future<void> _fetchMasjidEvents() async {
  try {
    final events = await _firestoreService.getMasjidEvents(widget.masjidId).first;
    setState(() {
      _masjidEvents = events;
      _isLoading = false;
      _fadeController.forward(); // Start the animation
    });
  } catch (e) {
    setState(() {
      _errorMessage = 'Failed to load masjid events.';
      _isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.masjidName} Events'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _masjidEvents.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.event_busy,
                              size: 80,
                              color: AppColors.lightGreen,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'There are no upcoming events for ${widget.masjidName}.',
                              style: const TextStyle(
                                fontSize: 18,
                                color: AppColors.darkGreen,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: EventListCard(
                        events: _masjidEvents,
                        fadeAnimation: _fadeAnimation,
                      ),
                    ),
    );
  }
}