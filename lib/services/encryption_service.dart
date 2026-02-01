import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Simple AES encryption helper using `encrypt` package and `flutter_secure_storage`
///
/// SECURITY: Uses cryptographically secure random key generation
class EncryptionService {
  static const _keyStorage = 'app_aes_key_v2'; // Versioned key storage
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<Uint8List> _getKey() async {
    final existing = await _secure.read(key: _keyStorage);
    if (existing != null) {
      return base64Url.decode(existing);
    }

    // Generate 32 bytes using cryptographically secure random
    // SECURITY FIX: Previously used DateTime.now().microsecond which is predictable
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final keyEnc = base64Url.encode(keyBytes);
    await _secure.write(key: _keyStorage, value: keyEnc);
    return Uint8List.fromList(keyBytes);
  }

  Future<String> encryptUtf8(String plain) async {
    final key = await _getKey();
    final keyObj = encrypt_pkg.Key(key);
    final iv = encrypt_pkg.IV.fromLength(16);
    final encr = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(keyObj, mode: encrypt_pkg.AESMode.cbc));
    final cipher = encr.encrypt(plain, iv: iv);
    return cipher.base64;
  }

  Future<String> decryptToUtf8(String cipherBase64) async {
    final key = await _getKey();
    final keyObj = encrypt_pkg.Key(key);
    final iv = encrypt_pkg.IV.fromLength(16);
    final encr = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(keyObj, mode: encrypt_pkg.AESMode.cbc));
    final dec = encr.decrypt64(cipherBase64, iv: iv);
    return dec;
  }

  Future<String> encryptMap(Map<String, dynamic> m) async {
    final js = jsonEncode(m);
    return encryptUtf8(js);
  }

  Future<Map<String, dynamic>> decryptToMap(String cipherBase64) async {
    final js = await decryptToUtf8(cipherBase64);
    return jsonDecode(js) as Map<String, dynamic>;
  }
}
