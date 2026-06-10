import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionUtil {
  static List<int> get _encryptionKeyBytes {
    final hostname = Platform.localHostname;
    final os = Platform.operatingSystem;
    final user = Platform.environment['USER'] ?? Platform.environment['USERNAME'] ?? 'unknown_user';
    
    // Create a stable machine-specific seed
    final seed = "$hostname-$os-$user-folio-cli-secret-salt-v1";
    return sha256.convert(utf8.encode(seed)).bytes;
  }

  static final Key _key = Key(Uint8List.fromList(_encryptionKeyBytes));
  static final IV _iv = IV(Uint8List.fromList(_encryptionKeyBytes.sublist(0, 16)));
  static final Encrypter _encrypter = Encrypter(AES(_key, mode: AESMode.gcm));

  static String encrypt(String plainText) {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('Hiba a titkosítás során: $e');
      return '';
    }
  }

  static String decrypt(String encryptedText) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      // If decryption fails (e.g., machine changed or not encrypted), throw
      throw FormatException('Decryption failed');
    }
  }
}
