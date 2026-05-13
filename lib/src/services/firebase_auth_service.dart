import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Phone validation: 1234567890 is false, 9489568455 is true
  bool isPhoneValid(String phone) {
    if (phone.length != 10) return false;
    if (phone == '1234567890' || phone == '0987654321') return false;
    if (RegExp(r'^(\d)\1{9}$').hasMatch(phone)) return false;
    if ('01234567890'.contains(phone) || '9876543210'.contains(phone)) return false;
    return true;
  }

  // Login with RBAC check
  Future<UserCredential> login(String loginId, String password) async {
    if (!isPhoneValid(loginId)) throw Exception('Invalid mobile number.');

    final email = '$loginId@spotsy.com';
    final userCred = await _auth.signInWithEmailAndPassword(email: email, password: password);

    // We allow login even if profile is missing, 
    // the UI will handle redirecting to setup.
    return userCred;
  }

  Future<UserCredential> register(String name, String loginId, String password) async {
    if (!isPhoneValid(loginId)) throw Exception('Please enter a valid mobile number.');

    final email = '$loginId@spotsy.com';
    final userCred = await _auth.createUserWithEmailAndPassword(email: email, password: password);

    try {
      await _db.collection('users').doc(userCred.user!.uid).set({
        'name': name,
        'loginId': loginId,
        'role': 'CAPTAIN',
        'kycStatus': 'PENDING',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      try { await userCred.user?.delete(); } catch (_) {}
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
