import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/platform_type.dart';
import '../models/account.dart';
import '../providers/account_manager.dart';
import 'account_selector.dart';

/// Callback function for platform selection changes
typedef PlatformSelectionCallback = void Function(PlatformType platform, bool selected);

/// Callback function for account selection changes
typedef AccountSelectionCallback = void Function(PlatformType platform, Account? account);

/// Widget for selecting social media platforms and associated accounts
class PlatformSelector extends StatelessWidget {
  /// Set of currently selected platforms
  final Set<PlatformType> selectedPlatforms;

  /// Map of selected accounts for each platform
  final Map<PlatformType, Account?> selectedAccounts;

  /// Callback when platform selection changes
  final PlatformSelectionCallback onPlatformToggled;

  /// Callback when account selection changes
  final AccountSelectionCallback onAccountSelected;

  /// Whether the selector should be enabled
  final bool enabled;

  /// Whether to show account dropdowns for selected platforms
  final bool showAccountSelection;

  const PlatformSelector({
    super.key,
    required this.selectedPlatforms,
    required this.selectedAccounts,
    required this.onPlatformToggled,
    required this.onAccountSelected,
    this.enabled = true,
    this.showAccountSelection = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountManager>(
      builder: (context, accountManager, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Platforms',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...PlatformType.values.map((platform) =>
                  _buildPlatformRow(context, platform, accountManager),
                ),
                if (selectedPlatforms.isEmpty)
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
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
    final isSelected = selectedPlatforms.contains(platform);
    final accounts = accountManager.getActiveAccountsForPlatform(platform);
    final hasAccounts = accounts.isNotEmpty;
    final selectedAccount = selectedAccounts[platform];
    final isEnabled = enabled && hasAccounts;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // Platform checkbox
          Checkbox(
            value: isSelected,
            onChanged: isEnabled
                ? (value) => onPlatformToggled(platform, value ?? false)
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
                        color: isEnabled ? null : Theme.of(context).disabledColor,
                        fontWeight: isSelected ? FontWeight.w500 : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildAccountAvailabilityIndicator(context, hasAccounts),
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

          // Account selection dropdown
          if (isSelected && showAccountSelection) ...[
            const SizedBox(width: 8),
            AccountSelector(
              platform: platform,
              selectedAccount: selectedAccount,
              onAccountSelected: (account) => onAccountSelected(platform, account),
              onAddAccount: () => _handleAddAccount(context, platform),
              enabled: enabled,
              width: 200,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountAvailabilityIndicator(BuildContext context, bool hasAccounts) {
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

  void _handleAddAccount(BuildContext context, PlatformType platform) {
    // TODO: This will be implemented in a future task for settings window
    // For now, show a placeholder dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${platform.displayName} Account'),
        content: const Text('Account management will be available in the settings window.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Extension to provide helper methods for platform selection validation
extension PlatformSelectorValidation on PlatformSelector {
  /// Check if the current selection is valid for posting
  bool get isValidSelection {
    if (selectedPlatforms.isEmpty) return false;

    // Check that all selected platforms have accounts selected
    return selectedPlatforms.every((platform) {
      return selectedAccounts[platform] != null;
    });
  }

  /// Get platforms that are selected but don't have accounts
  Set<PlatformType> get platformsWithoutAccounts {
    return selectedPlatforms.where((platform) {
      return selectedAccounts[platform] == null;
    }).toSet();
  }

  /// Get validation message for current selection
  String? get validationMessage {
    if (selectedPlatforms.isEmpty) {
      return 'Please select at least one platform';
    }

    final platformsWithoutAccounts = this.platformsWithoutAccounts;
    if (platformsWithoutAccounts.isNotEmpty) {
      final platformNames = platformsWithoutAccounts
          .map((p) => p.displayName)
          .join(', ');
      return 'Please select accounts for: $platformNames';
    }

    return null;
  }
}