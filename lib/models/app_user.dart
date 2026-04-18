import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationStatus { pending, approved, rejected }

extension VerificationStatusX on VerificationStatus {
  String get value => name;

  static VerificationStatus fromValue(String? value) {
    return VerificationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => VerificationStatus.pending,
    );
  }
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    this.fullName = '',
    this.passwordHash = '',
    this.verificationStatus = VerificationStatus.pending,
    this.cnicFrontUrl = '',
    this.cnicBackUrl = '',
    this.selfieUrl = '',
    this.termsAccepted = false,
    this.onTimeRate = 0,
    this.lateRate = 0,
    this.trustScore = 0,
    this.missedIntervals = 0,
    this.atRisk = false,
    this.isAdmin = false,
    this.fcmToken = '',
  });

  final String uid;
  final String phoneNumber;
  final String fullName;
  final String passwordHash;
  final VerificationStatus verificationStatus;
  final String cnicFrontUrl;
  final String cnicBackUrl;
  final String selfieUrl;
  final bool termsAccepted;
  final double onTimeRate;
  final double lateRate;
  final double trustScore;
  final int missedIntervals;
  final bool atRisk;
  final bool isAdmin;
  final String fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isProfileVerified =>
      verificationStatus == VerificationStatus.approved;

  bool get hasPassword => passwordHash.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'passwordHash': passwordHash,
      'verificationStatus': verificationStatus.value,
      'cnicFrontUrl': cnicFrontUrl,
      'cnicBackUrl': cnicBackUrl,
      'selfieUrl': selfieUrl,
      'termsAccepted': termsAccepted,
      'onTimeRate': onTimeRate,
      'lateRate': lateRate,
      'trustScore': trustScore,
      'missedIntervals': missedIntervals,
      'atRisk': atRisk,
      'isAdmin': isAdmin,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AppUser copyWith({
    String? fullName,
    String? passwordHash,
    VerificationStatus? verificationStatus,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? selfieUrl,
    bool? termsAccepted,
    double? onTimeRate,
    double? lateRate,
    double? trustScore,
    int? missedIntervals,
    bool? atRisk,
    bool? isAdmin,
    String? fcmToken,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      phoneNumber: phoneNumber,
      fullName: fullName ?? this.fullName,
      passwordHash: passwordHash ?? this.passwordHash,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      cnicFrontUrl: cnicFrontUrl ?? this.cnicFrontUrl,
      cnicBackUrl: cnicBackUrl ?? this.cnicBackUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      onTimeRate: onTimeRate ?? this.onTimeRate,
      lateRate: lateRate ?? this.lateRate,
      trustScore: trustScore ?? this.trustScore,
      missedIntervals: missedIntervals ?? this.missedIntervals,
      atRisk: atRisk ?? this.atRisk,
      isAdmin: isAdmin ?? this.isAdmin,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      phoneNumber: map['phoneNumber'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      passwordHash: map['passwordHash'] as String? ?? '',
      verificationStatus: VerificationStatusX.fromValue(
        map['verificationStatus'] as String?,
      ),
      cnicFrontUrl: map['cnicFrontUrl'] as String? ?? '',
      cnicBackUrl: map['cnicBackUrl'] as String? ?? '',
      selfieUrl: map['selfieUrl'] as String? ?? '',
      termsAccepted: map['termsAccepted'] as bool? ?? false,
      onTimeRate: (map['onTimeRate'] as num?)?.toDouble() ?? 0,
      lateRate: (map['lateRate'] as num?)?.toDouble() ?? 0,
      trustScore: (map['trustScore'] as num?)?.toDouble() ?? 0,
      missedIntervals: (map['missedIntervals'] as num?)?.toInt() ?? 0,
      atRisk: map['atRisk'] as bool? ?? false,
      isAdmin: map['isAdmin'] as bool? ?? false,
      fcmToken: map['fcmToken'] as String? ?? '',
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
