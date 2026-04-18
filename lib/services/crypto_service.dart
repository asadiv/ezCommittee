import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class CryptoService {
  CryptoService._();

  static final CryptoService instance = CryptoService._();

  // In production, replace with server-managed key or KMS fetched key.
  static const String _keySeed = 'ez_committee_mvp_local_encryption_key_2026';

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  bool verifyPassword({required String password, required String hashed}) {
    return hashPassword(password) == hashed;
  }

  String encryptText(String plainText) {
    final key = encrypt.Key.fromUtf8(_deriveKey());
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.encrypt(plainText, iv: iv).base64;
  }

  String decryptText(String encryptedText) {
    final key = encrypt.Key.fromUtf8(_deriveKey());
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt64(encryptedText, iv: iv);
  }

  String _deriveKey() {
    final digest = sha256.convert(utf8.encode(_keySeed)).toString();
    return digest.substring(0, 32);
  }
}
