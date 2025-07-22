import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:yall/models/account.dart';
import 'package:yall/models/platform_type.dart';
import 'package:yall/models/post_result.dart';
import 'package:yall/services/mastodon_service.dart';
import 'package:yall/services/social_platform_service.dart';

void main() {
  group('MastodonService', () {
    late MastodonService service;
    late Account testAccount;

    setUp(() {
      testAccount = Account(
        id: 'test-account-1',
        platform: PlatformType.mastodon,
        displayName: 'Test User',
        username: 'testuser',
        createdAt: DateTime.now(),
        credentials: {
          'instance_url': 'https://mastodon.social',
          'access_token': 'test-access-token',
        },
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('Basic Properties', () {
      test('should have correct platform type', () {
        service = MastodonService();
        expect(service.platformType, equals(PlatformType.mastodon));
        expect(service.platformName, equals('Mastodon'));
        expect(service.characterLimit, equals(500));
      });

      test('should have correct required credential fields', () {
        service = MastodonService();
        expect(service.requiredCredentialFields, containsAll([
          'instance_url',
          'access_token',
        ]));
      });
    });

    group('Credential Validation', () {
      test('should validate correct credentials', () {
        service = MastodonService();
        expect(service.validateCredentials(testAccount), isTrue);
      });

      test('should reject account with wrong platform', () {
        service = MastodonService();
        final wrongPlatformAccount = testAccount.copyWith(
          platform: PlatformType.bluesky,
        );
        expect(service.validateCredentials(wrongPlatformAccount), isFalse);
      });

      test('should reject account with missing instance_url', () {
        service = MastodonService();
        final invalidAccount = testAccount.copyWith(
          credentials: {'access_token': 'test-token'},
        );
        expect(service.validateCredentials(invalidAccount), isFalse);
      });

      test('should reject account with missing access_token', () {
        service = MastodonService();
        final invalidAccount = testAccount.copyWith(
          credentials: {'instance_url': 'https://mastodon.social'},
        );
        expect(service.validateCredentials(invalidAccount), isFalse);
      });

      test('should reject account with invalid instance_url format', () {
        service = MastodonService();
        final invalidAccount = testAccount.copyWith(
          credentials: {
            'instance_url': 'not-a-url',
            'access_token': 'test-token',
          },
        );
        expect(service.validateCredentials(invalidAccount), isFalse);
      });

      test('should reject account with empty credentials', () {
        service = MastodonService();
        final invalidAccount = testAccount.copyWith(
          credentials: {
            'instance_url': '',
            'access_token': '',
          },
        );
        expect(service.validateCredentials(invalidAccount), isFalse);
      });
    });

    group('Authentication', () {
      test('should authenticate successfully with valid credentials', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.toString(),
              equals('https://mastodon.social/api/v1/accounts/verify_credentials'));
          expect(request.headers['Authorization'], equals('Bearer test-access-token'));
          expect(request.headers['Content-Type'], startsWith('application/json'));

          return http.Response(
            jsonEncode({
              'id': '123',
              'username': 'testuser',
              'display_name': 'Test User',
            }),
            200,
          );
        });

        service = MastodonService(httpClient: mockClient);
        final result = await service.authenticate(testAccount);
        expect(result, isTrue);
      });

      test('should fail authentication with invalid token', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Unauthorized', 401);
        });

        service = MastodonService(httpClient: mockClient);

        expect(
          () => service.authenticate(testAccount),
          throwsA(isA<SocialPlatformException>()
              .having((e) => e.errorType, 'errorType', PostErrorType.authenticationError)
              .having((e) => e.message, 'message', contains('Invalid access token'))),
        );
      });

      test('should fail authentication with server error', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });

        service = MastodonService(httpClient: mockClient);

        expect(
          () => service.authenticate(testAccount),
          throwsA(isA<SocialPlatformException>()
              .having((e) => e.errorType, 'errorType', PostErrorType.serverError)),
        );
      });

      test('should fail authentication with network error', () async {
        final mockClient = MockClient((request) async {
          throw const SocketException('Network unreachable');
        });

        service = MastodonService(httpClient: mockClient);

        expect(
          () => service.authenticate(testAccount),
          throwsA(isA<SocialPlatformException>()
              .having((e) => e.errorType, 'errorType', PostErrorType.networkError)),
        );
      });

      test('should fail authentication with missing credentials', () async {
        service = MastodonService();
        final invalidAccount = testAccount.copyWith(
          credentials: {'instance_url': 'https://mastodon.social'},
        );

        expect(
          () => service.authenticate(invalidAccount),
          throwsA(isA<SocialPlatformException>()
              .having((e) => e.errorType, 'errorType', PostErrorType.invalidCredentials)),
        );
      });
    });

    group('Publishing Posts', () {
      test('should publish post successfully', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.toString(),
              equals('https://mastodon.social/api/v1/statuses'));
          expect(request.headers['Authorization'], equals('Bearer test-access-token'));
          expect(request.headers['Content-Type'], startsWith('application/json'));

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['status'], equals('Hello, Mastodon!'));
          expect(body['visibility'], equals('public'));

          return http.Response(
            jsonEncode({
              'id': '123456',
              'content': 'Hello, Mastodon!',
              'created_at': DateTime.now().toIso8601String(),
            }),
            201,
          );
        });

        service = MastodonService(httpClient: mockClient);
        final result = await service.publishPost('Hello, Mastodon!', testAccount);

        expect(result.isSuccessful(PlatformType.mastodon), isTrue);
        expect(result.hasErrors, isFalse);
        expect(result.originalContent, equals('Hello, Mastodon!'));
      });

      test('should fail to publish post that exceeds character limit', () async {
        service = MastodonService();
        final longContent = 'a' * 501; // Exceeds 500 character limit

        final result = await service.publishPost(longContent, testAccount);

        expect(result.isSuccessful(PlatformType.mastodon), isFalse);
        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.contentTooLong));
        expect(result.getError(PlatformType.mastodon), contains('character limit'));
      });

      test('should fail to publish with missing credentials', () async {
        service = MastodonService();
        final invalidAccount = testAccount.copyWith(
          credentials: {'instance_url': 'https://mastodon.social'},
        );

        final result = await service.publishPost('Hello!', invalidAccount);

        expect(result.isSuccessful(PlatformType.mastodon), isFalse);
        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.invalidCredentials));
      });

      test('should handle authentication error during publishing', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Unauthorized', 401);
        });

        service = MastodonService(httpClient: mockClient);
        final result = await service.publishPost('Hello!', testAccount);

        expect(result.isSuccessful(PlatformType.mastodon), isFalse);
        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.authenticationError));
        expect(result.getError(PlatformType.mastodon), contains('Authentication failed'));
      });

      test('should handle validation error during publishing', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'error': 'Status is too long'}),
            422,
          );
        });

        service = MastodonService(httpClient: mockClient);
        final result = await service.publishPost('Hello!', testAccount);

        expect(result.isSuccessful(PlatformType.mastodon), isFalse);
        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.contentTooLong));
        expect(result.getError(PlatformType.mastodon), equals('Status is too long'));
      });

      test('should handle rate limit error during publishing', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Too Many Requests', 429);
        });

        service = MastodonService(httpClient: mockClient);
        final result = await service.publishPost('Hello!', testAccount);

        expect(result.isSuccessful(PlatformType.mastodon), isFalse);
        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.rateLimitError));
        expect(result.getError(PlatformType.mastodon), contains('Rate limit exceeded'));
      });

      test('should handle server error during publishing', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });

        service = MastodonService(httpClient: mockClient);
        final result = await service.publishPost('Hello!', testAccount);

        expect(result.isSuccessful(PlatformType.mastodon), isFalse);
        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.serverError));
        expect(result.getError(PlatformType.mastodon), contains('server error'));
      });

      test('should handle network error during publishing', () async {
        final mockClient = MockClient((request) async {
          throw const SocketException('Network unreachable');
        });

        service = MastodonService(httpClient: mockClient);
        final result = await service.publishPost('Hello!', testAccount);

        expect(result.isSuccessful(PlatformType.mastodon), isFalse);
        expect(result.getErrorType(PlatformType.mastodon), equals(PostErrorType.networkError));
        expect(result.getError(PlatformType.mastodon), contains('Network connection failed'));
      });
    });

    group('Connection Validation', () {
      test('should validate connection successfully', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'id': '123', 'username': 'testuser'}),
            200,
          );
        });

        service = MastodonService(httpClient: mockClient);
        final result = await service.validateConnection(testAccount);
        expect(result, isTrue);
      });

      test('should fail connection validation with invalid credentials', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Unauthorized', 401);
        });

        service = MastodonService(httpClient: mockClient);
        final result = await service.validateConnection(testAccount);
        expect(result, isFalse);
      });

      test('should fail connection validation with network error', () async {
        final mockClient = MockClient((request) async {
          throw const SocketException('Network unreachable');
        });

        service = MastodonService(httpClient: mockClient);
        final result = await service.validateConnection(testAccount);
        expect(result, isFalse);
      });
    });

    group('OAuth Flow', () {
      test('should create OAuth app successfully', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.toString(),
              equals('https://mastodon.social/api/v1/apps'));
          expect(request.headers['Content-Type'], startsWith('application/json'));

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['client_name'], equals('Test App'));
          expect(body['redirect_uris'], equals('urn:ietf:wg:oauth:2.0:oob'));
          expect(body['scopes'], equals('read write'));

          return http.Response(
            jsonEncode({
              'client_id': 'test-client-id',
              'client_secret': 'test-client-secret',
            }),
            200,
          );
        });

        service = MastodonService(httpClient: mockClient);
        final result = await service.createOAuthApp(
          instanceUrl: 'https://mastodon.social',
          appName: 'Test App',
        );

        expect(result['client_id'], equals('test-client-id'));
        expect(result['client_secret'], equals('test-client-secret'));
      });

      test('should generate correct authorization URL', () {
        service = MastodonService();
        final url = service.getAuthorizationUrl(
          instanceUrl: 'https://mastodon.social',
          clientId: 'test-client-id',
        );

        final uri = Uri.parse(url);
        expect(uri.host, equals('mastodon.social'));
        expect(uri.path, equals('/oauth/authorize'));
        expect(uri.queryParameters['client_id'], equals('test-client-id'));
        expect(uri.queryParameters['response_type'], equals('code'));
        expect(uri.queryParameters['redirect_uri'], equals('urn:ietf:wg:oauth:2.0:oob'));
        expect(uri.queryParameters['scope'], equals('read write'));
      });

      test('should exchange authorization code for token successfully', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.toString(),
              equals('https://mastodon.social/oauth/token'));
          expect(request.headers['Content-Type'], startsWith('application/json'));

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['client_id'], equals('test-client-id'));
          expect(body['client_secret'], equals('test-client-secret'));
          expect(body['code'], equals('test-auth-code'));
          expect(body['grant_type'], equals('authorization_code'));

          return http.Response(
            jsonEncode({
              'access_token': 'test-access-token',
              'token_type': 'Bearer',
              'scope': 'read write',
            }),
            200,
          );
        });

        service = MastodonService(httpClient: mockClient);
        final result = await service.exchangeCodeForToken(
          instanceUrl: 'https://mastodon.social',
          clientId: 'test-client-id',
          clientSecret: 'test-client-secret',
          authorizationCode: 'test-auth-code',
        );

        expect(result['access_token'], equals('test-access-token'));
        expect(result['token_type'], equals('Bearer'));
        expect(result['scope'], equals('read write'));
      });

      test('should handle OAuth app creation failure', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Bad Request', 400);
        });

        service = MastodonService(httpClient: mockClient);

        expect(
          () => service.createOAuthApp(
            instanceUrl: 'https://mastodon.social',
            appName: 'Test App',
          ),
          throwsA(isA<SocialPlatformException>()
              .having((e) => e.errorType, 'errorType', PostErrorType.serverError)),
        );
      });

      test('should handle token exchange failure', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Invalid grant', 400);
        });

        service = MastodonService(httpClient: mockClient);

        expect(
          () => service.exchangeCodeForToken(
            instanceUrl: 'https://mastodon.social',
            clientId: 'test-client-id',
            clientSecret: 'test-client-secret',
            authorizationCode: 'invalid-code',
          ),
          throwsA(isA<SocialPlatformException>()
              .having((e) => e.errorType, 'errorType', PostErrorType.authenticationError)),
        );
      });
    });

    group('User Info', () {
      test('should get user info successfully', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.toString(),
              equals('https://mastodon.social/api/v1/accounts/verify_credentials'));
          expect(request.headers['Authorization'], equals('Bearer test-access-token'));

          return http.Response(
            jsonEncode({
              'id': '123',
              'username': 'testuser',
              'display_name': 'Test User',
              'followers_count': 100,
              'following_count': 50,
            }),
            200,
          );
        });

        service = MastodonService(httpClient: mockClient);
        final result = await service.getUserInfo(testAccount);

        expect(result['id'], equals('123'));
        expect(result['username'], equals('testuser'));
        expect(result['display_name'], equals('Test User'));
        expect(result['followers_count'], equals(100));
        expect(result['following_count'], equals(50));
      });

      test('should handle user info authentication error', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Unauthorized', 401);
        });

        service = MastodonService(httpClient: mockClient);

        expect(
          () => service.getUserInfo(testAccount),
          throwsA(isA<SocialPlatformException>()
              .having((e) => e.errorType, 'errorType', PostErrorType.authenticationError)),
        );
      });

      test('should handle user info with missing credentials', () async {
        service = MastodonService();
        final invalidAccount = testAccount.copyWith(
          credentials: {'instance_url': 'https://mastodon.social'},
        );

        expect(
          () => service.getUserInfo(invalidAccount),
          throwsA(isA<SocialPlatformException>()
              .having((e) => e.errorType, 'errorType', PostErrorType.invalidCredentials)),
        );
      });
    });

    group('Content Validation', () {
      test('should validate content within character limit', () {
        service = MastodonService();
        expect(service.isContentValid('Hello, world!'), isTrue);
        expect(service.isContentValid('a' * 500), isTrue);
      });

      test('should reject content exceeding character limit', () {
        service = MastodonService();
        expect(service.isContentValid('a' * 501), isFalse);
      });

      test('should calculate remaining characters correctly', () {
        service = MastodonService();
        expect(service.getRemainingCharacters('Hello!'), equals(494));
        expect(service.getRemainingCharacters('a' * 100), equals(400));
        expect(service.getRemainingCharacters('a' * 500), equals(0));
      });
    });
  });
}