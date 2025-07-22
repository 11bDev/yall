import 'package:flutter/material.dart';
import '../models/posting_progress.dart';
import '../models/platform_type.dart';

/// Widget that displays posting progress with platform-specific status
class PostingProgressWidget extends StatelessWidget {
  final PostingProgress progress;
  final VoidCallback? onCancel;

  const PostingProgressWidget({
    super.key,
    required this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (progress.state == PostingState.idle) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall progress header
            Row(
              children: [
                _buildStateIcon(context),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    progress.overallMessage ?? 'Processing...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (progress.isCancellable && onCancel != null)
                  TextButton(onPressed: onCancel, child: const Text('Cancel')),
              ],
            ),

            const SizedBox(height: 12),

            // Overall progress bar
            if (progress.overallProgress != null)
              LinearProgressIndicator(
                value: progress.overallProgress,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              ),

            const SizedBox(height: 16),

            // Platform-specific progress
            ...progress.platformStatuses.entries.map(
              (entry) => _buildPlatformStatus(context, entry.value),
            ),

            // Duration display
            if (progress.duration != null) ...[
              const SizedBox(height: 8),
              Text(
                'Duration: ${_formatDuration(progress.duration!)}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],

            // Result summary for completed state
            if (progress.state == PostingState.completed &&
                progress.result != null)
              _buildResultSummary(context, progress.result!),
          ],
        ),
      ),
    );
  }

  Widget _buildStateIcon(BuildContext context) {
    switch (progress.state) {
      case PostingState.preparing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case PostingState.posting:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case PostingState.completed:
        return Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        );
      case PostingState.cancelled:
        return Icon(
          Icons.cancel,
          color: Theme.of(context).colorScheme.error,
          size: 20,
        );
      case PostingState.failed:
        return Icon(
          Icons.error,
          color: Theme.of(context).colorScheme.error,
          size: 20,
        );
      case PostingState.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlatformStatus(
    BuildContext context,
    PlatformPostingStatus status,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          _buildPlatformIcon(context, status),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.platform.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (status.message != null)
                  Text(
                    status.message!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (status.error != null)
                  Text(
                    status.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformIcon(
    BuildContext context,
    PlatformPostingStatus status,
  ) {
    switch (status.state) {
      case PlatformPostingState.preparing:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      case PlatformPostingState.posting:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      case PlatformPostingState.completed:
        return Icon(Icons.check_circle, color: Colors.green, size: 16);
      case PlatformPostingState.failed:
        return Icon(
          Icons.error,
          color: Theme.of(context).colorScheme.error,
          size: 16,
        );
      case PlatformPostingState.cancelled:
        return Icon(
          Icons.cancel,
          color: Theme.of(context).colorScheme.error,
          size: 16,
        );
    }
  }

  Widget _buildResultSummary(BuildContext context, dynamic result) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.allSuccessful
            ? Colors.green.withOpacity(0.1)
            : result.allFailed
            ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.5)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.getSummaryMessage(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          if (result.hasErrors) ...[
            const SizedBox(height: 8),
            ...result.getDetailedErrors().map(
              (error) => Text(
                error,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
