import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:namaz_clock_app/services/firestore_service.dart';

class FeedbackManagementTab extends StatefulWidget {
  const FeedbackManagementTab({super.key});

  @override
  State<FeedbackManagementTab> createState() => _FeedbackManagementTabState();
}

class _FeedbackManagementTabState extends State<FeedbackManagementTab> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color lightGreen = Color(0xFF81C784);

  @override
  void initState() {
    super.initState();
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
        preferredSize: const Size.fromHeight(200.0), // Adjust height as needed
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
                      'Feedback Management',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Placeholder for potential other actions if needed
                  const SizedBox(width: 48), // To balance the back button
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
        stream: _getFilteredFeedbackStream(),
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
                          setState(() {}); // Rebuilds the StreamBuilder to try fetching again
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, color: Colors.grey, size: 60),
                  SizedBox(height: 10),
                  Text('No feedback yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          List<Map<String, dynamic>> feedbackList = snapshot.data!;

          // Apply search filter (client-side for simplicity, consider server-side for large datasets)
          if (_searchText.isNotEmpty) {
            feedbackList = feedbackList.where((feedback) {
              final content = (feedback['feedback'] as String? ?? '').toLowerCase();
              final name = (feedback['name'] as String? ?? '').toLowerCase();
              final email = (feedback['email'] as String? ?? '').toLowerCase();
              final type = (feedback['type'] as String? ?? '').toLowerCase();
              final query = _searchText.toLowerCase();
              return content.contains(query) ||
                     name.contains(query) ||
                     email.contains(query) ||
                     type.contains(query);
            }).toList();
          }
          
          if (feedbackList.isEmpty && _searchText.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, color: Colors.grey, size: 60),
                  SizedBox(height: 10),
                  Text('No matching feedback found for "${_searchText}".', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }


          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: feedbackList.length,
            itemBuilder: (context, index) {
              final feedback = feedbackList[index];
              return _buildFeedbackCard(feedback);
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
          hintText: 'Search feedback...',
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
              // Implement sorting logic here
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
      backgroundColor: Colors.transparent, // Make background transparent
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
                'Filter Feedback By:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGreen),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0, // gap between adjacent chips
                runSpacing: 4.0, // gap between lines
                children: [
                  _buildFilterChip('all', 'All'),
                  _buildFilterChip('pending', 'Pending'),
                  _buildFilterChip('resolved', 'Resolved'),
                  _buildFilterChip('suggestion', 'Suggestions'),
                  _buildFilterChip('complaint', 'Complaints'),
                  _buildFilterChip('praise', 'Praise'),
                  _buildFilterChip('bug_report', 'Bug Reports'),
                  _buildFilterChip('feature_request', 'Feature Requests'),
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
          // No need to pop here, let user hit 'Apply Filter'
        }
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _getFilteredFeedbackStream() {
    if (_selectedFilter == 'all') {
      return _firestoreService.getAllFeedback();
    } else {
      if (_selectedFilter == 'pending' || _selectedFilter == 'resolved') {
         return _firestoreService.getAllFeedback().map((list) {
           return list.where((feedback) => feedback['status'] == _selectedFilter).toList();
         });
      }
      return _firestoreService.getFeedbackByType(_selectedFilter);
    }
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    final String type = feedback['type'] ?? 'N/A';
    final String feedbackContent = feedback['feedback'] ?? 'No content';
    final String name = feedback['name'] ?? 'Anonymous';
    final String email = feedback['email'] ?? 'N/A';
    final String status = feedback['status'] ?? 'pending';
    final Timestamp? timestamp = feedback['timestamp'] is Timestamp ? feedback['timestamp'] : null;

    String formattedTimestamp = 'N/A';
    if (timestamp != null) {
      formattedTimestamp = DateFormat('MMM d, yyyy HH:mm').format(timestamp.toDate());
    }

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'suggestion':
        icon = Icons.lightbulb_outline;
        iconColor = Colors.orange;
        break;
      case 'complaint':
        icon = Icons.thumb_down_outlined;
        iconColor = Colors.red;
        break;
      case 'praise':
        icon = Icons.thumb_up_outlined;
        iconColor = primaryGreen;
        break;
      case 'bug_report':
        icon = Icons.bug_report_outlined;
        iconColor = Colors.redAccent;
        break;
      case 'feature_request':
        icon = Icons.add_circle_outline;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.feedback;
        iconColor = Colors.grey;
    }

    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'resolved':
        statusColor = primaryGreen;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      shadowColor: Colors.black12,
      child: InkWell( // Use InkWell for tap feedback on card
        borderRadius: BorderRadius.circular(15),
        onTap: () => _showFeedbackDetailsDialog(feedback),
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
                      name,
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
                feedbackContent.length > 120
                    ? '${feedbackContent.substring(0, 120)}...'
                    : feedbackContent,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
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
                        type.capitalize(),
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
                  onPressed: () => _showFeedbackDetailsDialog(feedback),
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

  // Dialog to show full feedback details and admin actions
  Future<void> _showFeedbackDetailsDialog(Map<String, dynamic> feedback) async {
    final String feedbackId = feedback['id'];
    final String type = feedback['type'] ?? 'N/A';
    final String feedbackContent = feedback['feedback'] ?? 'No content';
    final String name = feedback['name'] ?? 'Anonymous';
    final String email = feedback['email'] ?? 'N/A';
    String status = feedback['status'] ?? 'pending';
    final Timestamp? timestamp = feedback['timestamp'] is Timestamp ? feedback['timestamp'] : null;
    final Timestamp? statusUpdatedAt = feedback['statusUpdatedAt'] is Timestamp ? feedback['statusUpdatedAt'] : null;
    String? reply = feedback['reply'];

    String formattedTimestamp = 'N/A';
    if (timestamp != null) {
      formattedTimestamp = DateFormat('MMM d, yyyy HH:mm').format(timestamp.toDate());
    }

    String formattedStatusUpdate = '';
    if (statusUpdatedAt != null) {
      formattedStatusUpdate = ' (Updated: ${DateFormat('MMM d, yyyy HH:mm').format(statusUpdatedAt.toDate())})';
    }

    TextEditingController replyController = TextEditingController(text: reply);

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Use StatefulBuilder to update dialog content
          builder: (context, setStateInDialog) {
            Color statusColor;
            switch (status) {
              case 'pending':
                statusColor = Colors.orange;
                break;
              case 'resolved':
                statusColor = primaryGreen;
                break;
              case 'in_progress':
                statusColor = Colors.blue;
                break;
              default:
                statusColor = Colors.grey;
            }

            return AlertDialog(
              titlePadding: EdgeInsets.zero, // Remove default padding
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
                      '${type.capitalize()} Details',
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
                        Text('By: $name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkGreen)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.email, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Email: $email', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Submitted: $formattedTimestamp', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
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
                      'Feedback Content:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkGreen),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      feedbackContent,
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    ),
                    if (reply != null && reply!.isNotEmpty) ...[
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
                          reply!,
                          style: TextStyle(fontSize: 14, color: darkGreen),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextField(
                      controller: replyController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Reply to this feedback',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (status != 'resolved')
                          ElevatedButton(
                            onPressed: () async {
                              await _updateFeedbackStatus(feedbackId, 'resolved');
                              setStateInDialog(() {
                                status = 'resolved'; // Update status in dialog
                                feedback['status'] = 'resolved'; // Update local map
                                feedback['statusUpdatedAt'] = Timestamp.now(); // Update timestamp for display
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Mark as Resolved'),
                          ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            await _firestoreService.replyToFeedback(feedbackId, {
                              'reply': replyController.text.trim(),
                              'repliedAt': FieldValue.serverTimestamp(),
                              'status': 'in_progress', // Set status to in_progress upon reply
                            });
                            setStateInDialog(() {
                              reply = replyController.text.trim();
                              status = 'in_progress';
                              feedback['reply'] = reply;
                              feedback['status'] = status;
                              feedback['repliedAt'] = Timestamp.now();
                              feedback['statusUpdatedAt'] = Timestamp.now();
                            });
                            if (mounted) Navigator.pop(context); // Close dialog after reply
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Send Reply'),
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

  Future<void> _updateFeedbackStatus(String feedbackId, String status) async {
    try {
      await _firestoreService.updateFeedbackStatus(feedbackId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feedback marked as $status!'),
            backgroundColor: primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Extension to capitalize first letter of a string
extension StringCasingExtension on String {
  String capitalize() => length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}