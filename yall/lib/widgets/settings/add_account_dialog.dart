import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/platform_type.dart';
import '../../providers/account_manager.dart';
import '../../services/nostr_service.dart';

/// Dialog for adding a new social media account
class AddAccountDialog extends StatefulWidget {
  final PlatformType platform;
  final VoidCallback? onAccountAdded;

  const AddAccountDialog({
    super.key,
    required this.platform,
    this.onAccountAdded,
  });

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final Map<String, TextEditingController> _credentialControllers = {};
  final TextEditingController _nsecController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _obscurePasswords = true;

  @override
  void initState() {
    super.initState();
    _initializeCredentialFields();
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

  void _initializeCredentialFields() {
    final requiredFields = _getRequiredCredentialFields(widget.platform);
    for (final field in requiredFields) {
      _credentialControllers[field] = TextEditingController();
    }
  }

  List<String> _getRequiredCredentialFields(PlatformType platform) {
    switch (platform) {
      case PlatformType.mastodon:
        return ['instance_url', 'access_token'];
      case PlatformType.bluesky:
        return ['identifier', 'password'];
      case PlatformType.nostr:
        return ['private_key'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(_getPlatformIcon(widget.platform)),
          const SizedBox(width: 12),
          Text('Add ${widget.platform.displayName} Account'),
        ],
      ),
      content: SizedBox(
        width: 400,
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
                _buildBasicFields(),
                const SizedBox(height: 16),
                _buildCredentialFields(),
                const SizedBox(height: 16),
                _buildInstructions(),
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
        ElevatedButton(
          onPressed: _isLoading ? null : _addAccount,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Account'),
        ),
      ],
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
        if (widget.platform != PlatformType.nostr)
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
          )
        else
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username (Optional)',
              hintText: 'Optional display username',
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
      ],
    );
  }

  Widget _buildCredentialFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Authentication', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (widget.platform == PlatformType.nostr) 
          _buildNostrCredentialFields()
        else
          ..._credentialControllers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCredentialField(entry.key, entry.value),
            );
          }),
      ],
    );
  }

  Widget _buildNostrCredentialFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nsec input field
        TextFormField(
          controller: _nsecController,
          decoration: const InputDecoration(
            labelText: 'Private Key (nsec format)',
            hintText: 'nsec1... (recommended)',
            prefixIcon: Icon(Icons.key_outlined),
            helperText: 'Enter your nsec private key - it will be converted to hex automatically',
          ),
          onChanged: (value) {
            if (value.startsWith('nsec')) {
              final hexKey = NostrService.convertNsecToHex(value);
              if (hexKey != null) {
                _credentialControllers['private_key']?.text = hexKey;
              }
            } else {
              _credentialControllers['private_key']?.text = '';
            }
          },
          validator: (value) {
            if (value != null && value.isNotEmpty && !value.startsWith('nsec')) {
              return 'Please enter a valid nsec private key (starts with nsec1...)';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        
        // Hex output field (read-only)
        TextFormField(
          controller: _credentialControllers['private_key'],
          decoration: const InputDecoration(
            labelText: 'Private Key (hex format)',
            hintText: 'Auto-filled from nsec above, or enter hex directly',
            prefixIcon: Icon(Icons.vpn_key),
            helperText: 'This is the actual key used for signing (64 hex characters)',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Private key is required - enter nsec above or hex here';
            }
            if (value.trim().length < 32) {
              return 'Private key too short - should be 64 hex chars';
            }
            return null;
          },
        ),
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
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePasswords ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePasswords = !_obscurePasswords;
                  });
                },
              )
            : null,
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
      case 'instance_url':
        return 'Server URL';
      case 'access_token':
        return 'Access Token';
      case 'identifier':
        return 'Username/Handle';
      case 'password':
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
      case 'instance_url':
        return 'https://mastodon.social';
      case 'access_token':
        return 'Your Mastodon access token';
      case 'identifier':
        return 'your-handle.bsky.social or your-domain.com';
      case 'password':
        return 'Generated app password from Bluesky';
      case 'private_key':
        return 'Your Nostr private key (64 hex chars or nsec1... format)';
      default:
        return 'Enter your ${_getFieldLabel(fieldName).toLowerCase()}';
    }
  }

  IconData _getFieldIcon(String fieldName) {
    switch (fieldName) {
      case 'instance_url':
        return Icons.dns;
      case 'access_token':
      case 'password':
        return Icons.key;
      case 'identifier':
        return Icons.account_circle;
      case 'private_key':
        return Icons.vpn_key;
      default:
        return Icons.text_fields;
    }
  }

  String? _validateCredentialField(String fieldName, String value) {
    switch (fieldName) {
      case 'instance_url':
        final uri = Uri.tryParse(value);
        if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
          return 'Please enter a valid URL (e.g., https://mastodon.social)';
        }
        if (!uri.scheme.startsWith('http')) {
          return 'URL must start with http:// or https://';
        }
        // Check if it looks like a valid domain
        if (!uri.host.contains('.')) {
          return 'Please enter a complete server URL with domain';
        }
        break;
      case 'identifier':
        // Bluesky accepts both handle format (user.bsky.social) and domain format
        if (!value.contains('.') && !value.contains('@')) {
          return 'Enter your handle (user.bsky.social) or domain';
        }
        break;
      case 'private_key':
        if (value.trim().isEmpty) {
          return 'Private key is required';
        }
        // For now, accept any reasonable length private key
        // The service will validate the specific format
        if (value.trim().length < 32) {
          return 'Private key too short - should be 64 hex chars or nsec format';
        }
        break;
    }
    return null;
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Setup Instructions',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getSetupInstructions(widget.platform),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _getSetupInstructions(PlatformType platform) {
    switch (platform) {
      case PlatformType.mastodon:
        return 'To get your access token:\n'
            '1. Go to your Mastodon server\'s settings\n'
            '2. Navigate to Preferences → Development → New Application\n'
            '3. Create an app with "write:statuses" permission\n'
            '4. Copy the access token\n'
            '5. Enter your server URL (e.g., https://mastodon.social)';
      case PlatformType.bluesky:
        return 'To create an app password:\n'
            '1. Go to Settings → Privacy and Security → App Passwords\n'
            '2. Click "Add App Password"\n'
            '3. Generate a new password for this app\n'
            '4. Use your full handle (user.bsky.social) or domain name\n'
            '5. Use the generated password, not your account password';
      case PlatformType.nostr:
        return 'For Nostr setup:\n'
            '1. Use your existing private key (nsec format or hex)\n'
            '2. Your private key is all you need - no username required\n'
            '3. Keep your private key secure and never share it\n'
            '4. Optional: Enter a display username for this account';
    }
  }

  IconData _getPlatformIcon(PlatformType platform) {
    switch (platform) {
      case PlatformType.mastodon:
        return Icons.public;
      case PlatformType.bluesky:
        return Icons.cloud;
      case PlatformType.nostr:
        return Icons.bolt;
    }
  }

  Future<void> _addAccount() async {
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

      // Debug: print what credentials we're saving
      print(
        'Saving credentials for ${widget.platform}: ${credentials.keys.toList()}',
      );
      if (widget.platform == PlatformType.nostr) {
        print(
          'Nostr private_key present: ${credentials.containsKey("private_key")}',
        );
        print(
          'Nostr private_key value length: ${credentials["private_key"]?.length ?? 0}',
        );
      }

      final accountManager = context.read<AccountManager>();
      await accountManager.addAccount(
        platform: widget.platform,
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim().isEmpty
            ? ('${_displayNameController.text.trim()}_${DateTime.now().millisecondsSinceEpoch}')
            : _usernameController.text.trim(),
        credentials: credentials,
      );

      widget.onAccountAdded?.call();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.platform.displayName} account added successfully',
            ),
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
