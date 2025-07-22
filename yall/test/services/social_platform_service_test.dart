import 'package:flutter_test/flutter_test.dart';
import 'package:yall/models/account.dart';
import 'package:yall/models/platform_type.dart';
import 'package:yall/models/post_result.dart';
import 'package:yall/services/social_platform_service.dart';
import 'package:yall/services/mock_social_platform_service.dart';

void main() {
  group('SocialPlatformService Abstract Interface', () {
    late MockSocialPlatformService service;
    late Account testAccount;

    setUp(() {
      service = MockSocialPlatformService(platformType: PlatformType.mastodon);
      testAccount = Account(
        id: 'test-account-1',
        platform: PlatformType.mastodon,
        displayName: 'Test User',
        username: 'testuser',
        createdAt: DateTime.now(),
        credentials: {
          'access_token': 'test-token',
          'server_url': 'https://mastodon.social',
        },
      );
    });

    group('Platform Properties', () {
      test('should return correct platform type', () {
        expect(service.platformType, equals(PlatformType.mastodon));
      });

      test('should return correct platform name', () {
        expect(service.platformName, equals('Mastodon'));
      });

      test('should return correct character limit', () {
        expect(service.characterLimit, equals(500));
      });
    });

    group('Content Validation', () {
      test('should validate content within character limit', () {
        const shortContent = 'This is a short post';
        expect(service.isContentValid(shortContent), isTrue);
      });

      test('should reject content exceeding character limit', () {
        final longContent = 'a' * 501; // Exceeds Mastodon's 500 char limit
        expect(service.isContentValid(longContent), isFalse);
      });

      test('should calculate remaining characters correctly', () {
        const content = 'Hello world'; // 11 characters
        expect(service.getRemainingCharacters(content), equals(489)); // 500 - 11
      });

      test('should handle empty content', () {
        expect(service.isContentValid(''), isTrue);
        expect(service.getRemainingCharacters(''), equals(500));
      });

      test('should handle content at exact character limit', () {
        final exactContent = 'a' * 500;
        expect(service.isContentValid(exactContent), isTrue);
        expect(service.getRemainingCharacters(exactContent), equals(0));
      });
    });

    group('Result Creation Helpers', () {
      test('should create successful post result', () {
        const content = 'Test post';
        final result = service.createSuccessResult(content);

        expect(result.isSuccessful(PlatformType.mastodon), isTrue);
        expect(result.hasErrors, isFalse);
        expect(result.originalContent, equals(content));
      });

      test('should create failed post result', () {
        const content = 'Test post';
        const errorMessage = 'Test error';
        const errorType = PostErrorType.networkError;

        final result = service.createFailureResult(content, errorMessage, errorType);

        expect(result.isSuccessful(PlatformType.mastodon), isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.getError(PlatformType.mastodon), equals(errorMessage));
        expect(result.getErrorType(PlatformType.mastodon), equals(errorType));
        expect(result.originalContent, equals(content));
      });
    });

    group('Error Handling', () {
      test('should handle SocialPlatformException', () {
        const content = 'Test post';
        final exception = SocialPlatformException(
          platform: PlatformType.mastodon,
          errorType: PostErrorType.authenticationError,
          message: 'Auth failed',
        );

        final result = service.handleError(content, exception);

        expect(result.isSuccessful(PlatformType.mastodon), isFalse);
        expect(result.getError(PlatformType.mastodon), equals('Auth failed'));
        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.authenticationError));
      });

      test('should detect network errors from error message', () {
        const content = 'Test post';
        final error = Exception('Network connection failed');

        final result = service.handleError(content, error);

        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.networkError));
      });

      test('should detect authentication errors from error message', () {
        const content = 'Test post';
        final error = Exception('Unauthorized access');

        final result = service.handleError(content, error);

        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.authenticationError));
      });

      test('should detect rate limit errors from error message', () {
        const content = 'Test post';
        final error = Exception('Rate limit exceeded');

        final result = service.handleError(content, error);

        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.rateLimitError));
      });

      test('should detect server errors from error message', () {
        const content = 'Test post';
        final error = Exception('Internal server error 500');

        final result = service.handleError(content, error);

        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.serverError));
      });

      test('should use default error type for unknown errors', () {
        const content = 'Test post';
        final error = Exception('Unknown error');

        final result = service.handleError(content, error, defaultErrorType: PostErrorType.platformUnavailable);

        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.platformUnavailable));
      });

      test('should use unknown error type when no default provided', () {
        const content = 'Test post';
        final error = Exception('Some random error');

        final result = service.handleError(content, error);

        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.unknownError));
      });
    });

    group('Credential Validation', () {
      test('should validate correct platform type', () {
        expect(service.validateCredentials(testAccount), isTrue);
      });

      test('should reject wrong platform type', () {
        final wrongPlatformAccount = testAccount.copyWith(platform: PlatformType.bluesky);
        expect(service.validateCredentials(wrongPlatformAccount), isFalse);
      });

      test('should return required credential fields', () {
        expect(service.requiredCredentialFields, contains('access_token'));
        expect(service.requiredCredentialFields, contains('server_url'));
      });

      test('should validate account with all required credentials', () {
        expect(service.hasRequiredCredentials(testAccount), isTrue);
      });

      test('should reject account missing required credentials', () {
        final incompleteAccount = testAccount.copyWith(
          credentials: {'access_token': 'test-token'}, // Missing server_url
        );
        expect(service.hasRequiredCredentials(incompleteAccount), isFalse);
      });

      test('should reject account with wrong platform', () {
        final wrongPlatformAccount = testAccount.copyWith(platform: PlatformType.bluesky);
        expect(service.hasRequiredCredentials(wrongPlatformAccount), isFalse);
      });
    });
  });

  group('MockSocialPlatformService', () {
    group('Successful Operations', () {
      late MockSocialPlatformService service;
      late Account testAccount;

      setUp(() {
        service = MockSocialPlatformServiceFactory.createSuccessful(PlatformType.mastodon);
        testAccount = Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          credentials: {
            'access_token': 'test-token',
            'instance_url': 'https://mastodon.social',
          },
        );
      });

      test('should authenticate successfully', () async {
        final result = await service.authenticate(testAccount);
        expect(result, isTrue);
      });

      test('should publish post successfully', () async {
        const content = 'Test post content';
        final result = await service.publishPost(content, testAccount);

        expect(result.isSuccessful(PlatformType.mastodon), isTrue);
        expect(result.hasErrors, isFalse);
        expect(result.originalContent, equals(content));
      });

      test('should validate connection successfully', () async {
        final result = await service.validateConnection(testAccount);
        expect(result, isTrue);
      });
    });

    group('Authentication Failures', () {
      late MockSocialPlatformService service;
      late Account testAccount;

      setUp(() {
        service = MockSocialPlatformServiceFactory.createAuthenticationFailure(PlatformType.mastodon);
        testAccount = Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          credentials: {
            'access_token': 'test-token',
            'instance_url': 'https://mastodon.social',
          },
        );
      });

      test('should throw exception on authentication failure', () async {
        expect(
          () => service.authenticate(testAccount),
          throwsA(isA<SocialPlatformException>()),
        );
      });

      test('should throw exception with correct error details', () async {
        try {
          await service.authenticate(testAccount);
          fail('Expected SocialPlatformException');
        } catch (e) {
          expect(e, isA<SocialPlatformException>());
          final exception = e as SocialPlatformException;
          expect(exception.platform, equals(PlatformType.mastodon));
          expect(exception.errorType, equals(PostErrorType.authenticationError));
          expect(exception.message, equals('Authentication failed'));
        }
      });
    });

    group('Posting Failures', () {
      late MockSocialPlatformService service;
      late Account testAccount;

      setUp(() {
        service = MockSocialPlatformServiceFactory.createPostingFailure(PlatformType.mastodon);
        testAccount = Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          credentials: {
            'access_token': 'test-token',
            'instance_url': 'https://mastodon.social',
          },
        );
      });

      test('should return failure result on posting error', () async {
        const content = 'Test post content';
        final result = await service.publishPost(content, testAccount);

        expect(result.isSuccessful(PlatformType.mastodon), isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.getError(PlatformType.mastodon), equals('Failed to publish post'));
        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.serverError));
      });
    });

    group('Content Length Validation', () {
      late MockSocialPlatformService service;
      late Account testAccount;

      setUp(() {
        service = MockSocialPlatformServiceFactory.createSuccessful(PlatformType.mastodon);
        testAccount = Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          credentials: {
            'access_token': 'test-token',
            'instance_url': 'https://mastodon.social',
          },
        );
      });

      test('should reject content exceeding character limit', () async {
        final longContent = 'a' * 501; // Exceeds Mastodon's 500 char limit
        final result = await service.publishPost(longContent, testAccount);

        expect(result.isSuccessful(PlatformType.mastodon), isFalse);
        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.contentTooLong));
        expect(result.getError(PlatformType.mastodon), contains('character limit'));
      });
    });

    group('Credential Validation', () {
      late MockSocialPlatformService service;

      setUp(() {
        service = MockSocialPlatformServiceFactory.createSuccessful(PlatformType.mastodon);
      });

      test('should reject account with missing credentials', () async {
        final incompleteAccount = Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          credentials: {'access_token': 'test-token'}, // Missing instance_url
        );

        expect(
          () => service.authenticate(incompleteAccount),
          throwsA(isA<SocialPlatformException>()),
        );

        final result = await service.publishPost('Test content', incompleteAccount);
        expect(result.isSuccessful(PlatformType.mastodon), isFalse);
        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.invalidCredentials));
      });

      test('should validate Mastodon credentials format', () {
        final validAccount = Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          credentials: {
            'access_token': 'test-token',
            'instance_url': 'https://mastodon.social',
          },
        );

        expect(service.validateCredentials(validAccount), isTrue);
      });

      test('should reject invalid Mastodon instance URL', () {
        final invalidAccount = Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          credentials: {
            'access_token': 'test-token',
            'instance_url': 'http://mastodon.social', // Should be https
          },
        );

        expect(service.validateCredentials(invalidAccount), isFalse);
      });
    });

    group('Different Platform Types', () {
      test('should handle Bluesky platform correctly', () {
        final service = MockSocialPlatformServiceFactory.createSuccessful(PlatformType.bluesky);
        expect(service.platformType, equals(PlatformType.bluesky));
        expect(service.characterLimit, equals(300));
        expect(service.requiredCredentialFields, contains('handle'));
        expect(service.requiredCredentialFields, contains('app_password'));
      });

      test('should handle Nostr platform correctly', () {
        final service = MockSocialPlatformServiceFactory.createSuccessful(PlatformType.nostr);
        expect(service.platformType, equals(PlatformType.nostr));
        expect(service.characterLimit, equals(280));
        expect(service.requiredCredentialFields, contains('private_key'));
      });

      test('should validate Bluesky credentials format', () {
        final service = MockSocialPlatformServiceFactory.createSuccessful(PlatformType.bluesky);
        final validAccount = Account(
          id: 'test-account-1',
          platform: PlatformType.bluesky,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          credentials: {
            'handle': 'user.bsky.social',
            'app_password': 'test-password',
          },
        );

        expect(service.validateCredentials(validAccount), isTrue);
      });

      test('should validate Nostr credentials format', () {
        final service = MockSocialPlatformServiceFactory.createSuccessful(PlatformType.nostr);
        final validAccount = Account(
          id: 'test-account-1',
          platform: PlatformType.nostr,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          credentials: {
            'private_key': 'a' * 64, // 64 character hex string
          },
        );

        expect(service.validateCredentials(validAccount), isTrue);
      });
    });

    group('Factory Methods', () {
      test('should create network failure service', () {
        final service = MockSocialPlatformServiceFactory.createNetworkFailure(PlatformType.mastodon);
        expect(service.platformType, equals(PlatformType.mastodon));
      });

      test('should create rate limit failure service', () {
        final service = MockSocialPlatformServiceFactory.createRateLimitFailure(PlatformType.mastodon);
        expect(service.platformType, equals(PlatformType.mastodon));
      });

      test('should create validation failure service', () {
        final service = MockSocialPlatformServiceFactory.createValidationFailure(PlatformType.mastodon);
        expect(service.platformType, equals(PlatformType.mastodon));
      });

      test('should create slow service', () {
        final service = MockSocialPlatformServiceFactory.createSlow(PlatformType.mastodon);
        expect(service.platformType, equals(PlatformType.mastodon));
      });
    });
  });

  group('SocialPlatformException', () {
    test('should create exception with all properties', () {
      final exception = SocialPlatformException(
        platform: PlatformType.mastodon,
        errorType: PostErrorType.networkError,
        message: 'Network failed',
        originalError: Exception('Original error'),
      );

      expect(exception.platform, equals(PlatformType.mastodon));
      expect(exception.errorType, equals(PostErrorType.networkError));
      expect(exception.message, equals('Network failed'));
      expect(exception.originalError, isA<Exception>());
    });

    test('should have meaningful toString', () {
      final exception = SocialPlatformException(
        platform: PlatformType.mastodon,
        errorType: PostErrorType.networkError,
        message: 'Network failed',
      );

      final string = exception.toString();
      expect(string, contains('SocialPlatformException'));
      expect(string, contains('Mastodon'));
      expect(string, contains('networkError'));
      expect(string, contains('Network failed'));
    });
  });
}