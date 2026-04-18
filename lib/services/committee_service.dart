import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../models/committee.dart';
import '../models/committee_enums.dart';
import '../models/payment_record.dart';
import 'firestore_collections.dart';

class CommitteeService {
  CommitteeService(this._db);

  final FirebaseFirestore _db;
  final Uuid _uuid = const Uuid();

  Stream<List<Committee>> committeesForUser(String uid) {
    return userCommittees(_db, uid).snapshots().asyncMap((
      membershipSnap,
    ) async {
      final ids = membershipSnap.docs.map((doc) => doc.id).toList();
      if (ids.isEmpty) {
        return const <Committee>[];
      }

      final committeeDocs = await Future.wait(
        ids.map((id) => committeesRef(_db).doc(id).get()),
      );

      final committees = committeeDocs
          .where((doc) => doc.exists && doc.data() != null)
          .map((doc) => Committee.fromMap(doc.data()!))
          .toList();
      committees.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return committees;
    });
  }

  Stream<List<AppUser>> membersForCommittee(String committeeId) {
    return committeeMembers(_db, committeeId).snapshots().asyncMap((
      snap,
    ) async {
      final userDocs = await Future.wait(
        snap.docs.map((doc) {
          final uid = doc.data()['uid'] as String? ?? '';
          return usersRef(_db).doc(uid).get();
        }),
      );
      return userDocs
          .where((doc) => doc.exists && doc.data() != null)
          .map((doc) => AppUser.fromMap(doc.data()!))
          .toList();
    });
  }

  Future<Committee> createCommittee({
    required String ownerUid,
    required String name,
    required double contributionAmount,
    required CommitteeFrequency frequency,
    required int totalIntervals,
    required int memberLimit,
    required Map<String, String> paymentInstructions,
    String customFrequencyLabel = '',
  }) async {
    final now = DateTime.now();
    final committeeId = _uuid.v4();
    final inviteCode = committeeId.substring(0, 8).toUpperCase();

    final committee = Committee(
      id: committeeId,
      name: name,
      ownerId: ownerUid,
      contributionAmount: contributionAmount,
      frequency: frequency,
      customFrequencyLabel: customFrequencyLabel,
      totalIntervals: totalIntervals,
      currentInterval: 1,
      memberLimit: memberLimit,
      memberCount: 1,
      inviteCode: inviteCode,
      payoutOrder: [ownerUid],
      paymentInstructions: paymentInstructions,
      state: CommitteeState.gathering,
      createdAt: now,
      updatedAt: now,
    );

    final batch = _db.batch();
    batch.set(committeesRef(_db).doc(committee.id), committee.toMap());
    batch.set(committeeMembers(_db, committee.id).doc(ownerUid), {
      'uid': ownerUid,
      'joinedAt': Timestamp.fromDate(now),
    });
    batch.set(userCommittees(_db, ownerUid).doc(committee.id), {
      'committeeId': committee.id,
      'joinedAt': Timestamp.fromDate(now),
    });
    await batch.commit();
    return committee;
  }

  Future<void> joinCommittee({
    required String uid,
    required String inviteCode,
  }) async {
    final committeeQuery = await committeesRef(
      _db,
    ).where('inviteCode', isEqualTo: inviteCode.toUpperCase()).limit(1).get();
    if (committeeQuery.docs.isEmpty) {
      throw StateError('Invalid invite code.');
    }

    final committee = Committee.fromMap(committeeQuery.docs.first.data());
    final memberSnap = await committeeMembers(_db, committee.id).get();
    if (memberSnap.size >= committee.memberLimit) {
      throw StateError('Committee is full.');
    }
    if (committee.state != CommitteeState.gathering) {
      throw StateError('Committee is locked.');
    }
    final userDoc = await usersRef(_db).doc(uid).get();
    if (!userDoc.exists || userDoc.data() == null) {
      throw StateError('User not found.');
    }
    final user = AppUser.fromMap(userDoc.data()!);
    if (user.atRisk) {
      throw StateError('At-risk users cannot join new committees.');
    }

    final now = DateTime.now();
    var updatedPayout = committee.payoutOrder;
    var shouldActivate = false;
    await _db.runTransaction((tx) async {
      final memberRef = committeeMembers(_db, committee.id).doc(uid);
      final memberDoc = await tx.get(memberRef);
      if (memberDoc.exists) {
        return;
      }

      tx.set(memberRef, {'uid': uid, 'joinedAt': Timestamp.fromDate(now)});
      tx.set(userCommittees(_db, uid).doc(committee.id), {
        'committeeId': committee.id,
        'joinedAt': Timestamp.fromDate(now),
      });

      updatedPayout = [...committee.payoutOrder, uid];
      shouldActivate = updatedPayout.length >= committee.memberLimit;
      tx.update(committeesRef(_db).doc(committee.id), {
        'payoutOrder': updatedPayout,
        'memberCount': updatedPayout.length,
        'state': shouldActivate
            ? CommitteeState.active.value
            : committee.state.value,
        'updatedAt': Timestamp.fromDate(now),
      });
    });
    if (shouldActivate) {
      await _ensurePaymentSchedule(
        committee: committee.copyWith(
          payoutOrder: updatedPayout,
          memberCount: updatedPayout.length,
          state: CommitteeState.active,
          updatedAt: now,
        ),
      );
    }
  }

  Stream<Committee?> watchCommittee(String committeeId) {
    return committeesRef(_db).doc(committeeId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        return null;
      }
      return Committee.fromMap(data);
    });
  }

  Future<void> advanceInterval(Committee committee) async {
    final next = (committee.currentInterval + 1).clamp(
      1,
      committee.totalIntervals,
    );
    await committeesRef(_db).doc(committee.id).update({
      'currentInterval': next,
      'state': next >= committee.totalIntervals
          ? CommitteeState.completed.value
          : committee.state.value,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> ensurePaymentSchedule(Committee committee) {
    return _ensurePaymentSchedule(committee: committee);
  }

  Future<void> _ensurePaymentSchedule({required Committee committee}) async {
    final existing = await collectionPayments(
      _db,
    ).where('groupId', isEqualTo: committee.id).limit(1).get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final now = DateTime.now();
    final batch = _db.batch();
    for (final memberId in committee.payoutOrder) {
      for (var interval = 1; interval <= committee.totalIntervals; interval++) {
        final payment = PaymentRecord(
          id: _uuid.v4(),
          groupId: committee.id,
          memberUid: memberId,
          ownerUid: committee.ownerId,
          intervalIndex: interval,
          amount: committee.contributionAmount,
          dueAt: now.add(_intervalDuration(committee.frequency, interval)),
          createdAt: now,
          updatedAt: now,
        );
        batch.set(collectionPayments(_db).doc(payment.id), payment.toMap());
      }
    }
    await batch.commit();
  }

  Duration _intervalDuration(CommitteeFrequency frequency, int interval) {
    switch (frequency) {
      case CommitteeFrequency.daily:
        return Duration(days: interval);
      case CommitteeFrequency.weekly:
        return Duration(days: interval * 7);
      case CommitteeFrequency.monthly:
        return Duration(days: interval * 30);
      case CommitteeFrequency.custom:
        return Duration(days: interval * 10);
    }
  }
}
