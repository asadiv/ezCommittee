import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutEvent {
  const PayoutEvent({
    required this.id,
    required this.committeeId,
    required this.cycleNumber,
    required this.recipientUid,
    required this.ownerTransactionId,
    required this.ownerConfirmed,
    required this.recipientConfirmed,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String committeeId;
  final int cycleNumber;
  final String recipientUid;
  final String ownerTransactionId;
  final bool ownerConfirmed;
  final bool recipientConfirmed;
  final DateTime createdAt;
  final DateTime updatedAt;

  PayoutEvent copyWith({
    String? ownerTransactionId,
    bool? ownerConfirmed,
    bool? recipientConfirmed,
    DateTime? updatedAt,
  }) {
    return PayoutEvent(
      id: id,
      committeeId: committeeId,
      cycleNumber: cycleNumber,
      recipientUid: recipientUid,
      ownerTransactionId: ownerTransactionId ?? this.ownerTransactionId,
      ownerConfirmed: ownerConfirmed ?? this.ownerConfirmed,
      recipientConfirmed: recipientConfirmed ?? this.recipientConfirmed,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'committeeId': committeeId,
      'cycleNumber': cycleNumber,
      'recipientUid': recipientUid,
      'ownerTransactionId': ownerTransactionId,
      'ownerConfirmed': ownerConfirmed,
      'recipientConfirmed': recipientConfirmed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PayoutEvent.fromMap(Map<String, dynamic> map) {
    return PayoutEvent(
      id: map['id'] as String? ?? '',
      committeeId: map['committeeId'] as String? ?? '',
      cycleNumber: (map['cycleNumber'] as num?)?.toInt() ?? 1,
      recipientUid: map['recipientUid'] as String? ?? '',
      ownerTransactionId: map['ownerTransactionId'] as String? ?? '',
      ownerConfirmed: map['ownerConfirmed'] as bool? ?? false,
      recipientConfirmed: map['recipientConfirmed'] as bool? ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
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
