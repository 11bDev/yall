import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../models/post_result.dart';
import '../models/platform_type.dart';
import '../models/posting_progress.dart';
import '../models/post_data.dart';
import '../models/media_attachment.dart';
import '../services/social_platform_service.dart';
import '../services/mastodon_service.dart';
import '../services/bluesky_service.dart';
import '../services/nostr_service.dart';
import '../services/microblog_service.dart';
import '../services/retry_manager.dart';

/// Exception thrown by PostManager operations
class PostManagerException implements Exception {
  final String message;
  final dynamic originalError;

  const PostManagerException(this.message, [this.originalError]);

  @override
  String toString() => 'PostManagerException: $message';
}

/// Provider for managing post operations across multiple social media platforms
class PostManager extends ChangeNotifier {
  final Map<PlatformType, SocialPlatformService> _platformServices;

  bool _isPosting = false;
  PostResult? _lastPostResult;
  String? _error;
  PostingProgress _progress = PostingProgress.idle();
  Completer<void>? _cancellationCompleter;

  PostManager({Map<PlatformType, SocialPlatformService>? platformServices})
    : _platformServices =
          platformServices ??
          {
            PlatformType.mastodon: MastodonService(),
            PlatformType.bluesky: BlueskyService(),
            PlatformType.nostr: NostrService(),
            PlatformType.microblog: MicroblogService(),
          };

  /// Check if a posting operation is currently in progress
  bool get isPosting => _isPosting;

  /// Get the result of the last posting operation
  PostResult? get lastPostResult => _lastPostResult;

  /// Get current error message
  String? get error => _error;

  /// Get current posting progress
  PostingProgress get progress => _progress;

  /// Check if posting can be cancelled
  bool get canCancel =>
      _progress.isCancellable && _cancellationCompleter != null;

  /// Clear current error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear last post result
  void clearLastResult() {
    _lastPostResult = null;
    notifyListeners();
  }

  /// Cancel the current posting operation
  Future<void> cancelPosting() async {
    if (!canCancel) {
      return;
    }

    _cancellationCompleter?.complete();
    _cancellationCompleter = null;

    _progress = PostingProgress.cancelled(
      _progress.targetPlatforms,
      _progress.startTime ?? DateTime.now(),
    );
    _setPosting(false);
    notifyListeners();
  }

