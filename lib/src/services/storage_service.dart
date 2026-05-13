import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> uploadParkingPhoto(String spaceId, File file) async {
    final bytes = await file.readAsBytes();
    return uploadParkingPhotoData(spaceId, bytes);
  }

  Future<String?> uploadParkingPhotoData(String spaceId, Uint8List data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('parking_spaces/$spaceId/$fileName');

    try {
      final uploadTask = await ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<String?> uploadProfilePhoto(Uint8List data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final ref = _storage.ref().child('profile_photos/$uid.jpg');
    final uploadTask = await ref.putData(
      data,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deletePhoto(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Error deleting photo: $e');
    }
  }
}
