import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/parking_space.dart';
import '../models/booking.dart';
import '../models/earning.dart';
import '../models/bank_account.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─── Parking Spaces ──────────────────────────────────────────────

  Stream<List<ParkingSpace>> getOwnerSpaces() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('parking_spaces')
        .where('ownerId', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ParkingSpace.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addSpace(ParkingSpace space) async {
    if (_uid == null) return;
    await _db.collection('parking_spaces').add({
      ...space.toMap(),
      'ownerId': _uid,
    });
  }

  Future<void> updateSpace(ParkingSpace space) async {
    await _db.collection('parking_spaces').doc(space.id).update(space.toMap());
  }

  Future<void> deleteSpace(String id) async {
    await _db.collection('parking_spaces').doc(id).delete();
  }

  // ─── Bookings ──────────────────────────────────────────────

  Stream<List<Booking>> getPendingRequests() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('bookings')
        .where('ownerId', isEqualTo: _uid)
        .where('status', isEqualTo: 'PENDING_OWNER_CONFIRMATION')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Booking>> getActiveBookings() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('bookings')
        .where('ownerId', isEqualTo: _uid)
        .where('status', whereIn: ['CONFIRMED', 'ACTIVE'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateBookingStatus(String id, String status) async {
    await _db.collection('bookings').doc(id).update({
      'status': status,
      if (status == 'CONFIRMED') 'ownerConfirmedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Bank Accounts ──────────────────────────────────────────────

  Stream<List<BankAccount>> getBankAccounts() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(_uid)
        .collection('bank_accounts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return BankAccount(
                id: doc.id,
                holderName: data['holderName'] ?? '',
                accountNumber: data['accountNumber'] ?? '',
                ifscCode: data['ifscCode'] ?? '',
                bankName: data['bankName'] ?? '',
                accountType: BankAccountType.values.firstWhere(
                  (e) => e.name == data['accountType'],
                  orElse: () => BankAccountType.savings,
                ),
                isVerified: data['isVerified'] ?? false,
                isPrimary: data['isPrimary'] ?? false,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }).toList());
  }

  Future<void> addBankAccount(BankAccount account) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).collection('bank_accounts').add({
      'holderName': account.holderName,
      'accountNumber': account.accountNumber,
      'ifscCode': account.ifscCode,
      'bankName': account.bankName,
      'accountType': account.accountType.name,
      'isVerified': false,
      'isPrimary': account.isPrimary,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Earnings ──────────────────────────────────────────────────

  Stream<List<Earning>> getEarnings() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('earnings')
        .where('ownerId', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return Earning(
          id: doc.id,
          bookingId: data['bookingId'] ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          transactionStatus: TransactionStatus.values.firstWhere(
            (e) => e.name == data['transactionStatus'],
            orElse: () => TransactionStatus.completed,
          ),
          payoutStatus: PayoutStatus.values.firstWhere(
            (e) => e.name == data['payoutStatus'],
            orElse: () => PayoutStatus.unpaid,
          ),
          payoutDate: (data['payoutDate'] as Timestamp?)?.toDate(),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
