import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yall/services/error_handler.dart';
import 'package:yall/services/social_platform_service.dart';
import 'package:yall/models/platform_type.dart';
import 'package:yall/models/post_result.dart';

void main() {
  group('Global Error Handling', () {
    late ErrorHandler errorHandler;

    setUp(() {
      errorHandler = ErrorHandler();
      errorHandler.clearLogs();
    });

    group('FlutterError handling', () {
      test('should capture and log Flutter framework errors', () {
        final originalHandler = FlutterError.onError;
        var capturedError = false;

        // Set up test error handler
        FlutterError.onError = (FlutterErrorDetails details) {
          capturedError = true;
          errorHandler.logError(
            'Flutter Framework Error',
            details.exception,
            stackTrace: details.stack,
          );
        };

        // Trigger a Flutter error
        final error = FlutterError('Test error');
        FlutterError.onError!(FlutterErrorDetails(exception: error));

        expect(capturedError, isTrue);
        final logs = errorHandler.getRecentErrors(limit: 1);
        expect(logs, hasLength(1));
        expect(logs.first.operation, equals('Flutter Framework Error'));

        // Restore original handler
        FlutterError.onError = originalHandler;
      });

      test('should provide user-friendly error messages', () {
        final testCases = [
          SocketException('Connection failed'),
          TimeoutException('Request timed out'),
          HttpException('Server error'),
          FormatException('Invalid format'),
        ];

        for (final error in testCases) {
          final message = errorHandler.getUserFriendlyMessage(error);
          expect(message, isNotEmpty);
          expect(message, isNot(contains('SocketException')));
          expect(message, isNot(contains('TimeoutException')));
          expect(message, isNot(contains('HttpException')));
          expect(message, isNot(contains('FormatException')));
        }
      });

      test('should handle platform-specific errors correctly', () {
        final testError = SocialPlatformException(
          platform: PlatformType.mastodon,
          errorType: PostErrorType.networkError,
          message: 'Network connection failed',
        );

        final userMessage = errorHandler.getUserFriendlyMessage(testError);
        expect(userMessage, contains('Mastodon'));
        expect(userMessage, contains('internet connection'));
      });
    });

    group('Error logging', () {
      test('should sanitize sensitive information in error logs', () {
        final sensitiveContext = {
          'password': 'secret123',
          'token': 'bearer_token_456',
          'api_key': 'sk_live_123456789',
          'safe_data': 'this_is_safe',
        };

        errorHandler.logError(
          'Test operation',
          'Error with sensitive data',
          context: sensitiveContext,
        );

        final logs = errorHandler.getRecentErrors(limit: 1);
        final logEntry = logs.first;

        expect(logEntry.context!['password'], equals('[REDACTED]'));
        expect(logEntry.context!['token'], equals('[REDACTED]'));
        expect(logEntry.context!['api_key'], equals('[REDACTED]'));
        expect(logEntry.context!['safe_data'], equals('this_is_safe'));
      });

      test('should remove JWT tokens from error messages', () {
        const errorWithJWT =
            'Authentication failed with token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

        errorHandler.logError('JWT test', errorWithJWT);

        final logs = errorHandler.getRecentErrors(limit: 1);
        final sanitizedError = logs.first.error;

        expect(sanitizedError, contains('[JWT_TOKEN]'));
        expect(
          sanitizedError,
          isNot(contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')),
        );
      });

      test('should maintain error log size limit', () {
        // Add more than the max limit of errors
        for (int i = 0; i < 1100; i++) {
          errorHandler.logError('Test operation $i', 'Error $i');
        }

        final logs = errorHandler.getRecentErrors();
        expect(logs.length, lessThanOrEqualTo(50)); // Recent errors limit
      });
    });

    group('Error recovery', () {
      test('should handle errors during error logging gracefully', () {
        // This test ensures the error handler itself doesn't crash
        expect(() {
          errorHandler.logError(
            'Test operation',
            null, // Null error
            context: null,
          );
        }, returnsNormally);

        expect(() {
          errorHandler.logError(
            '', // Empty operation name
            Exception('Test'),
          );
        }, returnsNormally);
      });
    });

    group('Platform-specific error messages', () {
      test('should provide appropriate messages for each platform', () {
        for (final platform in PlatformType.values) {
          final error = SocialPlatformException(
            platform: platform,
            errorType: PostErrorType.authenticationError,
            message: 'Auth failed',
          );

          final message = errorHandler.getUserFriendlyMessage(error);
          expect(message, contains(platform.displayName));
          expect(message, contains('credentials'));
        }
      });

      test('should handle all error types appropriately', () {
        final platform = PlatformType.bluesky;

        for (final errorType in PostErrorType.values) {
          final error = SocialPlatformException(
            platform: platform,
            errorType: errorType,
            message: 'Test error',
          );

          final message = errorHandler.getUserFriendlyMessage(error);
          expect(message, isNotEmpty);
          expect(
            message,
            isNot(equals('Test error')),
          ); // Should be user-friendly
        }
      });
    });
  });
}
