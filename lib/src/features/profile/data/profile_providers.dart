import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../models/bank_account.dart';
import '../../dashboard/data/dashboard_providers.dart';

final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return null;
        return UserModel.fromMap(snapshot.data()!, snapshot.id);
      });
});

final bankAccountsProvider = StreamProvider<List<BankAccount>>((ref) {
  return ref.watch(firestoreServiceProvider).getBankAccounts();
});
