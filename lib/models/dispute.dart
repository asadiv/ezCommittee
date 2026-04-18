import 'package:cloud_firestore/cloud_firestore.dart';

enum DisputeStatus { open, inReview, resolved, rejected }

extension DisputeStatusX on DisputeStatus {
  String get value => name;

  static DisputeStatus fromValue(String? value) {
    return DisputeStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DisputeStatus.open,
    );
  }
}

class Dispute {
  const Dispute({
    required this.id,
    required this.committeeId,
    required this.raisedByUid,
    required this.reason,
    required this.createdAt,
    this.status = DisputeStatus.open,
    this.referencePaymentId = '',
    this.referencePayoutId = '',
    this.ownerNote = '',
    this.adminResolution = '',
    this.updatedAt,
  });

  final String id;
  final String committeeId;
  final String raisedByUid;
  final String reason;
  final String referencePaymentId;
  final String referencePayoutId;
  final DisputeStatus status;
  final String ownerNote;
  final String adminResolution;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'committeeId': committeeId,
      'raisedByUid': raisedByUid,
      'reason': reason,
      'referencePaymentId': referencePaymentId,
      'referencePayoutId': referencePayoutId,
      'status': status.value,
      'ownerNote': ownerNote,
      'adminResolution': adminResolution,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory Dispute.fromMap(Map<String, dynamic> map) {
    return Dispute(
      id: map['id'] as String? ?? '',
      committeeId: map['committeeId'] as String? ?? '',
      raisedByUid: map['raisedByUid'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      referencePaymentId: map['referencePaymentId'] as String? ?? '',
      referencePayoutId: map['referencePayoutId'] as String? ?? '',
      status: DisputeStatusX.fromValue(map['status'] as String?),
      ownerNote: map['ownerNote'] as String? ?? '',
      adminResolution: map['adminResolution'] as String? ?? '',
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: map['updatedAt'] == null
          ? null
          : _parseTimestamp(map['updatedAt']),
    );
  }

  static DateTime _parseTimestamp(dynamic source) {
    if (source is Timestamp) {
      return source.toDate();
    }
    if (source is DateTime) {
      return source;
    }
    return DateTime.now();
  }
}
