import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { pendingVerification, verified, rejected, unpaid }

extension PaymentStatusX on PaymentStatus {
  String get value => name;

  static PaymentStatus fromValue(String? value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.groupId,
    required this.memberUid,
    required this.ownerUid,
    required this.intervalIndex,
    required this.amount,
    required this.dueAt,
    required this.createdAt,
    required this.updatedAt,
    this.transactionId = '',
    this.method = '',
    this.status = PaymentStatus.unpaid,
    this.reviewedBy = '',
    this.reviewedAt,
    this.rejectionReason = '',
    this.isLate = false,
  });

  final String id;
  final String groupId;
  final String memberUid;
  final String ownerUid;
  final int intervalIndex;
  final double amount;
  final DateTime dueAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String transactionId;
  final String method;
  final PaymentStatus status;
  final String reviewedBy;
  final DateTime? reviewedAt;
  final String rejectionReason;
  final bool isLate;

  bool get canRetry =>
      status == PaymentStatus.rejected || status == PaymentStatus.unpaid;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'memberUid': memberUid,
      'ownerUid': ownerUid,
      'intervalIndex': intervalIndex,
      'amount': amount,
      'dueAt': Timestamp.fromDate(dueAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'transactionId': transactionId,
      'method': method,
      'status': status.value,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      'rejectionReason': rejectionReason,
      'isLate': isLate,
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id'] as String,
      groupId: map['groupId'] as String? ?? '',
      memberUid: map['memberUid'] as String? ?? '',
      ownerUid: map['ownerUid'] as String? ?? '',
      intervalIndex: (map['intervalIndex'] as num?)?.toInt() ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      dueAt: _parseTimestamp(map['dueAt']),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      transactionId: map['transactionId'] as String? ?? '',
      method: map['method'] as String? ?? '',
      status: PaymentStatusX.fromValue(map['status'] as String?),
      reviewedBy: map['reviewedBy'] as String? ?? '',
      reviewedAt: _parseTimestampNullable(map['reviewedAt']),
      rejectionReason: map['rejectionReason'] as String? ?? '',
      isLate: map['isLate'] as bool? ?? false,
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

  static DateTime? _parseTimestampNullable(dynamic source) {
    if (source == null) {
      return null;
    }
    return _parseTimestamp(source);
  }
}
