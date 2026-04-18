import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import 'crypto_service.dart';
import 'firestore_collections.dart';

class UserService {
  UserService(this._db);

  final FirebaseFirestore _db;
  final CryptoService _crypto = CryptoService.instance;

  Future<AppUser?> getUserById(String uid) async {
    final snapshot = await usersRef(_db).doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return AppUser.fromMap(_decodeUserMap(snapshot.data()!));
  }

  Stream<AppUser?> watchUser(String uid) {
    return usersRef(_db).doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return AppUser.fromMap(_decodeUserMap(snapshot.data()!));
    });
  }

  Future<AppUser> upsertAfterOtp({
    required String uid,
    required String phoneNumber,
    required String fullName,
    required String passwordHash,
    required String fcmToken,
  }) async {
    final now = DateTime.now();
    final userRef = usersRef(_db).doc(uid);
    final existing = await userRef.get();
    if (existing.exists && existing.data() != null) {
      await userRef.update({
        'phoneNumber': phoneNumber,
        'fullName': fullName,
        'passwordHash': passwordHash,
        'fcmToken': fcmToken,
        'updatedAt': Timestamp.fromDate(now),
      });
      final updated = await userRef.get();
      return AppUser.fromMap(updated.data()!);
    }

    final user = AppUser(
      uid: uid,
      phoneNumber: phoneNumber,
      fullName: fullName,
      passwordHash: passwordHash,
      verificationStatus: VerificationStatus.pending,
      createdAt: now,
      updatedAt: now,
      fcmToken: fcmToken,
    );
    await userRef.set(user.toMap());
    return user;
  }

  Future<void> updateAuthMetadata({
    required String uid,
    required String phoneNumber,
    required String fcmToken,
  }) async {
    await usersRef(_db).doc(uid).update({
      'phoneNumber': phoneNumber,
      'fcmToken': fcmToken,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> submitVerification({
    required String uid,
    required String cnicFrontUrl,
    required String cnicBackUrl,
    required String selfieUrl,
    required bool termsAccepted,
  }) async {
    await usersRef(_db).doc(uid).update({
      'cnicFrontUrl': _crypto.encryptText(cnicFrontUrl),
      'cnicBackUrl': _crypto.encryptText(cnicBackUrl),
      'selfieUrl': _crypto.encryptText(selfieUrl),
      'termsAccepted': termsAccepted,
      'verificationStatus': VerificationStatus.pending.value,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> updateVerificationStatus({
    required String uid,
    required VerificationStatus status,
  }) async {
    await usersRef(_db).doc(uid).update({
      'verificationStatus': status.value,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<List<AppUser>> pendingUsers() {
    return usersRef(_db)
        .where(
          'verificationStatus',
          isEqualTo: VerificationStatus.pending.value,
        )
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data().isNotEmpty)
              .map((doc) => AppUser.fromMap(_decodeUserMap(doc.data())))
              .toList(growable: false),
        );
  }

  Map<String, dynamic> _decodeUserMap(Map<String, dynamic> raw) {
    final decoded = Map<String, dynamic>.from(raw);
    decoded['cnicFrontUrl'] = _decryptSafe(
      raw['cnicFrontUrl'] as String? ?? '',
    );
    decoded['cnicBackUrl'] = _decryptSafe(raw['cnicBackUrl'] as String? ?? '');
    decoded['selfieUrl'] = _decryptSafe(raw['selfieUrl'] as String? ?? '');
    return decoded;
  }

  String _decryptSafe(String value) {
    if (value.isEmpty) {
      return value;
    }
    try {
      return _crypto.decryptText(value);
    } catch (_) {
      return value;
    }
  }
}
