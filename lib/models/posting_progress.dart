import 'platform_type.dart';
import 'post_result.dart';

/// Enum representing the current state of a posting operation
enum PostingState { idle, preparing, posting, completed, cancelled, failed }

/// Model representing the progress of a posting operation
class PostingProgress {
  final PostingState state;
  final Set<PlatformType> targetPlatforms;
  final Map<PlatformType, PlatformPostingStatus> platformStatuses;
  final String? overallMessage;
  final double? overallProgress; // 0.0 to 1.0
  final DateTime? startTime;
  final DateTime? endTime;
  final PostResult? result;
  final bool isCancellable;

  const PostingProgress({
    required this.state,
    required this.targetPlatforms,
    required this.platformStatuses,
    this.overallMessage,
    this.overallProgress,
    this.startTime,
    this.endTime,
    this.result,
    this.isCancellable = false,
  });

  /// Create an idle progress state
  factory PostingProgress.idle() {
    return const PostingProgress(
      state: PostingState.idle,
      targetPlatforms: {},
      platformStatuses: {},
    );
  }

  /// Create a preparing progress state
  factory PostingProgress.preparing(Set<PlatformType> platforms) {
    final statuses = <PlatformType, PlatformPostingStatus>{};
    for (final platform in platforms) {
      statuses[platform] = PlatformPostingStatus.preparing(platform);
    }

    return PostingProgress(
      state: PostingState.preparing,
      targetPlatforms: platforms,
      platformStatuses: statuses,
      overallMessage: 'Preparing to post...',
      overallProgress: 0.0,
      startTime: DateTime.now(),
      isCancellable: true,
    );
  }

  /// Create a posting progress state
  factory PostingProgress.posting(
    Set<PlatformType> platforms,
    DateTime startTime,
  ) {
    final statuses = <PlatformType, PlatformPostingStatus>{};
    for (final platform in platforms) {
      statuses[platform] = PlatformPostingStatus.posting(platform);
    }

    return PostingProgress(
      state: PostingState.posting,
      targetPlatforms: platforms,
      platformStatuses: statuses,
      overallMessage:
          'Posting to ${platforms.length} platform${platforms.length == 1 ? '' : 's'}...',
      overallProgress: 0.1,
      startTime: startTime,
      isCancellable: true,
    );
  }

  /// Create a completed progress state
  factory PostingProgress.completed(PostResult result, DateTime startTime) {
    final statuses = <PlatformType, PlatformPostingStatus>{};
    for (final platform in result.platformResults.keys) {
      final success = result.isSuccessful(platform);
      final error = result.getError(platform);
      final errorType = result.getErrorType(platform);

      statuses[platform] = success
          ? PlatformPostingStatus.completed(platform)
          : PlatformPostingStatus.failed(platform, error, errorType);
    }

    return PostingProgress(
      state: PostingState.completed,
      targetPlatforms: result.platformResults.keys.toSet(),
      platformStatuses: statuses,
      overallMessage: result.getSummaryMessage(),
      overallProgress: 1.0,
      startTime: startTime,
      endTime: DateTime.now(),
      result: result,
      isCancellable: false,
    );
  }

  /// Create a cancelled progress state
  factory PostingProgress.cancelled(
    Set<PlatformType> platforms,
    DateTime startTime,
  ) {
    final statuses = <PlatformType, PlatformPostingStatus>{};
    for (final platform in platforms) {
      statuses[platform] = PlatformPostingStatus.cancelled(platform);
    }

    return PostingProgress(
      state: PostingState.cancelled,
      targetPlatforms: platforms,
      platformStatuses: statuses,
      overallMessage: 'Posting cancelled',
      overallProgress: null,
      startTime: startTime,
      endTime: DateTime.now(),
      isCancellable: false,
    );
  }

  /// Create a failed progress state
  factory PostingProgress.failed(
    Set<PlatformType> platforms,
    String errorMessage,
    DateTime startTime,
  ) {
    final statuses = <PlatformType, PlatformPostingStatus>{};
    for (final platform in platforms) {
      statuses[platform] = PlatformPostingStatus.failed(
        platform,
        errorMessage,
        PostErrorType.unknownError,
      );
    }

    return PostingProgress(
      state: PostingState.failed,
      targetPlatforms: platforms,
      platformStatuses: statuses,
      overallMessage: 'Posting failed: $errorMessage',
      overallProgress: null,
      startTime: startTime,
      endTime: DateTime.now(),
      isCancellable: false,
    );
  }

