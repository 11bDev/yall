import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:yall/models/platform_type.dart';
import 'package:yall/models/account.dart';
import 'package:yall/providers/account_manager.dart';
import 'package:yall/widgets/platform_selector.dart';
import 'package:yall/widgets/account_selector.dart';

import '../providers/account_manager_test.mocks.dart';

void main() {
  group('PlatformSelector Widget Tests', () {
    late MockAccountManager mockAccountManager;
    late Set<PlatformType> selectedPlatforms;
    late Map<PlatformType, Account?> selectedAccounts;
    late List<PlatformType> toggledPlatforms;
    late List<MapEntry<PlatformType, Account?>> selectedAccountChanges;

    // Test accounts
    final mastodonAccount1 = Account(
      id: 'mastodon-1',
      platform: PlatformType.mastodon,
      displayName: 'Mastodon User 1',
      username: 'user1',
      createdAt: DateTime.now(),
      isActive: true,
      credentials: {'token': 'test-token-1'},
    );

    final mastodonAccount2 = Account(
      id: 'mastodon-2',
      platform: PlatformType.mastodon,
      displayName: 'Mastodon User 2',
      username: 'user2',
      createdAt: DateTime.now(),
      isActive: true,
      credentials: {'token': 'test-token-2'},
    );

    final blueskyAccount = Account(
      id: 'bluesky-1',
      platform: PlatformType.bluesky,
      displayName: 'Bluesky User',
      username: 'bluesky.user',
      createdAt: DateTime.now(),
      isActive: true,
      credentials: {'handle': 'bluesky.user', 'password': 'test-pass'},
    );

    setUp(() {
      mockAccountManager = MockAccountManager();
      selectedPlatforms = <PlatformType>{};
      selectedAccounts = <PlatformType, Account?>{};
      toggledPlatforms = [];
      selectedAccountChanges = [];

      // Default mock behavior - no accounts
      when(mockAccountManager.getActiveAccountsForPlatform(any))
          .thenReturn([]);
    });

    Widget createTestWidget({
      bool enabled = true,
      bool showAccountSelection = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<AccountManager>.value(
            value: mockAccountManager,
            child: PlatformSelector(
              selectedPlatforms: selectedPlatforms,
              selectedAccounts: selectedAccounts,
              onPlatformToggled: (platform, selected) {
                toggledPlatforms.add(platform);
                if (selected) {
                  selectedPlatforms.add(platform);
                } else {
                  selectedPlatforms.remove(platform);
                  selectedAccounts.remove(platform);
                }
              },
              onAccountSelected: (platform, account) {
                selectedAccountChanges.add(MapEntry(platform, account));
                selectedAccounts[platform] = account;
              },
              enabled: enabled,
              showAccountSelection: showAccountSelection,
            ),
          ),
        ),
      );
    }

    testWidgets('displays all platform types with checkboxes', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify all platforms are displayed
      expect(find.text('Mastodon'), findsOneWidget);
      expect(find.text('Bluesky'), findsOneWidget);
      expect(find.text('Nostr'), findsOneWidget);

      // Verify checkboxes are present
      expect(find.byType(Checkbox), findsNWidgets(3));

      // Verify all checkboxes are unchecked initially
      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      for (final checkbox in checkboxes) {
        expect(checkbox.value, false);
      }
    });

    testWidgets('shows "No accounts configured" for platforms without accounts', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should show "No accounts configured" for all platforms
      expect(find.text('No accounts configured'), findsNWidgets(3));

      // Checkboxes should be disabled
      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      for (final checkbox in checkboxes) {
        expect(checkbox.onChanged, isNull);
      }
    });

    testWidgets('shows account availability indicators', (tester) async {
      // Setup accounts for Mastodon only
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([mastodonAccount1]);

      await tester.pumpWidget(createTestWidget());

      // Find all availability indicator circles
      final indicators = find.byWidgetPredicate(
        (widget) => widget is Container &&
                    widget.decoration is BoxDecoration &&
                    (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      );

      expect(indicators, findsNWidgets(3)); // One for each platform
    });

    testWidgets('enables checkbox when accounts are available', (tester) async {
      // Setup accounts for Mastodon
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([mastodonAccount1]);

      await tester.pumpWidget(createTestWidget());

      // Find Mastodon checkbox
      final mastodonCheckbox = find.byWidgetPredicate(
        (widget) => widget is Checkbox && widget.onChanged != null,
      );

      expect(mastodonCheckbox, findsOneWidget);

      // Tap the checkbox
      await tester.tap(mastodonCheckbox);
      await tester.pump();

      // Verify callback was called
      expect(toggledPlatforms, contains(PlatformType.mastodon));
    });

    testWidgets('shows account count information', (tester) async {
      // Setup single account for Mastodon
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([mastodonAccount1]);

      // Setup multiple accounts for Bluesky
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.bluesky))
          .thenReturn([blueskyAccount]);

      await tester.pumpWidget(createTestWidget());

      expect(find.text('1 account available'), findsNWidgets(2)); // Both Mastodon and Bluesky have 1 account
    });

    testWidgets('shows account dropdown when platform is selected', (tester) async {
      // Setup accounts for Mastodon
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([mastodonAccount1, mastodonAccount2]);

      // Pre-select Mastodon platform
      selectedPlatforms.add(PlatformType.mastodon);

      await tester.pumpWidget(createTestWidget());

      // Should show dropdown for selected platform
      expect(find.byType(DropdownButton<Account?>), findsOneWidget);
      // Should show AccountSelector widget
      expect(find.byType(AccountSelector), findsOneWidget);
    });

    testWidgets('account dropdown shows all available accounts', (tester) async {
      // Setup multiple accounts for Mastodon
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([mastodonAccount1, mastodonAccount2]);

      selectedPlatforms.add(PlatformType.mastodon);

      await tester.pumpWidget(createTestWidget());

      // Tap dropdown to open it
      await tester.tap(find.byType(DropdownButton<Account?>));
      await tester.pumpAndSettle();

      // Should show both accounts
      expect(find.text('Mastodon User 1'), findsOneWidget);
      expect(find.text('Mastodon User 2'), findsOneWidget);
    });

    testWidgets('selecting account triggers callback', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([mastodonAccount1, mastodonAccount2]);

      selectedPlatforms.add(PlatformType.mastodon);

      await tester.pumpWidget(createTestWidget());

      // Open dropdown and select account
      await tester.tap(find.byType(DropdownButton<Account?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mastodon User 1').last);
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(selectedAccountChanges, hasLength(1));
      expect(selectedAccountChanges.first.key, PlatformType.mastodon);
      expect(selectedAccountChanges.first.value, mastodonAccount1);
    });

    testWidgets('shows username in account dropdown items', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([mastodonAccount1]);

      selectedPlatforms.add(PlatformType.mastodon);

      await tester.pumpWidget(createTestWidget());

      // Open dropdown
      await tester.tap(find.byType(DropdownButton<Account?>));
      await tester.pumpAndSettle();

      // Should show username
      expect(find.text('@user1'), findsOneWidget);
    });

    testWidgets('hides account dropdown when showAccountSelection is false', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([mastodonAccount1]);

      selectedPlatforms.add(PlatformType.mastodon);

      await tester.pumpWidget(createTestWidget(showAccountSelection: false));

      // Should not show dropdown
      expect(find.byType(DropdownButton<Account?>), findsNothing);
    });

    testWidgets('disables all interactions when enabled is false', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([mastodonAccount1]);

      await tester.pumpWidget(createTestWidget(enabled: false));

      // All checkboxes should be disabled
      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      for (final checkbox in checkboxes) {
        expect(checkbox.onChanged, isNull);
      }
    });

    testWidgets('shows warning when no platforms are selected', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Please select at least one platform'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('hides warning when platforms are selected', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([mastodonAccount1]);

      selectedPlatforms.add(PlatformType.mastodon);

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Please select at least one platform'), findsNothing);
    });

    testWidgets('platform selection updates visual state', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([mastodonAccount1]);

      await tester.pumpWidget(createTestWidget());

      // Initially not selected
      final initialText = tester.widget<Text>(find.text('Mastodon'));
      expect(initialText.style?.fontWeight, isNot(FontWeight.w500));

      // Select platform
      selectedPlatforms.add(PlatformType.mastodon);
      await tester.pumpWidget(createTestWidget());

      // Should show as selected with bold text
      final selectedText = tester.widget<Text>(find.text('Mastodon'));
      expect(selectedText.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('multiple platforms can be selected simultaneously', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([mastodonAccount1]);
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.bluesky))
          .thenReturn([blueskyAccount]);

      selectedPlatforms.addAll([PlatformType.mastodon, PlatformType.bluesky]);

      await tester.pumpWidget(createTestWidget());

      // Should show dropdowns for both selected platforms
      expect(find.byType(DropdownButton<Account?>), findsNWidgets(2));
    });

    group('PlatformSelectorValidation Extension Tests', () {
      testWidgets('isValidSelection returns false when no platforms selected', (tester) async {
        final selector = PlatformSelector(
          selectedPlatforms: {},
          selectedAccounts: {},
          onPlatformToggled: (_, __) {},
          onAccountSelected: (_, __) {},
        );

        expect(selector.isValidSelection, false);
      });

      testWidgets('isValidSelection returns false when platform has no account', (tester) async {
        final selector = PlatformSelector(
          selectedPlatforms: {PlatformType.mastodon},
          selectedAccounts: {PlatformType.mastodon: null},
          onPlatformToggled: (_, __) {},
          onAccountSelected: (_, __) {},
        );

        expect(selector.isValidSelection, false);
      });

      testWidgets('isValidSelection returns true when all platforms have accounts', (tester) async {
        final selector = PlatformSelector(
          selectedPlatforms: {PlatformType.mastodon},
          selectedAccounts: {PlatformType.mastodon: mastodonAccount1},
          onPlatformToggled: (_, __) {},
          onAccountSelected: (_, __) {},
        );

        expect(selector.isValidSelection, true);
      });

      testWidgets('platformsWithoutAccounts returns correct platforms', (tester) async {
        final selector = PlatformSelector(
          selectedPlatforms: {PlatformType.mastodon, PlatformType.bluesky},
          selectedAccounts: {
            PlatformType.mastodon: mastodonAccount1,
            PlatformType.bluesky: null,
          },
          onPlatformToggled: (_, __) {},
          onAccountSelected: (_, __) {},
        );

        expect(selector.platformsWithoutAccounts, {PlatformType.bluesky});
      });

      testWidgets('validationMessage returns correct messages', (tester) async {
        // No platforms selected
        var selector = PlatformSelector(
          selectedPlatforms: {},
          selectedAccounts: {},
          onPlatformToggled: (_, __) {},
          onAccountSelected: (_, __) {},
        );
        expect(selector.validationMessage, 'Please select at least one platform');

        // Platform without account
        selector = PlatformSelector(
          selectedPlatforms: {PlatformType.mastodon},
          selectedAccounts: {PlatformType.mastodon: null},
          onPlatformToggled: (_, __) {},
          onAccountSelected: (_, __) {},
        );
        expect(selector.validationMessage, 'Please select accounts for: Mastodon');

        // Valid selection
        selector = PlatformSelector(
          selectedPlatforms: {PlatformType.mastodon},
          selectedAccounts: {PlatformType.mastodon: mastodonAccount1},
          onPlatformToggled: (_, __) {},
          onAccountSelected: (_, __) {},
        );
        expect(selector.validationMessage, null);
      });
    });
  });
}