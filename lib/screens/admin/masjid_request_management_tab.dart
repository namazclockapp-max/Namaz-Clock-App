// lib/screens/masjid_request_management_tab.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:namaz_clock_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class MasjidRequestManagementTab extends StatefulWidget {
  const MasjidRequestManagementTab({super.key});

  @override
  State<MasjidRequestManagementTab> createState() => _MasjidRequestManagementTabState();
}

class _MasjidRequestManagementTabState extends State<MasjidRequestManagementTab> {
  final FirestoreService _firestoreService = FirestoreService();
  // Add FirebaseAuth instance for debugging authentication state
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color lightGreen = Color(0xFF81C784);

  @override
  void initState() {
    super.initState();

    // Check authentication state right here for debugging
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      print('MasjidRequestManagementTab: User is authenticated. UID: ${currentUser.uid}, Email: ${currentUser.email}');
    } else {
      print('MasjidRequestManagementTab: User is NOT authenticated.');
    }

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200.0),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // IconButton(
                  //   icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  //   onPressed: () => Navigator.pop(context),
                  // ),
                  const Expanded(
                    child: Text(
                      'Masjid Request Management',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 10),
              _buildSearchBar(),
              const SizedBox(height: 10),
              _buildFilterAndSortButtons(),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getFilteredMasjidRequestStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (snapshot.error.toString().contains('The query requires an index')) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 20),
                      const Text(
                        'Oops! Something went wrong.',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Error: ${snapshot.error.toString()}\n\n'
                        'This query requires a Firestore index. Please go to your Firebase console '
                        'and create the missing composite index. The console link '
                        'should be provided in the full error message in your debug console or Firebase UI.',
                        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center( // Corrected syntax here, removed extra closing parenthesis and comma
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, color: Colors.grey, size: 60),
                  SizedBox(height: 10),
                  Text('No masjid requests yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            ); // Corrected
          }

          List<Map<String, dynamic>> requestList = snapshot.data!;

          if (_searchText.isNotEmpty) {
            requestList = requestList.where((request) {
              final masjidName = (request['masjidName'] as String? ?? '').toLowerCase();
              final requesterName = (request['requesterName'] as String? ?? '').toLowerCase();
              final requesterEmail = (request['requesterEmail'] as String? ?? '').toLowerCase();
              final requestType = (request['requestType'] as String? ?? '').toLowerCase();
              final query = _searchText.toLowerCase();
              return masjidName.contains(query) ||
                  requesterName.contains(query) ||
                  requesterEmail.contains(query) ||
                  requestType.contains(query);
            }).toList();
          }

          if (requestList.isEmpty && _searchText.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, color: Colors.grey, size: 60),
                  const SizedBox(height: 10),
                  Text('No matching requests found for "${_searchText}".', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: requestList.length,
            itemBuilder: (context, index) {
              final request = requestList[index];
              return _buildMasjidRequestCard(request);
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search masjid requests...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: InputBorder.none,
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchText = '';
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterAndSortButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showFilterBottomSheet,
            icon: const Icon(Icons.filter_list, color: primaryGreen),
            label: Text('Filter: ${_selectedFilter.capitalize()}', style: const TextStyle(color: primaryGreen)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryGreen),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sort functionality coming soon!')),
              );
            },
            icon: const Icon(Icons.sort, color: primaryGreen),
            label: const Text('Sort: Newest', style: TextStyle(color: primaryGreen)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryGreen),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Filter Masjid Requests By:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGreen),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  _buildFilterChip('all', 'All'),
                  _buildFilterChip('pending', 'Pending'),
                  _buildFilterChip('approved', 'Approved'),
                  _buildFilterChip('rejected', 'Rejected'),
                  _buildFilterChip('new_masjid', 'New Masjid'),
                  _buildFilterChip('update_info', 'Update Info'),
                  _buildFilterChip('other', 'Other'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Apply Filter'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String filterValue, String label) {
    final isSelected = _selectedFilter == filterValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primaryGreen.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? primaryGreen : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? primaryGreen : Colors.grey[400]!,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filterValue;
          });
        }
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _getFilteredMasjidRequestStream() {
    // Always fetch all requests and then filter in-memory to handle cases
    // where 'requestType' might be missing in older documents and to avoid
    // complex Firestore indexing issues for various filters.
    return _firestoreService.getAllMasjidRequests().map((list) {
      if (_selectedFilter == 'all') {
        return list;
      } else if (_selectedFilter == 'pending' || _selectedFilter == 'approved' || _selectedFilter == 'rejected') {
        return list.where((request) => request['status'] == _selectedFilter).toList();
      } else {
        // Handle 'new_masjid', 'update_info', 'other' filters in-memory
        return list.where((request) {
          final requestType = request['requestType'] as String?;
          if (_selectedFilter == 'new_masjid') {
            // Treat null requestType as 'new_masjid' for this filter if it's the default request type.
            return requestType == 'new_masjid' || requestType == null;
          }
          return requestType == _selectedFilter;
        }).toList();
      }
    });
  }

  Widget _buildMasjidRequestCard(Map<String, dynamic> request) {
    // Default to 'new_masjid' if requestType is null for display purposes.
    final String requestType = request['requestType'] ?? 'new_masjid';
    final String masjidName = request['masjidName'] ?? 'No Masjid Name';
    final String requesterName = request['requesterName'] ?? 'Anonymous';
    // final String requesterEmail = request['requesterEmail'] ?? 'N/A'; // Not directly used in card
    final String status = request['status'] ?? 'pending';
    // Use 'timestamp' or fallback to 'requestDate' if 'timestamp' is not present
    final Timestamp? timestamp = request['timestamp'] is Timestamp
        ? request['timestamp']
        : (request['requestDate'] is Timestamp ? request['requestDate'] : null);

    String formattedTimestamp = 'N/A';
    if (timestamp != null) {
      formattedTimestamp = DateFormat('MMM d, h:mm a').format(timestamp.toDate());
    }

    IconData icon;
    Color iconColor;
    switch (requestType) {
      case 'new_masjid':
        icon = Icons.add_location_alt_outlined;
        iconColor = Colors.blue;
        break;
      case 'update_info':
        icon = Icons.edit_location_alt_outlined;
        iconColor = Colors.orange;
        break;
      case 'other':
        icon = Icons.notes;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.mosque;
        iconColor = Colors.grey;
    }

    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'approved':
        statusColor = primaryGreen;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'in_progress': // Add in_progress status color
        statusColor = Colors.blueAccent;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _showMasjidRequestDetailsDialog(request),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: lightGreen.withOpacity(0.2),
                    child: Icon(Icons.person, color: primaryGreen),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      requesterName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: darkGreen,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 0.5),
              Text(
                'Masjid: ${masjidName}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                'Request Type: ${requestType.capitalize()}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: iconColor, size: 18),
                      const SizedBox(width: 5),
                      Text(
                        requestType.capitalize(),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Text(
                    formattedTimestamp,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton.icon(
                  onPressed: () => _showMasjidRequestDetailsDialog(request),
                  icon: const Icon(Icons.info_outline, color: primaryGreen),
                  label: const Text('View Details', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMasjidRequestDetailsDialog(Map<String, dynamic> request) async {
    final String requestId = request['id'];
    // Default to 'new_masjid' if requestType is null for display purposes.
    final String requestType = request['requestType'] ?? 'new_masjid';
    final String masjidName = request['masjidName'] ?? 'No Masjid Name';
    final String requesterName = request['requesterName'] ?? 'Anonymous';
    final String requesterEmail = request['requesterEmail'] ?? 'N/A';
    final String requestContent = request['requestContent'] ?? 'No content provided';
    final String masjidAddress = request['masjidAddress'] ?? ''; // Added to capture address
    final String masjidCity = request['masjidCity'] ?? '';     // Added to capture city
    final String masjidCountry = request['masjidCountry'] ?? ''; // Added to capture country


    String status = request['status'] ?? 'pending';
    // Use 'timestamp' or fallback to 'requestDate' if 'timestamp' is not present
    final Timestamp? timestamp = request['timestamp'] is Timestamp
        ? request['timestamp']
        : (request['requestDate'] is Timestamp ? request['requestDate'] : null);
    final Timestamp? statusUpdatedAt = request['statusUpdatedAt'] is Timestamp ? request['statusUpdatedAt'] : null;
    String? adminReply = request['adminReply'];

    String formattedTimestamp = 'N/A';
    if (timestamp != null) {
      formattedTimestamp = DateFormat('MMM d, h:mm a').format(timestamp.toDate());
    }

    String formattedStatusUpdate = '';
    if (statusUpdatedAt != null) {
      formattedStatusUpdate = ' (Updated: ${DateFormat('MMM d, h:mm a').format(statusUpdatedAt.toDate())})';
    }

    TextEditingController replyController = TextEditingController(text: adminReply);

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            Color statusColor;
            switch (status) {
              case 'pending':
                statusColor = Colors.orange;
                break;
              case 'approved':
                statusColor = primaryGreen;
                break;
              case 'rejected':
                statusColor = Colors.red;
                break;
              case 'in_progress':
                statusColor = Colors.blueAccent;
                break;
              default:
                statusColor = Colors.grey;
            }

            return AlertDialog(
              titlePadding: EdgeInsets.zero,
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${requestType.capitalize()} Request Details',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: darkGreen),
                        const SizedBox(width: 8),
                        Text('By: ${requesterName}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkGreen)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.email, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Email: ${requesterEmail}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Submitted: ${formattedTimestamp}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkGreen),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        status.toUpperCase() + formattedStatusUpdate,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Masjid Name:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkGreen),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      masjidName,
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    ),
                    if (requestType == 'new_masjid') ...[ // Show address/city/country for new masjid requests
                      const SizedBox(height: 15),
                      Text(
                        'Masjid Address:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkGreen),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        masjidAddress.isNotEmpty ? masjidAddress : 'N/A',
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Masjid City:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkGreen),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        masjidCity.isNotEmpty ? masjidCity : 'N/A',
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Masjid Country:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkGreen),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        masjidCountry.isNotEmpty ? masjidCountry : 'N/A',
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                    ],
                    const SizedBox(height: 15),
                    Text(
                      'Request Content:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkGreen),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      requestContent,
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    ),
                    if (adminReply != null && adminReply!.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      Text(
                        'Reply from Admin:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryGreen),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryGreen.withOpacity(0.2)),
                        ),
                        child: Text(
                          adminReply!,
                          style: TextStyle(fontSize: 14, color: darkGreen),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextField(
                      controller: replyController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Reply to this request',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (status == 'pending' || status == 'in_progress') // Only show approve/reject if pending or in_progress
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  await _updateMasjidRequestStatus(requestId, 'rejected', requestType);
                                  setStateInDialog(() {
                                    status = 'rejected';
                                    request['status'] = 'rejected';
                                    request['statusUpdatedAt'] = Timestamp.now();
                                  });
                                  if (mounted) Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Reject'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  await _updateMasjidRequestStatus(requestId, 'approved', requestType, request);
                                  setStateInDialog(() {
                                    status = 'approved';
                                    request['status'] = 'approved';
                                    request['statusUpdatedAt'] = Timestamp.now();
                                  });
                                  if (mounted) Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Approve'),
                              ),
                            ],
                          ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            await _firestoreService.replyToMasjidRequest(requestId, {
                              'adminReply': replyController.text.trim(),
                              'repliedAt': FieldValue.serverTimestamp(),
                              'status': 'in_progress', // Set status to in_progress upon reply
                            });
                            setStateInDialog(() {
                              adminReply = replyController.text.trim();
                              status = 'in_progress';
                              request['adminReply'] = adminReply;
                              request['status'] = status;
                              request['repliedAt'] = Timestamp.now();
                              request['statusUpdatedAt'] = Timestamp.now();
                            });
                            if (mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Reply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Updates the status of a masjid request and optionally adds a new masjid if approved.
  Future<void> _updateMasjidRequestStatus(
    String requestId,
    String status,
    String requestType, [
    Map<String, dynamic>? requestData,
  ]) async {
    try {
      print('[_updateMasjidRequestStatus] Called for Request ID: $requestId, Status: $status, Type: $requestType');
      await _firestoreService.updateMasjidRequestStatus(requestId, status);
      print('[_updateMasjidRequestStatus] Request status updated in Firestore.');

      if (status == 'approved' && requestType == 'new_masjid') {
        print('[_updateMasjidRequestStatus] Request is approved and type is new_masjid.');
        if (requestData != null) {
          print('[_updateMasjidRequestStatus] requestData is NOT null. Proceeding to add new masjid.');
          // Prepare new masjid data
          final newMasjid = {
            'name': requestData['masjidName'] ?? 'Unnamed Masjid',
            'address': requestData['masjidAddress'] ?? '',
            'city': requestData['masjidCity'] ?? '',
            'country': requestData['masjidCountry'] ?? '',
            // Ensure latitude and longitude are handled, even if null in requestData
            'latitude': requestData['latitude'],
            'longitude': requestData['longitude'],
            'createdBy': requestData['requesterId'],
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
            'isApproved': true,
            'prayerTimes': {
              'fajr': '00:00',
              'dhuhr': '00:00',
              'asr': '00:00',
              'maghrib': '00:00',
              'isha': '00:00',
              'jummah': '00:00',
            },
            'contactEmail': requestData['requesterEmail'],
            'contactPhone': requestData['requesterPhone'] ?? '',
            'website': requestData['masjidWebsite'] ?? '',
          };
          print('[_updateMasjidRequestStatus] New Masjid data prepared: $newMasjid');

          // Add the new masjid to the masjids collection
          await _firestoreService.addMasjid(newMasjid);
          print('[_updateMasjidRequestStatus] _firestoreService.addMasjid called successfully.');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New Masjid added successfully!'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        } else {
          print('[_updateMasjidRequestStatus] WARNING: requestData is null for approved new_masjid request.');
        }
      } else {
        print('[_updateMasjidRequestStatus] Condition not met: status=$status, requestType=$requestType. (Expected: approved, new_masjid)');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Masjid request marked as $status!'),
            backgroundColor: primaryGreen,
          ),
        );
      }
    } catch (e) {
      print('[_updateMasjidRequestStatus] ERROR: Failed to update status or add masjid: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status or add masjid: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

extension StringCasingExtension on String {
  String capitalize() => length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}