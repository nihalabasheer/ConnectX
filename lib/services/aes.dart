import 'package:encrypt/encrypt.dart' as encrypt;

class AESHelper {
  static final _key = encrypt.Key.fromUtf8('16byteslongkey!!');
  static final _iv = encrypt.IV.fromUtf8('16byteslongiv!!!');

  static final _encrypter = encrypt.Encrypter(
    encrypt.AES(_key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
  );

  static String encryptMessage(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }
  static String decryptMessage(String encryptedBase64) {
    try {
      return _encrypter.decrypt64(encryptedBase64, iv: _iv);
    } catch (e) {
      print("Decryption failed: $e");
      return "[Decryption Failed]";
    }
  }
}