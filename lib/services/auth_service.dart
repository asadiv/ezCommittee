import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseMessaging? firebaseMessaging,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseMessaging _firebaseMessaging;

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<String?> getFcmToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<String> sendOtp({
    required String phoneNumber,
    required Duration timeout,
    void Function(PhoneAuthCredential credential)? onVerificationCompleted,
    void Function(FirebaseAuthException error)? onVerificationFailed,
    void Function(String verificationId, int? resendToken)? onCodeSent,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
  }) async {
    final completer = Completer<String>();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      verificationCompleted: (PhoneAuthCredential credential) {
        onVerificationCompleted?.call(credential);
        if (!completer.isCompleted) {
          completer.complete(credential.verificationId ?? 'auto');
        }
      },
      verificationFailed: (FirebaseAuthException error) {
        onVerificationFailed?.call(error);
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent?.call(verificationId, resendToken);
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        onCodeAutoRetrievalTimeout?.call(verificationId);
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    return completer.future;
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> signOut() => _firebaseAuth.signOut();
}
