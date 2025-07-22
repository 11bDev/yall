import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import '../models/platform_type.dart';
import '../models/post_result.dart';
import 'social_platform_service.dart';

/// Global error handler for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final List<ErrorLogEntry> _errorLog = [];
  final int _maxLogEntries = 1000;

  /// Log an error without exposing sensitive data
  void logError(
    String operation,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    PlatformType? platform,
  }) {
    final sanitizedContext = _sanitizeContext(context);
    final sanitizedError = _sanitizeError(error);

    final entry = ErrorLogEntry(
      timestamp: DateTime.now(),
      operation: operation,
      error: sanitizedError,
      stackTrace: stackTrace?.toString(),
      context: sanitizedContext,
      platform: platform,
    );

    _errorLog.add(entry);

    // Keep log size manageable
    if (_errorLog.length > _maxLogEntries) {
      _errorLog.removeAt(0);
    }

    // Log to developer console (in debug mode)
    developer.log(
      'Error in $operation: $sanitizedError',
      name: 'MultiPlatformPoster',
      error: sanitizedError,
      stackTrace: stackTrace,
    );
  }

  /// Get recent error logs
  List<ErrorLogEntry> getRecentErrors({int limit = 50}) {
    final startIndex = _errorLog.length > limit ? _errorLog.length - limit : 0;
    return _errorLog.sublist(startIndex);
  }

  /// Clear error logs
  void clearLogs() {
    _errorLog.clear();
  }

  /// Get user-friendly error message from exception
  String getUserFriendlyMessage(dynamic error, {PlatformType? platform}) {
    if (error is SocialPlatformException) {
      return _getPlatformSpecificMessage(error);
    }

    if (error is SocketException) {
      return 'Network connection failed. Please check your internet connection and try again.';
    }

    if (error is HttpException) {
      return 'Network error occurred. Please try again later.';
    }

    if (error is TimeoutException) {
      return 'Request timed out. Please check your connection and try again.';
    }

    if (error is FormatException) {
      return 'Invalid data format received. Please try again.';
    }

    // Generic fallback
    return 'An unexpected error occurred. Please try again.';
  }

  /// Get platform-specific user-friendly error messages
  String _getPlatformSpecificMessage(SocialPlatformException exception) {
    final platformName = exception.platform.displayName;

    switch (exception.errorType) {
      case PostErrorType.networkError:
        return 'Unable to connect to $platformName. Please check your internet connection.';

      case PostErrorType.authenticationError:
        return 'Authentication failed for $platformName. Please check your account credentials in settings.';

      case PostErrorType.rateLimitError:
        return '$platformName rate limit exceeded. Please wait a few minutes before posting again.';

      case PostErrorType.contentTooLong:
        return 'Post is too long for $platformName. Maximum ${exception.platform.characterLimit} characters allowed.';

      case PostErrorType.platformUnavailable:
        return '$platformName is currently unavailable. Please try again later.';

      case PostErrorType.invalidCredentials:
        return 'Invalid credentials for $platformName. Please update your account settings.';

      case PostErrorType.serverError:
        return '$platformName server error. Please try again later.';

      case PostErrorType.unknownError:
        return 'An error occurred while posting to $platformName. Please try again.';
    }
  }

  /// Sanitize error information to remove sensitive data
  String _sanitizeError(dynamic error) {
    String errorString = error.toString();

    // Remove common sensitive patterns
    errorString = _removeSensitivePatterns(errorString);

    return errorString;
  }

  /// Sanitize context information to remove sensitive data
  Map<String, dynamic>? _sanitizeContext(Map<String, dynamic>? context) {
    if (context == null) return null;

    final sanitized = <String, dynamic>{};

    for (final entry in context.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;

      // Skip sensitive keys
      if (_isSensitiveKey(key)) {
        sanitized[entry.key] = '[REDACTED]';
        continue;
      }

      // Sanitize string values
      if (value is String) {
        sanitized[entry.key] = _removeSensitivePatterns(value);
      } else if (value is Map) {
        sanitized[entry.key] = _sanitizeContext(value.cast<String, dynamic>());
      } else {
        sanitized[entry.key] = value;
      }
    }

    return sanitized;
  }

  /// Check if a key contains sensitive information
  bool _isSensitiveKey(String key) {
    const sensitiveKeys = [
      'password',
      'token',
      'key',
      'secret',
      'auth',
      'credential',
      'jwt',
      'bearer',
      'private',
    ];

    return sensitiveKeys.any((sensitive) => key.contains(sensitive));
  }

  /// Remove sensitive patterns from strings
  String _removeSensitivePatterns(String input) {
    String result = input;

    // Remove JWT tokens
    result = result.replaceAll(
      RegExp(r'eyJ[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*'),
      '[JWT_TOKEN]',
    );

    // Remove bearer tokens
    result = result.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9-_=]+', caseSensitive: false),
      'Bearer [TOKEN]',
    );

    // Remove API keys (common patterns)
    result = result.replaceAll(RegExp(r'[A-Za-z0-9]{32,}'), '[API_KEY]');

    // Remove hex private keys (64 characters)
    result = result.replaceAll(RegExp(r'[a-fA-F0-9]{64}'), '[PRIVATE_KEY]');

    // Remove email addresses
    result = result.replaceAll(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      '[EMAIL]',
    );

    // Remove URLs with credentials
    result = result.replaceAll(
      RegExp(r'https?://[^:]+:[^@]+@'),
      'https://[CREDENTIALS]@',
    );

    return result;
  }
}

/// Represents an entry in the error log
class ErrorLogEntry {
  final DateTime timestamp;
  final String operation;
  final String error;
  final String? stackTrace;
  final Map<String, dynamic>? context;
  final PlatformType? platform;

  ErrorLogEntry({
    required this.timestamp,
    required this.operation,
    required this.error,
    this.stackTrace,
    this.context,
    this.platform,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'operation': operation,
      'error': error,
      'stackTrace': stackTrace,
      'context': context,
      'platform': platform?.id,
    };
  }

  @override
  String toString() {
    return 'ErrorLogEntry(timestamp: $timestamp, operation: $operation, '
        'error: $error, platform: ${platform?.displayName})';
  }
}
