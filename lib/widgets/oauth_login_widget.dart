import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/platform_type.dart';
import '../providers/account_manager.dart';
import '../services/mastodon_service.dart';

/// OAuth login widget for Mastodon and Bluesky
class OAuthLoginWidget extends StatefulWidget {
  final PlatformType platform;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const OAuthLoginWidget({
    super.key,
    required this.platform,
    this.onSuccess,
    this.onCancel,
  });

  @override
  State<OAuthLoginWidget> createState() => _OAuthLoginWidgetState();
}

class _OAuthLoginWidgetState extends State<OAuthLoginWidget> {
  final _instanceController = TextEditingController();
  final _authCodeController = TextEditingController();
  final _accountNameController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;
  String? _clientId;
  String? _clientSecret;
  String? _authUrl;
  bool _showCodeInput = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill Bluesky URL since it's typically the same for all users
    if (widget.platform == PlatformType.bluesky) {
      _instanceController.text = 'https://bsky.social';
    }
    
    // Add listeners to update button state when text changes
    _instanceController.addListener(_updateButtonState);
    _accountNameController.addListener(_updateButtonState);
    _authCodeController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    // Trigger rebuild to update button enabled state
    setState(() {});
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _instanceController.removeListener(_updateButtonState);
    _accountNameController.removeListener(_updateButtonState);
    _authCodeController.removeListener(_updateButtonState);
    
    _instanceController.dispose();
    _authCodeController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        width: 550, // Increased width for better content display
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getPlatformIcon(),
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add ${_getPlatformName()} Account',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Scrollable content area
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error display
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.onErrorContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Content
                    if (!_showCodeInput) ...[
                      _buildInstanceInput(theme),
                    ] else ...[
                      _buildAuthCodeInput(theme),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  FilledButton(
                    onPressed: _getNextAction(),
                    child: Text(_getNextActionText()),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstanceInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.platform == PlatformType.mastodon 
              ? 'Enter your Mastodon instance URL:'
              : 'Enter your Bluesky server URL (or leave default):',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _instanceController,
          decoration: InputDecoration(
            hintText: widget.platform == PlatformType.mastodon 
                ? 'https://mastodon.social'
                : 'https://bsky.social',
            prefixIcon: const Icon(Icons.public),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        Text(
          'Account Name (optional - will be filled from OAuth):',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _accountNameController,
          decoration: const InputDecoration(
            hintText: 'Leave empty for auto-fill from OAuth',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.platform == PlatformType.mastodon
                      ? 'We\'ll open your browser to authorize the app. You\'ll need to copy the authorization code back here.'
                      : 'We\'ll guide you through the Bluesky OAuth process.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthCodeInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.launch,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Browser opened for authorization',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Copy the authorization code from your browser and paste it below.',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => _openAuthUrl(),
                child: const Text('Reopen Browser'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Authorization Code:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _authCodeController,
          decoration: const InputDecoration(
            hintText: 'Paste authorization code here',
            prefixIcon: Icon(Icons.key),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  IconData _getPlatformIcon() {
    switch (widget.platform) {
      case PlatformType.mastodon:
        return Icons.people;
      case PlatformType.bluesky:
        return Icons.cloud;
      default:
        return Icons.account_circle;
    }
  }

  String _getPlatformName() {
    switch (widget.platform) {
      case PlatformType.mastodon:
        return 'Mastodon';
      case PlatformType.bluesky:
        return 'Bluesky';
      default:
        return 'Platform';
    }
  }

  VoidCallback? _getNextAction() {
    if (_isLoading) return null;
    
    if (!_showCodeInput) {
      return _canStartAuth() ? _startOAuthFlow : null;
    } else {
      return _authCodeController.text.isNotEmpty ? _completeOAuth : null;
    }
  }

  String _getNextActionText() {
    if (!_showCodeInput) {
      return 'Start Authorization';
    } else {
      return 'Complete Setup';
    }
  }

  bool _canStartAuth() {
    // For OAuth flow, we only need the instance URL
    // Account name can be optional and filled later from OAuth response
    return _instanceController.text.isNotEmpty;
  }

  Future<void> _startOAuthFlow() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.platform == PlatformType.mastodon) {
        await _startMastodonOAuth();
      } else {
        throw Exception('OAuth not supported for ${widget.platform.displayName}');
      }

      setState(() {
        _showCodeInput = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startMastodonOAuth() async {
    final service = MastodonService();
    final instanceUrl = _instanceController.text.trim();
    
    // Create OAuth app
    final credentials = await service.createOAuthApp(
      instanceUrl: instanceUrl,
      appName: 'Yall - Social Media Poster',
      website: 'https://github.com/PlebOne/yall',
      scopes: ['read', 'write'],
    );
    
    _clientId = credentials['client_id'];
    _clientSecret = credentials['client_secret'];
    
    // Get authorization URL
    _authUrl = service.getAuthorizationUrl(
      instanceUrl: instanceUrl,
      clientId: _clientId!,
      scopes: ['read', 'write'],
    );
    
    // Open browser
    await _openAuthUrl();
  }

  Future<void> _openAuthUrl() async {
    if (_authUrl != null) {
      final uri = Uri.parse(_authUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy URL to clipboard
        await Clipboard.setData(ClipboardData(text: _authUrl!));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authorization URL copied to clipboard'),
            ),
          );
        }
      }
    }
  }

  Future<void> _completeOAuth() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.platform == PlatformType.mastodon) {
        await _completeMastodonOAuth();
      }
      
      // Close the dialog first
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Then call success callback
      widget.onSuccess?.call();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeMastodonOAuth() async {
    final service = MastodonService();
    final instanceUrl = _instanceController.text.trim();
    final authCode = _authCodeController.text.trim();
    
    // Exchange code for token
    final tokenData = await service.exchangeCodeForToken(
      instanceUrl: instanceUrl,
      clientId: _clientId!,
      clientSecret: _clientSecret!,
      authorizationCode: authCode,
    );
    
    // Create account
    final displayName = _accountNameController.text.trim().isNotEmpty 
        ? _accountNameController.text.trim()
        : 'Mastodon Account'; // Default name, will be updated with user info
    
    final account = await context.read<AccountManager>().addAccount(
      platform: PlatformType.mastodon,
      displayName: displayName,
      username: '', // Will be filled from user info
      credentials: {
        'instance_url': instanceUrl,
        'access_token': tokenData['access_token']!,
        'client_id': _clientId!,
        'client_secret': _clientSecret!,
        if (tokenData.containsKey('refresh_token'))
          'refresh_token': tokenData['refresh_token']!,
      },
    );
    
    // Get user info to update username and display name
    try {
      final userInfo = await service.getUserInfo(account);
      final username = userInfo['username'] ?? userInfo['acct'] ?? '';
      final realDisplayName = userInfo['display_name'] ?? userInfo['username'] ?? displayName;
      
      // Update account with real user info
      if (mounted) {
        final updatedAccount = account.copyWith(
          username: username.isNotEmpty ? username : account.username,
          displayName: realDisplayName.isNotEmpty ? realDisplayName : account.displayName,
        );
        await context.read<AccountManager>().updateAccount(updatedAccount);
      }
    } catch (e) {
      // Continue without username if we can't get user info
    }
  }
}
