import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/committee.dart';
import '../models/payout_event.dart';
import 'firestore_collections.dart';

class PayoutService {
  PayoutService({required FirebaseFirestore firestore, Uuid? uuid})
    : _firestore = firestore,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  Stream<List<PayoutEvent>> watchPayoutEvents(String committeeId) {
    return committeePayouts(_firestore, committeeId)
        .orderBy('cycleNumber')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PayoutEvent.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> ownerConfirmPayout({
    required Committee committee,
    required int cycleNumber,
    required String ownerTransactionId,
  }) async {
    final recipientUid = _recipientForCycle(committee, cycleNumber);
    if (recipientUid == null) {
      throw StateError('No recipient available for cycle $cycleNumber');
    }
    final docRef = committeePayouts(
      _firestore,
      committee.id,
    ).doc('$cycleNumber');
    final now = DateTime.now();
    final exists = await docRef.get();
    if (exists.exists) {
      await docRef.update({
        'ownerTransactionId': ownerTransactionId,
        'ownerConfirmed': true,
        'updatedAt': Timestamp.fromDate(now),
      });
      return;
    }
    final event = PayoutEvent(
      id: '$cycleNumber',
      committeeId: committee.id,
      cycleNumber: cycleNumber,
      recipientUid: recipientUid,
      ownerTransactionId: ownerTransactionId,
      ownerConfirmed: true,
      recipientConfirmed: false,
      createdAt: now,
      updatedAt: now,
    );
    await docRef.set(event.toMap());
  }

  Future<void> recipientConfirmPayout({
    required String committeeId,
    required int cycleNumber,
  }) async {
    await committeePayouts(_firestore, committeeId).doc('$cycleNumber').update({
      'recipientConfirmed': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  String? _recipientForCycle(Committee committee, int cycleNumber) {
    if (committee.payoutOrder.isEmpty) {
      return null;
    }
    final index = cycleNumber - 1;
    if (index < 0 || index >= committee.payoutOrder.length) {
      return null;
    }
    return committee.payoutOrder[index];
  }

  String nextPayoutDraftId() => _uuid.v4();
}
