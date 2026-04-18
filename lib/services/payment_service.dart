import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/payment_record.dart';
import 'crypto_service.dart';
import 'firestore_collections.dart';
import 'trust_service.dart';

class PaymentService {
  PaymentService(this._firestore, this._trustService) : _uuid = const Uuid();

  final FirebaseFirestore _firestore;
  final TrustService _trustService;
  final Uuid _uuid;
  final CryptoService _crypto = CryptoService.instance;

  CollectionReference<Map<String, dynamic>> get _payments =>
      collectionPayments(_firestore);

  Stream<List<PaymentRecord>> streamCommitteePayments(String committeeId) {
    return _payments
        .where('groupId', isEqualTo: committeeId)
        .orderBy('intervalIndex', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PaymentRecord.fromMap(doc.data()))
              .toList(growable: false);
        });
  }

  Stream<List<PaymentRecord>> streamUserCommitteePayments({
    required String committeeId,
    required String userId,
  }) {
    return _payments
        .where('groupId', isEqualTo: committeeId)
        .where('memberUid', isEqualTo: userId)
        .orderBy('intervalIndex', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PaymentRecord.fromMap(doc.data()))
              .toList(growable: false);
        });
  }

  Future<void> createInitialPaymentRecords({
    required String committeeId,
    required String ownerUid,
    required List<String> memberIds,
    required int totalIntervals,
    required double contributionAmount,
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();
    for (final member in memberIds) {
      for (var interval = 1; interval <= totalIntervals; interval++) {
        final id = _uuid.v4();
        final payment = PaymentRecord(
          id: id,
          groupId: committeeId,
          memberUid: member,
          ownerUid: ownerUid,
          intervalIndex: interval,
          amount: contributionAmount,
          dueAt: now.add(Duration(days: interval * 7)),
          createdAt: now,
          updatedAt: now,
        );
        batch.set(_payments.doc(id), payment.toMap());
      }
    }
    await batch.commit();
  }

  Future<void> submitPayment({
    required String paymentId,
    required String transactionId,
    required String method,
  }) async {
    final now = DateTime.now();
    await _payments.doc(paymentId).update({
      'transactionId': _crypto.encryptText(transactionId),
      'method': method,
      'status': PaymentStatus.pendingVerification.value,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> reviewPayment({
    required PaymentRecord payment,
    required String reviewerUid,
    required bool approve,
    String rejectionReason = '',
  }) async {
    final now = DateTime.now();
    await _payments.doc(payment.id).update({
      'status': approve
          ? PaymentStatus.verified.value
          : PaymentStatus.rejected.value,
      'reviewedBy': reviewerUid,
      'reviewedAt': Timestamp.fromDate(now),
      'rejectionReason': rejectionReason,
      'updatedAt': Timestamp.fromDate(now),
      'isLate': approve
          ? DateTime.now().isAfter(payment.dueAt)
          : payment.isLate,
    });
    if (approve) {
      await _trustService.recalculateUserTrust(payment.memberUid);
    }
  }

  Future<List<PaymentRecord>> getUserPayments(String userId) async {
    final snapshot = await _payments
        .where('memberUid', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => _fromFirestoreMap(doc.data())).toList();
  }

  Future<void> markMissedPaymentsAndRisk({
    required String committeeId,
    required String ownerUid,
  }) async {
    final now = DateTime.now();
    final dueUnpaidSnapshot = await _payments
        .where('groupId', isEqualTo: committeeId)
        .where('status', isEqualTo: PaymentStatus.unpaid.value)
        .where('dueAt', isLessThan: Timestamp.fromDate(now))
        .get();

    final missedByUser = <String, int>{};
    for (final doc in dueUnpaidSnapshot.docs) {
      final payment = PaymentRecord.fromMap(doc.data());
      missedByUser.update(
        payment.memberUid,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    for (final entry in missedByUser.entries) {
      final userRef = usersRef(_firestore).doc(entry.key);
      final snap = await userRef.get();
      final currentMissed =
          (snap.data()?['missedIntervals'] as num?)?.toInt() ?? 0;
      final updatedMissed = currentMissed + entry.value;
      await userRef.update({
        'missedIntervals': updatedMissed,
        'atRisk': updatedMissed >= 3,
        'updatedAt': Timestamp.fromDate(now),
      });
    }

    // Reminder and owner alerts are represented as notification documents.
    final notifications = _firestore.collection(
      FirestoreCollections.notifications,
    );
    for (final doc in dueUnpaidSnapshot.docs) {
      final payment = PaymentRecord.fromMap(doc.data());
      final reminderId = _uuid.v4();
      await notifications.doc(reminderId).set({
        'id': reminderId,
        'userId': payment.memberUid,
        'type': 'payment_reminder',
        'committeeId': committeeId,
        'paymentId': payment.id,
        'message': 'Payment overdue for interval ${payment.intervalIndex}.',
        'createdAt': Timestamp.fromDate(now),
      });
      final memberDoc = await usersRef(_firestore).doc(payment.memberUid).get();
      final memberMissed =
          (memberDoc.data()?['missedIntervals'] as num?)?.toInt() ?? 0;
      if (memberMissed >= 3) {
        final ownerAlertId = _uuid.v4();
        await notifications.doc(ownerAlertId).set({
          'id': ownerAlertId,
          'userId': ownerUid,
          'type': 'at_risk_member',
          'committeeId': committeeId,
          'paymentId': payment.id,
          'message':
              'Member ${payment.memberUid} is at risk (3+ missed payments).',
          'createdAt': Timestamp.fromDate(now),
        });
      }
    }
  }

  PaymentRecord fromFirestoreMap(Map<String, dynamic> map) {
    return _fromFirestoreMap(map);
  }

  PaymentRecord _fromFirestoreMap(Map<String, dynamic> raw) {
    final decoded = Map<String, dynamic>.from(raw);
    final encryptedTx = raw['transactionId'] as String? ?? '';
    if (encryptedTx.isNotEmpty) {
      try {
        decoded['transactionId'] = _crypto.decryptText(encryptedTx);
      } catch (_) {
        decoded['transactionId'] = encryptedTx;
      }
    }
    return PaymentRecord.fromMap(decoded);
  }
}
