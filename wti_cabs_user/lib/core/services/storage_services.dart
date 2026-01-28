// storage_service.dart
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageServices {
  static final StorageServices _instance = StorageServices._();
  static StorageServices get instance => _instance;

  // Corporate session keys that we want to preserve when clearing user data
  static const Set<String> _corporateKeys = {
    'crpKey',
    'crpId',
    'branchId',
    'guestId',
    'guestName',
    'email',
  };
  
  // App-level keys that should never be cleared (like onboarding flags)
  static const Set<String> _appLevelKeys = {
    'isFirstTime',
    'hasSeenAppModule',
    'lastSelectedModule',
  };

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
    await clearPreservingCorporate(preserveCorporate: false);
  }

  /// Clear all stored values, optionally keeping corporate session keys.
  Future<void> clearPreservingCorporate({bool preserveCorporate = true}) async {
    if (Platform.isAndroid) {
      if (preserveCorporate) {
        final all = await _secureStorage.readAll();
        for (final entry in all.entries) {
          if (_corporateKeys.contains(entry.key) || _appLevelKeys.contains(entry.key)) continue;
          await _secureStorage.delete(key: entry.key);
        }
      } else {
        // When clearing all, preserve app-level keys
        final all = await _secureStorage.readAll();
        for (final entry in all.entries) {
          if (_appLevelKeys.contains(entry.key)) continue;
          await _secureStorage.delete(key: entry.key);
        }
      }
    } else if (Platform.isIOS) {
      if (_sharedPreferences == null) await init();
      if (!preserveCorporate) {
        // When clearing all, preserve app-level keys
        final keys = _sharedPreferences?.getKeys() ?? {};
        for (final key in keys) {
          if (_appLevelKeys.contains(key)) continue;
          await _sharedPreferences?.remove(key);
        }
      } else {
        final keys = _sharedPreferences?.getKeys() ?? {};
        for (final key in keys) {
          if (_corporateKeys.contains(key) || _appLevelKeys.contains(key)) continue;
          await _sharedPreferences?.remove(key);
        }
      }
    }
  }
}
