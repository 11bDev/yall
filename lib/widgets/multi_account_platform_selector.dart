import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/platform_type.dart';
import '../models/account.dart';
import '../providers/account_manager.dart';

/// Callback function for platform selection changes
typedef PlatformSelectionCallback =
    void Function(PlatformType platform, bool selected);

/// Callback function for account toggle changes (when multiple accounts are supported)
typedef AccountToggleCallback =
    void Function(PlatformType platform, Account account, bool selected);

/// Widget for selecting social media platforms and multiple accounts per platform
class MultiAccountPlatformSelector extends StatefulWidget {
  /// Set of currently selected platforms
  final Set<PlatformType> selectedPlatforms;

  /// Map of selected accounts for each platform (multiple accounts per platform)
  final Map<PlatformType, List<Account>> selectedAccounts;

  /// Callback when platform selection changes
  final PlatformSelectionCallback onPlatformToggled;

  /// Callback when account selection changes
  final AccountToggleCallback onAccountToggled;

  /// Whether the selector should be enabled
  final bool enabled;

  /// Whether to show account selection for selected platforms
  final bool showAccountSelection;

  /// Whether the selector should be initially expanded
  final bool initiallyExpanded;

  const MultiAccountPlatformSelector({
    super.key,
    required this.selectedPlatforms,
    required this.selectedAccounts,
    required this.onPlatformToggled,
    required this.onAccountToggled,
    this.enabled = true,
    this.showAccountSelection = true,
    this.initiallyExpanded = false,
  });

  @override
  State<MultiAccountPlatformSelector> createState() =>
      _MultiAccountPlatformSelectorState();
}

class _MultiAccountPlatformSelectorState
    extends State<MultiAccountPlatformSelector> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AccountManager>(
      builder: (context, accountManager, child) {
        return Card(
          child: ExpansionTile(
            initiallyExpanded: widget.initiallyExpanded,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Platforms & Accounts',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.selectedPlatforms.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.selectedPlatforms.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...PlatformType.values.map(
                      (platform) =>
                          _buildPlatformRow(context, platform, accountManager),
                    ),
                    if (widget.selectedPlatforms.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_outlined,
                              size: 16,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Please select at least one platform',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlatformRow(
    BuildContext context,
    PlatformType platform,
    AccountManager accountManager,
  ) {
    final isSelected = widget.selectedPlatforms.contains(platform);
    final accounts = accountManager.getActiveAccountsForPlatform(platform);
    final hasAccounts = accounts.isNotEmpty;
    final selectedAccounts = widget.selectedAccounts[platform] ?? [];
    final isEnabled = widget.enabled && hasAccounts;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          Row(
            children: [
              // Platform checkbox
              Checkbox(
                value: isSelected,
                onChanged: isEnabled
                    ? (value) =>
                          widget.onPlatformToggled(platform, value ?? false)
                    : null,
              ),
              const SizedBox(width: 8),

              // Platform info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          platform.displayName,
                          style: TextStyle(
                            color: isEnabled
                                ? null
                                : Theme.of(context).disabledColor,
                            fontWeight: isSelected ? FontWeight.w500 : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildAccountAvailabilityIndicator(
                          context,
                          hasAccounts,
                        ),
                      ],
                    ),
                    if (!hasAccounts)
                      Text(
                        'No accounts configured',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    else if (accounts.length == 1)
                      Text(
                        '1 account available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Text(
                        '${accounts.length} accounts available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Account selection checkboxes when platform is selected
          if (isSelected &&
              widget.showAccountSelection &&
              accounts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(left: 40),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select accounts to post to:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...accounts.map(
                    (account) => _buildAccountRow(
                      context,
                      platform,
                      account,
                      selectedAccounts,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountRow(
    BuildContext context,
    PlatformType platform,
    Account account,
    List<Account> selectedAccounts,
  ) {
    final isSelected = selectedAccounts.contains(account);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: widget.enabled
                ? (value) =>
                      widget.onAccountToggled(platform, account, value ?? false)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w500 : null,
                  ),
                ),
                Text(
                  '@${account.username}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountAvailabilityIndicator(
    BuildContext context,
    bool hasAccounts,
  ) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasAccounts
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
      ),
    );
  }
}
