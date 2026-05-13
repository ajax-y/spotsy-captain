import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String loginId; // Phone number
  final String role;
  final String kycStatus; // PENDING, VERIFIED, REJECTED
  final String? dob;
  final String? gender;
  final String? address;
  final String? aadhaarLast4;
  final String? email;
  final String? businessName;
  final String? photoUrl;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.loginId,
    required this.role,
    this.kycStatus = 'PENDING',
    this.dob,
    this.gender,
    this.address,
    this.aadhaarLast4,
    this.email,
    this.businessName,
    this.photoUrl,
    required this.createdAt,
  });

  UserModel copyWith({
    String? name,
    String? kycStatus,
    String? dob,
    String? gender,
    String? address,
    String? aadhaarLast4,
    String? email,
    String? businessName,
    String? photoUrl,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      loginId: loginId,
      role: role,
      kycStatus: kycStatus ?? this.kycStatus,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      aadhaarLast4: aadhaarLast4 ?? this.aadhaarLast4,
      email: email ?? this.email,
      businessName: businessName ?? this.businessName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'loginId': loginId,
      'role': role,
      'kycStatus': kycStatus,
      'dob': dob,
      'gender': gender,
      'address': address,
      'aadhaarLast4': aadhaarLast4,
      'email': email,
      'businessName': businessName,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      loginId: map['loginId'] ?? '',
      role: map['role'] ?? 'CAPTAIN',
      kycStatus: map['kycStatus'] ?? 'PENDING',
      dob: map['dob'],
      gender: map['gender'],
      address: map['address'],
      aadhaarLast4: map['aadhaarLast4'],
      email: map['email'],
      businessName: map['businessName'],
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is String 
              ? DateTime.parse(map['createdAt']) 
              : (map['createdAt'] as Timestamp).toDate())
          : DateTime.now(),
    );
  }
}
