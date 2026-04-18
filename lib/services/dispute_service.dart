import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/dispute.dart';
import 'firestore_collections.dart';

class DisputeService {
  DisputeService(this._firestore);

  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  Stream<List<Dispute>> watchDisputes(String committeeId) {
    return collectionDisputes(_firestore)
        .where('committeeId', isEqualTo: committeeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Dispute.fromMap(doc.data()))
              .toList(growable: false),
        );
  }

  Stream<List<Dispute>> watchAllDisputes() {
    return collectionDisputes(_firestore)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Dispute.fromMap(doc.data()))
              .toList(growable: false),
        );
  }

  Future<void> raiseDispute({
    required String committeeId,
    required String raisedByUid,
    required String reason,
    String referencePaymentId = '',
    String referencePayoutId = '',
  }) async {
    final now = DateTime.now();
    final disputeId = _uuid.v4();
    final dispute = Dispute(
      id: disputeId,
      committeeId: committeeId,
      raisedByUid: raisedByUid,
      reason: reason.trim(),
      referencePaymentId: referencePaymentId,
      referencePayoutId: referencePayoutId,
      createdAt: now,
      updatedAt: now,
    );
    await collectionDisputes(_firestore).doc(disputeId).set(dispute.toMap());
  }

  Future<void> updateDisputeStatus({
    required String disputeId,
    required DisputeStatus status,
    String ownerNote = '',
    String adminResolution = '',
  }) async {
    await collectionDisputes(_firestore).doc(disputeId).update({
      'status': status.value,
      'ownerNote': ownerNote,
      'adminResolution': adminResolution,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
