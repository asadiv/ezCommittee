import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class VerificationService {
  VerificationService(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadCnicFront({
    required String uid,
    required File file,
  }) async {
    return _upload(uid: uid, file: file, label: 'cnic_front');
  }

  Future<String> uploadCnicBack({
    required String uid,
    required File file,
  }) async {
    return _upload(uid: uid, file: file, label: 'cnic_back');
  }

  Future<String> uploadSelfie({required String uid, required File file}) async {
    return _upload(uid: uid, file: file, label: 'selfie');
  }

  Future<String> _upload({
    required String uid,
    required File file,
    required String label,
  }) async {
    final ref = _storage.ref('verifications/$uid/$label.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