  /// Publish content to selected platforms with specified accounts
  ///
  /// [postData] - The post data including content and media
  /// [selectedPlatforms] - Set of platforms to post to
  /// [selectedAccounts] - Map of platform to account for posting
  ///
  /// Returns a [PostResult] with the outcome for each platform
  Future<PostResult> publishToSelectedPlatforms(
    PostData postData,
    Set<PlatformType> selectedPlatforms,
    Map<PlatformType, Account> selectedAccounts,
  ) async {
    if (_isPosting) {
      throw PostManagerException('A posting operation is already in progress');
    }

    final startTime = DateTime.now();
    _setPosting(true);
    _clearError();
    _cancellationCompleter = Completer<void>();

    try {
      // Initialize progress tracking
      _progress = PostingProgress.preparing(selectedPlatforms);
      notifyListeners();

      // Validate inputs
      if (!postData.isValid) {
        throw PostManagerException('Post must have content or media attachments');
      }

      if (selectedPlatforms.isEmpty) {
        throw PostManagerException('No platforms selected');
      }

      // Validate character limits for all selected platforms
      final characterLimitValidation = validateCharacterLimits(
        postData.content,
        selectedPlatforms,
      );
      if (!characterLimitValidation.isValid) {
        throw PostManagerException(characterLimitValidation.errorMessage!);
      }

      // Validate that we have accounts for all selected platforms
      for (final platform in selectedPlatforms) {
        if (!selectedAccounts.containsKey(platform)) {
          throw PostManagerException(
            'No account selected for ${platform.displayName}',
          );
        }

        final account = selectedAccounts[platform]!;
        if (account.platform != platform) {
          throw PostManagerException(
            'Account platform mismatch for ${platform.displayName}',
          );
        }

        if (!account.isActive) {
          throw PostManagerException(
            'Account for ${platform.displayName} is not active',
          );
        }
      }

      // Update progress to posting state
      _progress = PostingProgress.posting(selectedPlatforms, startTime);
      notifyListeners();

      // Create futures for parallel posting with progress tracking
      final postingFutures = <Future<PostResult>>[];
      final platformList = selectedPlatforms.toList();

      for (final platform in platformList) {
        final account = selectedAccounts[platform]!;
        final service = _platformServices[platform];

        if (service == null) {
          // Update progress for unsupported platform
          _progress = _progress.updatePlatformStatus(
            platform,
            PlatformPostingStatus.failed(
              platform,
              'Platform service not available',
              PostErrorType.platformUnavailable,
            ),
          );
          notifyListeners();

          // Create a failure result for unsupported platform
          final failureResult = PostResult.empty(postData.content).addPlatformResult(
            platform,
            false,
            error: 'Platform service not available',
            errorType: PostErrorType.platformUnavailable,
          );
          postingFutures.add(Future.value(failureResult));
          continue;
        }

        // Create posting future with progress tracking
        final postingFuture = _postToPlatform(
          service,
          postData,
          account,
          platform,
        );
        postingFutures.add(postingFuture);
      }

      // Wait for all posting operations to complete or cancellation
      final results = await Future.any([
        Future.wait(postingFutures),
        _cancellationCompleter!.future.then(
          (_) => throw PostManagerException('Posting cancelled'),
        ),
      ]);

      // Check if operation was cancelled
      if (_cancellationCompleter!.isCompleted) {
        return PostResult.allFailed(
          selectedPlatforms,
          postData.content,
          'Posting cancelled',
          PostErrorType.unknownError,
        );
      }

      // Combine all results into a single PostResult
      PostResult combinedResult = PostResult.empty(postData.content);
      for (final result in results) {
        for (final entry in result.platformResults.entries) {
          final platform = entry.key;
          final success = entry.value;
          final error = result.getError(platform);
          final errorType = result.getErrorType(platform);

          combinedResult = combinedResult.addPlatformResult(
            platform,
            success,
            error: error,
            errorType: errorType,
          );
        }
      }

      // Update progress to completed state
      _progress = PostingProgress.completed(combinedResult, startTime);
      _lastPostResult = combinedResult;
      notifyListeners();

      return combinedResult;
    } catch (e) {
      final errorMessage = e is PostManagerException
          ? e.message
          : 'Failed to publish post: ${e.toString()}';
      _setError(errorMessage);

      // Update progress to failed state
      if (errorMessage == 'Posting cancelled') {
        _progress = PostingProgress.cancelled(selectedPlatforms, startTime);
      } else {
        _progress = PostingProgress.failed(
          selectedPlatforms,
          errorMessage,
          startTime,
        );
      }

      // Create a failure result for all platforms
      final failureResult = PostResult.allFailed(
        selectedPlatforms,
        postData.content,
        errorMessage,
        PostErrorType.unknownError,
      );

      _lastPostResult = failureResult;
      notifyListeners();

      if (e is PostManagerException) {
        rethrow;
      }
      throw PostManagerException(errorMessage, e);
    } finally {
      _setPosting(false);
      _cancellationCompleter = null;
    }
  }

  /// Post to a single platform with progress tracking
  Future<PostResult> _postToPlatform(
    SocialPlatformService service,
    PostData postData,
    Account account,
    PlatformType platform,
  ) async {
    try {
      // Update progress to posting state for this platform
      _progress = _progress.updatePlatformStatus(
        platform,
        PlatformPostingStatus.posting(platform),
      );
      notifyListeners();

      // Truncate content if necessary for this platform
      String platformContent = postData.content;
      final characterLimit = service.characterLimit;
      if (characterLimit > 0 && postData.content.length > characterLimit) {
        platformContent = postData.content.substring(0, characterLimit);
        // Optionally add an ellipsis to indicate truncation
        if (platformContent.length >= 3) {
          platformContent =
              '${platformContent.substring(0, platformContent.length - 3)}...';
        }
      }

      // Create platform-specific post data
      final platformPostData = postData.copyWith(content: platformContent);

      // Validate account credentials
      if (!service.hasRequiredCredentials(account)) {
        final result = service.createFailureResult(
          platformContent,
          'Account missing required credentials',
          PostErrorType.invalidCredentials,
        );

        // Update progress to failed state
        _progress = _progress.updatePlatformStatus(
          platform,
          PlatformPostingStatus.failed(
            platform,
            'Invalid credentials',
            PostErrorType.invalidCredentials,
          ),
        );
        notifyListeners();

        return result;
      }

      // Attempt to publish the post with media support
      final result = platformPostData.hasMedia
          ? await service.publishPostWithMediaRetry(platformPostData, account)
          : await service.publishPostWithRetry(platformContent, account);

      // Update progress based on result
      if (result.isSuccessful(platform)) {
        _progress = _progress.updatePlatformStatus(
          platform,
          PlatformPostingStatus.completed(platform),
        );
      } else {
        _progress = _progress.updatePlatformStatus(
          platform,
          PlatformPostingStatus.failed(
            platform,
            result.getError(platform),
            result.getErrorType(platform),
          ),
        );
      }
      notifyListeners();

      return result;
    } catch (e) {
      // Handle any exceptions that occur during posting
      final result = service.handleError(postData.content, e);

      // Update progress to failed state
      _progress = _progress.updatePlatformStatus(
        platform,
        PlatformPostingStatus.failed(
          platform,
          e.toString(),
          PostErrorType.unknownError,
        ),
      );
      notifyListeners();

      return result;
    }
  }

