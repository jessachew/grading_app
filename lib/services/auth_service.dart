import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<fb_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get current user id
  String? get currentUid => _firebaseAuth.currentUser?.uid;

  // Register user
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fb_auth.User? user = credential.user;
      if (user == null) {
        throw Exception('User registration failed.');
      }

      final userModel = UserModel(
        userId: user.uid,
        fullName: fullName,
        email: email,
        role: role,
        createdAt: DateTime.now(),
      );

      // Store in users collection
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      return userModel;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'An error occurred during registration.');
    } catch (e) {
      throw Exception('Failed to register user: $e');
    }
  }

  // Login user
  Future<fb_auth.User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on fb_auth.FirebaseAuthException catch (e) {
      String message = 'An error occurred during login. Please try again.';
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = 'Incorrect email or password. Please check your credentials and try again.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled. Please contact support.';
          break;
        case 'too-many-requests':
          message = 'Too many failed login attempts. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your connection and try again.';
          break;
        default:
          message = e.message ?? 'Failed to login. Please try again.';
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  // Get user profile details
  Future<UserModel?> getUserDetails(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to retrieve user details: $e');
    }
  }

  // Update user profile in Firebase Auth and Firestore
  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String email,
    required String role,
    String? photoUrl,
    String? newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.uid != uid) {
        throw Exception('User is not authenticated correctly.');
      }

      // Update email in Firebase Auth if changed
      if (email != user.email) {
        await user.updateEmail(email);
      }

      // Update password in Firebase Auth if provided
      if (newPassword != null && newPassword.trim().isNotEmpty) {
        await user.updatePassword(newPassword.trim());
      }

      // Update Firestore document
      await _firestore.collection('users').doc(uid).set({
        'fullName': fullName,
        'email': email,
        'role': role,
        'photoUrl': photoUrl,
      }, SetOptions(merge: true));
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('This operation is sensitive and requires recent authentication. Please log out, sign in again, and retry.');
      }
      throw Exception(e.message ?? 'An error occurred during profile update.');
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