  /// Update progress with platform-specific status
  PostingProgress updatePlatformStatus(
    PlatformType platform,
    PlatformPostingStatus status,
  ) {
    final newStatuses = Map<PlatformType, PlatformPostingStatus>.from(
      platformStatuses,
    );
    newStatuses[platform] = status;

    // Calculate overall progress based on platform statuses
    final completedCount = newStatuses.values
        .where(
          (status) =>
              status.state == PlatformPostingState.completed ||
              status.state == PlatformPostingState.failed,
        )
        .length;
    final totalCount = newStatuses.length;
    final newProgress = totalCount > 0
        ? (0.1 + (completedCount / totalCount) * 0.9)
        : 0.0;

    return PostingProgress(
      state: state,
      targetPlatforms: targetPlatforms,
      platformStatuses: newStatuses,
      overallMessage: overallMessage,
      overallProgress: newProgress,
      startTime: startTime,
      endTime: endTime,
      result: result,
      isCancellable: isCancellable,
    );
  }

  /// Get duration of the posting operation
  Duration? get duration {
    if (startTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  /// Check if posting is in progress
  bool get isInProgress =>
      state == PostingState.preparing || state == PostingState.posting;

  /// Check if posting is complete (success or failure)
  bool get isComplete =>
      state == PostingState.completed ||
      state == PostingState.failed ||
      state == PostingState.cancelled;

  /// Get successful platforms
  Set<PlatformType> get successfulPlatforms {
    return platformStatuses.entries
        .where((entry) => entry.value.state == PlatformPostingState.completed)
        .map((entry) => entry.key)
        .toSet();
  }

  /// Get failed platforms
  Set<PlatformType> get failedPlatforms {
    return platformStatuses.entries
        .where((entry) => entry.value.state == PlatformPostingState.failed)
        .map((entry) => entry.key)
        .toSet();
  }

  /// Get platforms still in progress
  Set<PlatformType> get inProgressPlatforms {
    return platformStatuses.entries
        .where(
          (entry) =>
              entry.value.state == PlatformPostingState.preparing ||
              entry.value.state == PlatformPostingState.posting,
        )
        .map((entry) => entry.key)
        .toSet();
  }

  @override
  String toString() {
    return 'PostingProgress(state: $state, platforms: $targetPlatforms, '
        'progress: $overallProgress, message: $overallMessage)';
  }
}

/// Enum representing the state of posting to a specific platform
enum PlatformPostingState { preparing, posting, completed, failed, cancelled }

/// Model representing the posting status for a specific platform
class PlatformPostingStatus {
  final PlatformType platform;
  final PlatformPostingState state;
  final String? message;
  final String? error;
  final PostErrorType? errorType;
  final DateTime timestamp;

  PlatformPostingStatus({
    required this.platform,
    required this.state,
    this.message,
    this.error,
    this.errorType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a preparing status
  factory PlatformPostingStatus.preparing(PlatformType platform) {
    return PlatformPostingStatus(
      platform: platform,
      state: PlatformPostingState.preparing,
      message: 'Preparing...',
    );
  }

  /// Create a posting status
  factory PlatformPostingStatus.posting(PlatformType platform) {
    return PlatformPostingStatus(
      platform: platform,
      state: PlatformPostingState.posting,
      message: 'Posting...',
    );
  }

  /// Create a completed status
  factory PlatformPostingStatus.completed(PlatformType platform) {
    return PlatformPostingStatus(
      platform: platform,
      state: PlatformPostingState.completed,
      message: 'Posted successfully',
    );
  }

  /// Create a failed status
  factory PlatformPostingStatus.failed(
    PlatformType platform,
    String? error,
    PostErrorType? errorType,
  ) {
    return PlatformPostingStatus(
      platform: platform,
      state: PlatformPostingState.failed,
      message: 'Failed to post',
      error: error,
      errorType: errorType,
    );
  }

  /// Create a cancelled status
  factory PlatformPostingStatus.cancelled(PlatformType platform) {
    return PlatformPostingStatus(
      platform: platform,
      state: PlatformPostingState.cancelled,
      message: 'Cancelled',
    );
  }

  @override
  String toString() {
    return 'PlatformPostingStatus(platform: $platform, state: $state, '
        'message: $message, error: $error)';
  }
}
