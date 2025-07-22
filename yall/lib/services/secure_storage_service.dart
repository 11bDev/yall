import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Exception thrown when secure storage operations fail
class SecureStorageException implements Exception {
  final String message;
  final dynamic originalError;

  const SecureStorageException(this.message, [this.originalError]);

  @override
  String toString() => 'SecureStorageException: $message';
}

/// Service for securely storing and retrieving encrypted credentials
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    lOptions: LinuxOptions(),
    wOptions: WindowsOptions(),
    mOptions: MacOsOptions(),
  );

  // Key prefixes for different types of data
  static const String _accountPrefix = 'account_';
  static const String _settingsPrefix = 'settings_';
  static const String _credentialsPrefix = 'credentials_';

  /// Stores account credentials securely
  ///
  /// [accountId] - Unique identifier for the account
  /// [credentials] - Map containing credential data to encrypt and store
  ///
  /// Throws [SecureStorageException] if storage operation fails
  Future<void> storeAccountCredentials(
    String accountId,
    Map<String, dynamic> credentials,
  ) async {
    try {
      final key = '$_credentialsPrefix$accountId';
      final jsonString = jsonEncode(credentials);
      await _storage.write(key: key, value: jsonString);
    } catch (e) {
      throw SecureStorageException(
        'Failed to store credentials for account $accountId',
        e,
      );
    }
  }

  /// Retrieves account credentials from secure storage
  ///
  /// [accountId] - Unique identifier for the account
  ///
  /// Returns the decrypted credentials map or null if not found
  /// Throws [SecureStorageException] if retrieval operation fails
  Future<Map<String, dynamic>?> getAccountCredentials(String accountId) async {
    try {
      final key = '$_credentialsPrefix$accountId';
      final jsonString = await _storage.read(key: key);

      if (jsonString == null) {
        return null;
      }

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw SecureStorageException(
        'Failed to retrieve credentials for account $accountId',
        e,
      );
    }
  }

  /// Deletes account credentials from secure storage
  ///
  /// [accountId] - Unique identifier for the account
  ///
  /// Throws [SecureStorageException] if deletion operation fails
  Future<void> deleteAccountCredentials(String accountId) async {
    try {
      final key = '$_credentialsPrefix$accountId';
      await _storage.delete(key: key);
    } catch (e) {
      throw SecureStorageException(
        'Failed to delete credentials for account $accountId',
        e,
      );
    }
  }

  /// Stores application settings securely
  ///
  /// [key] - Setting key identifier
  /// [value] - Setting value to store
  ///
  /// Throws [SecureStorageException] if storage operation fails
  Future<void> storeSetting(String key, String value) async {
    try {
      final storageKey = '$_settingsPrefix$key';
      await _storage.write(key: storageKey, value: value);
    } catch (e) {
      throw SecureStorageException(
        'Failed to store setting $key',
        e,
      );
    }
  }

  /// Retrieves application setting from secure storage
  ///
  /// [key] - Setting key identifier
  ///
  /// Returns the setting value or null if not found
  /// Throws [SecureStorageException] if retrieval operation fails
  Future<String?> getSetting(String key) async {
    try {
      final storageKey = '$_settingsPrefix$key';
      return await _storage.read(key: storageKey);
    } catch (e) {
      throw SecureStorageException(
        'Failed to retrieve setting $key',
        e,
      );
    }
  }

  /// Deletes application setting from secure storage
  ///
  /// [key] - Setting key identifier
  ///
  /// Throws [SecureStorageException] if deletion operation fails
  Future<void> deleteSetting(String key) async {
    try {
      final storageKey = '$_settingsPrefix$key';
      await _storage.delete(key: storageKey);
    } catch (e) {
      throw SecureStorageException(
        'Failed to delete setting $key',
        e,
      );
    }
  }

  /// Stores account metadata (non-sensitive data)
  ///
  /// [accountId] - Unique identifier for the account
  /// [accountData] - Map containing account metadata
  ///
  /// Throws [SecureStorageException] if storage operation fails
  Future<void> storeAccountData(
    String accountId,
    Map<String, dynamic> accountData,
  ) async {
    try {
      final key = '$_accountPrefix$accountId';
      final jsonString = jsonEncode(accountData);
      await _storage.write(key: key, value: jsonString);
    } catch (e) {
      throw SecureStorageException(
        'Failed to store account data for $accountId',
        e,
      );
    }
  }

  /// Retrieves account metadata from secure storage
  ///
  /// [accountId] - Unique identifier for the account
  ///
  /// Returns the account metadata map or null if not found
  /// Throws [SecureStorageException] if retrieval operation fails
  Future<Map<String, dynamic>?> getAccountData(String accountId) async {
    try {
      final key = '$_accountPrefix$accountId';
      final jsonString = await _storage.read(key: key);

      if (jsonString == null) {
        return null;
      }

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw SecureStorageException(
        'Failed to retrieve account data for $accountId',
        e,
      );
    }
  }

  /// Deletes account metadata from secure storage
  ///
  /// [accountId] - Unique identifier for the account
  ///
  /// Throws [SecureStorageException] if deletion operation fails
  Future<void> deleteAccountData(String accountId) async {
    try {
      final key = '$_accountPrefix$accountId';
      await _storage.delete(key: key);
    } catch (e) {
      throw SecureStorageException(
        'Failed to delete account data for $accountId',
        e,
      );
    }
  }

  /// Gets all stored account IDs
  ///
  /// Returns a list of account IDs that have stored data
  /// Throws [SecureStorageException] if operation fails
  Future<List<String>> getAllAccountIds() async {
    try {
      final allKeys = await _storage.readAll();
      final accountIds = <String>[];

      for (final key in allKeys.keys) {
        if (key.startsWith(_accountPrefix)) {
          final accountId = key.substring(_accountPrefix.length);
          accountIds.add(accountId);
        }
      }

      return accountIds;
    } catch (e) {
      throw SecureStorageException(
        'Failed to retrieve account IDs',
        e,
      );
    }
  }

  /// Completely removes all data for an account
  ///
  /// [accountId] - Unique identifier for the account
  ///
  /// Deletes both credentials and metadata for the account
  /// Throws [SecureStorageException] if any deletion operation fails
  Future<void> deleteAllAccountData(String accountId) async {
    try {
      await Future.wait([
        deleteAccountCredentials(accountId),
        deleteAccountData(accountId),
      ]);
    } catch (e) {
      throw SecureStorageException(
        'Failed to delete all data for account $accountId',
        e,
      );
    }
  }

  /// Clears all stored data (use with caution)
  ///
  /// Throws [SecureStorageException] if operation fails
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecureStorageException(
        'Failed to clear all stored data',
        e,
      );
    }
  }

  /// Checks if secure storage is available on the current platform
  ///
  /// Returns true if secure storage is available and functional
  Future<bool> isAvailable() async {
    try {
      // Test storage by writing and reading a test value
      const testKey = 'storage_test';
      const testValue = 'test';

      await _storage.write(key: testKey, value: testValue);
      final result = await _storage.read(key: testKey);
      await _storage.delete(key: testKey);

      return result == testValue;
    } catch (e) {
      return false;
    }
  }
}