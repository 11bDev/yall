import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../models/account.dart';
import '../models/platform_type.dart';
import '../models/post_result.dart';
import 'error_handler.dart';
import 'social_platform_service.dart';

/// Configuration for retry behavior
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool retryOnNetworkError;
  final bool retryOnServerError;
  final bool retryOnRateLimit;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.retryOnNetworkError = true,
    this.retryOnServerError = true,
    this.retryOnRateLimit = false, // Rate limits usually need longer waits
  });

  /// Default configuration for posting operations
  static const posting = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 15),
    backoffMultiplier: 2.0,
    retryOnNetworkError: true,
    retryOnServerError: true,
    retryOnRateLimit: false,
  );

  /// Configuration for authentication operations
  static const authentication = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 5),
    backoffMultiplier: 1.5,
    retryOnNetworkError: true,
    retryOnServerError: false,
    retryOnRateLimit: false,
  );

  /// Configuration for connection validation
  static const validation = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 3),
    backoffMultiplier: 2.0,
    retryOnNetworkError: true,
    retryOnServerError: false,
    retryOnRateLimit: false,
  );
}

/// Manages retry logic for operations that may fail due to transient errors
class RetryManager {
  static final RetryManager _instance = RetryManager._internal();
  factory RetryManager() => _instance;
  RetryManager._internal();

  final ErrorHandler _errorHandler = ErrorHandler();
  final Random _random = Random();

  /// Execute an operation with retry logic
  Future<T> executeWithRetry<T>(
    String operationName,
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
    PlatformType? platform,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = config.initialDelay;

    while (attempt < config.maxAttempts) {
      attempt++;

      try {
        final result = await operation();

        // Log successful retry if this wasn't the first attempt
        if (attempt > 1) {
          _errorHandler.logError(
            '$operationName - Success after retry',
            'Operation succeeded on attempt $attempt',
            context: {'attempt': attempt, 'total_attempts': config.maxAttempts},
            platform: platform,
          );
        }

        return result;
      } catch (error, stackTrace) {
        final isLastAttempt = attempt >= config.maxAttempts;
        final shouldRetryError =
            shouldRetry?.call(error) ?? _shouldRetryError(error, config);

        _errorHandler.logError(
          '$operationName - Attempt $attempt',
          error,
          stackTrace: stackTrace,
          context: {
            'attempt': attempt,
            'total_attempts': config.maxAttempts,
            'will_retry': !isLastAttempt && shouldRetryError,
            'delay_ms': delay.inMilliseconds,
          },
          platform: platform,
        );

        if (isLastAttempt || !shouldRetryError) {
          rethrow;
        }

        // Wait before retrying with exponential backoff and jitter
        await _waitWithJitter(delay);
        delay = _calculateNextDelay(delay, config);
      }
    }

    // This should never be reached, but just in case
    throw StateError('Retry loop completed without result or exception');
  }

  /// Execute a posting operation with appropriate retry configuration
  Future<PostResult> executePostWithRetry(
    String platformName,
    Future<PostResult> Function() postOperation, {
    PlatformType? platform,
  }) async {
    return executeWithRetry(
      'Post to $platformName',
      postOperation,
      config: RetryConfig.posting,
      platform: platform,
      shouldRetry: (error) => _shouldRetryPostError(error),
    );
  }

  /// Execute an authentication operation with appropriate retry configuration
  Future<bool> executeAuthWithRetry(
    String platformName,
    Future<bool> Function() authOperation, {
    PlatformType? platform,
  }) async {
    return executeWithRetry(
      'Authenticate with $platformName',
      authOperation,
      config: RetryConfig.authentication,
      platform: platform,
      shouldRetry: (error) => _shouldRetryAuthError(error),
    );
  }

  /// Execute a validation operation with appropriate retry configuration
  Future<bool> executeValidationWithRetry(
    String platformName,
    Future<bool> Function() validationOperation, {
    PlatformType? platform,
  }) async {
    return executeWithRetry(
      'Validate connection to $platformName',
      validationOperation,
      config: RetryConfig.validation,
      platform: platform,
      shouldRetry: (error) => _shouldRetryValidationError(error),
    );
  }

  /// Determine if an error should be retried based on configuration
  bool _shouldRetryError(dynamic error, RetryConfig config) {
    if (error is SocialPlatformException) {
      switch (error.errorType) {
        case PostErrorType.networkError:
          return config.retryOnNetworkError;
        case PostErrorType.serverError:
          return config.retryOnServerError;
        case PostErrorType.rateLimitError:
          return config.retryOnRateLimit;
        case PostErrorType.authenticationError:
        case PostErrorType.invalidCredentials:
        case PostErrorType.contentTooLong:
        case PostErrorType.platformUnavailable:
        case PostErrorType.unknownError:
          return false;
      }
    }

    if (error is SocketException || error is HttpException) {
      return config.retryOnNetworkError;
    }

    if (error is TimeoutException) {
      return config.retryOnNetworkError;
    }

    // Don't retry unknown errors by default
    return false;
  }

