import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/account.dart';
import '../../models/platform_type.dart';
import '../../providers/account_manager.dart';
import 'add_account_dialog.dart';
import 'edit_account_dialog.dart';

/// Tab for managing platform accounts in the settings window
class AccountSettingsTab extends StatefulWidget {
  final VoidCallback? onChanged;
  final VoidCallback? onSaved;

  const AccountSettingsTab({super.key, this.onChanged, this.onSaved});

  @override
  State<AccountSettingsTab> createState() => _AccountSettingsTabState();
}

class _AccountSettingsTabState extends State<AccountSettingsTab> {
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountManager>(
      builder: (context, accountManager, child) {
        if (accountManager.isLoading || _isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final error = accountManager.error ?? _error;
        if (error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading accounts',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    accountManager.clearError();
                    _clearError();
                    accountManager.loadAccounts();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              ...PlatformType.values.map(
                (platform) =>
                    _buildPlatformSection(context, platform, accountManager),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Management',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your social media accounts for posting. You can add multiple accounts per platform.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformSection(
    BuildContext context,
    PlatformType platform,
    AccountManager accountManager,
  ) {
    final accounts = accountManager.getAccountsForPlatform(platform);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPlatformIcon(platform),
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        platform.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${accounts.length} account${accounts.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddAccountDialog(context, platform),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Account'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            if (accounts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...accounts.map(
                (account) =>
                    _buildAccountTile(context, account, accountManager),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context,
    Account account,
    AccountManager accountManager,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: account.isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(
            account.displayName.isNotEmpty
                ? account.displayName[0].toUpperCase()
                : account.username[0].toUpperCase(),
            style: TextStyle(
              color: account.isActive
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          account.displayName.isNotEmpty
              ? account.displayName
              : account.username,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: account.isActive
                ? null
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${account.username}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: account.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    account.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      color: account.isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) =>
              _handleAccountAction(context, value, account, accountManager),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: account.isActive ? 'deactivate' : 'activate',
              child: Row(
                children: [
                  Icon(
                    account.isActive ? Icons.pause : Icons.play_arrow,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(account.isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'test',
              child: Row(
                children: [
                  Icon(Icons.wifi_protected_setup, size: 18),
                  SizedBox(width: 8),
                  Text('Test Connection'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  void _showAddAccountDialog(BuildContext context, PlatformType platform) {
    showDialog(
      context: context,
      builder: (context) => AddAccountDialog(
        platform: platform,
        onAccountAdded: () {
          widget.onChanged?.call();
        },
      ),
    );
  }

  void _handleAccountAction(
    BuildContext context,
    String action,
    Account account,
    AccountManager accountManager,
  ) async {
    switch (action) {
      case 'edit':
        _showEditAccountDialog(context, account);
        break;
      case 'activate':
      case 'deactivate':
        await _toggleAccountStatus(account, accountManager);
        break;
      case 'test':
        await _testAccountConnection(context, account, accountManager);
        break;
      case 'delete':
        await _deleteAccount(context, account, accountManager);
        break;
    }
  }

  void _showEditAccountDialog(BuildContext context, Account account) {
    showDialog(
      context: context,
      builder: (context) => EditAccountDialog(
        account: account,
        onAccountUpdated: () {
          widget.onChanged?.call();
        },
      ),
    );
  }

  Future<void> _toggleAccountStatus(
    Account account,
    AccountManager accountManager,
  ) async {
    try {
      setState(() => _isLoading = true);
      await accountManager.setAccountActive(account.id, !account.isActive);
      widget.onChanged?.call();
    } catch (e) {
      _setError('Failed to update account status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testAccountConnection(
    BuildContext context,
    Account account,
    AccountManager accountManager,
  ) async {
    try {
      setState(() => _isLoading = true);
      final isValid = await accountManager.validateAccount(account);

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isValid ? 'Connection test successful' : 'Connection test failed',
            ),
            backgroundColor: isValid ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection test error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAccount(
    BuildContext context,
    Account account,
    AccountManager accountManager,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete the account "${account.displayName}" (@${account.username})?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        setState(() => _isLoading = true);
        await accountManager.removeAccount(account.id);
        widget.onChanged?.call();

        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        _setError('Failed to delete account: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setError(String error) {
    setState(() => _error = error);
  }

  void _clearError() {
    setState(() => _error = null);
  }
}
