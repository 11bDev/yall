import 'dart:convert';
import 'platform_type.dart';

/// Enum representing different types of posting errors
enum PostErrorType {
  networkError,
  authenticationError,
  rateLimitError,
  contentTooLong,
  platformUnavailable,
  invalidCredentials,
  serverError,
  unknownError,
}

/// Model representing the result of a posting operation across multiple platforms
class PostResult {
  final Map<PlatformType, bool> platformResults;
  final Map<PlatformType, String> errors;
  final Map<PlatformType, PostErrorType> errorTypes;
  final DateTime timestamp;
  final String originalContent;

  PostResult({
    required this.platformResults,
    required this.errors,
    required this.errorTypes,
    required this.originalContent,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create an empty result
  factory PostResult.empty(String content) {
    return PostResult(
      platformResults: {},
      errors: {},
      errorTypes: {},
      originalContent: content,
    );
  }

  /// Create a successful result for all platforms
  factory PostResult.allSuccessful(Set<PlatformType> platforms, String content) {
    final results = <PlatformType, bool>{};
    for (final platform in platforms) {
      results[platform] = true;
    }
    return PostResult(
      platformResults: results,
      errors: {},
      errorTypes: {},
      originalContent: content,
    );
  }

  /// Create a failed result for all platforms
  factory PostResult.allFailed(
    Set<PlatformType> platforms,
    String content,
    String errorMessage,
    PostErrorType errorType,
  ) {
    final results = <PlatformType, bool>{};
    final errors = <PlatformType, String>{};
    final errorTypes = <PlatformType, PostErrorType>{};

    for (final platform in platforms) {
      results[platform] = false;
      errors[platform] = errorMessage;
      errorTypes[platform] = errorType;
    }

    return PostResult(
      platformResults: results,
      errors: errors,
      errorTypes: errorTypes,
      originalContent: content,
    );
  }

  /// Check if there are any errors
  bool get hasErrors => errors.isNotEmpty;

  /// Check if all platforms were successful
  bool get allSuccessful => platformResults.isNotEmpty &&
      platformResults.values.every((success) => success);

  /// Check if all platforms failed
  bool get allFailed => platformResults.isNotEmpty &&
      platformResults.values.every((success) => !success);

  /// Get successful platforms
  Set<PlatformType> get successfulPlatforms {
    return platformResults.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toSet();
  }

  /// Get failed platforms
  Set<PlatformType> get failedPlatforms {
    return platformResults.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toSet();
  }

  /// Get count of successful posts
  int get successCount => successfulPlatforms.length;

  /// Get count of failed posts
  int get failureCount => failedPlatforms.length;

  /// Get total platforms attempted
  int get totalPlatforms => platformResults.length;

  /// Add result for a specific platform
  PostResult addPlatformResult(
    PlatformType platform,
    bool success, {
    String? error,
    PostErrorType? errorType,
  }) {
    final newResults = Map<PlatformType, bool>.from(platformResults);
    final newErrors = Map<PlatformType, String>.from(errors);
    final newErrorTypes = Map<PlatformType, PostErrorType>.from(errorTypes);

    newResults[platform] = success;

    if (!success && error != null) {
      newErrors[platform] = error;
      newErrorTypes[platform] = errorType ?? PostErrorType.unknownError;
    } else {
      newErrors.remove(platform);
      newErrorTypes.remove(platform);
    }

    return PostResult(
      platformResults: newResults,
      errors: newErrors,
      errorTypes: newErrorTypes,
      originalContent: originalContent,
      timestamp: timestamp,
    );
  }

  /// Get error message for a specific platform
  String? getError(PlatformType platform) => errors[platform];

  /// Get error type for a specific platform
  PostErrorType? getErrorType(PlatformType platform) => errorTypes[platform];

  /// Check if a specific platform was successful
  bool isSuccessful(PlatformType platform) => platformResults[platform] ?? false;

  /// Get a summary message of the posting result
  String getSummaryMessage() {
    if (allSuccessful) {
      return 'Successfully posted to all $totalPlatforms platform${totalPlatforms == 1 ? '' : 's'}';
    } else if (allFailed) {
      return 'Failed to post to all $totalPlatforms platform${totalPlatforms == 1 ? '' : 's'}';
    } else {
      return 'Posted to $successCount of $totalPlatforms platforms successfully';
    }
  }

  /// Get detailed error messages
  List<String> getDetailedErrors() {
    final errorMessages = <String>[];
    for (final entry in errors.entries) {
      final platform = entry.key.displayName;
      final error = entry.value;
      errorMessages.add('$platform: $error');
    }
    return errorMessages;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'platformResults': platformResults.map(
        (platform, result) => MapEntry(platform.id, result),
      ),
      'errors': errors.map(
        (platform, error) => MapEntry(platform.id, error),
      ),
      'errorTypes': errorTypes.map(
        (platform, errorType) => MapEntry(platform.id, errorType.name),
      ),
      'timestamp': timestamp.toIso8601String(),
      'originalContent': originalContent,
    };
  }

  /// Create from JSON
  factory PostResult.fromJson(Map<String, dynamic> json) {
    final platformResults = <PlatformType, bool>{};
    final errors = <PlatformType, String>{};
    final errorTypes = <PlatformType, PostErrorType>{};

    // Parse platform results
    final resultsJson = json['platformResults'] as Map<String, dynamic>? ?? {};
    for (final entry in resultsJson.entries) {
      try {
        final platform = PlatformType.fromId(entry.key);
        platformResults[platform] = entry.value as bool;
      } catch (e) {
        // Skip invalid platform IDs
        continue;
      }
    }

    // Parse errors
    final errorsJson = json['errors'] as Map<String, dynamic>? ?? {};
    for (final entry in errorsJson.entries) {
      try {
        final platform = PlatformType.fromId(entry.key);
        errors[platform] = entry.value as String;
      } catch (e) {
        // Skip invalid platform IDs
        continue;
      }
    }

    // Parse error types
    final errorTypesJson = json['errorTypes'] as Map<String, dynamic>? ?? {};
    for (final entry in errorTypesJson.entries) {
      try {
        final platform = PlatformType.fromId(entry.key);
        final errorTypeName = entry.value as String;
        final errorType = PostErrorType.values.firstWhere(
          (type) => type.name == errorTypeName,
          orElse: () => PostErrorType.unknownError,
        );
        errorTypes[platform] = errorType;
      } catch (e) {
        // Skip invalid platform IDs or error types
        continue;
      }
    }

    return PostResult(
      platformResults: platformResults,
      errors: errors,
      errorTypes: errorTypes,
      originalContent: json['originalContent'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create from JSON string
  factory PostResult.fromJsonString(String jsonString) {
    return PostResult.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostResult &&
        _mapEquals(other.platformResults, platformResults) &&
        _mapEquals(other.errors, errors) &&
        _mapEquals(other.errorTypes, errorTypes) &&
        other.timestamp == timestamp &&
        other.originalContent == originalContent;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(platformResults.entries.map((e) => Object.hash(e.key, e.value))),
      Object.hashAll(errors.entries.map((e) => Object.hash(e.key, e.value))),
      Object.hashAll(errorTypes.entries.map((e) => Object.hash(e.key, e.value))),
      timestamp,
      originalContent,
    );
  }

  /// Helper method to compare maps
  bool _mapEquals<K, V>(Map<K, V> map1, Map<K, V> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'PostResult(platformResults: $platformResults, errors: $errors, '
        'errorTypes: $errorTypes, timestamp: $timestamp, '
        'originalContent: ${originalContent.length > 50 ? '${originalContent.substring(0, 50)}...' : originalContent})';
  }
}