  /// Specific retry logic for posting operations
  bool _shouldRetryPostError(dynamic error) {
    if (error is SocialPlatformException) {
      switch (error.errorType) {
        case PostErrorType.networkError:
        case PostErrorType.serverError:
          return true;
        case PostErrorType.rateLimitError:
          // Don't retry rate limits immediately - they need longer waits
          return false;
        case PostErrorType.authenticationError:
        case PostErrorType.invalidCredentials:
        case PostErrorType.contentTooLong:
        case PostErrorType.platformUnavailable:
        case PostErrorType.unknownError:
          return false;
      }
    }

    return error is SocketException ||
        error is HttpException ||
        error is TimeoutException;
  }

  /// Specific retry logic for authentication operations
  bool _shouldRetryAuthError(dynamic error) {
    if (error is SocialPlatformException) {
      switch (error.errorType) {
        case PostErrorType.networkError:
          return true;
        case PostErrorType.serverError:
          // Server errors during auth might be temporary
          return true;
        case PostErrorType.authenticationError:
        case PostErrorType.invalidCredentials:
        case PostErrorType.rateLimitError:
        case PostErrorType.contentTooLong:
        case PostErrorType.platformUnavailable:
        case PostErrorType.unknownError:
          return false;
      }
    }

    return error is SocketException ||
        error is HttpException ||
        error is TimeoutException;
  }

  /// Specific retry logic for validation operations
  bool _shouldRetryValidationError(dynamic error) {
    if (error is SocialPlatformException) {
      switch (error.errorType) {
        case PostErrorType.networkError:
          return true;
        case PostErrorType.serverError:
        case PostErrorType.authenticationError:
        case PostErrorType.invalidCredentials:
        case PostErrorType.rateLimitError:
        case PostErrorType.contentTooLong:
        case PostErrorType.platformUnavailable:
        case PostErrorType.unknownError:
          return false;
      }
    }

    return error is SocketException ||
        error is HttpException ||
        error is TimeoutException;
  }

  /// Calculate the next delay using exponential backoff
  Duration _calculateNextDelay(Duration currentDelay, RetryConfig config) {
    final nextDelay = Duration(
      milliseconds: (currentDelay.inMilliseconds * config.backoffMultiplier)
          .round(),
    );

    return nextDelay > config.maxDelay ? config.maxDelay : nextDelay;
  }

  /// Wait with jitter to avoid thundering herd problems
  Future<void> _waitWithJitter(Duration baseDelay) async {
    // Add up to 25% jitter
    final jitterMs = (_random.nextDouble() * baseDelay.inMilliseconds * 0.25)
        .round();
    final totalDelay = Duration(
      milliseconds: baseDelay.inMilliseconds + jitterMs,
    );

    await Future.delayed(totalDelay);
  }

  /// Create a retry wrapper for a service method
  Future<T> Function() wrapWithRetry<T>(
    Future<T> Function() operation,
    String operationName, {
    RetryConfig? config,
    PlatformType? platform,
    bool Function(dynamic error)? shouldRetry,
  }) {
    return () => executeWithRetry(
      operationName,
      operation,
      config: config ?? const RetryConfig(),
      platform: platform,
      shouldRetry: shouldRetry,
    );
  }
}

/// Extension to add retry capabilities to social platform services
extension SocialPlatformServiceRetry on SocialPlatformService {
  /// Authenticate with retry logic
  Future<bool> authenticateWithRetry(Account account) async {
    final retryManager = RetryManager();
    return retryManager.executeAuthWithRetry(
      platformName,
      () => authenticate(account),
      platform: platformType,
    );
  }

  /// Publish post with retry logic
  Future<PostResult> publishPostWithRetry(
    String content,
    Account account,
  ) async {
    final retryManager = RetryManager();
    return retryManager.executePostWithRetry(
      platformName,
      () => publishPost(content, account),
      platform: platformType,
    );
  }

  /// Validate connection with retry logic
  Future<bool> validateConnectionWithRetry(Account account) async {
    final retryManager = RetryManager();
    return retryManager.executeValidationWithRetry(
      platformName,
      () => validateConnection(account),
      platform: platformType,
    );
  }
}