  /// Validate character limits across selected platforms
  CharacterLimitValidation validateCharacterLimits(
    String content,
    Set<PlatformType> selectedPlatforms,
  ) {
    if (selectedPlatforms.isEmpty) {
      return CharacterLimitValidation(
        isValid: false,
        errorMessage: 'No platforms selected',
      );
    }

    // Since we now support truncation, we should always allow posting
    // The UI will show warnings for platforms where truncation will occur
    return CharacterLimitValidation(
      isValid: true,
      contentLength: content.length,
    );
  }

  /// Check if posting is possible with the given content and platforms
  bool canPost(String content, Set<PlatformType> selectedPlatforms) {
    if (content.trim().isEmpty || selectedPlatforms.isEmpty || _isPosting) {
      return false;
    }

    return validateCharacterLimits(content, selectedPlatforms).isValid;
  }

  /// Get the minimum character limit across selected platforms
  int getCharacterLimit(Set<PlatformType> selectedPlatforms) {
    if (selectedPlatforms.isEmpty) {
      return 0;
    }

    int minLimit = double.maxFinite.toInt();
    for (final platform in selectedPlatforms) {
      final service = _platformServices[platform];
      if (service != null) {
        minLimit = minLimit < service.characterLimit
            ? minLimit
            : service.characterLimit;
      }
    }

    return minLimit == double.maxFinite.toInt() ? 0 : minLimit;
  }

  /// Get remaining characters for the given content and selected platforms
  int getRemainingCharacters(
    String content,
    Set<PlatformType> selectedPlatforms,
  ) {
    final limit = getCharacterLimit(selectedPlatforms);
    return limit > 0 ? limit - content.length : 0;
  }

  /// Get character limit information for all platforms
  Map<PlatformType, int> getCharacterLimitsForPlatforms(
    Set<PlatformType> platforms,
  ) {
    final limits = <PlatformType, int>{};
    for (final platform in platforms) {
      final service = _platformServices[platform];
      if (service != null) {
        limits[platform] = service.characterLimit;
      }
    }
    return limits;
  }

  /// Check if content is valid for all selected platforms
  Map<PlatformType, bool> validateContentForPlatforms(
    String content,
    Set<PlatformType> platforms,
  ) {
    final validation = <PlatformType, bool>{};
    for (final platform in platforms) {
      final service = _platformServices[platform];
      validation[platform] = service?.isContentValid(content) ?? false;
    }
    return validation;
  }

  /// Get platform service for testing purposes
  @visibleForTesting
  SocialPlatformService? getPlatformService(PlatformType platform) {
    return _platformServices[platform];
  }

  /// Update Nostr relay configuration
  void updateNostrRelays(List<String> relays) {
    print('PostManager: Updating Nostr relays to: ${relays.join(', ')}');
    final nostrService = _platformServices[PlatformType.nostr];
    if (nostrService is NostrService) {
      nostrService.updateRelays(relays);
      print('PostManager: Successfully updated NostrService relays');
    } else {
      print('PostManager: NostrService not found or wrong type');
    }
  }

  /// Set posting state for testing purposes
  @visibleForTesting
  void setPostingForTesting(bool isPosting) {
    _isPosting = isPosting;
    notifyListeners();
  }

  /// Set error for testing purposes
  @visibleForTesting
  void setErrorForTesting(String error) {
    _error = error;
    notifyListeners();
  }

  /// Set last result for testing purposes
  @visibleForTesting
  void setLastResultForTesting(PostResult result) {
    _lastPostResult = result;
    notifyListeners();
  }

  /// Private helper methods
  void _setPosting(bool posting) {
    _isPosting = posting;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _lastPostResult = null;
    _error = null;
    super.dispose();
  }
}

/// Result of character limit validation
class CharacterLimitValidation {
  final bool isValid;
  final String? errorMessage;
  final Set<PlatformType>? violatingPlatforms;
  final int? contentLength;
  final int? minCharacterLimit;

  const CharacterLimitValidation({
    required this.isValid,
    this.errorMessage,
    this.violatingPlatforms,
    this.contentLength,
    this.minCharacterLimit,
  });

  @override
  String toString() {
    return 'CharacterLimitValidation(isValid: $isValid, errorMessage: $errorMessage, '
        'violatingPlatforms: $violatingPlatforms, contentLength: $contentLength, '
        'minCharacterLimit: $minCharacterLimit)';
  }
}
