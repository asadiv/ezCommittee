import 'package:cloud_firestore/cloud_firestore.dart';

import 'committee_enums.dart';

class Committee {
  const Committee({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.contributionAmount,
    required this.frequency,
    required this.totalIntervals,
    required this.memberLimit,
    required this.memberCount,
    required this.inviteCode,
    required this.payoutOrder,
    required this.paymentInstructions,
    required this.createdAt,
    required this.updatedAt,
    this.customFrequencyLabel = '',
    this.currentInterval = 1,
    this.state = CommitteeState.gathering,
  });

  final String id;
  final String name;
  final String ownerId;
  final double contributionAmount;
  final CommitteeFrequency frequency;
  final String customFrequencyLabel;
  final int totalIntervals;
  final int currentInterval;
  final int memberLimit;
  final int memberCount;
  final String inviteCode;
  final List<String> payoutOrder;
  final Map<String, String> paymentInstructions;
  final CommitteeState state;
  final DateTime createdAt;
  final DateTime updatedAt;

  double progressPercent() {
    if (totalIntervals <= 0) {
      return 0;
    }
    return (currentInterval / totalIntervals).clamp(0, 1).toDouble();
  }

  Committee copyWith({
    String? name,
    double? contributionAmount,
    CommitteeFrequency? frequency,
    String? customFrequencyLabel,
    int? totalIntervals,
    int? currentInterval,
    int? memberLimit,
    int? memberCount,
    List<String>? payoutOrder,
    Map<String, String>? paymentInstructions,
    CommitteeState? state,
    DateTime? updatedAt,
  }) {
    return Committee(
      id: id,
      name: name ?? this.name,
      ownerId: ownerId,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      frequency: frequency ?? this.frequency,
      customFrequencyLabel: customFrequencyLabel ?? this.customFrequencyLabel,
      totalIntervals: totalIntervals ?? this.totalIntervals,
      currentInterval: currentInterval ?? this.currentInterval,
      memberLimit: memberLimit ?? this.memberLimit,
      memberCount: memberCount ?? this.memberCount,
      inviteCode: inviteCode,
      payoutOrder: payoutOrder ?? this.payoutOrder,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      state: state ?? this.state,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'contributionAmount': contributionAmount,
      'frequency': frequency.value,
      'customFrequencyLabel': customFrequencyLabel,
      'totalIntervals': totalIntervals,
      'currentInterval': currentInterval,
      'memberLimit': memberLimit,
      'memberCount': memberCount,
      'inviteCode': inviteCode,
      'payoutOrder': payoutOrder,
      'paymentInstructions': paymentInstructions,
      'state': state.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Committee.fromMap(Map<String, dynamic> map) {
    return Committee(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      contributionAmount: (map['contributionAmount'] as num?)?.toDouble() ?? 0,
      frequency: CommitteeFrequencyX.fromValue(map['frequency'] as String?),
      customFrequencyLabel: map['customFrequencyLabel'] as String? ?? '',
      totalIntervals: (map['totalIntervals'] as num?)?.toInt() ?? 0,
      currentInterval: (map['currentInterval'] as num?)?.toInt() ?? 1,
      memberLimit: (map['memberLimit'] as num?)?.toInt() ?? 0,
      memberCount: (map['memberCount'] as num?)?.toInt() ?? 0,
      inviteCode: map['inviteCode'] as String? ?? '',
      payoutOrder: (map['payoutOrder'] as List<dynamic>? ?? [])
          .cast<String>()
          .toList(),
      paymentInstructions:
          (map['paymentInstructions'] as Map<String, dynamic>? ??
                  const <String, dynamic>{})
              .map((key, value) => MapEntry(key, value.toString())),
      state: CommitteeStateX.fromValue(map['state'] as String?),
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
