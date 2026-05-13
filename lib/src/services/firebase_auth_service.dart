import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Login with RBAC check
  Future<UserCredential> login(String loginId, String password) async {
    // 1. Authenticate with Firebase
    final email = '$loginId@spotsy.com';
    final userCred = await _auth.signInWithEmailAndPassword(email: email, password: password);

    // 2. RBAC Verification (Role-Based Access Control)
    try {
      final userDoc = await _db.collection('users').doc(userCred.user!.uid).get().timeout(const Duration(seconds: 10));
      
      if (!userDoc.exists) {
        // Handle case where user exists in Auth but doc is missing (failed registration retry)
        await _auth.signOut();
        throw Exception('User profile not found. This can happen if registration didn\'t complete. Please register again.');
      }

      final role = userDoc.data()?['role'];
      if (role != 'CAPTAIN') {
        await _auth.signOut();
        throw Exception('Access Denied. This app is only for Parking Owners (Captains).');
      }
    } catch (e) {
      await _auth.signOut();
      if (e is TimeoutException) {
        throw Exception('Connection timed out while fetching user data. Check your internet or Firestore setup.');
      }
      rethrow;
    }

    return userCred;
  }

  // Register with requirement: password == loginId
  Future<UserCredential> register(String name, String loginId, String password) async {
    final email = '$loginId@spotsy.com';
    
    // 1. Create Firebase Auth user
    final userCred = await _auth.createUserWithEmailAndPassword(email: email, password: password);

    // 2. Setup RBAC (Default role for this app is CAPTAIN)
    try {
      await _db.collection('users').doc(userCred.user!.uid).set({
        'name': name,
        'loginId': loginId,
        'role': 'CAPTAIN',
        'kycStatus': 'PENDING',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      // ATOMICITY: If Firestore fails, delete the Auth user so they can try again with the same phone/email
      try {
        await userCred.user?.delete();
      } catch (deleteError) {
        // Silently fail if delete fails, but the main error is the important one
      }
      
      if (e is TimeoutException) {
        throw Exception('Registration timed out while saving data. Please check if your Firestore Database is enabled in the Firebase Console.');
      }
      throw Exception('Failed to save user profile: $e');
    }

    return userCred;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> forgotPassword(String loginId) async {
    final email = '$loginId@spotsy.com';
    await _auth.sendPasswordResetEmail(email: email);
  }

  User? get currentUser => _auth.currentUser;
}
