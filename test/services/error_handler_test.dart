import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yall/models/platform_type.dart';
import 'package:yall/models/post_result.dart';
import 'package:yall/services/error_handler.dart';
import 'package:yall/services/social_platform_service.dart';

void main() {
  group('ErrorHandler', () {
    late ErrorHandler errorHandler;

    setUp(() {
      errorHandler = ErrorHandler();
      errorHandler.clearLogs(); // Start with clean logs
    });

    group('logError', () {
      test('should log error without sensitive data', () {
        const operation = 'test_operation';
        const error = 'Test error message';
        const context = {
          'password': 'secret123',
          'token': 'bearer_token_123',
          'safe_data': 'this_is_safe',
        };

        errorHandler.logError(
          operation,
          error,
          context: context,
          platform: PlatformType.mastodon,
        );

        final logs = errorHandler.getRecentErrors(limit: 1);
        expect(logs, hasLength(1));

        final logEntry = logs.first;
        expect(logEntry.operation, equals(operation));
        expect(logEntry.error, equals(error));
        expect(logEntry.platform, equals(PlatformType.mastodon));
        expect(logEntry.context!['password'], equals('[REDACTED]'));
        expect(logEntry.context!['token'], equals('[REDACTED]'));
        expect(logEntry.context!['safe_data'], equals('this_is_safe'));
      });

      test('should sanitize JWT tokens in error messages', () {
        const operation = 'jwt_test';
        const error =
            'Authentication failed with token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

        errorHandler.logError(operation, error);

        final logs = errorHandler.getRecentErrors(limit: 1);
        expect(logs.first.error, contains('[JWT_TOKEN]'));
        expect(
          logs.first.error,
          isNot(contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')),
        );
      });

      test('should sanitize email addresses in error messages', () {
        const operation = 'email_test';
        const error = 'Failed to authenticate user@example.com';

        errorHandler.logError(operation, error);

        final logs = errorHandler.getRecentErrors(limit: 1);
        expect(logs.first.error, contains('[EMAIL]'));
        expect(logs.first.error, isNot(contains('user@example.com')));
      });

      test('should sanitize API keys in error messages', () {
        const operation = 'api_key_test';
        const error =
            'Invalid API key: sk_test_1234567890abcdef1234567890abcdef';

        errorHandler.logError(operation, error);

        final logs = errorHandler.getRecentErrors(limit: 1);
        expect(logs.first.error, contains('[API_KEY]'));
        expect(
          logs.first.error,
          isNot(contains('sk_test_1234567890abcdef1234567890abcdef')),
        );
      });

      test('should sanitize private keys in error messages', () {
        const operation = 'private_key_test';
        const error =
            'Invalid private key: 1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';

        errorHandler.logError(operation, error);

        final logs = errorHandler.getRecentErrors(limit: 1);
        // The 64-character hex string should be sanitized as either PRIVATE_KEY or API_KEY
        expect(
          logs.first.error,
          anyOf(contains('[PRIVATE_KEY]'), contains('[API_KEY]')),
        );
        expect(
          logs.first.error,
          isNot(
            contains(
              '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
            ),
          ),
        );
      });

      test('should limit log entries to maximum', () {
        // Add more than the maximum number of entries
        for (int i = 0; i < 1100; i++) {
          errorHandler.logError('operation_$i', 'error_$i');
        }

        final logs = errorHandler.getRecentErrors(limit: 2000);
        expect(logs.length, lessThanOrEqualTo(1000)); // Should be capped at max
      });
    });

    group('getUserFriendlyMessage', () {
      test(
        'should return platform-specific message for SocialPlatformException',
        () {
          final exception = SocialPlatformException(
            platform: PlatformType.mastodon,
            errorType: PostErrorType.networkError,
            message: 'Network connection failed',
          );

          final message = errorHandler.getUserFriendlyMessage(exception);
          expect(message, contains('Mastodon'));
          expect(message, anyOf(contains('network'), contains('connect')));
          expect(
            message,
            isNot(contains('Network connection failed')),
          ); // Should be user-friendly
        },
      );

      test('should return network message for SocketException', () {
        final exception = const SocketException('Connection refused');

        final message = errorHandler.getUserFriendlyMessage(exception);
        expect(message, contains('Network connection failed'));
        expect(message, contains('internet connection'));
      });

      test('should return network message for HttpException', () {
        final exception = const HttpException('Bad request');

        final message = errorHandler.getUserFriendlyMessage(exception);
        expect(message, contains('Network error'));
        expect(message, contains('try again'));
      });

      test('should return timeout message for TimeoutException', () {
        final exception = TimeoutException(
          'Request timed out',
          const Duration(seconds: 30),
        );

        final message = errorHandler.getUserFriendlyMessage(exception);
        expect(message, contains('timed out'));
        expect(message, contains('connection'));
      });

      test('should return format message for FormatException', () {
        final exception = const FormatException('Invalid JSON');

        final message = errorHandler.getUserFriendlyMessage(exception);
        expect(message, contains('Invalid data format'));
        expect(message, contains('try again'));
      });

      test('should return generic message for unknown errors', () {
        final exception = Exception('Unknown error');

        final message = errorHandler.getUserFriendlyMessage(exception);
        expect(message, contains('unexpected error'));
        expect(message, contains('try again'));
      });
    });

    group('platform-specific error messages', () {
      test('should return authentication error message', () {
        final exception = SocialPlatformException(
          platform: PlatformType.bluesky,
          errorType: PostErrorType.authenticationError,
          message: 'Invalid credentials',
        );

        final message = errorHandler.getUserFriendlyMessage(exception);
        expect(message, contains('Bluesky'));
        expect(message, contains('Authentication failed'));
        expect(message, contains('account credentials'));
      });

      test('should return rate limit error message', () {
        final exception = SocialPlatformException(
          platform: PlatformType.nostr,
          errorType: PostErrorType.rateLimitError,
          message: 'Rate limit exceeded',
        );

        final message = errorHandler.getUserFriendlyMessage(exception);
        expect(message, contains('Nostr'));
        expect(message, contains('rate limit'));
        expect(message, contains('wait'));
      });

      test('should return content too long error message', () {
        final exception = SocialPlatformException(
          platform: PlatformType.mastodon,
          errorType: PostErrorType.contentTooLong,
          message: 'Content too long',
        );

        final message = errorHandler.getUserFriendlyMessage(exception);
        expect(message, contains('Mastodon'));
        expect(message, contains('too long'));
        expect(message, contains('500 characters'));
      });

      test('should return server error message', () {
        final exception = SocialPlatformException(
          platform: PlatformType.bluesky,
          errorType: PostErrorType.serverError,
          message: 'Server error',
        );

        final message = errorHandler.getUserFriendlyMessage(exception);
        expect(message, contains('Bluesky'));
        expect(message, contains('server error'));
        expect(message, contains('try again later'));
      });
    });

    group('log management', () {
      test('should return recent errors with limit', () {
        for (int i = 0; i < 10; i++) {
          errorHandler.logError('operation_$i', 'error_$i');
        }

        final logs = errorHandler.getRecentErrors(limit: 5);
        expect(logs, hasLength(5));

        // Should return the most recent entries
        expect(logs.last.operation, equals('operation_9'));
        expect(logs.first.operation, equals('operation_5'));
      });

      test('should clear all logs', () {
        for (int i = 0; i < 5; i++) {
          errorHandler.logError('operation_$i', 'error_$i');
        }

        expect(errorHandler.getRecentErrors(), hasLength(5));

        errorHandler.clearLogs();
        expect(errorHandler.getRecentErrors(), isEmpty);
      });
    });

    group('ErrorLogEntry', () {
      test('should serialize to JSON correctly', () {
        final entry = ErrorLogEntry(
          timestamp: DateTime(2023, 1, 1, 12, 0, 0),
          operation: 'test_operation',
          error: 'test_error',
          stackTrace: 'test_stack_trace',
          context: {'key': 'value'},
          platform: PlatformType.mastodon,
        );

        final json = entry.toJson();
        expect(json['timestamp'], equals('2023-01-01T12:00:00.000'));
        expect(json['operation'], equals('test_operation'));
        expect(json['error'], equals('test_error'));
        expect(json['stackTrace'], equals('test_stack_trace'));
        expect(json['context'], equals({'key': 'value'}));
        expect(json['platform'], equals('mastodon'));
      });

      test('should handle null values in JSON serialization', () {
        final entry = ErrorLogEntry(
          timestamp: DateTime(2023, 1, 1, 12, 0, 0),
          operation: 'test_operation',
          error: 'test_error',
        );

        final json = entry.toJson();
        expect(json['stackTrace'], isNull);
        expect(json['context'], isNull);
        expect(json['platform'], isNull);
      });

      test('should create string representation', () {
        final entry = ErrorLogEntry(
          timestamp: DateTime(2023, 1, 1, 12, 0, 0),
          operation: 'test_operation',
          error: 'test_error',
          platform: PlatformType.mastodon,
        );

        final string = entry.toString();
        expect(string, contains('test_operation'));
        expect(string, contains('test_error'));
        expect(string, contains('Mastodon'));
      });
    });
  });
}
