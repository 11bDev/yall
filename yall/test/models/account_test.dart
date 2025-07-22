import 'package:flutter_test/flutter_test.dart';
import 'package:yall/models/account.dart';
import 'package:yall/models/platform_type.dart';

void main() {
  group('Account', () {
    late Account testAccount;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      testAccount = Account(
        id: 'test-id',
        platform: PlatformType.mastodon,
        displayName: 'Test User',
        username: 'testuser',
        createdAt: testDate,
        isActive: true,
        credentials: {'token': 'test-token', 'secret': 'test-secret'},
      );
    });

    test('should create account with all properties', () {
      expect(testAccount.id, 'test-id');
      expect(testAccount.platform, PlatformType.mastodon);
      expect(testAccount.displayName, 'Test User');
      expect(testAccount.username, 'testuser');
      expect(testAccount.createdAt, testDate);
      expect(testAccount.isActive, true);
      expect(testAccount.credentials['token'], 'test-token');
      expect(testAccount.credentials['secret'], 'test-secret');
    });

    test('should create account with default values', () {
      final account = Account(
        id: 'test-id',
        platform: PlatformType.bluesky,
        displayName: 'Test User',
        username: 'testuser',
        createdAt: testDate,
      );

      expect(account.isActive, true);
      expect(account.credentials, isEmpty);
    });

    test('credentials should be read-only', () {
      final credentials = testAccount.credentials;
      expect(() => credentials['new'] = 'value', throwsUnsupportedError);
    });

    test('copyWith should create new instance with updated fields', () {
      final updated = testAccount.copyWith(
        displayName: 'Updated User',
        isActive: false,
      );

      expect(updated.id, testAccount.id);
      expect(updated.platform, testAccount.platform);
      expect(updated.displayName, 'Updated User');
      expect(updated.username, testAccount.username);
      expect(updated.createdAt, testAccount.createdAt);
      expect(updated.isActive, false);
      expect(updated.credentials, testAccount.credentials);
    });

    test('toJson should serialize account without credentials', () {
      final json = testAccount.toJson();

      expect(json['id'], 'test-id');
      expect(json['platform'], 'mastodon');
      expect(json['displayName'], 'Test User');
      expect(json['username'], 'testuser');
      expect(json['createdAt'], testDate.toIso8601String());
      expect(json['isActive'], true);
      expect(json.containsKey('credentials'), false);
    });

    test('fromJson should deserialize account', () {
      final json = {
        'id': 'test-id',
        'platform': 'bluesky',
        'displayName': 'Test User',
        'username': 'testuser',
        'createdAt': testDate.toIso8601String(),
        'isActive': false,
      };

      final account = Account.fromJson(json);

      expect(account.id, 'test-id');
      expect(account.platform, PlatformType.bluesky);
      expect(account.displayName, 'Test User');
      expect(account.username, 'testuser');
      expect(account.createdAt, testDate);
      expect(account.isActive, false);
      expect(account.credentials, isEmpty);
    });

    test('fromJson should handle missing isActive field', () {
      final json = {
        'id': 'test-id',
        'platform': 'nostr',
        'displayName': 'Test User',
        'username': 'testuser',
        'createdAt': testDate.toIso8601String(),
      };

      final account = Account.fromJson(json);
      expect(account.isActive, true);
    });

    test('toJsonString and fromJsonString should work correctly', () {
      final jsonString = testAccount.toJsonString();
      final recreated = Account.fromJsonString(jsonString);

      expect(recreated.id, testAccount.id);
      expect(recreated.platform, testAccount.platform);
      expect(recreated.displayName, testAccount.displayName);
      expect(recreated.username, testAccount.username);
      expect(recreated.createdAt, testAccount.createdAt);
      expect(recreated.isActive, testAccount.isActive);
    });

    test('withCredentials should return new instance with credentials', () {
      final newCredentials = {'newToken': 'new-value'};
      final updated = testAccount.withCredentials(newCredentials);

      expect(updated.credentials, newCredentials);
      expect(testAccount.credentials, isNot(newCredentials));
    });

    test('hasCredential should check for credential existence', () {
      expect(testAccount.hasCredential('token'), true);
      expect(testAccount.hasCredential('secret'), true);
      expect(testAccount.hasCredential('nonexistent'), false);
    });

    test('getCredential should return credential value', () {
      expect(testAccount.getCredential<String>('token'), 'test-token');
      expect(testAccount.getCredential<String>('secret'), 'test-secret');
      expect(testAccount.getCredential<String>('nonexistent'), null);
    });

    test('equality should work correctly', () {
      final account1 = Account(
        id: 'test-id',
        platform: PlatformType.mastodon,
        displayName: 'Test User',
        username: 'testuser',
        createdAt: testDate,
        isActive: true,
      );

      final account2 = Account(
        id: 'test-id',
        platform: PlatformType.mastodon,
        displayName: 'Test User',
        username: 'testuser',
        createdAt: testDate,
        isActive: true,
      );

      final account3 = Account(
        id: 'different-id',
        platform: PlatformType.mastodon,
        displayName: 'Test User',
        username: 'testuser',
        createdAt: testDate,
        isActive: true,
      );

      expect(account1, equals(account2));
      expect(account1, isNot(equals(account3)));
      expect(account1.hashCode, equals(account2.hashCode));
    });

    test('toString should provide readable representation', () {
      final string = testAccount.toString();
      expect(string, contains('test-id'));
      expect(string, contains('Mastodon'));
      expect(string, contains('Test User'));
      expect(string, contains('testuser'));
      expect(string, contains('true'));
    });
  });
}