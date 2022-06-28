import 'package:encrypt/encrypt.dart';
import '../screens/change_key.dart';

class EncryptionDecryption{
  static Encrypted? encrypted ;
  static var decrypted = '';
  static String _secretKey = '';

  static loadKey() {
    _secretKey = Keys.getKey();
  }

  static encryptAES(plainText){
    final key = Key.fromUtf8(_secretKey);
    var iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted!.base64;
  }

  static decryptAES(encryptedText){
    final key = Key.fromUtf8(_secretKey);
    var iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    decrypted = encrypter.decrypt(encryptedText,iv:iv);
    return decrypted;
  }
}