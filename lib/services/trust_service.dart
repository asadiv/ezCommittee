import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payment_record.dart';
import 'firestore_collections.dart';

class TrustService {
  TrustService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> recalculateUserTrust(String uid) => recomputeForUser(uid);

  Future<void> recomputeForUser(String uid) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.payments)
        .where('memberUid', isEqualTo: uid)
        .get();
    final records = snapshot.docs
        .map((doc) => PaymentRecord.fromMap(doc.data()))
        .toList(growable: false);
    if (records.isEmpty) {
      return;
    }

    final verified = records
        .where((payment) => payment.status == PaymentStatus.verified)
        .toList(growable: false);
    final paidCount = verified.length;
    if (paidCount == 0) {
      await _firestore.collection(FirestoreCollections.users).doc(uid).update({
        'onTimeRate': 0,
        'lateRate': 0,
        'trustScore': 0,
      });
      return;
    }

    final onTimeCount = verified.where((payment) => !payment.isLate).length;
    final lateCount = verified.where((payment) => payment.isLate).length;
    final onTimeRate = (onTimeCount / paidCount) * 100;
    final lateRate = (lateCount / paidCount) * 100;

    await _firestore.collection(FirestoreCollections.users).doc(uid).update({
      'onTimeRate': onTimeRate,
      'lateRate': lateRate,
      'trustScore': onTimeRate,
      'updatedAt': Timestamp.now(),
    });
  }
}
