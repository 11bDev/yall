# Multi-Account Posting Feature

## Overview

The multi-account posting feature allows users to post to multiple accounts of the same platform type simultaneously. For example, users can now post to two different Nostr accounts or multiple Mastodon accounts at once.

## Implementation Details

### Core Changes

1. **Data Structure Change**: 
   - Changed from `Map<PlatformType, Account?>` to `Map<PlatformType, List<Account>>`
   - This allows storing multiple accounts per platform instead of just one

2. **New PostManager Method**:
   - Added `publishToMultipleAccounts()` method that accepts the new data structure
   - Existing `publishToSelectedPlatforms()` method maintained for backward compatibility
   - Multiple accounts per platform are processed in parallel for efficiency

3. **Updated UI Components**:
   - Created `MultiAccountPlatformSelector` widget
   - Shows checkboxes for each available account when a platform is selected
   - Displays account information (display name and username)
   - Visual indicators for account availability

### Key Files Modified

- `lib/providers/post_manager.dart` - Added multi-account posting logic
- `lib/widgets/posting_widget.dart` - Updated to use new data structure and UI
- `lib/widgets/multi_account_platform_selector.dart` - New widget for account selection
- `test/providers/multi_account_post_manager_test.dart` - Tests for new functionality

### User Experience

1. **Platform Selection**: Users select platforms as before
2. **Account Selection**: When a platform is selected, users see a list of available accounts with checkboxes
3. **Multi-Account Posting**: Users can select multiple accounts per platform
4. **Validation**: The system validates that at least one account is selected per platform
5. **Progress Tracking**: Individual posting progress is tracked for each account

### Example Usage

```dart
// Select platforms
final selectedPlatforms = {PlatformType.nostr, PlatformType.mastodon};

// Select multiple accounts per platform
final selectedAccounts = {
  PlatformType.nostr: [nostrAccount1, nostrAccount2],
  PlatformType.mastodon: [mastodonAccount1],
};

// Post to all selected accounts
final result = await postManager.publishToMultipleAccounts(
  postData,
  selectedPlatforms,
  selectedAccounts,
);
```

### Error Handling

- Individual account failures don't prevent posting to other accounts
- Comprehensive error reporting shows which accounts succeeded/failed
- Validation ensures:
  - Each platform has at least one selected account
  - All accounts belong to the correct platform
  - All accounts are active

### Backward Compatibility

The existing `publishToSelectedPlatforms()` method is preserved and internally converts single accounts to lists, maintaining compatibility with existing code.

### Future Enhancements

- Account grouping/favorites for easier selection
- Per-account posting schedules
- Account-specific content modifications
- Bulk account management features
