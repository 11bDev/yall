import '../models/account.dart';
import '../models/post_result.dart';
import '../models/platform_type.dart';

/// Exception thrown by social platform services
class SocialPlatformException implements Exception {
  final PlatformType platform;
  final PostErrorType errorType;
  final String message;
  final dynamic originalError;

  const SocialPlatformException({
    required this.platform,
    required this.errorType,
    required this.message,
    this.originalError,
  });

  @override
  String toString() {
    return 'SocialPlatformException(platform: ${platform.displayName}, '
        'errorType: $errorType, message: $message)';
  }
}

/// Abstract base class for all social platform services
abstract class SocialPlatformService {
  /// The platform type this service handles
  PlatformType get platformType;

  /// The display name of the platform
  String get platformName => platformType.displayName;

  /// The character limit for posts on this platform
  int get characterLimit => platformType.characterLimit;

  /// Authenticate an account with the platform
  ///
  /// Returns true if authentication is successful, false otherwise.
  /// Throws [SocialPlatformException] if authentication fails due to an error.
  Future<bool> authenticate(Account account);

  /// Publish a post to the platform
  ///
  /// Returns a [PostResult] indicating success or failure for this platform.
  /// The result will contain error information if the post fails.
  Future<PostResult> publishPost(String content, Account account);

  /// Validate that an account's connection to the platform is still valid
  ///
  /// Returns true if the connection is valid, false otherwise.
  /// This is typically used to check if stored credentials are still valid.
  Future<bool> validateConnection(Account account);

  /// Check if the given content is within the character limit
  bool isContentValid(String content) {
    return content.length <= characterLimit;
  }

  /// Get the remaining character count for the given content
  int getRemainingCharacters(String content) {
    return characterLimit - content.length;
  }

  /// Create a successful post result for this platform
  PostResult createSuccessResult(String content) {
    return PostResult.empty(content).addPlatformResult(platformType, true);
  }

  /// Create a failed post result for this platform
  PostResult createFailureResult(
    String content,
    String errorMessage,
    PostErrorType errorType,
  ) {
    return PostResult.empty(content).addPlatformResult(
      platformType,
      false,
      error: errorMessage,
      errorType: errorType,
    );
  }

  /// Helper method to handle common error scenarios
  PostResult handleError(
    String content,
    dynamic error, {
    PostErrorType? defaultErrorType,
  }) {
    if (error is SocialPlatformException) {
      return createFailureResult(content, error.message, error.errorType);
    }

    // Handle common error types
    final errorMessage = error.toString();
    PostErrorType errorType = defaultErrorType ?? PostErrorType.unknownError;

    if (errorMessage.toLowerCase().contains('network') || errorMessage.toLowerCase().contains('connection')) {
      errorType = PostErrorType.networkError;
    } else if (errorMessage.toLowerCase().contains('auth') || errorMessage.toLowerCase().contains('unauthorized')) {
      errorType = PostErrorType.authenticationError;
    } else if (errorMessage.toLowerCase().contains('rate limit') || errorMessage.toLowerCase().contains('too many requests')) {
      errorType = PostErrorType.rateLimitError;
    } else if (errorMessage.toLowerCase().contains('server') || errorMessage.toLowerCase().contains('500')) {
      errorType = PostErrorType.serverError;
    }

    return createFailureResult(content, errorMessage, errorType);
  }

  /// Validate account credentials format for this platform
  ///
  /// This method should be overridden by concrete implementations to validate
  /// that the account has all required credential fields for the platform.
  bool validateCredentials(Account account) {
    return account.platform == platformType;
  }

  /// Get required credential fields for this platform
  ///
  /// This should be overridden by concrete implementations to specify
  /// which credential fields are required for authentication.
  List<String> get requiredCredentialFields => [];

  /// Check if account has all required credentials
  bool hasRequiredCredentials(Account account) {
    if (!validateCredentials(account)) return false;

    for (final field in requiredCredentialFields) {
      if (!account.hasCredential(field)) return false;
    }
    return true;
  }
}