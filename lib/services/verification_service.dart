import 'dart:io';
import 'dart:convert';

class VerificationService {
  VerificationService();

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
    if (uid.isEmpty) {
      throw StateError('User id is required to process $label image.');
    }
    final compressedBytes = await file.readAsBytes();
    if (compressedBytes.isEmpty) {
      throw StateError('Unable to process $label image.');
    }
    return base64Encode(compressedBytes);
  }
}
