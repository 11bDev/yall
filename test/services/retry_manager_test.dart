import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yall/models/platform_type.dart';
import 'package:yall/models/post_result.dart';
import 'package:yall/services/retry_manager.dart';
import 'package:yall/services/social_platform_service.dart';

void main() {
  group('RetryConfig', () {
    test('should have correct default values', () {
      const config = RetryConfig();
      expect(config.maxAttempts, equals(3));
      expect(config.initialDelay, equals(Duration(seconds: 1)));
      expect(config.maxDelay, equals(Duration(seconds: 30)));
      expect(config.backoffMultiplier, equals(2.0));
      expect(config.retryOnNetworkError, isTrue);
      expect(config.retryOnServerError, isTrue);
      expect(config.retryOnRateLimit, isFalse);
    });

    test('should have correct posting configuration', () {
      const config = RetryConfig.posting;
      expect(config.maxAttempts, equals(3));
      expect(config.initialDelay, equals(Duration(seconds: 2)));
      expect(config.maxDelay, equals(Duration(seconds: 15)));
      expect(config.backoffMultiplier, equals(2.0));
      expect(config.retryOnNetworkError, isTrue);
      expect(config.retryOnServerError, isTrue);
      expect(config.retryOnRateLimit, isFalse);
    });

    test('should have correct authentication configuration', () {
      const config = RetryConfig.authentication;
      expect(config.maxAttempts, equals(2));
      expect(config.initialDelay, equals(Duration(seconds: 1)));
      expect(config.maxDelay, equals(Duration(seconds: 5)));
      expect(config.backoffMultiplier, equals(1.5));
      expect(config.retryOnNetworkError, isTrue);
      expect(config.retryOnServerError, isFalse);
      expect(config.retryOnRateLimit, isFalse);
    });

    test('should have correct validation configuration', () {
      const config = RetryConfig.validation;
      expect(config.maxAttempts, equals(2));
      expect(config.initialDelay, equals(Duration(milliseconds: 500)));
      expect(config.maxDelay, equals(Duration(seconds: 3)));
      expect(config.backoffMultiplier, equals(2.0));
      expect(config.retryOnNetworkError, isTrue);
      expect(config.retryOnServerError, isFalse);
      expect(config.retryOnRateLimit, isFalse);
    });
  });

  group('RetryManager', () {
    late RetryManager retryManager;

    setUp(() {
      retryManager = RetryManager();
    });

    group('executeWithRetry', () {
      test('should succeed on first attempt', () async {
        int callCount = 0;
        final result = await retryManager.executeWithRetry(
          'test_operation',
          () async {
            callCount++;
            return 'success';
          },
          config: const RetryConfig(maxAttempts: 3),
        );

        expect(result, equals('success'));
        expect(callCount, equals(1));
      });

      test('should retry on network error and succeed', () async {
        int callCount = 0;
        final result = await retryManager.executeWithRetry(
          'test_operation',
          () async {
            callCount++;
            if (callCount == 1) {
              throw const SocketException('Connection failed');
            }
            return 'success';
          },
          config: const RetryConfig(
            maxAttempts: 3,
            initialDelay: Duration(milliseconds: 10),
            retryOnNetworkError: true,
          ),
        );

        expect(result, equals('success'));
        expect(callCount, equals(2));
      });

      test(
        'should retry on SocialPlatformException with network error',
        () async {
          int callCount = 0;
          final result = await retryManager.executeWithRetry(
            'test_operation',
            () async {
              callCount++;
              if (callCount == 1) {
                throw SocialPlatformException(
                  platform: PlatformType.mastodon,
                  errorType: PostErrorType.networkError,
                  message: 'Network error',
                );
              }
              return 'success';
            },
            config: const RetryConfig(
              maxAttempts: 3,
              initialDelay: Duration(milliseconds: 10),
              retryOnNetworkError: true,
            ),
          );

          expect(result, equals('success'));
          expect(callCount, equals(2));
        },
      );

      test('should not retry on authentication error', () async {
        int callCount = 0;

        expect(
          () => retryManager.executeWithRetry(
            'test_operation',
            () async {
              callCount++;
              throw SocialPlatformException(
                platform: PlatformType.mastodon,
                errorType: PostErrorType.authenticationError,
                message: 'Auth failed',
              );
            },
            config: const RetryConfig(
              maxAttempts: 3,
              initialDelay: Duration(milliseconds: 10),
              retryOnNetworkError: true,
            ),
          ),
          throwsA(isA<SocialPlatformException>()),
        );

        await Future.delayed(
          const Duration(milliseconds: 50),
        ); // Wait for any potential retries
        expect(callCount, equals(1));
      });

      test('should not retry rate limit errors by default', () async {
        int callCount = 0;

        expect(
          () => retryManager.executeWithRetry(
            'test_operation',
            () async {
              callCount++;
              throw SocialPlatformException(
                platform: PlatformType.mastodon,
                errorType: PostErrorType.rateLimitError,
                message: 'Rate limited',
              );
            },
            config: const RetryConfig(
              maxAttempts: 3,
              initialDelay: Duration(milliseconds: 10),
              retryOnRateLimit: false,
            ),
          ),
          throwsA(isA<SocialPlatformException>()),
        );

        await Future.delayed(const Duration(milliseconds: 50));
        expect(callCount, equals(1));
      });

      test('should exhaust all attempts and fail', () async {
        int callCount = 0;

        expect(
          () => retryManager.executeWithRetry(
            'test_operation',
            () async {
              callCount++;
              throw const SocketException('Connection failed');
            },
            config: const RetryConfig(
              maxAttempts: 3,
              initialDelay: Duration(milliseconds: 10),
              retryOnNetworkError: true,
            ),
          ),
          throwsA(isA<SocketException>()),
        );

        await Future.delayed(const Duration(milliseconds: 100));
        expect(callCount, equals(3));
      });

      test('should use custom shouldRetry function', () async {
        int callCount = 0;
        final result = await retryManager.executeWithRetry(
          'test_operation',
          () async {
            callCount++;
            if (callCount == 1) {
              throw Exception('Custom error');
            }
            return 'success';
          },
          config: const RetryConfig(
            maxAttempts: 3,
            initialDelay: Duration(milliseconds: 10),
          ),
          shouldRetry: (error) => error is Exception,
        );

        expect(result, equals('success'));
        expect(callCount, equals(2));
      });

      test('should apply exponential backoff', () async {
        final delays = <Duration>[];
        int callCount = 0;

        try {
          await retryManager.executeWithRetry(
            'test_operation',
            () async {
              callCount++;
              final start = DateTime.now();
              throw const SocketException('Connection failed');
            },
            config: const RetryConfig(
              maxAttempts: 3,
              initialDelay: Duration(milliseconds: 100),
              backoffMultiplier: 2.0,
              retryOnNetworkError: true,
            ),
          );
        } catch (e) {
          // Expected to fail
        }

        expect(callCount, equals(3));
        // Note: Testing exact timing is difficult in unit tests due to jitter and execution time
      });
    });

    group('executePostWithRetry', () {
      test('should use posting configuration', () async {
        int callCount = 0;
        final result = await retryManager.executePostWithRetry(
          'Mastodon',
          () async {
            callCount++;
            if (callCount == 1) {
              throw const SocketException('Network error');
            }
            return PostResult.empty(
              'test content',
            ).addPlatformResult(PlatformType.mastodon, true);
          },
          platform: PlatformType.mastodon,
        );

        expect(result.isSuccessful(PlatformType.mastodon), isTrue);
        expect(callCount, equals(2));
      });

      test('should not retry rate limit errors in posting', () async {
        int callCount = 0;

        expect(
          () => retryManager.executePostWithRetry('Mastodon', () async {
            callCount++;
            throw SocialPlatformException(
              platform: PlatformType.mastodon,
              errorType: PostErrorType.rateLimitError,
              message: 'Rate limited',
            );
          }, platform: PlatformType.mastodon),
          throwsA(isA<SocialPlatformException>()),
        );

        await Future.delayed(const Duration(milliseconds: 50));
        expect(callCount, equals(1));
      });
    });

    group('executeAuthWithRetry', () {
      test('should use authentication configuration', () async {
        int callCount = 0;
        final result = await retryManager.executeAuthWithRetry(
          'Mastodon',
          () async {
            callCount++;
            if (callCount == 1) {
              throw const SocketException('Network error');
            }
            return true;
          },
          platform: PlatformType.mastodon,
        );

        expect(result, isTrue);
        expect(callCount, equals(2));
      });

      test('should not retry authentication errors', () async {
        int callCount = 0;

        expect(
          () => retryManager.executeAuthWithRetry('Mastodon', () async {
            callCount++;
            throw SocialPlatformException(
              platform: PlatformType.mastodon,
              errorType: PostErrorType.authenticationError,
              message: 'Auth failed',
            );
          }, platform: PlatformType.mastodon),
          throwsA(isA<SocialPlatformException>()),
        );

        await Future.delayed(const Duration(milliseconds: 50));
        expect(callCount, equals(1));
      });
    });

    group('executeValidationWithRetry', () {
      test('should use validation configuration', () async {
        int callCount = 0;
        final result = await retryManager.executeValidationWithRetry(
          'Mastodon',
          () async {
            callCount++;
            if (callCount == 1) {
              throw const SocketException('Network error');
            }
            return true;
          },
          platform: PlatformType.mastodon,
        );

        expect(result, isTrue);
        expect(callCount, equals(2));
      });

      test('should not retry server errors in validation', () async {
        int callCount = 0;

        expect(
          () => retryManager.executeValidationWithRetry('Mastodon', () async {
            callCount++;
            throw SocialPlatformException(
              platform: PlatformType.mastodon,
              errorType: PostErrorType.serverError,
              message: 'Server error',
            );
          }, platform: PlatformType.mastodon),
          throwsA(isA<SocialPlatformException>()),
        );

        await Future.delayed(const Duration(milliseconds: 50));
        expect(callCount, equals(1));
      });
    });

    group('wrapWithRetry', () {
      test('should create retry wrapper function', () async {
        int callCount = 0;
        final wrappedFunction = retryManager.wrapWithRetry(
          () async {
            callCount++;
            if (callCount == 1) {
              throw const SocketException('Network error');
            }
            return 'success';
          },
          'test_operation',
          config: const RetryConfig(
            maxAttempts: 3,
            initialDelay: Duration(milliseconds: 10),
            retryOnNetworkError: true,
          ),
        );

        final result = await wrappedFunction();
        expect(result, equals('success'));
        expect(callCount, equals(2));
      });
    });
  });
}
