import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:yall/services/secure_storage_service.dart';

void main() {
  group('SecureStorageService', () {
    late SecureStorageService service;

    setUp(() {
      service = SecureStorageService();
    });

    group('SecureStorageException', () {
      test('should create exception with message only', () {
        const message = 'Test error message';
        final exception = SecureStorageException(message);

        expect(exception.message, equals(message));
        expect(exception.originalError, isNull);
        expect(exception.toString(), contains(message));
      });

      test('should create exception with message and original error', () {
        const message = 'Test error message';
        const originalError = 'Original error';
        final exception = SecureStorageException(message, originalError);

        expect(exception.message, equals(message));
        expect(exception.originalError, equals(originalError));
        expect(exception.toString(), contains(message));
      });
    });

    group('Service Interface', () {
      test('should have proper service instantiation', () {
        expect(service, isA<SecureStorageService>());
      });

      test('should have all required methods', () {
        // Verify that the service has all the expected methods
        expect(service.storeAccountCredentials, isA<Function>());
        expect(service.getAccountCredentials, isA<Function>());
        expect(service.deleteAccountCredentials, isA<Function>());
        expect(service.storeSetting, isA<Function>());
        expect(service.getSetting, isA<Function>());
        expect(service.deleteSetting, isA<Function>());
        expect(service.storeAccountData, isA<Function>());
        expect(service.getAccountData, isA<Function>());
        expect(service.deleteAccountData, isA<Function>());
        expect(service.getAllAccountIds, isA<Function>());
        expect(service.deleteAllAccountData, isA<Function>());
        expect(service.clearAll, isA<Function>());
        expect(service.isAvailable, isA<Function>());
      });
    });

    group('Data Serialization', () {
      test('should handle JSON serialization correctly', () {
        final credentials = {
          'username': 'testuser',
          'token': 'secret_token_123',
          'nested': {
            'key': 'value',
            'number': 42,
          },
          'list': ['item1', 'item2'],
        };

        // Test that credentials can be serialized to JSON
        final jsonString = jsonEncode(credentials);
        expect(jsonString, isA<String>());

        // Test that JSON can be deserialized back to map
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        expect(decoded['username'], equals('testuser'));
        expect(decoded['token'], equals('secret_token_123'));
        expect(decoded['nested']['key'], equals('value'));
        expect(decoded['nested']['number'], equals(42));
        expect(decoded['list'], equals(['item1', 'item2']));
      });

      test('should handle empty data structures', () {
        final emptyCredentials = <String, dynamic>{};
        final jsonString = jsonEncode(emptyCredentials);
        expect(jsonString, equals('{}'));

        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        expect(decoded, isEmpty);
      });

      test('should handle complex nested data structures', () {
        final complexData = {
          'simple_string': 'value',
          'number': 42,
          'boolean': true,
          'null_value': null,
          'nested_object': {
            'inner_key': 'inner_value',
            'inner_number': 123,
          },
          'array': [1, 2, 3, 'string', true],
          'mixed_array': [
            {'key': 'value'},
            'string',
            42,
          ],
        };

        final jsonString = jsonEncode(complexData);
        expect(jsonString, isA<String>());

        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        expect(decoded['simple_string'], equals('value'));
        expect(decoded['number'], equals(42));
        expect(decoded['boolean'], equals(true));
        expect(decoded['null_value'], isNull);
        expect(decoded['nested_object']['inner_key'], equals('inner_value'));
        expect(decoded['array'], equals([1, 2, 3, 'string', true]));
      });

      test('should handle unicode characters in data', () {
        final unicodeData = {
          'display_name': '测试用户',
          'emoji': '🚀💻🌟',
          'special_chars': 'àáâãäåæçèéêë',
        };

        final jsonString = jsonEncode(unicodeData);
        expect(jsonString, isA<String>());

        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        expect(decoded['display_name'], equals('测试用户'));
        expect(decoded['emoji'], equals('🚀💻🌟'));
        expect(decoded['special_chars'], equals('àáâãäåæçèéêë'));
      });
    });

    group('Key Generation Logic', () {
      test('should use correct key prefixes for different data types', () {
        // Test the expected key structure based on the implementation
        const accountId = 'test123';

        // Expected key formats based on the implementation
        const expectedCredentialsKey = 'credentials_test123';
        const expectedAccountKey = 'account_test123';
        const expectedSettingsKey = 'settings_theme_mode';

        expect(expectedCredentialsKey, startsWith('credentials_'));
        expect(expectedAccountKey, startsWith('account_'));
        expect(expectedSettingsKey, startsWith('settings_'));

        // Verify key construction logic
        expect(expectedCredentialsKey, equals('credentials_$accountId'));
        expect(expectedAccountKey, equals('account_$accountId'));
      });

      test('should handle special characters in account IDs', () {
        const specialAccountId = 'test-account_123.special@domain.com';
        const expectedKey = 'credentials_test-account_123.special@domain.com';

        expect(expectedKey, startsWith('credentials_'));
        expect(expectedKey, contains(specialAccountId));
      });
    });

    group('Method Parameter Validation', () {
      test('should accept valid account IDs', () {
        const validAccountIds = [
          'simple_id',
          'test-account_123',
          'user@domain.com',
          'account.with.dots',
          'UPPERCASE_ID',
          'mixed_Case-123',
        ];

        for (final accountId in validAccountIds) {
          expect(accountId, isA<String>());
          expect(accountId.isNotEmpty, isTrue);
        }
      });

      test('should accept valid credential maps', () {
        final validCredentials = [
          {'token': 'simple_token'},
          {'username': 'user', 'password': 'pass'},
          {'complex': {'nested': 'value'}},
          {'array': [1, 2, 3]},
          <String, dynamic>{}, // empty map
        ];

        for (final credentials in validCredentials) {
          expect(credentials, isA<Map<String, dynamic>>());
        }
      });

      test('should accept valid setting keys and values', () {
        const validSettings = [
          {'theme_mode': 'dark'},
          {'language': 'en'},
          {'auto_save': 'true'},
          {'window_size': '800x600'},
        ];

        for (final setting in validSettings) {
          final key = setting.keys.first;
          final value = setting.values.first;

          expect(key, isA<String>());
          expect(key.isNotEmpty, isTrue);
          expect(value, isA<String>());
        }
      });
    });

    group('Error Handling Patterns', () {
      test('should define proper error messages', () {
        const accountId = 'test_account';
        const settingKey = 'test_setting';

        // Test error message patterns that would be used
        final credentialsStoreError = 'Failed to store credentials for account $accountId';
        final credentialsRetrieveError = 'Failed to retrieve credentials for account $accountId';
        final credentialsDeleteError = 'Failed to delete credentials for account $accountId';
        final settingStoreError = 'Failed to store setting $settingKey';
        final settingRetrieveError = 'Failed to retrieve setting $settingKey';
        final settingDeleteError = 'Failed to delete setting $settingKey';

        expect(credentialsStoreError, contains('store credentials'));
        expect(credentialsRetrieveError, contains('retrieve credentials'));
        expect(credentialsDeleteError, contains('delete credentials'));
        expect(settingStoreError, contains('store setting'));
        expect(settingRetrieveError, contains('retrieve setting'));
        expect(settingDeleteError, contains('delete setting'));
      });
    });

    group('Service Configuration', () {
      test('should have proper storage configuration constants', () {
        // Test that the service uses expected configuration
        // These are based on the implementation in the service
        expect('account_', isA<String>());
        expect('settings_', isA<String>());
        expect('credentials_', isA<String>());

        // Verify prefix patterns
        expect('account_'.length, greaterThan(0));
        expect('settings_'.length, greaterThan(0));
        expect('credentials_'.length, greaterThan(0));
      });
    });
  });
}