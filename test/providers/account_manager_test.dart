import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:yall/models/account.dart';
import 'package:yall/models/platform_type.dart';
import 'package:yall/providers/account_manager.dart';
import 'package:yall/services/secure_storage_service.dart';
import 'package:yall/services/social_platform_service.dart';

import 'account_manager_test.mocks.dart';

@GenerateMocks([
  SecureStorageService,
  SocialPlatformService,
  AccountManager,
])
void main() {
  group('AccountManager', () {
    late AccountManager accountManager;
    late MockSecureStorageService mockStorageService;
    late MockSocialPlatformService mockMastodonService;
    late MockSocialPlatformService mockBlueskyService;
    late MockSocialPlatformService mockNostrService;

    setUp(() {
      mockStorageService = MockSecureStorageService();
      mockMastodonService = MockSocialPlatformService();
      mockBlueskyService = MockSocialPlatformService();
      mockNostrService = MockSocialPlatformService();

      // Configure mock services
      when(mockMastodonService.platformType).thenReturn(PlatformType.mastodon);
      when(mockMastodonService.requiredCredentialFields).thenReturn(['instance_url', 'access_token']);
      when(mockMastodonService.hasRequiredCredentials(any)).thenReturn(true);

      when(mockBlueskyService.platformType).thenReturn(PlatformType.bluesky);
      when(mockBlueskyService.requiredCredentialFields).thenReturn(['handle', 'password']);
      when(mockBlueskyService.hasRequiredCredentials(any)).thenReturn(true);

      when(mockNostrService.platformType).thenReturn(PlatformType.nostr);
      when(mockNostrService.requiredCredentialFields).thenReturn(['private_key']);
      when(mockNostrService.hasRequiredCredentials(any)).thenReturn(true);

      accountManager = AccountManager(
        storageService: mockStorageService,
        platformServices: {
          PlatformType.mastodon: mockMastodonService,
          PlatformType.bluesky: mockBlueskyService,
          PlatformType.nostr: mockNostrService,
        },
      );
    });

    group('loadAccounts', () {
      test('should load accounts from storage successfully', () async {
        // Arrange
        final accountIds = ['account1', 'account2'];
        final account1Data = {
          'id': 'account1',
          'platform': 'mastodon',
          'displayName': 'Test User 1',
          'username': 'testuser1',
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
        };
        final account1Credentials = {
          'instance_url': 'https://mastodon.social',
          'access_token': 'token123',
        };

        when(mockStorageService.getAllAccountIds()).thenAnswer((_) async => accountIds);
        when(mockStorageService.getAccountData('account1')).thenAnswer((_) async => account1Data);
        when(mockStorageService.getAccountCredentials('account1')).thenAnswer((_) async => account1Credentials);
        when(mockStorageService.getAccountData('account2')).thenAnswer((_) async => null);

        // Act
        await accountManager.loadAccounts();

        // Assert
        expect(accountManager.accounts.length, equals(1));
        expect(accountManager.accounts.first.id, equals('account1'));
        expect(accountManager.accounts.first.platform, equals(PlatformType.mastodon));
        expect(accountManager.accounts.first.credentials['access_token'], equals('token123'));
        expect(accountManager.isLoading, isFalse);
        expect(accountManager.error, isNull);
      });

      test('should handle storage errors gracefully', () async {
        // Arrange
        when(mockStorageService.getAllAccountIds()).thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(() => accountManager.loadAccounts(), throwsA(isA<AccountManagerException>()));
        expect(accountManager.error, contains('Failed to load accounts'));
      });
    });

    group('addAccount', () {
      test('should add account successfully', () async {
        // Arrange
        final credentials = {
          'instance_url': 'https://mastodon.social',
          'access_token': 'token123',
        };

        when(mockMastodonService.validateConnection(any)).thenAnswer((_) async => true);
        when(mockStorageService.storeAccountData(any, any)).thenAnswer((_) async {});
        when(mockStorageService.storeAccountCredentials(any, any)).thenAnswer((_) async {});

        // Act
        final account = await accountManager.addAccount(
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          credentials: credentials,
        );

        // Assert
        expect(account.platform, equals(PlatformType.mastodon));
        expect(account.displayName, equals('Test User'));
        expect(account.username, equals('testuser'));
        expect(account.isActive, isTrue);
        expect(accountManager.accounts.length, equals(1));
        expect(accountManager.accounts.first.id, equals(account.id));

        verify(mockStorageService.storeAccountData(account.id, any)).called(1);
        verify(mockStorageService.storeAccountCredentials(account.id, credentials)).called(1);
      });

      test('should throw exception for unsupported platform', () async {
        // Arrange
        final accountManagerWithoutServices = AccountManager(
          storageService: mockStorageService,
          platformServices: {},
        );

        // Act & Assert
        expect(
          () => accountManagerWithoutServices.addAccount(
            platform: PlatformType.mastodon,
            displayName: 'Test User',
            username: 'testuser',
            credentials: {},
          ),
          throwsA(isA<AccountManagerException>()),
        );
      });

      test('should throw exception for missing required credentials', () async {
        // Arrange
        when(mockMastodonService.hasRequiredCredentials(any)).thenReturn(false);

        // Act & Assert
        expect(
          () => accountManager.addAccount(
            platform: PlatformType.mastodon,
            displayName: 'Test User',
            username: 'testuser',
            credentials: {},
          ),
          throwsA(isA<AccountManagerException>()),
        );
      });

      test('should throw exception for failed authentication', () async {
        // Arrange
        final credentials = {
          'instance_url': 'https://mastodon.social',
          'access_token': 'invalid_token',
        };

        when(mockMastodonService.validateConnection(any)).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => accountManager.addAccount(
            platform: PlatformType.mastodon,
            displayName: 'Test User',
            username: 'testuser',
            credentials: credentials,
          ),
          throwsA(isA<AccountManagerException>()),
        );
      });
    });

    group('updateAccount', () {
      test('should update existing account successfully', () async {
        // Arrange
        final originalAccount = Account(
          id: 'account1',
          platform: PlatformType.mastodon,
          displayName: 'Original Name',
          username: 'original',
          createdAt: DateTime.now(),
          credentials: {'access_token': 'token123'},
        );

        // Add account to simulate it being loaded
        accountManager.addAccountForTesting(originalAccount);

        final updatedAccount = originalAccount.copyWith(
          displayName: 'Updated Name',
          username: 'updated',
        );

        when(mockStorageService.storeAccountData(any, any)).thenAnswer((_) async {});
        when(mockStorageService.storeAccountCredentials(any, any)).thenAnswer((_) async {});

        // Act
        final result = await accountManager.updateAccount(updatedAccount);

        // Assert
        expect(result.displayName, equals('Updated Name'));
        expect(result.username, equals('updated'));
        expect(accountManager.accounts.first.displayName, equals('Updated Name'));

        verify(mockStorageService.storeAccountData(updatedAccount.id, any)).called(1);
        verify(mockStorageService.storeAccountCredentials(updatedAccount.id, any)).called(1);
      });

      test('should throw exception for non-existent account', () async {
        // Arrange
        final nonExistentAccount = Account(
          id: 'nonexistent',
          platform: PlatformType.mastodon,
          displayName: 'Test',
          username: 'test',
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(
          () => accountManager.updateAccount(nonExistentAccount),
          throwsA(isA<AccountManagerException>()),
        );
      });
    });

    group('removeAccount', () {
      test('should remove account successfully', () async {
        // Arrange
        final account = Account(
          id: 'account1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
        );

        accountManager.addAccountForTesting(account);

        when(mockStorageService.deleteAllAccountData(any)).thenAnswer((_) async {});

        // Act
        await accountManager.removeAccount('account1');

        // Assert
        expect(accountManager.accounts.length, equals(0));
        verify(mockStorageService.deleteAllAccountData('account1')).called(1);
      });

      test('should throw exception for non-existent account', () async {
        // Act & Assert
        expect(
          () => accountManager.removeAccount('nonexistent'),
          throwsA(isA<AccountManagerException>()),
        );
      });
    });

    group('getAccountsForPlatform', () {
      test('should return accounts for specific platform', () {
        // Arrange
        final mastodonAccount = Account(
          id: 'mastodon1',
          platform: PlatformType.mastodon,
          displayName: 'Mastodon User',
          username: 'mastodonuser',
          createdAt: DateTime.now(),
        );

        final blueskyAccount = Account(
          id: 'bluesky1',
          platform: PlatformType.bluesky,
          displayName: 'Bluesky User',
          username: 'blueskyuser',
          createdAt: DateTime.now(),
        );

        accountManager.addAccountForTesting(mastodonAccount);
        accountManager.addAccountForTesting(blueskyAccount);

        // Act
        final mastodonAccounts = accountManager.getAccountsForPlatform(PlatformType.mastodon);
        final blueskyAccounts = accountManager.getAccountsForPlatform(PlatformType.bluesky);
        final nostrAccounts = accountManager.getAccountsForPlatform(PlatformType.nostr);

        // Assert
        expect(mastodonAccounts.length, equals(1));
        expect(mastodonAccounts.first.platform, equals(PlatformType.mastodon));
        expect(blueskyAccounts.length, equals(1));
        expect(blueskyAccounts.first.platform, equals(PlatformType.bluesky));
        expect(nostrAccounts.length, equals(0));
      });
    });

    group('getActiveAccountsForPlatform', () {
      test('should return only active accounts for platform', () {
        // Arrange
        final activeAccount = Account(
          id: 'active1',
          platform: PlatformType.mastodon,
          displayName: 'Active User',
          username: 'activeuser',
          createdAt: DateTime.now(),
          isActive: true,
        );

        final inactiveAccount = Account(
          id: 'inactive1',
          platform: PlatformType.mastodon,
          displayName: 'Inactive User',
          username: 'inactiveuser',
          createdAt: DateTime.now(),
          isActive: false,
        );

        accountManager.addAccountForTesting(activeAccount);
        accountManager.addAccountForTesting(inactiveAccount);

        // Act
        final activeAccounts = accountManager.getActiveAccountsForPlatform(PlatformType.mastodon);

        // Assert
        expect(activeAccounts.length, equals(1));
        expect(activeAccounts.first.isActive, isTrue);
        expect(activeAccounts.first.id, equals('active1'));
      });
    });

    group('validateAccount', () {
      test('should validate account connection', () async {
        // Arrange
        final account = Account(
          id: 'account1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
        );

        when(mockMastodonService.validateConnection(account)).thenAnswer((_) async => true);

        // Act
        final isValid = await accountManager.validateAccount(account);

        // Assert
        expect(isValid, isTrue);
        verify(mockMastodonService.validateConnection(account)).called(1);
      });

      test('should return false for unsupported platform', () async {
        // Arrange
        final accountManagerWithoutServices = AccountManager(
          storageService: mockStorageService,
          platformServices: {},
        );

        final account = Account(
          id: 'account1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
        );

        // Act
        final isValid = await accountManagerWithoutServices.validateAccount(account);

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('testAuthentication', () {
      test('should test account authentication', () async {
        // Arrange
        final account = Account(
          id: 'account1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
        );

        when(mockMastodonService.authenticate(account)).thenAnswer((_) async => true);

        // Act
        final authResult = await accountManager.testAuthentication(account);

        // Assert
        expect(authResult, isTrue);
        verify(mockMastodonService.authenticate(account)).called(1);
      });
    });

    group('setAccountActive', () {
      test('should activate/deactivate account', () async {
        // Arrange
        final account = Account(
          id: 'account1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          isActive: true,
        );

        accountManager.addAccountForTesting(account);

        when(mockStorageService.storeAccountData(any, any)).thenAnswer((_) async {});
        when(mockStorageService.storeAccountCredentials(any, any)).thenAnswer((_) async {});

        // Act
        await accountManager.setAccountActive('account1', false);

        // Assert
        expect(accountManager.accounts.first.isActive, isFalse);
      });
    });

    group('utility methods', () {
      test('should get default account for platform', () {
        // Arrange
        final account1 = Account(
          id: 'account1',
          platform: PlatformType.mastodon,
          displayName: 'User 1',
          username: 'user1',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          isActive: true,
        );

        final account2 = Account(
          id: 'account2',
          platform: PlatformType.mastodon,
          displayName: 'User 2',
          username: 'user2',
          createdAt: DateTime.now(),
          isActive: true,
        );

        accountManager.addAccountForTesting(account1);
        accountManager.addAccountForTesting(account2);

        // Act
        final defaultAccount = accountManager.getDefaultAccountForPlatform(PlatformType.mastodon);

        // Assert
        expect(defaultAccount, isNotNull);
        expect(defaultAccount!.id, equals('account1')); // First active account
      });

      test('should check if accounts exist for platform', () {
        // Arrange
        final account = Account(
          id: 'account1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
        );

        accountManager.addAccountForTesting(account);

        // Act & Assert
        expect(accountManager.hasAccountsForPlatform(PlatformType.mastodon), isTrue);
        expect(accountManager.hasAccountsForPlatform(PlatformType.bluesky), isFalse);
      });

      test('should get account counts', () {
        // Arrange
        final activeAccount = Account(
          id: 'active1',
          platform: PlatformType.mastodon,
          displayName: 'Active User',
          username: 'activeuser',
          createdAt: DateTime.now(),
          isActive: true,
        );

        final inactiveAccount = Account(
          id: 'inactive1',
          platform: PlatformType.bluesky,
          displayName: 'Inactive User',
          username: 'inactiveuser',
          createdAt: DateTime.now(),
          isActive: false,
        );

        accountManager.addAccountForTesting(activeAccount);
        accountManager.addAccountForTesting(inactiveAccount);

        // Act & Assert
        expect(accountManager.totalAccountCount, equals(2));
        expect(accountManager.activeAccountCount, equals(1));
      });
    });

    group('error handling', () {
      test('should clear error', () {
        // Arrange
        accountManager.setErrorForTesting('Test error');

        // Act
        accountManager.clearError();

        // Assert
        expect(accountManager.error, isNull);
      });
    });
  });
}