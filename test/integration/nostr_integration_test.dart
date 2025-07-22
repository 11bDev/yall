import 'package:flutter_test/flutter_test.dart';
import 'package:yall/models/account.dart';
import 'package:yall/models/platform_type.dart';
import 'package:yall/models/post_result.dart';
import 'package:yall/services/nostr_service.dart';

void main() {
  group('Nostr Integration Tests', () {
    late NostrService nostrService;
    late Account testAccount;

    setUp(() {
      nostrService = NostrService();

      // Generate a test key pair
      final keyPair = NostrService.generateKeyPair();

      testAccount = Account(
        id: 'test-nostr-integration',
        platform: PlatformType.nostr,
        displayName: 'Test Nostr Integration',
        username: 'testuser',
        credentials: {
          'private_key': keyPair['private_key']!,
          'public_key': keyPair['public_key']!,
          'relays': ['wss://relay.damus.io'], // Use a real relay for integration test
        },
        isActive: true,
        createdAt: DateTime.now(),
      );
    });

    tearDown(() {
      nostrService.dispose();
    });

    test('should generate valid key pairs', () {
      final keyPair1 = NostrService.generateKeyPair();
      final keyPair2 = NostrService.generateKeyPair();

      // Keys should be different
      expect(keyPair1['private_key'], isNot(equals(keyPair2['private_key'])));
      expect(keyPair1['public_key'], isNot(equals(keyPair2['public_key'])));

      // Keys should be valid hex strings of correct length
      expect(keyPair1['private_key']!.length, equals(64));
      expect(keyPair1['public_key']!.length, equals(64));
      expect(RegExp(r'^[0-9a-fA-F]+$').hasMatch(keyPair1['private_key']!), isTrue);
      expect(RegExp(r'^[0-9a-fA-F]+$').hasMatch(keyPair1['public_key']!), isTrue);
    });

    test('should validate credentials correctly', () {
      expect(nostrService.validateCredentials(testAccount), isTrue);
      expect(nostrService.hasRequiredCredentials(testAccount), isTrue);
    });

    test('should handle content validation', () {
      const shortContent = 'Hello Nostr!';
      final longContent = 'a' * 281; // Exceeds 280 character limit

      expect(nostrService.isContentValid(shortContent), isTrue);
      expect(nostrService.isContentValid(longContent), isFalse);
      expect(nostrService.getRemainingCharacters(shortContent), equals(280 - shortContent.length));
      expect(nostrService.getRemainingCharacters(longContent), equals(-1));
    });

    test('should create proper error results', () {
      const content = 'Test content';
      const errorMessage = 'Test error';
      const errorType = PostErrorType.networkError;

      final result = nostrService.createFailureResult(content, errorMessage, errorType);

      expect(result.allSuccessful, isFalse);
      expect(result.hasErrors, isTrue);
      expect(result.getError(PlatformType.nostr), equals(errorMessage));
      expect(result.getErrorType(PlatformType.nostr), equals(errorType));
      expect(result.originalContent, equals(content));
    });

    test('should create proper success results', () {
      const content = 'Test content';

      final result = nostrService.createSuccessResult(content);

      expect(result.allSuccessful, isTrue);
      expect(result.hasErrors, isFalse);
      expect(result.isSuccessful(PlatformType.nostr), isTrue);
      expect(result.originalContent, equals(content));
    });

    test('should have correct platform properties', () {
      expect(nostrService.platformType, equals(PlatformType.nostr));
      expect(nostrService.platformName, equals('Nostr'));
      expect(nostrService.characterLimit, equals(280));
      expect(nostrService.requiredCredentialFields, containsAll(['private_key', 'relays']));
    });

    test('should handle default relays', () {
      expect(NostrService.defaultRelays, isNotEmpty);
      for (final relay in NostrService.defaultRelays) {
        expect(relay, startsWith('wss://'));
      }
    });
  });
}