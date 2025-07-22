import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:yall/models/account.dart';
import 'package:yall/models/platform_type.dart';
import 'package:yall/models/post_result.dart';
import 'package:yall/services/bluesky_service.dart';
import 'package:yall/services/social_platform_service.dart';

import 'bluesky_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('BlueskyService', () {
    late BlueskyService service;
    late MockClient mockHttpClient;
    late Account testAccount;

    setUp(() {
      mockHttpClient = MockClient();
      service = BlueskyService(httpClient: mockHttpClient);

      testAccount = Account(
        id: 'test-account-id',
        platform: PlatformType.bluesky,
        displayName: 'Test User',
        username: 'testuser.bsky.social',
        createdAt: DateTime.now(),
        credentials: {
          'identifier': 'testuser.bsky.social',
          'password': 'testpassword123',
        },
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('Basic Properties', () {
      test('should return correct platform type', () {
        expect(service.platformType, equals(PlatformType.bluesky));
      });

      test('should return correct platform name', () {
        expect(service.platformName, equals('Bluesky'));
      });

      test('should return correct character limit', () {
        expect(service.characterLimit, equals(300));
      });

      test('should return required credential fields', () {
        expect(service.requiredCredentialFields, equals(['identifier', 'password']));
      });
    });

    group('Credential Validation', () {
      test('should validate correct credentials', () {
        expect(service.validateCredentials(testAccount), isTrue);
      });

      test('should reject account with wrong platform', () {
        final wrongPlatformAccount = testAccount.copyWith(
          platform: PlatformType.mastodon,
        );
        expect(service.validateCredentials(wrongPlatformAccount), isFalse);
      });

      test('should reject account with missing identifier', () {
        final invalidAccount = testAccount.copyWith(
          credentials: {'password': 'testpassword123'},
        );
        expect(service.validateCredentials(invalidAccount), isFalse);
      });

      test('should reject account with missing password', () {
        final invalidAccount = testAccount.copyWith(
          credentials: {'identifier': 'testuser.bsky.social'},
        );
        expect(service.validateCredentials(invalidAccount), isFalse);
      });

      test('should reject account with empty identifier', () {
        final invalidAccount = testAccount.copyWith(
          credentials: {
            'identifier': '',
            'password': 'testpassword123',
          },
        );
        expect(service.validateCredentials(invalidAccount), isFalse);
      });

      test('should reject account with empty password', () {
        final invalidAccount = testAccount.copyWith(
          credentials: {
            'identifier': 'testuser.bsky.social',
            'password': '',
          },
        );
        expect(service.validateCredentials(invalidAccount), isFalse);
      });

      test('should validate email identifier format', () {
        final emailAccount = testAccount.copyWith(
          credentials: {
            'identifier': 'test@example.com',
            'password': 'testpassword123',
          },
        );
        expect(service.validateCredentials(emailAccount), isTrue);
      });

      test('should validate handle identifier format', () {
        final handleAccount = testAccount.copyWith(
          credentials: {
            'identifier': 'user.bsky.social',
            'password': 'testpassword123',
          },
        );
        expect(service.validateCredentials(handleAccount), isTrue);
      });

      test('should reject invalid identifier format', () {
        final invalidAccount = testAccount.copyWith(
          credentials: {
            'identifier': 'invalid..identifier',
            'password': 'testpassword123',
          },
        );
        expect(service.validateCredentials(invalidAccount), isFalse);
      });

      test('should validate custom PDS URL', () {
        final customPdsAccount = testAccount.copyWith(
          credentials: {
            'identifier': 'testuser.bsky.social',
            'password': 'testpassword123',
            'pds_url': 'https://custom.pds.example.com',
          },
        );
        expect(service.validateCredentials(customPdsAccount), isTrue);
      });

      test('should reject invalid PDS URL', () {
        final invalidPdsAccount = testAccount.copyWith(
          credentials: {
            'identifier': 'testuser.bsky.social',
            'password': 'testpassword123',
            'pds_url': 'not-a-valid-url',
          },
        );
        expect(service.validateCredentials(invalidPdsAccount), isFalse);
      });
    });

    group('Authentication', () {
      test('should authenticate successfully with valid credentials', () async {
        // Mock successful session creation
        when(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.server.createSession'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'accessJwt': 'test-access-token',
            'refreshJwt': 'test-refresh-token',
            'did': 'did:plc:test123',
            'handle': 'testuser.bsky.social',
          }),
          200,
        ));

        final result = await service.authenticate(testAccount);
        expect(result, isTrue);

        // Verify the request was made correctly
        verify(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.server.createSession'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'identifier': 'testuser.bsky.social',
            'password': 'testpassword123',
          }),
        )).called(1);
      });

      test('should fail authentication with invalid credentials', () async {
        // Mock authentication failure
        when(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.server.createSession'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({'error': 'InvalidCredentials', 'message': 'Invalid identifier or password'}),
          401,
        ));

        expect(
          () => service.authenticate(testAccount),
          throwsA(isA<SocialPlatformException>()
              .having((e) => e.platform, 'platform', PlatformType.bluesky)
              .having((e) => e.errorType, 'errorType', PostErrorType.authenticationError)),
        );
      });

      test('should fail authentication with missing credentials', () async {
        final invalidAccount = testAccount.copyWith(
          credentials: {'identifier': 'testuser.bsky.social'},
        );

        expect(
          () => service.authenticate(invalidAccount),
          throwsA(isA<SocialPlatformException>()
              .having((e) => e.platform, 'platform', PlatformType.bluesky)
              .having((e) => e.errorType, 'errorType', PostErrorType.invalidCredentials)),
        );
      });

      test('should handle network errors during authentication', () async {
        // Mock network error
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(const SocketException('Network unreachable'));

        expect(
          () => service.authenticate(testAccount),
          throwsA(isA<SocialPlatformException>()
              .having((e) => e.platform, 'platform', PlatformType.bluesky)
              .having((e) => e.errorType, 'errorType', PostErrorType.networkError)),
        );
      });

      test('should use custom PDS URL when provided', () async {
        final customPdsAccount = testAccount.copyWith(
          credentials: {
            'identifier': 'testuser.bsky.social',
            'password': 'testpassword123',
            'pds_url': 'https://custom.pds.example.com',
          },
        );

        // Mock successful session creation
        when(mockHttpClient.post(
          Uri.parse('https://custom.pds.example.com/xrpc/com.atproto.server.createSession'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'accessJwt': 'test-access-token',
            'refreshJwt': 'test-refresh-token',
            'did': 'did:plc:test123',
            'handle': 'testuser.bsky.social',
          }),
          200,
        ));

        final result = await service.authenticate(customPdsAccount);
        expect(result, isTrue);

        // Verify the custom PDS URL was used
        verify(mockHttpClient.post(
          Uri.parse('https://custom.pds.example.com/xrpc/com.atproto.server.createSession'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).called(1);
      });
    });

    group('Publishing Posts', () {
      test('should publish post successfully', () async {
        const testContent = 'Hello Bluesky!';

        // Mock successful session creation
        when(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.server.createSession'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'accessJwt': 'test-access-token',
            'refreshJwt': 'test-refresh-token',
            'did': 'did:plc:test123',
            'handle': 'testuser.bsky.social',
          }),
          200,
        ));

        // Mock successful post creation
        when(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.repo.createRecord'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'uri': 'at://did:plc:test123/app.bsky.feed.post/test123',
            'cid': 'test-cid',
          }),
          200,
        ));

        final result = await service.publishPost(testContent, testAccount);

        expect(result.isSuccessful(PlatformType.bluesky), isTrue);
        expect(result.hasErrors, isFalse);
        expect(result.originalContent, equals(testContent));

        // Verify session creation was called
        verify(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.server.createSession'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).called(1);

        // Verify post creation was called
        verify(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.repo.createRecord'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).called(1);
      });

      test('should use existing session tokens when available', () async {
        const testContent = 'Hello Bluesky!';

        final accountWithTokens = testAccount.copyWith(
          credentials: {
            'identifier': 'testuser.bsky.social',
            'password': 'testpassword123',
            'access_jwt': 'existing-access-token',
            'did': 'did:plc:test123',
          },
        );

        // Mock successful post creation (no session creation should be called)
        when(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.repo.createRecord'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'uri': 'at://did:plc:test123/app.bsky.feed.post/test123',
            'cid': 'test-cid',
          }),
          200,
        ));

        final result = await service.publishPost(testContent, accountWithTokens);

        expect(result.isSuccessful(PlatformType.bluesky), isTrue);
        expect(result.hasErrors, isFalse);

        // Verify session creation was NOT called
        verifyNever(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.server.createSession'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ));

        // Verify post creation was called with existing token
        verify(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.repo.createRecord'),
          headers: {
            'Authorization': 'Bearer existing-access-token',
            'Content-Type': 'application/json',
          },
          body: anyNamed('body'),
        )).called(1);
      });

      test('should reject content that exceeds character limit', () async {
        final longContent = 'a' * 301; // Exceeds 300 character limit

        final result = await service.publishPost(longContent, testAccount);

        expect(result.isSuccessful(PlatformType.bluesky), isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.getError(PlatformType.bluesky), contains('character limit'));
        expect(result.getErrorType(PlatformType.bluesky), equals(PostErrorType.contentTooLong));

        // Verify no HTTP requests were made
        verifyNever(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')));
      });

      test('should handle authentication errors during posting', () async {
        const testContent = 'Hello Bluesky!';

        // Mock session creation failure
        when(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.server.createSession'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({'error': 'InvalidCredentials'}),
          401,
        ));

        final result = await service.publishPost(testContent, testAccount);

        expect(result.isSuccessful(PlatformType.bluesky), isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.getErrorType(PlatformType.bluesky), equals(PostErrorType.authenticationError));
      });

      test('should handle rate limiting', () async {
        const testContent = 'Hello Bluesky!';

        // Mock successful session creation
        when(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.server.createSession'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'accessJwt': 'test-access-token',
            'refreshJwt': 'test-refresh-token',
            'did': 'did:plc:test123',
            'handle': 'testuser.bsky.social',
          }),
          200,
        ));

        // Mock rate limit error
        when(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.repo.createRecord'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({'error': 'RateLimitExceeded'}),
          429,
        ));

        final result = await service.publishPost(testContent, testAccount);

        expect(result.isSuccessful(PlatformType.bluesky), isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.getError(PlatformType.bluesky), contains('Rate limit'));
        expect(result.getErrorType(PlatformType.bluesky), equals(PostErrorType.rateLimitError));
      });

      test('should handle server errors', () async {
        const testContent = 'Hello Bluesky!';

        // Mock successful session creation
        when(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.server.createSession'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'accessJwt': 'test-access-token',
            'refreshJwt': 'test-refresh-token',
            'did': 'did:plc:test123',
            'handle': 'testuser.bsky.social',
          }),
          200,
        ));

        // Mock server error
        when(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.repo.createRecord'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          'Internal Server Error',
          500,
        ));

        final result = await service.publishPost(testContent, testAccount);

        expect(result.isSuccessful(PlatformType.bluesky), isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.getError(PlatformType.bluesky), contains('server error'));
        expect(result.getErrorType(PlatformType.bluesky), equals(PostErrorType.serverError));
      });

      test('should handle network errors during posting', () async {
        const testContent = 'Hello Bluesky!';

        // Mock network error
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(const SocketException('Network unreachable'));

        final result = await service.publishPost(testContent, testAccount);

        expect(result.isSuccessful(PlatformType.bluesky), isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.getError(PlatformType.bluesky), contains('Network connection failed'));
        expect(result.getErrorType(PlatformType.bluesky), equals(PostErrorType.networkError));
      });

      test('should handle missing credentials during posting', () async {
        const testContent = 'Hello Bluesky!';
        final invalidAccount = testAccount.copyWith(
          credentials: {'identifier': 'testuser.bsky.social'},
        );

        final result = await service.publishPost(testContent, invalidAccount);

        expect(result.isSuccessful(PlatformType.bluesky), isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.getError(PlatformType.bluesky), contains('Missing required credentials'));
        expect(result.getErrorType(PlatformType.bluesky), equals(PostErrorType.invalidCredentials));

        // Verify no HTTP requests were made
        verifyNever(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')));
      });
    });

    group('Connection Validation', () {
      test('should validate connection successfully', () async {
        // Mock successful session creation
        when(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.server.createSession'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'accessJwt': 'test-access-token',
            'refreshJwt': 'test-refresh-token',
            'did': 'did:plc:test123',
            'handle': 'testuser.bsky.social',
          }),
          200,
        ));

        final result = await service.validateConnection(testAccount);
        expect(result, isTrue);
      });

      test('should fail connection validation with invalid credentials', () async {
        // Mock authentication failure
        when(mockHttpClient.post(
          Uri.parse('https://bsky.social/xrpc/com.atproto.server.createSession'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({'error': 'InvalidCredentials'}),
          401,
        ));

        final result = await service.validateConnection(testAccount);
        expect(result, isFalse);
      });

      test('should fail connection validation on network error', () async {
        // Mock network error
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(const SocketException('Network unreachable'));

        final result = await service.validateConnection(testAccount);
        expect(result, isFalse);
      });
    });

    group('Content Validation', () {
      test('should validate content within character limit', () {
        const validContent = 'This is a valid post within the character limit.';
        expect(service.isContentValid(validContent), isTrue);
      });

      test('should reject content exceeding character limit', () {
        final invalidContent = 'a' * 301; // Exceeds 300 character limit
        expect(service.isContentValid(invalidContent), isFalse);
      });

      test('should calculate remaining characters correctly', () {
        const content = 'Hello Bluesky!'; // 14 characters
        expect(service.getRemainingCharacters(content), equals(286)); // 300 - 14
      });

      test('should handle empty content', () {
        expect(service.isContentValid(''), isTrue);
        expect(service.getRemainingCharacters(''), equals(300));
      });

      test('should handle content at exact character limit', () {
        final exactLimitContent = 'a' * 300;
        expect(service.isContentValid(exactLimitContent), isTrue);
        expect(service.getRemainingCharacters(exactLimitContent), equals(0));
      });
    });

    group('Required Credentials Check', () {
      test('should confirm account has required credentials', () {
        expect(service.hasRequiredCredentials(testAccount), isTrue);
      });

      test('should detect missing identifier', () {
        final invalidAccount = testAccount.copyWith(
          credentials: {'password': 'testpassword123'},
        );
        expect(service.hasRequiredCredentials(invalidAccount), isFalse);
      });

      test('should detect missing password', () {
        final invalidAccount = testAccount.copyWith(
          credentials: {'identifier': 'testuser.bsky.social'},
        );
        expect(service.hasRequiredCredentials(invalidAccount), isFalse);
      });

      test('should detect wrong platform', () {
        final wrongPlatformAccount = testAccount.copyWith(
          platform: PlatformType.mastodon,
        );
        expect(service.hasRequiredCredentials(wrongPlatformAccount), isFalse);
      });
    });
  });
}