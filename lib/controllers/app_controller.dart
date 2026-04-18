import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/committee.dart';
import '../models/committee_enums.dart';
import '../models/dispute.dart';
import '../models/group_message.dart';
import '../models/payment_record.dart';
import '../models/payout_event.dart';
import '../services/auth_service.dart';
import '../services/committee_service.dart';
import '../services/crypto_service.dart';
import '../services/dispute_service.dart';
import '../services/messaging_service.dart';
import '../services/payment_service.dart';
import '../services/payout_service.dart';
import '../services/trust_service.dart';
import '../services/user_service.dart';
import '../services/verification_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance {
    _authService = AuthService(firebaseAuth: _firebaseAuth);
    _userService = UserService(_firestore);
    _committeeService = CommitteeService(_firestore);
    _trustService = TrustService(_firestore);
    _paymentService = PaymentService(_firestore, _trustService);
    _messagingService = MessagingService(_firestore);
    _disputeService = DisputeService(_firestore);
    _payoutService = PayoutService(firestore: _firestore);
    _verificationService = VerificationService(_storage);
    _authSub = _authService.authStateChanges().listen(_onAuthStateChanged);
  }

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final CryptoService _crypto = CryptoService.instance;

  late final AuthService _authService;
  late final UserService _userService;
  late final CommitteeService _committeeService;
  late final TrustService _trustService;
  late final PaymentService _paymentService;
  late final MessagingService _messagingService;
  late final DisputeService _disputeService;
  late final PayoutService _payoutService;
  late final VerificationService _verificationService;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _userSub;

  User? firebaseUser;
  AppUser? appUser;
  bool loading = false;
  String? errorMessage;
  String? verificationId;

  bool get isSignedIn => firebaseUser != null;

  bool get needsVerification {
    if (!isSignedIn) {
      return false;
    }
    final user = appUser;
    if (user == null) {
      return true;
    }
    return !user.isProfileVerified;
  }

  Future<String?> sendOtp(String phoneNumber) async {
    await _runSafely(() async {
      verificationId = await _authService.sendOtp(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
      );
    });
    return verificationId;
  }

  Future<void> verifyOtp({
    required String otpCode,
    required String fullName,
    required String password,
  }) async {
    await _runSafely(() async {
      final currentVerification = verificationId;
      if (currentVerification == null || currentVerification.isEmpty) {
        throw StateError('Please request OTP first.');
      }
      final credential = await _authService.verifyOtp(
        verificationId: currentVerification,
        smsCode: otpCode,
      );
      firebaseUser = credential.user;
      final uid = firebaseUser?.uid;
      if (uid == null) {
        throw StateError('Authentication failed. Try again.');
      }
      final hashedPassword = _crypto.hashPassword(password);
      final fcmToken = await _authService.getFcmToken() ?? '';
      await _userService.upsertAfterOtp(
        uid: uid,
        phoneNumber: firebaseUser?.phoneNumber ?? '',
        fullName: fullName.trim(),
        passwordHash: hashedPassword,
        fcmToken: fcmToken,
      );
    });
  }

  Future<void> submitVerification({
    required File cnicFront,
    required File cnicBack,
    required File selfie,
    required bool termsAccepted,
  }) async {
    await _runSafely(() async {
      final uid = firebaseUser?.uid;
      if (uid == null) {
        throw StateError('Sign in required.');
      }
      if (!termsAccepted) {
        throw StateError('Terms acceptance is required.');
      }
      final cnicFrontUrl = await _verificationService.uploadCnicFront(
        uid: uid,
        file: cnicFront,
      );
      final cnicBackUrl = await _verificationService.uploadCnicBack(
        uid: uid,
        file: cnicBack,
      );
      final selfieUrl = await _verificationService.uploadSelfie(
        uid: uid,
        file: selfie,
      );
      await _userService.submitVerification(
        uid: uid,
        cnicFrontUrl: cnicFrontUrl,
        cnicBackUrl: cnicBackUrl,
        selfieUrl: selfieUrl,
        termsAccepted: termsAccepted,
      );
    });
  }

  Stream<List<Committee>> committeesStream() {
    final uid = firebaseUser?.uid;
    if (uid == null) {
      return const Stream<List<Committee>>.empty();
    }
    return _committeeService.committeesForUser(uid);
  }

  Future<void> createCommittee({
    required String name,
    required double amount,
    required CommitteeFrequency frequency,
    required int totalIntervals,
    required int members,
    required Map<String, String> paymentInstructions,
    String customFrequencyLabel = '',
  }) async {
    await _runSafely(() async {
      final uid = firebaseUser?.uid;
      if (uid == null) {
        throw StateError('Sign in required.');
      }
      await _committeeService.createCommittee(
        ownerUid: uid,
        name: name,
        contributionAmount: amount,
        frequency: frequency,
        totalIntervals: totalIntervals,
        memberLimit: members,
        paymentInstructions: paymentInstructions,
        customFrequencyLabel: customFrequencyLabel,
      );
    });
  }

  Future<void> joinCommittee(String inviteCode) async {
    await _runSafely(() async {
      final uid = firebaseUser?.uid;
      if (uid == null) {
        throw StateError('Sign in required.');
      }
      await _committeeService.joinCommittee(uid: uid, inviteCode: inviteCode);
    });
  }

  Stream<Committee?> committeeStream(String committeeId) {
    return _committeeService.watchCommittee(committeeId);
  }

  Stream<List<AppUser>> membersStream(String committeeId) {
    return _committeeService.membersForCommittee(committeeId);
  }

  Stream<List<PaymentRecord>> committeePaymentsStream(String committeeId) {
    return _paymentService.streamCommitteePayments(committeeId);
  }

  Future<void> submitPayment({
    required String paymentId,
    required String transactionId,
    required String method,
  }) async {
    await _runSafely(() async {
      await _paymentService.submitPayment(
        paymentId: paymentId,
        transactionId: transactionId,
        method: method,
      );
    });
  }

  Future<void> reviewPayment({
    required PaymentRecord payment,
    required bool approve,
    String rejectionReason = '',
  }) async {
    await _runSafely(() async {
      final uid = firebaseUser?.uid;
      if (uid == null) {
        throw StateError('Sign in required.');
      }
      await _paymentService.reviewPayment(
        payment: payment,
        reviewerUid: uid,
        approve: approve,
        rejectionReason: rejectionReason,
      );
    });
  }

  Future<void> runMissedPaymentCheck({
    required String committeeId,
    required String ownerUid,
  }) async {
    await _runSafely(() async {
      await _paymentService.markMissedPaymentsAndRisk(
        committeeId: committeeId,
        ownerUid: ownerUid,
      );
    });
  }

  Stream<List<GroupMessage>> messagesStream(String committeeId) {
    return _messagingService.streamMessages(committeeId);
  }

  Future<void> sendMessage({
    required String committeeId,
    required String text,
  }) async {
    await _runSafely(() async {
      final uid = firebaseUser?.uid;
      final sender = appUser;
      if (uid == null || sender == null) {
        throw StateError('Sign in required.');
      }
      await _messagingService.sendMessage(
        committeeId: committeeId,
        senderId: uid,
        senderName: sender.fullName.isEmpty
            ? sender.phoneNumber
            : sender.fullName,
        body: text.trim(),
      );
    });
  }

  Stream<List<Dispute>> disputesStream(String committeeId) {
    return _disputeService.watchDisputes(committeeId);
  }

  Future<void> raiseDispute({
    required String committeeId,
    required String reason,
    String paymentId = '',
    String payoutId = '',
  }) async {
    await _runSafely(() async {
      final uid = firebaseUser?.uid;
      if (uid == null) {
        throw StateError('Sign in required.');
      }
      await _disputeService.raiseDispute(
        committeeId: committeeId,
        raisedByUid: uid,
        reason: reason,
        referencePaymentId: paymentId,
        referencePayoutId: payoutId,
      );
    });
  }

  Stream<List<Dispute>> adminDisputesStream() {
    return _disputeService.watchAllDisputes();
  }

  Future<void> resolveDispute({
    required String disputeId,
    required DisputeStatus status,
    String ownerNote = '',
    String adminResolution = '',
  }) async {
    await _runSafely(() async {
      await _disputeService.updateDisputeStatus(
        disputeId: disputeId,
        status: status,
        ownerNote: ownerNote,
        adminResolution: adminResolution,
      );
    });
  }

  Stream<List<PayoutEvent>> payoutStream(String committeeId) {
    return _payoutService.watchPayoutEvents(committeeId);
  }

  Future<void> ownerConfirmPayout({
    required Committee committee,
    required int cycleNumber,
    required String ownerTransactionId,
  }) async {
    await _runSafely(() async {
      await _payoutService.ownerConfirmPayout(
        committee: committee,
        cycleNumber: cycleNumber,
        ownerTransactionId: ownerTransactionId,
      );
    });
  }

  Future<void> recipientConfirmPayout({
    required String committeeId,
    required int cycleNumber,
  }) async {
    await _runSafely(() async {
      await _payoutService.recipientConfirmPayout(
        committeeId: committeeId,
        cycleNumber: cycleNumber,
      );
    });
  }

  Future<void> advanceCommitteeInterval(Committee committee) =>
      _committeeService.advanceInterval(committee);

  Stream<List<AppUser>> pendingVerificationUsers() =>
      _userService.pendingUsers();

  Future<void> updateVerificationStatus({
    required String uid,
    required VerificationStatus status,
  }) async {
    await _runSafely(() async {
      await _userService.updateVerificationStatus(uid: uid, status: status);
    });
  }

  Future<void> signOut() async {
    await _runSafely(() async {
      await _authService.signOut();
      _clearAuthState();
    });
  }

  Future<void> _onAuthStateChanged(User? user) async {
    firebaseUser = user;
    errorMessage = null;
    await _userSub?.cancel();
    _userSub = null;
    if (user == null) {
      appUser = null;
      notifyListeners();
      return;
    }

    final fcmToken = await _authService.getFcmToken() ?? '';
    final phone = user.phoneNumber;
    if (phone != null && phone.isNotEmpty) {
      await _userService.updateAuthMetadata(
        uid: user.uid,
        phoneNumber: phone,
        fcmToken: fcmToken,
      );
    }
    _userSub = _userService.watchUser(user.uid).listen((profile) {
      appUser = profile;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> _runSafely(Future<void> Function() action) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _clearAuthState() {
    firebaseUser = null;
    appUser = null;
    verificationId = null;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
