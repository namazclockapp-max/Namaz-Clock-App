// services/firestore_service.dart
// Optimized Firestore service with caching
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';


class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance; // Initialize FirebaseStorage

  // OPTIMIZATION: Add caching for frequently accessed data
  static final Map<String, Map<String, dynamic>> _masjidCache = {};
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // --- Users Collection Operations ---
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      rethrow;
    }
  }

  Future<void> updateUserRole(String uid, String role) async {
    try {
      print('Attempting to update user $uid role to: $role');
      await _firestore.collection('users').doc(uid).update({'role': role});
      print('Successfully updated user $uid role to: $role');
    } catch (e) {
      print('Error updating user $uid role to $role: $e');
      rethrow;
    }
  }

  Future<void> updateUserMasjidId(String uid, String masjidId) async {
    try {
      print('Attempting to update user $uid masjidId to: $masjidId');
      await _firestore.collection('users').doc(uid).update({'masjidId': masjidId});
      print('Successfully updated user $uid masjidId to: $masjidId');
    } catch (e) {
      print('Error updating user $uid masjidId to $masjidId: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList())
        .handleError((error) {
          print('Error getting all users: $error');
          return <Map<String, dynamic>>[];
        });
  }

  Future<void> deleteUser(String userId) async {
    try {
      final masjidsRepresented = await _firestore
          .collection('masjids')
          .where('representativeId', isEqualTo: userId)
          .get();

      for (var doc in masjidsRepresented.docs) {
        await doc.reference.update({'representativeId': null});
      }

      final pendingRequests = await _firestore
          .collection('representativeRequests')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in pendingRequests.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // --- Masjid Collection Operations ---

  // OPTIMIZATION: Optimized getMasjids with better error handling and caching
  Stream<List<Map<String, dynamic>>> getMasjids() {
    return _firestore
        .collection('masjids')
        .snapshots()
        .map((snapshot) {
          try {
            final masjids = snapshot.docs.map((doc) {
              final data = doc.data();
              return {'id': doc.id, ...data};
            }).toList();

            // Update cache
            _updateMasjidCache(masjids);

            return masjids;
          } catch (e) {
            print('Error processing masjids snapshot: $e');
            return <Map<String, dynamic>>[];
          }
        })
        .handleError((error) {
          print('Error in getMasjids stream: $error');
          return <Map<String, dynamic>>[];
        });
  }

  // OPTIMIZATION: Add cache update method
  void _updateMasjidCache(List<Map<String, dynamic>> masjids) {
    _masjidCache.clear();
    for (var masjid in masjids) {
      _masjidCache[masjid['id']] = masjid;
    }
    _lastCacheUpdate = DateTime.now();
  }

  // OPTIMIZATION: Optimized getMasjidById with caching
  Future<Map<String, dynamic>?> getMasjidById(String masjidId) async {
    try {
      // Check cache first
      if (_isCacheValid() && _masjidCache.containsKey(masjidId)) {
        return _masjidCache[masjidId];
      }

      // Fetch from Firestore if not in cache or cache expired
      final doc = await _firestore.collection('masjids').doc(masjidId).get();
      final data = doc.data();

      if (data != null) {
        // Update cache
        _masjidCache[masjidId] = {'id': doc.id, ...data};
        return _masjidCache[masjidId];
      }

      return null;
    } catch (e) {
      print('Error getting masjid by ID: $e');
      rethrow;
    }
  }
  

  // OPTIMIZATION: Cache validation method
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheExpiry;
  }

  Future<void> addMasjid(Map<String, dynamic> masjidData) async {
    try {
      await _firestore.collection('masjids').add(masjidData);
      // Clear cache to force refresh for all masjids
      _masjidCache.clear();
    } catch (e) {
      print('Error adding masjid: $e');
      rethrow;
    }
  }

  Future<void> updateMasjid(String masjidId, Map<String, dynamic> data) async {
    try {
      print('Attempting to update masjid $masjidId with data: $data');
      await _firestore.collection('masjids').doc(masjidId).update(data);
      print('Successfully updated masjid $masjidId with data: $data');
      // Update specific item in cache
      if (_masjidCache.containsKey(masjidId)) {
        _masjidCache[masjidId]!.addAll(data);
      }
    } catch (e) {
      print('Error updating masjid $masjidId: $e');
      rethrow;
    }
  }

  Future<void> deleteMasjid(String masjidId) async {
    try {
      await _firestore.collection('masjids').doc(masjidId).delete();
    } catch (e) {
      print('Error deleting masjid: $e');
      rethrow;
    }
  }

  Future<void> updateMasjidPrayerTimes(
  String masjidId, {
  required String fajr,
  required String dhuhr,
  required String asr,
  required String maghrib,
  required String isha,
  required String jummah,
}) async {
  try {
    final updateData = {
      'prayerTimes.fajr': fajr,
      'prayerTimes.dhuhr': dhuhr,
      'prayerTimes.asr': asr,
      'prayerTimes.maghrib': maghrib,
      'prayerTimes.isha': isha,
      'prayerTimes.jummah': jummah,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('masjids').doc(masjidId).update(updateData);

    if (_masjidCache.containsKey(masjidId)) {
      _masjidCache[masjidId]!.addAll(updateData);
    }
  } catch (e) {
    print('Error updating prayer times: $e');
    rethrow;
  }
}

  // OPTIMIZATION: Optimized subscription toggle with better error handling and cache update
  Future<void> toggleMasjidSubscription(
      String masjidId, String userId, bool subscribe) async {
    try {
      if (subscribe) {
        await _firestore.collection('masjids').doc(masjidId).update({
          'subscribers': FieldValue.arrayUnion([userId])
        });
      } else {
        await _firestore.collection('masjids').doc(masjidId).update({
          'subscribers': FieldValue.arrayRemove([userId])
        });
      }

      // Re-fetch the specific masjid to update cache accurately after array operations
      // This is safer than manual list manipulation, especially with multiple clients
      getMasjidById(masjidId);

    } catch (e) {
      print('Error toggling subscription: $e');
      rethrow;
    }
  }

  // --- Masjid Request Operations (for user to request admin to add masjid) ---
  Future<void> addMasjidRequest(Map<String, dynamic> requestData) async {
    try {
      await _firestore.collection('masjidRequests').add(requestData);
    } catch (e) {
      print('Error adding masjid request: $e');
      rethrow;
    }
  }

  // Method specifically called by masjid_request_management_tab.dart
  Stream<QuerySnapshot> getMasjidRequests() {
    return _firestore.collection('masjidRequests').orderBy('timestamp', descending: true).snapshots(); // Changed 'createdAt' to 'timestamp'
  }

  // NEW METHOD: Get only pending masjid requests
  Stream<QuerySnapshot<Map<String, dynamic>>> getPendingMasjidRequests() {
    return _firestore.collection('masjidRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<List<Map<String, dynamic>>> getAllMasjidRequests() {
    return _firestore.collection('masjidRequests').orderBy('timestamp', descending: true).snapshots().map((snapshot) { // Changed 'createdAt' to 'timestamp'
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    }).handleError((error) {
      print('Error getting all masjid requests: $error');
      return <Map<String, dynamic>>[];
    });
  }

  Stream<List<Map<String, dynamic>>> getMasjidRequestsByType(String type) {
    return _firestore.collection('masjidRequests').where('requestType', isEqualTo: type).orderBy('timestamp', descending: true).snapshots().map((snapshot) { // Changed 'createdAt' to 'timestamp'
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    }).handleError((error) {
      print('Error getting masjid requests by type: $error');
      return <Map<String, dynamic>>[];
    });
  }

  Future<void> updateMasjidRequestStatus(String requestId, String status) async {
    try {
      await _firestore.collection('masjidRequests').doc(requestId).update({
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating masjid request status: $e');
      rethrow;
    }
  }

  Future<void> replyToMasjidRequest(String requestId, Map<String, dynamic> replyData) async {
    try {
      await _firestore.collection('masjidRequests').doc(requestId).update({
        'adminReply': replyData['adminReply'],
        'repliedAt': FieldValue.serverTimestamp(), // Use server timestamp for consistency
        'status': replyData['status'], // Update status when admin replies
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error replying to masjid request: $e');
      rethrow;
    }
  }

  // --- Representative Requests Operations ---
  Future<void> sendRepresentativeRequest(
      String userId, String userName, String masjidId, String masjidName) async {
    try {
      await _firestore.collection('representativeRequests').add({ 
        'userId': userId,
        'userName': userName,
        'masjidId': masjidId,
        'masjidName': masjidName,
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending representative request: $e');
      rethrow;
    }
  }
  
  // Stream to get all representative requests
  Stream<QuerySnapshot> getRepresentativeRequests() {
    return _firestore.collection('representativeRequests').snapshots();
  }

  Stream<List<Map<String, dynamic>>> getPendingRepresentativeRequests() {
    return _firestore
        .collection('representativeRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        }).handleError((error) {
          print('Error getting pending representative requests: $error');
          return <Map<String, dynamic>>[];
        });
  }

  // Stream to get the count of pending representative requests
  Stream<int> getPendingRepresentativeRequestsCount() {
    return _firestore
        .collection('representativeRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> updateRepresentativeRequestStatus(
      String requestId, String status, String? masjidId, String? representativeId) async {
    try {
      await _firestore
          .collection('representativeRequests')
          .doc(requestId)
          .update({'status': status});
      
      if (status == 'accepted' && masjidId != null && representativeId != null) {
        await _firestore.collection('masjids').doc(masjidId).update({
          'representativeId': representativeId,
        });
        await _firestore.collection('users').doc(representativeId).update({
          'role': 'representative',
          'masjidId': masjidId,
        });
      }
    } catch (e) {
      print('Error updating representative request status: $e');
      rethrow;
    }
  }

  // --- User Profile Operations ---
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
  
  /// Uploads a profile image to Firebase Storage. This method is cross-platform compatible.
  /// It accepts the image as raw bytes (Uint8List) and the filename.
  // Future<String?> uploadProfileImage(
  //     String userId, Uint8List imageBytes, String fileName) async {
  //   try {
  //     final ref = _storage
  //         .ref()
  //         .child('profile_images')
  //         .child(userId)
  //         .child(fileName);

  //     await ref.putData(imageBytes);
  //     final downloadUrl = await ref.getDownloadURL();
  //     return downloadUrl;
  //   } on FirebaseException catch (e) {
  //     print('Error uploading profile image: ${e.message}');
  //     rethrow;
  //   }
  // }

  

  // --- Feedback Operations ---
  Future<void> submitFeedback(Map<String, dynamic> feedbackData) async {
    try {
      await _firestore.collection('feedback').add(feedbackData);
    } catch (e) {
      print('Error submitting feedback: $e');
      rethrow;
    }
  }

  // Get feedback by type
  Stream<List<Map<String, dynamic>>> getFeedbackByType(String type) {
    return _firestore
        .collection('feedback')
        .where('type', isEqualTo: type)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList())
        .handleError((error) {
          print('Error getting feedback by type: $error');
          return <Map<String, dynamic>>[];
        });
  }

  // NEW METHOD: Get feedback by user ID
  Stream<List<Map<String, dynamic>>> getFeedbackByUserId(String userId) {
    return _firestore
        .collection('feedback')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true) // Order by timestamp to show latest
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList())
        .handleError((error) {
          print('Error getting feedback by user ID: $error');
          return <Map<String, dynamic>>[];
        });
  }

  // Reply to feedback
  Future<void> replyToFeedback(String feedbackId, Map<String, dynamic> replyData) async {
    try {
      await _firestore
          .collection('feedback')
          .doc(feedbackId)
          .update(replyData);
    } catch (e) {
      print('Error replying to feedback: $e');
      rethrow;
    }
  }

  // Update feedback status
  Future<void> updateFeedbackStatus(String feedbackId, String status) async {
    try {
      await _firestore
          .collection('feedback')
          .doc(feedbackId)
          .update({
            'status': status,
            'statusUpdatedAt': FieldValue.serverTimestamp(), // Use server timestamp
          });
    } catch (e) {
      print('Error updating feedback status: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getAllFeedback() {
    return _firestore
        .collection('feedback')
        .orderBy('timestamp', descending: true) // Order for consistency
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList())
        .handleError((error) {
          print('Error getting all feedback: $error');
          return <Map<String, dynamic>>[];
        });
  }
  
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserDocumentStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // --- NEW: Masjid Events Operations ---
  Future<void> addMasjidEvent({
    required String masjidId,
    required String eventName,
    required String description,
    required String dateTime,
    required String day,
  }) async {
    try {
      await _firestore.collection('masjids').doc(masjidId).collection('events').add({
        'eventName': eventName,
        'description': description,
        'dateTime': dateTime,
        'day': day,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding masjid event: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getMasjidEvents(String masjidId) {
    return _firestore
        .collection('masjids')
        .doc(masjidId)
        .collection('events')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Add the document ID to the map
            return data;
          }).toList();
        })
        .handleError((error) {
          print('Error getting masjid events: $error');
          return <Map<String, dynamic>>[];
        });
  }
  
  Future<void> deleteMasjidEvent(String masjidId, String eventId) async {
    try {
      await _firestore.collection('masjids').doc(masjidId).collection('events').doc(eventId).delete();
    } catch (e) {
      print('Error deleting masjid event: $e');
      rethrow;
    }
  }

  Future<void> updateMasjidEvent(String masjidId, String eventId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('masjids').doc(masjidId).collection('events').doc(eventId).update(data);
    } catch (e) {
      print('Error updating masjid event: $e');
      rethrow;
    }
  }
  
  // --- Masjid Announcement Operations ---
  Future<void> addMasjidAnnouncement(String s, String text, {
    required String masjidId,
    required String title,
    required String body,
  }) async {
    try {
      await _firestore.collection('masjids').doc(masjidId).collection('announcements').add({
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding masjid announcement: $e');
      rethrow;
    }
  }

  Future<void> updateMasjidIqamaTimes(String masjidId, Map<String, dynamic> updatedIqamaTimes) async {
    try {
      final updateData = <String, dynamic>{};
      
      // Map the iqama times to flat fields
      if (updatedIqamaTimes.containsKey('fajr')) {
        updateData['fajr'] = updatedIqamaTimes['fajr'];
      }
      if (updatedIqamaTimes.containsKey('dhuhr')) {
        updateData['dhuhr'] = updatedIqamaTimes['dhuhr'];
      }
      if (updatedIqamaTimes.containsKey('asr')) {
        updateData['asr'] = updatedIqamaTimes['asr'];
      }
      if (updatedIqamaTimes.containsKey('maghrib')) {
        updateData['maghrib'] = updatedIqamaTimes['maghrib'];
      }
      if (updatedIqamaTimes.containsKey('isha')) {
        updateData['isha'] = updatedIqamaTimes['isha'];
      }
      if (updatedIqamaTimes.containsKey('jummah')) {
        updateData['jummah'] = updatedIqamaTimes['jummah'];
      }
      
      updateData['lastUpdated'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('masjids').doc(masjidId).update(updateData);
    } catch (e) {
      print('Error updating iqama times: $e');
      rethrow;
    }
  }
Future<List<Map<String, dynamic>>> getSubscribedMasjids(String userId) async {
  try {
    final querySnapshot = await _firestore
        .collection('masjids')
        .where('subscribers', arrayContains: userId)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // Merge root-level timings if prayerTimes is empty or invalid
      final prayerTimes = (data['prayerTimes'] != null &&
              (data['prayerTimes'] as Map).values.any((v) => v != '00:00'))
          ? data['prayerTimes']
          : {
              'fajr': data['fajr'] ?? 'N/A',
              'dhuhr': data['dhuhr'] ?? 'N/A',
              'asr': data['asr'] ?? 'N/A',
              'maghrib': data['maghrib'] ?? 'N/A',
              'isha': data['isha'] ?? 'N/A',
              'jummah': data['jummah'] ?? 'N/A',
            };

      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'address': data['address'] ?? '',
        'prayerTimes': prayerTimes, // ✅ always returns valid times
      };
    }).toList();
  } catch (e) {
    print('Error fetching subscribed masjids: $e');
    return [];
  }
}

//  Future<List<Map<String, dynamic>>> getSubscribedMasjids(String userId) async {
//   try {
//     final querySnapshot = await _firestore
//         .collection('masjids')
//         .where('subscribers', arrayContains: userId)
//         .get();

//     return querySnapshot.docs.map((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       return {
//         'id': doc.id, // ✅ Add the document ID here
//         'name': data['name'] ?? '',
//         'address': data['address'] ?? '',
//         // include any other fields you want
//       };
//     }).toList();
//   } catch (e) {
//     print('Error fetching subscribed masjids: $e');
//     return [];
//   }
// }

  // Stream<List<Map<String, dynamic>>> getSubscribedMasjids(String userId) {
  //   return _db
  //       .collection('masjids')
  //       .where('subscribers', arrayContains: userId)
  //       .snapshots()
  //       .map((snapshot) {
  //     return snapshot.docs.map((doc) {
  //       return {
  //         'id': doc.id,
  //         ...doc.data(),
  //       };
  //     }).toList();
  //   });
  // }
}