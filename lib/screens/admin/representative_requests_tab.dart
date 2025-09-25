import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firestore_service.dart';

class RepresentativeRequestsTab extends StatefulWidget {
  const RepresentativeRequestsTab({super.key});

  @override
  State<RepresentativeRequestsTab> createState() => _RepresentativeRequestsTabState();
}

class _RepresentativeRequestsTabState extends State<RepresentativeRequestsTab>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchRequestsController = TextEditingController();
  
  late AnimationController _listController;
  String _requestSearchQuery = '';

  // Green gradient colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _searchRequestsController.addListener(() {
      setState(() {
        _requestSearchQuery = _searchRequestsController.text;
      });
    });
    
    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    _searchRequestsController.dispose();
    super.dispose();
  }

  Future<void> _handleRepresentativeRequest(
      String requestId, String userId, String masjidId, bool approve) async {
    print('Handling request: $requestId, userId: $userId, masjidId: $masjidId, approve: $approve');
    try {
      if (approve) {
        await _firestoreService.updateRepresentativeRequestStatus(
            requestId, 'accepted', masjidId, userId);
        _showSuccessSnackBar('Representative approved and assigned!');
      } else {
        await _firestoreService.updateRepresentativeRequestStatus(
            requestId, 'rejected', null, null);
        _showSuccessSnackBar('Representative request rejected.');
      }
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('*** CRITICAL ERROR IN _handleRepresentativeRequest: $e');
      _showErrorSnackBar('Failed to handle request: $e');
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _listController,
              curve: Curves.easeOutBack,
            )),
            child: _buildHeader(),
          ),
          const SizedBox(height: 24),
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _listController,
              curve: Interval(0.2, 1.0, curve: Curves.easeOutBack),
            )),
            child: _buildRequestsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8F5E8),
            Color(0xFFF1F8E9),
            Color(0xFFE8F5E8),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: lightGreen.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                  Icons.person_add_alt_1,
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
                      'Representative Requests',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    Text(
                      'Manage pending requests',
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
              controller: _searchRequestsController,
              decoration: InputDecoration(
                labelText: 'Search Requests',
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
                fillColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getPendingRepresentativeRequests(),
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
          return _buildEmptyState('No pending requests', Icons.inbox);
        }

        final requests = snapshot.data!;
        final filteredRequests = requests.where((request) {
          final userNameLower = request['userName'].toLowerCase();
          final masjidNameLower = request['masjidName'].toLowerCase();
          final queryLower = _requestSearchQuery.toLowerCase();
          return userNameLower.contains(queryLower) || masjidNameLower.contains(queryLower);
        }).toList();

        if (filteredRequests.isEmpty) {
          return _buildEmptyState('No matching requests found', Icons.search_off);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredRequests.length,
          itemBuilder: (context, index) {
            final request = filteredRequests[index];
            return _buildRequestCard(request, index);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFFAFDFA),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: lightGreen.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
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
                  child: Icon(
                    Icons.person_add,
                    color: primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${request['userName']} → ${request['masjidName']}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Requested: ${DateTime.fromMillisecondsSinceEpoch(request['requestDate'].millisecondsSinceEpoch).toLocal().toString().split(' ')[0]}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: primaryGreen.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.1),
                    Colors.orange.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pending,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Status: ${request['status']}',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [secondaryGreen, lightGreen],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: secondaryGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _handleRepresentativeRequest(
                        request['id'],
                        request['userId'],
                        request['masjidId'],
                        true,
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleRepresentativeRequest(
                      request['id'],
                      request['userId'],
                      request['masjidId'],
                      false,
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
            child: Icon(
              icon,
              size: 64,
              color: primaryGreen.withOpacity(0.5),
            ),
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
}