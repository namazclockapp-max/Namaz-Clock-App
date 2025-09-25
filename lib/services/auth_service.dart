// services/auth_service.dart
// Handles Firebase Authentication operations
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

get currentUser => getCurrentUser();

  // Sign up with email and password
  Future<User?> signUp(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // Create a user document in Firestore with a default role
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': name,
          'role': 'user', // Default role for new users
          'fcmToken': null, // Will be updated later if FCM is implemented
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      // Handle specific errors (e.g., 'email-already-in-use')
      return null;
    } catch (e) {
      print('Error during sign up: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      return null;
    } catch (e) {
      print('Error during sign in: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Method to send a password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      // We don't need to re-throw here, as the calling code will handle the success
      // case (the email was sent). Any exception from the line above will be caught.
    } on FirebaseAuthException catch (e) {
      // Re-throw the specific Firebase exception. This allows the UI to show
      // a more specific error message based on the error code.
      throw e;
    } catch (e) {
      // Re-throw any other potential errors.
      throw e;
    }
  }

  // Re-authenticate a user (useful for sensitive actions like password change/account deletion)
  Future<UserCredential?> reauthenticateUser(String email, String password) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
      User? user = _auth.currentUser;
      if (user != null) {
        return await user.reauthenticateWithCredential(credential);
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Update password for the current user
  Future<void> updateCurrentUserPassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }
}