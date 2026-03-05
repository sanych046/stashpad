import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class StorageService {
  static const _keyPrefix = 'stashpad_';
  final _algorithm = AesGcm.with256bits();

  // We use a fixed salt and the Master Key from the session to derive 
  // a local storage encryption key. 
  // For this simplified version, we'll store the master key itself 
  // in plain shared_prefs (since it's the root of trust), 
  // and use it to encrypt notes.
  
  Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrefix + key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPrefix + key);
  }

  Future<void> saveEncrypted(String key, String value, List<int> masterKey) async {
    if (masterKey.isEmpty) return;
    
    final secretKey = SecretKey(masterKey);
    final nonce = _algorithm.newNonce();
    final clearText = utf8.encode(value);
    
    final box = await _algorithm.encrypt(
      clearText,
      secretKey: secretKey,
      nonce: nonce,
    );

    final combined = Uint8List(nonce.length + box.cipherText.length + box.mac.bytes.length);
    combined.setRange(0, nonce.length, nonce);
    combined.setRange(nonce.length, nonce.length + box.cipherText.length, box.cipherText);
    combined.setRange(nonce.length + box.cipherText.length, combined.length, box.mac.bytes);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrefix + key, base64Encode(combined));
  }

  Future<String?> getEncrypted(String key, List<int> masterKey) async {
    if (masterKey.isEmpty) return null;
    
    final prefs = await SharedPreferences.getInstance();
    final encryptedStr = prefs.getString(_keyPrefix + key);
    if (encryptedStr == null) return null;

    try {
      final combined = base64Decode(encryptedStr);
      final nonce = combined.sublist(0, 12);
      final macBytes = combined.sublist(combined.length - 16);
      final cipherText = combined.sublist(12, combined.length - 16);

      final box = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
      final secretKey = SecretKey(masterKey);
      
      final clearText = await _algorithm.decrypt(
        box,
        secretKey: secretKey,
      );
      
      return utf8.decode(clearText);
    } catch (e) {
      print('Decryption error for $key: $e');
      return null;
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith(_keyPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
