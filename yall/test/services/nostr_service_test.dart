import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:yall/models/account.dart';
import 'package:yall/models/platform_type.dart';
import 'package:yall/models/post_result.dart';
import 'package:yall/services/nostr_service.dart';
import 'package:yall/services/social_platform_service.dart';

// Mock classes for testing
@GenerateMocks([WebSocketChannel, WebSocketSink, Stream])
import 'nostr_service_test.mocks.dart';

void main() {
  group('NostrService', () {
    late NostrService nostrService;
    late Account testAccount;
    late Map<String, String> testKeyPair;

    setUp(() {
      nostrService = NostrService();
      testKeyPair = NostrService.generateKeyPair();

      testAccount = Account(
        id: 'test-nostr-account',
        platform: PlatformType.nostr,
        displayName: 'Test Nostr Account',
        username: 'testuser',
        credentials: {
          'private_key': testKeyPair['private_key']!,
          'public_key': testKeyPair['public_key']!,
          'relays': ['wss://test-relay.example.com', 'wss://test-relay2.example.com'],
        },
        isActive: true,
        createdAt: DateTime.now(),
      );
    });

    tearDown(() {
      nostrService.dispose();
    });

    group('Platform Properties', () {
      test('should return correct platform type', () {
        expect(nostrService.platformType, equals(PlatformType.nostr));
      });

      test('should return correct platform name', () {
        expect(nostrService.platformName, equals('Nostr'));
      });

      test('should return correct character limit', () {
        expect(nostrService.characterLimit, equals(280));
      });

      test('should return required credential fields', () {
        expect(nostrService.requiredCredentialFields, containsAll(['private_key', 'relays']));
      });
    });

    group('Key Pair Generation', () {
      test('should generate valid key pair', () {
        final keyPair = NostrService.generateKeyPair();

        expect(keyPair.containsKey('private_key'), isTrue);
        expect(keyPair.containsKey('public_key'), isTrue);
        expect(keyPair['private_key']!.length, equals(64));
        expect(keyPair['public_key']!.length, equals(64));

        // Should be valid hex strings
        expect(RegExp(r'^[0-9a-fA-F]+$').hasMatch(keyPair['private_key']!), isTrue);
        expect(RegExp(r'^[0-9a-fA-F]+$').hasMatch(keyPair['public_key']!), isTrue);
      });

      test('should generate different key pairs each time', () {
        final keyPair1 = NostrService.generateKeyPair();
        final keyPair2 = NostrService.generateKeyPair();

        expect(keyPair1['private_key'], isNot(equals(keyPair2['private_key'])));
        expect(keyPair1['public_key'], isNot(equals(keyPair2['public_key'])));
      });
    });

    group('Credential Validation', () {
      test('should validate correct credentials', () {
        expect(nostrService.validateCredentials(testAccount), isTrue);
      });

      test('should reject account with wrong platform', () {
        final wrongPlatformAccount = Account(
          id: 'test-account',
          platform: PlatformType.mastodon,
          displayName: 'Test Account',
          username: 'testuser',
          credentials: {
            'private_key': testKeyPair['private_key']!,
            'relays': ['wss://test-relay.example.com'],
          },
          isActive: true,
          createdAt: DateTime.now(),
        );

        expect(nostrService.validateCredentials(wrongPlatformAccount), isFalse);
      });

      test('should reject account with missing private key', () {
        final accountWithoutPrivateKey = Account(
          id: 'test-account',
          platform: PlatformType.nostr,
          displayName: 'Test Account',
          username: 'testuser',
          credentials: {
            'relays': ['wss://test-relay.example.com'],
          },
          isActive: true,
          createdAt: DateTime.now(),
        );

        expect(nostrService.validateCredentials(accountWithoutPrivateKey), isFalse);
      });

      test('should reject account with invalid private key format', () {
        final accountWithInvalidKey = Account(
          id: 'test-account',
          platform: PlatformType.nostr,
          displayName: 'Test Account',
          username: 'testuser',
          credentials: {
            'private_key': 'invalid-key',
            'relays': ['wss://test-relay.example.com'],
          },
          isActive: true,
          createdAt: DateTime.now(),
        );

        expect(nostrService.validateCredentials(accountWithInvalidKey), isFalse);
      });

      test('should reject account with invalid relay URLs', () {
        final accountWithInvalidRelays = Account(
          id: 'test-account',
          platform: PlatformType.nostr,
          displayName: 'Test Account',
          username: 'testuser',
          credentials: {
            'private_key': testKeyPair['private_key']!,
            'relays': ['http://invalid-relay.com', 'not-a-url'],
          },
          isActive: true,
          createdAt: DateTime.now(),
        );

        expect(nostrService.validateCredentials(accountWithInvalidRelays), isFalse);
      });

      test('should accept account without relays (uses defaults)', () {
        final accountWithoutRelays = Account(
          id: 'test-account',
          platform: PlatformType.nostr,
          displayName: 'Test Account',
          username: 'testuser',
          credentials: {
            'private_key': testKeyPair['private_key']!,
          },
          isActive: true,
          createdAt: DateTime.now(),
        );

        expect(nostrService.validateCredentials(accountWithoutRelays), isTrue);
      });
    });

    group('Content Validation', () {
      test('should accept content within character limit', () {
        const shortContent = 'This is a short message';
        expect(nostrService.isContentValid(shortContent), isTrue);
        expect(nostrService.getRemainingCharacters(shortContent), equals(280 - shortContent.length));
      });

      test('should reject content exceeding character limit', () {
        final longContent = 'a' * 281;
        expect(nostrService.isContentValid(longContent), isFalse);
        expect(nostrService.getRemainingCharacters(longContent), equals(-1));
      });

      test('should accept content at exact character limit', () {
        final exactContent = 'a' * 280;
        expect(nostrService.isContentValid(exactContent), isTrue);
        expect(nostrService.getRemainingCharacters(exactContent), equals(0));
      });
    });

    group('Authentication', () {
      test('should fail authentication with missing credentials', () async {
        final accountWithoutCredentials = Account(
          id: 'test-account',
          platform: PlatformType.nostr,
          displayName: 'Test Account',
          username: 'testuser',
          credentials: {},
          isActive: true,
          createdAt: DateTime.now(),
        );

        expect(
          () => nostrService.authenticate(accountWithoutCredentials),
          throwsA(isA<SocialPlatformException>()
              .having((e) => e.errorType, 'errorType', PostErrorType.invalidCredentials)),
        );
      });

      test('should fail authentication with invalid private key', () async {
        final accountWithInvalidKey = Account(
          id: 'test-account',
          platform: PlatformType.nostr,
          displayName: 'Test Account',
          username: 'testuser',
          credentials: {
            'private_key': 'invalid-key',
            'relays': ['wss://test-relay.example.com'],
          },
          isActive: true,
          createdAt: DateTime.now(),
        );

        expect(
          () => nostrService.authenticate(accountWithInvalidKey),
          throwsA(isA<SocialPlatformException>()
              .having((e) => e.errorType, 'errorType', PostErrorType.invalidCredentials)),
        );
      });
    });

    group('Post Publishing', () {
      test('should fail to publish content exceeding character limit', () async {
        final longContent = 'a' * 281;

        final result = await nostrService.publishPost(longContent, testAccount);

        expect(result.allSuccessful, isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.getError(PlatformType.nostr), contains('character limit'));
        expect(result.getErrorType(PlatformType.nostr), equals(PostErrorType.contentTooLong));
      });

      test('should fail to publish with missing credentials', () async {
        final accountWithoutCredentials = Account(
          id: 'test-account',
          platform: PlatformType.nostr,
          displayName: 'Test Account',
          username: 'testuser',
          credentials: {},
          isActive: true,
          createdAt: DateTime.now(),
        );

        const content = 'Test message';
        final result = await nostrService.publishPost(content, accountWithoutCredentials);

        expect(result.allSuccessful, isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.getError(PlatformType.nostr), contains('Missing required credentials'));
        expect(result.getErrorType(PlatformType.nostr), equals(PostErrorType.invalidCredentials));
      });

      test('should fail to publish with invalid private key', () async {
        final accountWithInvalidKey = Account(
          id: 'test-account',
          platform: PlatformType.nostr,
          displayName: 'Test Account',
          username: 'testuser',
          credentials: {
            'private_key': 'invalid-key',
            'relays': ['wss://test-relay.example.com'],
          },
          isActive: true,
          createdAt: DateTime.now(),
        );

        const content = 'Test message';
        final result = await nostrService.publishPost(content, accountWithInvalidKey);

        expect(result.allSuccessful, isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.getError(PlatformType.nostr), contains('Invalid private key format'));
        expect(result.getErrorType(PlatformType.nostr), equals(PostErrorType.invalidCredentials));
      });
    });

    group('Connection Validation', () {
      test('should return false for invalid connection', () async {
        final accountWithInvalidKey = Account(
          id: 'test-account',
          platform: PlatformType.nostr,
          displayName: 'Test Account',
          username: 'testuser',
          credentials: {
            'private_key': 'invalid-key',
            'relays': ['wss://test-relay.example.com'],
          },
          isActive: true,
          createdAt: DateTime.now(),
        );

        final isValid = await nostrService.validateConnection(accountWithInvalidKey);
        expect(isValid, isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // This test would require mocking WebSocket connections
        // For now, we test the error handling structure
        const content = 'Test message';

        final result = nostrService.handleError(
          content,
          const SocketException('Network error'),
        );

        expect(result.allSuccessful, isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.getErrorType(PlatformType.nostr), equals(PostErrorType.networkError));
      });

      test('should handle authentication errors gracefully', () async {
        const content = 'Test message';

        final result = nostrService.handleError(
          content,
          const SocialPlatformException(
            platform: PlatformType.nostr,
            errorType: PostErrorType.authenticationError,
            message: 'Auth failed',
          ),
        );

        expect(result.allSuccessful, isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.getErrorType(PlatformType.nostr), equals(PostErrorType.authenticationError));
      });

      test('should handle unknown errors gracefully', () async {
        const content = 'Test message';

        final result = nostrService.handleError(
          content,
          Exception('Unknown error'),
        );

        expect(result.allSuccessful, isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.getErrorType(PlatformType.nostr), equals(PostErrorType.unknownError));
      });
    });

    group('Result Creation', () {
      test('should create success result correctly', () {
        const content = 'Test message';
        final result = nostrService.createSuccessResult(content);

        expect(result.allSuccessful, isTrue);
        expect(result.hasErrors, isFalse);
        expect(result.originalContent, equals(content));
        expect(result.isSuccessful(PlatformType.nostr), isTrue);
      });

      test('should create failure result correctly', () {
        const content = 'Test message';
        const errorMessage = 'Test error';
        const errorType = PostErrorType.networkError;

        final result = nostrService.createFailureResult(content, errorMessage, errorType);

        expect(result.allSuccessful, isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.originalContent, equals(content));
        expect(result.isSuccessful(PlatformType.nostr), isFalse);
        expect(result.getError(PlatformType.nostr), equals(errorMessage));
        expect(result.getErrorType(PlatformType.nostr), equals(errorType));
      });
    });

    group('Default Relays', () {
      test('should have default relays defined', () {
        expect(NostrService.defaultRelays, isNotEmpty);
        expect(NostrService.defaultRelays.length, greaterThan(0));

        for (final relay in NostrService.defaultRelays) {
          expect(relay, startsWith('wss://'));
        }
      });
    });

    group('Disposal', () {
      test('should dispose without throwing', () {
        expect(() => nostrService.dispose(), returnsNormally);
      });
    });
  });
}