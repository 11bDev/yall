import 'dart:async';
import 'dart:math';

import '../models/account.dart';
import '../models/post_result.dart';
import '../models/platform_type.dart';
import 'social_platform_service.dart';

/// Mock implementation of SocialPlatformService for testing
class MockSocialPlatformService extends SocialPlatformService {
  final PlatformType _platformType;
  bool _shouldFailAuthentication;
  bool _shouldFailPosting;
  bool _shouldFailValidation;
  Duration _simulatedDelay;
  PostErrorType _errorType;
  String _errorMessage;
  bool _throwError;

  MockSocialPlatformService({
    required PlatformType platformType,
    bool shouldFailAuthentication = false,
    bool shouldFailPosting = false,
    bool shouldFailValidation = false,
    Duration simulatedDelay = const Duration(milliseconds: 100),
    PostErrorType errorType = PostErrorType.unknownError,
    String errorMessage = 'Mock error',
    bool throwError = false,
  })  : _platformType = platformType,
        _shouldFailAuthentication = shouldFailAuthentication,
        _shouldFailPosting = shouldFailPosting,
        _shouldFailValidation = shouldFailValidation,
        _simulatedDelay = simulatedDelay,
        _errorType = errorType,
        _errorMessage = errorMessage,
        _throwError = throwError;

  @override
  PlatformType get platformType => _platformType;

  @override
  List<String> get requiredCredentialFields {
    switch (_platformType) {
      case PlatformType.mastodon:
        return ['server_url', 'access_token'];
      case PlatformType.bluesky:
        return ['handle', 'app_password'];
      case PlatformType.nostr:
        return ['private_key'];
      case PlatformType.x:
        return ['api_key', 'api_secret', 'access_token', 'access_token_secret'];
      case PlatformType.microblog:
        return ['username', 'token'];
    }
  }

  @override
  Future<bool> authenticate(Account account) async {
    await Future.delayed(_simulatedDelay);

    if (!hasRequiredCredentials(account)) {
      throw SocialPlatformException(
        platform: platformType,
        errorType: PostErrorType.invalidCredentials,
        message: 'Missing required credentials: ${requiredCredentialFields.join(', ')}',
      );
    }

    if (_shouldFailAuthentication) {
      throw SocialPlatformException(
        platform: platformType,
        errorType: _errorType,
        message: _errorMessage,
      );
    }

    return true;
  }

  @override
  Future<PostResult> publishPost(String content, Account account) async {
    await Future.delayed(_simulatedDelay);

    // Check content length
    if (!isContentValid(content)) {
      return createFailureResult(
        content,
        'Content exceeds character limit of $characterLimit',
        PostErrorType.contentTooLong,
      );
    }

    // Check credentials
    if (!hasRequiredCredentials(account)) {
      return createFailureResult(
        content,
        'Invalid or missing credentials',
        PostErrorType.invalidCredentials,
      );
    }

    if (_shouldFailPosting) {
      return createFailureResult(content, _errorMessage, _errorType);
    }

    // Simulate random failures occasionally
    if (Random().nextDouble() < 0.05) { // 5% chance of random failure
      return createFailureResult(
        content,
        'Random simulated failure',
        PostErrorType.serverError,
      );
    }

    return createSuccessResult(content);
  }

  @override
  Future<bool> validateConnection(Account account) async {
    await Future.delayed(_simulatedDelay);

    if (_throwError) {
      throw Exception('Mock validation error');
    }

    if (!hasRequiredCredentials(account)) {
      return false;
    }

    if (_shouldFailValidation) {
      return false;
    }

    return true;
  }

  // Dynamic configuration methods for testing
  void setAuthenticationResult(bool shouldSucceed) {
    _shouldFailAuthentication = !shouldSucceed;
  }

  void setValidationResult(bool shouldSucceed) {
    _shouldFailValidation = !shouldSucceed;
  }

  void setPostingResult(bool shouldSucceed) {
    _shouldFailPosting = !shouldSucceed;
  }

  void setThrowError(bool shouldThrow) {
    _throwError = shouldThrow;
  }

  void setErrorType(PostErrorType errorType) {
    _errorType = errorType;
  }

  void setErrorMessage(String message) {
    _errorMessage = message;
  }

  void setSimulatedDelay(Duration delay) {
    _simulatedDelay = delay;
  }

  @override
  bool validateCredentials(Account account) {
    if (!super.validateCredentials(account)) return false;

    // Additional mock-specific validation
    switch (_platformType) {
      case PlatformType.mastodon:
        final serverUrl = account.getCredential<String>('server_url');
        return serverUrl != null && serverUrl.startsWith('https://');
      case PlatformType.bluesky:
        final handle = account.getCredential<String>('handle');
        return handle != null && handle.contains('.');
      case PlatformType.nostr:
        final privateKey = account.getCredential<String>('private_key');
        return privateKey != null && privateKey.length >= 32;
      case PlatformType.microblog:
        final username = account.getCredential<String>('username');
        final token = account.getCredential<String>('token');
        return username != null && token != null;
      case PlatformType.x:
        return true;
    }
  }
}

/// Factory class for creating mock services
class MockSocialPlatformServiceFactory {
  /// Create a mock service that always succeeds
  static MockSocialPlatformService createSuccessful(PlatformType platform) {
    return MockSocialPlatformService(platformType: platform);
  }

  /// Create a mock service that fails authentication
  static MockSocialPlatformService createAuthenticationFailure(PlatformType platform) {
    return MockSocialPlatformService(
      platformType: platform,
      shouldFailAuthentication: true,
      errorType: PostErrorType.authenticationError,
      errorMessage: 'Authentication failed',
    );
  }

  /// Create a mock service that fails posting
  static MockSocialPlatformService createPostingFailure(PlatformType platform) {
    return MockSocialPlatformService(
      platformType: platform,
      shouldFailPosting: true,
      errorType: PostErrorType.serverError,
      errorMessage: 'Failed to publish post',
    );
  }

  /// Create a mock service that fails validation
  static MockSocialPlatformService createValidationFailure(PlatformType platform) {
    return MockSocialPlatformService(
      platformType: platform,
      shouldFailValidation: true,
    );
  }

  /// Create a mock service with network errors
  static MockSocialPlatformService createNetworkFailure(PlatformType platform) {
    return MockSocialPlatformService(
      platformType: platform,
      shouldFailPosting: true,
      errorType: PostErrorType.networkError,
      errorMessage: 'Network connection failed',
    );
  }

  /// Create a mock service with rate limiting
  static MockSocialPlatformService createRateLimitFailure(PlatformType platform) {
    return MockSocialPlatformService(
      platformType: platform,
      shouldFailPosting: true,
      errorType: PostErrorType.rateLimitError,
      errorMessage: 'Rate limit exceeded',
    );
  }

  /// Create a slow mock service for testing timeouts
  static MockSocialPlatformService createSlow(PlatformType platform) {
    return MockSocialPlatformService(
      platformType: platform,
      simulatedDelay: const Duration(seconds: 2),
    );
  }
}