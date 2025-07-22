import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/platform_type.dart';
import '../models/account.dart';
import '../providers/account_manager.dart';

/// Callback function for account selection changes
typedef AccountSelectionCallback = void Function(Account? account);

/// Callback function for add account action
typedef AddAccountCallback = void Function();

/// Dropdown widget for selecting accounts for a specific platform
class AccountSelector extends StatelessWidget {
  /// The platform type for which to show accounts
  final PlatformType platform;

  /// Currently selected account
  final Account? selectedAccount;

  /// Callback when account selection changes
  final AccountSelectionCallback onAccountSelected;

  /// Callback when "Add Account" is pressed
  final AddAccountCallback? onAddAccount;

  /// Whether the selector should be enabled
  final bool enabled;

  /// Whether to show the "Add Account" option
  final bool showAddAccountOption;

  /// Custom hint text when no account is selected
  final String? hintText;

  /// Width of the dropdown
  final double? width;

  const AccountSelector({
    super.key,
    required this.platform,
    required this.selectedAccount,
    required this.onAccountSelected,
    this.onAddAccount,
    this.enabled = true,
    this.showAddAccountOption = true,
    this.hintText,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountManager>(
      builder: (context, accountManager, child) {
        final accounts = accountManager.getActiveAccountsForPlatform(platform);
        final hasAccounts = accounts.isNotEmpty;

        Widget dropdown = _buildDropdown(context, accounts, hasAccounts);

        if (width != null) {
          dropdown = SizedBox(width: width, child: dropdown);
        }

        return dropdown;
      },
    );
  }

  Widget _buildDropdown(BuildContext context, List<Account> accounts, bool hasAccounts) {
    // If no accounts exist and we can't add accounts, show disabled state
    if (!hasAccounts && !showAddAccountOption) {
      return DropdownButton<Account>(
        value: null,
        isExpanded: true,
        hint: Text(
          'No accounts available',
          style: TextStyle(color: Theme.of(context).disabledColor),
        ),
        items: const [],
        onChanged: null,
      );
    }

    // Build dropdown items
    final List<DropdownMenuItem<Account?>> items = [];

    // Add account items
    for (final account in accounts) {
      items.add(DropdownMenuItem<Account?>(
        value: account,
        child: _buildAccountItem(context, account),
      ));
    }

    // Add "Add Account" option if enabled
    if (showAddAccountOption && onAddAccount != null) {
      items.add(DropdownMenuItem<Account?>(
        value: null,
        child: _buildAddAccountItem(context),
      ));
    }

    return DropdownButton<Account?>(
      value: selectedAccount,
      isExpanded: true,
      hint: Text(hintText ?? 'Select account'),
      items: items,
      onChanged: enabled ? _handleSelectionChange : null,
      underline: Container(
        height: 1,
        color: enabled
            ? Theme.of(context).colorScheme.outline
            : Theme.of(context).disabledColor,
      ),
    );
  }

  Widget _buildAccountItem(BuildContext context, Account account) {
    return Row(
      children: [
        // Account status indicator
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: account.isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ),

        // Account info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                account.displayName,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
              if (account.username.isNotEmpty)
                Text(
                  '@${account.username}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddAccountItem(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.add,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Add ${platform.displayName} Account',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _handleSelectionChange(Account? value) {
    if (value == null && showAddAccountOption && onAddAccount != null) {
      // "Add Account" was selected
      onAddAccount!();
    } else {
      // Regular account was selected
      onAccountSelected(value);
    }
  }
}

/// Compact version of AccountSelector for use in tight spaces
class CompactAccountSelector extends StatelessWidget {
  /// The platform type for which to show accounts
  final PlatformType platform;

  /// Currently selected account
  final Account? selectedAccount;

  /// Callback when account selection changes
  final AccountSelectionCallback onAccountSelected;

  /// Callback when "Add Account" is pressed
  final AddAccountCallback? onAddAccount;

  /// Whether the selector should be enabled
  final bool enabled;

  const CompactAccountSelector({
    super.key,
    required this.platform,
    required this.selectedAccount,
    required this.onAccountSelected,
    this.onAddAccount,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountManager>(
      builder: (context, accountManager, child) {
        final accounts = accountManager.getActiveAccountsForPlatform(platform);
        final hasAccounts = accounts.isNotEmpty;

        if (!hasAccounts) {
          return _buildNoAccountsState(context);
        }

        if (accounts.length == 1 && selectedAccount == null) {
          // Auto-select the only available account
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onAccountSelected(accounts.first);
          });
        }

        return _buildCompactDropdown(context, accounts);
      },
    );
  }

  Widget _buildNoAccountsState(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.warning_amber_outlined,
          size: 16,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 4),
        Text(
          'No accounts',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        if (onAddAccount != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: enabled ? onAddAccount : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Add'),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactDropdown(BuildContext context, List<Account> accounts) {
    return DropdownButton<Account>(
      value: selectedAccount,
      isDense: true,
      underline: const SizedBox.shrink(),
      hint: Text(
        'Select',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      items: accounts.map((account) {
        return DropdownMenuItem<Account>(
          value: account,
          child: Text(
            account.displayName,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: enabled ? onAccountSelected : null,
    );
  }
}

/// Extension to provide validation helpers for AccountSelector
extension AccountSelectorValidation on AccountSelector {
  /// Check if the current selection is valid
  bool get hasValidSelection => selectedAccount != null;

  /// Get validation message for current selection
  String? get validationMessage {
    if (selectedAccount == null) {
      return 'Please select an account for ${platform.displayName}';
    }
    return null;
  }
}