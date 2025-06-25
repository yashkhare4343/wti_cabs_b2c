// storage_service.dart
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageServices {
  static final StorageServices _instance = StorageServices._();
  static StorageServices get instance => _instance;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  SharedPreferences? _sharedPreferences;

  StorageServices._();

  Future<void> init() async {
    if (Platform.isIOS) {
      _sharedPreferences = await SharedPreferences.getInstance();
    }
  }

  Future<void> save(String key, String value) async {
    if (Platform.isAndroid) {
      await _secureStorage.write(key: key, value: value);
    } else if (Platform.isIOS) {
      if (_sharedPreferences == null) await init();
      await _sharedPreferences?.setString(key, value);
    }
  }

  Future<String?> read(String key) async {
    if (Platform.isAndroid) {
      return await _secureStorage.read(key: key);
    } else if (Platform.isIOS) {
      if (_sharedPreferences == null) await init();
      return _sharedPreferences?.getString(key);
    }
    return null;
  }

  Future<void> delete(String key) async {
    if (Platform.isAndroid) {
      await _secureStorage.delete(key: key);
    } else if (Platform.isIOS) {
      if (_sharedPreferences == null) await init();
      await _sharedPreferences?.remove(key);
    }
  }

  Future<void> clear() async {
    if (Platform.isAndroid) {
      await _secureStorage.deleteAll();
    } else if (Platform.isIOS) {
      if (_sharedPreferences == null) await init();
      await _sharedPreferences?.clear();
    }
  }
}
