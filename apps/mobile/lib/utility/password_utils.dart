import 'package:crypto/crypto.dart';
import 'dart:convert';

class PasswordUtils {
  static String encodeSHA1(String password) {
    final bytes = utf8.encode(password);
    final hash = sha1.convert(bytes);
    return hash.toString();
  }
}