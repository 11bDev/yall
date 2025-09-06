import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/account.dart';
import '../../models/platform_type.dart';
import '../../providers/account_manager.dart';

/// Dialog for editing an existing social media account
class EditAccountDialog extends StatefulWidget {
  final Account account;
  final VoidCallback? onAccountUpdated;

  const EditAccountDialog({
    super.key,
    required this.account,
    this.onAccountUpdated,
  });

  @override
  State<EditAccountDialog> createState() => _EditAccountDialogState();
}

class _EditAccountDialogState extends State<EditAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  final Map<String, TextEditingController> _credentialControllers = {};
  final TextEditingController _nsecController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _obscurePasswords = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _nsecController.dispose();
    for (final controller in _credentialControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    _displayNameController = TextEditingController(
      text: widget.account.displayName,
    );
    _usernameController = TextEditingController(text: widget.account.username);

    // Initialize credential fields
    final requiredFields = _getRequiredCredentialFields(
      widget.account.platform,
    );
    for (final field in requiredFields) {
      final value = widget.account.getCredential<String>(field) ?? '';
      _credentialControllers[field] = TextEditingController(text: value);
    }

    // Add listeners to detect changes
    _displayNameController.addListener(_onFieldChanged);
    _usernameController.addListener(_onFieldChanged);
    for (final controller in _credentialControllers.values) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  List<String> _getRequiredCredentialFields(PlatformType platform) {
    switch (platform) {
      case PlatformType.mastodon:
        return ['server_url', 'access_token'];
      case PlatformType.bluesky:
        return ['handle', 'app_password'];
      case PlatformType.nostr:
        return ['private_key'];
      case PlatformType.microblog:
        return ['username', 'app_token'];
      case PlatformType.x:
        return ['access_token', 'access_token_secret', 'api_key', 'api_secret'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(_getPlatformIcon(widget.account.platform)),
          const SizedBox(width: 12),
          Text('Edit ${widget.account.platform.displayName} Account'),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 500, // Add max height to prevent overflow
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildAccountInfo(),
                const SizedBox(height: 16),
                _buildBasicFields(),
                const SizedBox(height: 16),
                _buildCredentialFields(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_hasChanges) ...[
          OutlinedButton(
            onPressed: _isLoading ? null : _testConnection,
            child: const Text('Test Connection'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _updateAccount,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Changes'),
          ),
        ] else ...[
          OutlinedButton(
            onPressed: _isLoading ? null : _testConnection,
            child: const Text('Test Connection'),
          ),
        ],
      ],
    );
  }

  Widget _buildAccountInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Platform: ', style: Theme.of(context).textTheme.bodySmall),
              Text(
                widget.account.platform.displayName,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Created: ', style: Theme.of(context).textTheme.bodySmall),
              Text(
                _formatDate(widget.account.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Status: ', style: Theme.of(context).textTheme.bodySmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.account.isActive ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.account.isActive ? 'Active' : 'Inactive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _displayNameController,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'How you want this account to appear',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Display name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'Your username on the platform',
            prefixIcon: Icon(Icons.alternate_email),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Username is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCredentialFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Authentication',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _obscurePasswords = !_obscurePasswords;
                });
              },
              icon: Icon(
                _obscurePasswords ? Icons.visibility : Icons.visibility_off,
                size: 16,
              ),
              label: Text(
                _obscurePasswords ? 'Show' : 'Hide',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._credentialControllers.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCredentialField(entry.key, entry.value),
          );
        }),
      ],
    );
  }

  Widget _buildCredentialField(
    String fieldName,
    TextEditingController controller,
  ) {
    final isPassword =
        fieldName.contains('password') ||
        fieldName.contains('token') ||
        fieldName.contains('key');

    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePasswords,
      decoration: InputDecoration(
        labelText: _getFieldLabel(fieldName),
        hintText: _getFieldHint(fieldName),
        prefixIcon: Icon(_getFieldIcon(fieldName)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '${_getFieldLabel(fieldName)} is required';
        }
        return _validateCredentialField(fieldName, value);
      },
    );
  }

  String _getFieldLabel(String fieldName) {
    switch (fieldName) {
      case 'server_url':
        return 'Server URL';
      case 'access_token':
        return 'Access Token';
      case 'access_token_secret':
        return 'Access Token Secret';
      case 'api_key':
        return 'API Key (Consumer Key)';
      case 'api_secret':
        return 'API Secret (Consumer Secret)';
      case 'handle':
        return 'Handle';
      case 'app_password':
        return 'App Password';
      case 'private_key':
        return 'Private Key';
      default:
        return fieldName
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  String _getFieldHint(String fieldName) {
    switch (fieldName) {
      case 'server_url':
        return 'https://mastodon.social';
      case 'access_token':
        return 'Your access token from X developer portal';
      case 'access_token_secret':
        return 'Your access token secret from X developer portal';
      case 'api_key':
        return 'Your API key from X developer portal';
      case 'api_secret':
        return 'Your API secret from X developer portal';
      case 'handle':
        return 'your-handle.bsky.social';
      case 'app_password':
        return 'Generated app password from Bluesky';
      case 'private_key':
        return 'Your Nostr private key (nsec...)';
      default:
        return 'Enter your ${_getFieldLabel(fieldName).toLowerCase()}';
    }
  }

  IconData _getFieldIcon(String fieldName) {
    switch (fieldName) {
      case 'server_url':
        return Icons.dns;
      case 'access_token':
      case 'access_token_secret':
        return Icons.key;
      case 'api_key':
      case 'api_secret':
        return Icons.api;
      case 'app_password':
        return Icons.key;
      case 'handle':
        return Icons.account_circle;
      case 'private_key':
        return Icons.vpn_key;
      default:
        return Icons.text_fields;
    }
  }

  String? _validateCredentialField(String fieldName, String value) {
    switch (fieldName) {
      case 'server_url':
        final uri = Uri.tryParse(value);
        if (uri == null || !uri.hasAbsolutePath) {
          return 'Please enter a valid URL';
        }
        break;
      case 'handle':
        if (!value.contains('.')) {
          return 'Handle should include domain (e.g., user.bsky.social)';
        }
        break;
      case 'private_key':
        if (!value.startsWith('nsec') && value.length < 32) {
          return 'Private key should be nsec format or hex (32+ chars)';
        }
        break;
    }
    return null;
  }

  IconData _getPlatformIcon(PlatformType platform) {
    switch (platform) {
      case PlatformType.mastodon:
        return Icons.public;
      case PlatformType.bluesky:
        return Icons.cloud;
      case PlatformType.nostr:
        return Icons.bolt;
      case PlatformType.microblog:
        return Icons.rss_feed;
      case PlatformType.x:
        return Icons.close; // X icon placeholder
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Create a temporary account with updated credentials for testing
      final credentials = <String, dynamic>{};
      for (final entry in _credentialControllers.entries) {
        credentials[entry.key] = entry.value.text.trim();
      }

      final tempAccount = widget.account.copyWith(
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim(),
        credentials: credentials,
      );

      final accountManager = context.read<AccountManager>();
      final isValid = await accountManager.validateAccount(tempAccount);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isValid
                  ? 'Connection test successful'
                  : 'Connection test failed - please check your credentials',
            ),
            backgroundColor: isValid ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('AccountManagerException: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final credentials = <String, dynamic>{};
      for (final entry in _credentialControllers.entries) {
        credentials[entry.key] = entry.value.text.trim();
      }

      final updatedAccount = widget.account.copyWith(
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim(),
        credentials: credentials,
      );

      final accountManager = context.read<AccountManager>();
      await accountManager.updateAccount(updatedAccount);

      widget.onAccountUpdated?.call();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('AccountManagerException: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
