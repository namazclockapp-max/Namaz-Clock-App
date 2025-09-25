// lib/screens/my_feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

class MyFeedbackScreen extends StatefulWidget {
  const MyFeedbackScreen({super.key});

  @override
  State<MyFeedbackScreen> createState() => _MyFeedbackScreenState();
}

class _MyFeedbackScreenState extends State<MyFeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  bool _isAdmin = false; // Simulate admin status for demonstration

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    // For demonstration, you might check admin status here, e.g.:
    // _checkAdminStatus();
  }

  // Future<void> _checkAdminStatus() async {
  //   // In a real app, you'd fetch user roles/claims from Firestore or Firebase Auth
  //   // For now, let's just hardcode it for testing, or set it based on a known admin UID
  //   if (_currentUser != null && _currentUser!.email == 'admin@example.com') { // Replace with your admin email
  //     setState(() {
  //       _isAdmin = true;
  //     });
  //   }
  // }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback cannot be empty!')),
      );
      return;
    }

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to submit feedback.')),
      );
      return;
    }

    try {
      await _firestore.collection('feedback').add({
        'userId': _currentUser!.uid,
        'userEmail': _currentUser!.email,
        'feedback': _feedbackController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'adminReply': null, // Initialize adminReply as null
        'isReadByAdmin': false, // To track if admin has seen it
        'isReplied': false, // To easily query for replies
        'repliedAt': null,
        'userAcknowledgedReply': false, // Track if user has seen the reply
      });
      _feedbackController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit feedback: $e')),
      );
      print('Error submitting feedback: $e');
    }
  }

  Future<void> _showReplyDialog(DocumentSnapshot feedbackDoc) async {
    final TextEditingController replyController = TextEditingController();
    // Pre-fill if there's an existing reply
    if (feedbackDoc['adminReply'] != null) {
      replyController.text = feedbackDoc['adminReply'];
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Feedback'),
        content: TextField(
          controller: replyController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Type your reply here...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (replyController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reply cannot be empty!')),
                );
                return;
              }
              await _firestore.collection('feedback').doc(feedbackDoc.id).update({
                'adminReply': replyController.text.trim(),
                'isReplied': true,
                'repliedAt': FieldValue.serverTimestamp(),
                'userAcknowledgedReply': false, // Reset when admin replies
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reply sent!')),
              );
            },
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Feedback'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submit New Feedback:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _feedbackController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter your feedback here...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    fillColor: Colors.grey[100],
                    filled: true,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _submitFeedback,
                    icon: const Icon(Icons.send),
                    label: const Text('Submit Feedback'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Fetch feedback for the current user OR all feedback if admin
              stream: _isAdmin
                  ? _firestore.collection('feedback').orderBy('timestamp', descending: true).snapshots()
                  : _firestore.collection('feedback')
                      .where('userId', isEqualTo: _currentUser?.uid)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No feedback submitted yet.'));
                }

                final feedbackDocs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: feedbackDocs.length,
                  itemBuilder: (context, index) {
                    final doc = feedbackDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final feedbackText = data['feedback'] ?? 'No feedback text';
                    final adminReply = data['adminReply'];
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                    final repliedAt = (data['repliedAt'] as Timestamp?)?.toDate();
                    final userEmail = data['userEmail'] ?? 'Anonymous';

                    String formattedDate = timestamp != null
                        ? DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp)
                        : 'N/A';
                    String formattedReplyDate = repliedAt != null
                        ? DateFormat('MMM dd, yyyy - hh:mm a').format(repliedAt)
                        : '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From: $userEmail',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Feedback: "$feedbackText"',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Submitted: $formattedDate',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            if (adminReply != null && adminReply.isNotEmpty) ...[
                              const Divider(height: 20, thickness: 1),
                              Text(
                                'Admin Reply: "$adminReply"',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Replied: $formattedReplyDate',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                            if (_isAdmin) // Only show reply button if user is admin
                              Align(
                                alignment: Alignment.bottomRight,
                                child: TextButton.icon(
                                  onPressed: () => _showReplyDialog(doc),
                                  icon: const Icon(Icons.reply),
                                  label: Text(adminReply != null ? 'Edit Reply' : 'Reply'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}