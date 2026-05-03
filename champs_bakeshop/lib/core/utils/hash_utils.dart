import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Returns the SHA-256 hex digest of [password].
String hashPassword(String password) {
  final bytes  = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

/// Returns true if [s] looks like an already-hashed SHA-256 value
/// (64 lowercase hex characters). Used to avoid double-hashing.
bool isHashed(String s) =>
    s.length == 64 && RegExp(r'^[0-9a-f]{64}$').hasMatch(s);
