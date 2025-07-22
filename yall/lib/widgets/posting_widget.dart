import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/platform_type.dart';
import '../models/account.dart';
import '../models/posting_progress.dart';
import '../providers/post_manager.dart';
import '../providers/account_manager.dart';
import 'platform_selector.dart';
import 'posting_progress_widget.dart';

/// Main widget for composing and posting messages to multiple platforms
class PostingWidget extends StatefulWidget {
  const PostingWidget({super.key});

  @override
  State<PostingWidget> createState() => _PostingWidgetState();
}

class _PostingWidgetState extends State<PostingWidget> {
  final TextEditingController _textController = TextEditingController();
  final Set<PlatformType> _selectedPlatforms = <PlatformType>{};
  final Map<PlatformType, Account?> _selectedAccounts =
      <PlatformType, Account?>{};

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      // Trigger rebuild to update character counter and validation
    });
  }

  void _onPlatformToggled(PlatformType platform, bool selected) {
    setState(() {
      if (selected) {
        _selectedPlatforms.add(platform);
        // Set default account if available
        final accountManager = context.read<AccountManager>();
        final defaultAccount = accountManager.getDefaultAccountForPlatform(
          platform,
        );
        _selectedAccounts[platform] = defaultAccount;
      } else {
        _selectedPlatforms.remove(platform);
        _selectedAccounts.remove(platform);
      }
    });
  }

  void _onAccountSelected(PlatformType platform, Account? account) {
    setState(() {
      _selectedAccounts[platform] = account;
    });
  }

  Future<void> _onPostPressed() async {
    final postManager = context.read<PostManager>();
    final content = _textController.text.trim();

    if (content.isEmpty || _selectedPlatforms.isEmpty) {
      return;
    }

    // Filter out platforms without selected accounts
    final validPlatforms = _selectedPlatforms.where((platform) {
      return _selectedAccounts[platform] != null;
    }).toSet();

    final validAccounts = Map<PlatformType, Account>.fromEntries(
      validPlatforms.map(
        (platform) => MapEntry(platform, _selectedAccounts[platform]!),
      ),
    );

    try {
      final result = await postManager.publishToSelectedPlatforms(
        content,
        validPlatforms,
        validAccounts,
      );

      if (result.allSuccessful) {
        // Clear the text field on successful post
        _textController.clear();
        _showSuccessMessage();
      } else {
        _showErrorMessage(result);
      }
    } catch (e) {
      _showErrorDialog('Failed to post: ${e.toString()}');
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post published successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(dynamic result) {
    final errorMessage = result.hasErrors
        ? 'Some posts failed. Check the details.'
        : 'Failed to post to some platforms.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Details',
          onPressed: () => _showErrorDialog(result.toString()),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Posting Error'),
        content: SelectableText(message),
        actions: [
          TextButton(
            onPressed: () {
              // Copy to clipboard
              final data = ClipboardData(text: message);
              Clipboard.setData(data);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error message copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PostManager, AccountManager>(
      builder: (context, postManager, accountManager, child) {
        final content = _textController.text;
        final canPost =
            postManager.canPost(content, _selectedPlatforms) &&
            _selectedPlatforms.every(
              (platform) => _selectedAccounts[platform] != null,
            );

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text input area
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _textController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText: 'What\'s on your mind?',
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCharacterCounter(postManager),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Platform selection
              PlatformSelector(
                selectedPlatforms: _selectedPlatforms,
                selectedAccounts: _selectedAccounts,
                onPlatformToggled: _onPlatformToggled,
                onAccountSelected: _onAccountSelected,
                enabled: !postManager.isPosting,
              ),

              const SizedBox(height: 16),

              // Post button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: canPost && !postManager.isPosting
                      ? _onPostPressed
                      : null,
                  child: postManager.isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                ),
              ),

              // Progress display
              if (postManager.progress.state != PostingState.idle) ...[
                const SizedBox(height: 16),
                PostingProgressWidget(
                  progress: postManager.progress,
                  onCancel: postManager.canCancel
                      ? postManager.cancelPosting
                      : null,
                ),
              ],

              // Error display
              if (postManager.error != null) ...[
                const SizedBox(height: 8),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            postManager.error!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: postManager.clearError,
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCharacterCounter(PostManager postManager) {
    final content = _textController.text;
    if (content.isEmpty || _selectedPlatforms.isEmpty) {
      return const SizedBox.shrink();
    }

    final limits = postManager.getCharacterLimitsForPlatforms(_selectedPlatforms);
    final contentLength = content.length;
    final platformsWithIssues = <PlatformType>[];

    // Check which platforms will have truncated content
    for (final platform in _selectedPlatforms) {
      final limit = limits[platform] ?? 0;
      if (limit > 0 && contentLength > limit) {
        platformsWithIssues.add(platform);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Character count display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Content length: $contentLength characters',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_selectedPlatforms.isNotEmpty)
              _buildLimitsSummary(limits, contentLength),
          ],
        ),

        // Truncation warnings
        if (platformsWithIssues.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Content will be truncated',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...platformsWithIssues.map((platform) {
                  final limit = limits[platform]!;
                  final excess = contentLength - limit;
                  return Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2),
                    child: Text(
                      '${platform.displayName}: ${excess} characters will be removed (limit: $limit)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLimitsSummary(Map<PlatformType, int> limits, int contentLength) {
    final hasUnlimited = limits.values.any((limit) => limit == 0);
    final finiteLimits = limits.entries.where((e) => e.value > 0).toList();
    
    if (finiteLimits.isEmpty && hasUnlimited) {
      return Text(
        'No character limit',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.green,
        ),
      );
    }
    
    if (finiteLimits.length == 1) {
      final entry = finiteLimits.first;
      final remaining = entry.value - contentLength;
      return Text(
        '${entry.key.displayName}: $remaining remaining',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: remaining < 0 ? Theme.of(context).colorScheme.error : null,
          fontWeight: remaining < 0 ? FontWeight.bold : null,
        ),
      );
    }
    
    final mostRestrictive = finiteLimits
        .reduce((a, b) => a.value < b.value ? a : b);
    final remaining = mostRestrictive.value - contentLength;
    
    return Text(
      'Most restrictive: ${mostRestrictive.key.displayName} ($remaining remaining)',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: remaining < 0 ? Theme.of(context).colorScheme.error : null,
        fontWeight: remaining < 0 ? FontWeight.bold : null,
      ),
    );
  }
}
