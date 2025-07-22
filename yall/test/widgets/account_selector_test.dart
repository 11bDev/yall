import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:yall/models/account.dart';
import 'package:yall/models/platform_type.dart';
import 'package:yall/providers/account_manager.dart';
import 'package:yall/widgets/account_selector.dart';

import '../providers/account_manager_test.mocks.dart';

void main() {
  group('AccountSelector', () {
    late MockAccountManager mockAccountManager;
    late List<Account> testAccounts;

    setUp(() {
      mockAccountManager = MockAccountManager();
      testAccounts = [
        Account(
          id: '1',
          platform: PlatformType.mastodon,
          displayName: 'John Doe',
          username: 'johndoe',
          createdAt: DateTime.now(),
          isActive: true,
        ),
        Account(
          id: '2',
          platform: PlatformType.mastodon,
          displayName: 'Jane Smith',
          username: 'janesmith',
          createdAt: DateTime.now(),
          isActive: true,
        ),
        Account(
          id: '3',
          platform: PlatformType.mastodon,
          displayName: 'Inactive User',
          username: 'inactive',
          createdAt: DateTime.now(),
          isActive: false,
        ),
      ];
    });

    Widget createTestWidget({
      PlatformType platform = PlatformType.mastodon,
      Account? selectedAccount,
      void Function(Account?)? onAccountSelected,
      void Function()? onAddAccount,
      bool enabled = true,
      bool showAddAccountOption = true,
      String? hintText,
      double? width,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<AccountManager>.value(
            value: mockAccountManager,
            child: AccountSelector(
              platform: platform,
              selectedAccount: selectedAccount,
              onAccountSelected: onAccountSelected ?? (account) {},
              onAddAccount: onAddAccount,
              enabled: enabled,
              showAddAccountOption: showAddAccountOption,
              hintText: hintText,
              width: width,
            ),
          ),
        ),
      );
    }

    testWidgets('displays accounts for the specified platform', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn(testAccounts.where((a) => a.isActive).toList());

      await tester.pumpWidget(createTestWidget());

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<Account?>));
      await tester.pumpAndSettle();

      // Verify that active accounts are displayed
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Inactive User'), findsNothing);
    });

    testWidgets('displays account usernames when available', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccounts.first]);

      await tester.pumpWidget(createTestWidget());

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<Account?>));
      await tester.pumpAndSettle();

      // Verify that username is displayed
      expect(find.text('@johndoe'), findsOneWidget);
    });

    testWidgets('calls onAccountSelected when account is selected', (tester) async {
      Account? selectedAccount;
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccounts.first]);

      await tester.pumpWidget(createTestWidget(
        onAccountSelected: (account) => selectedAccount = account,
      ));

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<Account?>));
      await tester.pumpAndSettle();

      // Select the first account
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      expect(selectedAccount, equals(testAccounts.first));
    });

    testWidgets('displays "Add Account" option when enabled', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccounts.first]);

      await tester.pumpWidget(createTestWidget(
        onAddAccount: () {},
      ));

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<Account?>));
      await tester.pumpAndSettle();

      // Verify "Add Account" option is displayed
      expect(find.text('Add Mastodon Account'), findsWidgets);
      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets('calls onAddAccount when "Add Account" is selected', (tester) async {
      bool addAccountCalled = false;
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccounts.first]);

      await tester.pumpWidget(createTestWidget(
        onAddAccount: () => addAccountCalled = true,
      ));

      // Get the dropdown widget and simulate selection change with null value
      final dropdown = tester.widget<DropdownButton<Account?>>(
        find.byType(DropdownButton<Account?>),
      );

      // Simulate selecting the "Add Account" option (null value)
      dropdown.onChanged!(null);
      await tester.pumpAndSettle();

      expect(addAccountCalled, isTrue);
    });

    testWidgets('hides "Add Account" option when showAddAccountOption is false', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccounts.first]);

      await tester.pumpWidget(createTestWidget(
        showAddAccountOption: false,
        onAddAccount: () {},
      ));

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<Account?>));
      await tester.pumpAndSettle();

      // Verify "Add Account" option is not displayed
      expect(find.text('Add Mastodon Account'), findsNothing);
    });

    testWidgets('displays custom hint text when provided', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccounts.first]);

      await tester.pumpWidget(createTestWidget(
        hintText: 'Choose your account',
      ));

      expect(find.text('Choose your account'), findsOneWidget);
    });

    testWidgets('displays default hint text when none provided', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccounts.first]);

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Select account'), findsOneWidget);
    });

    testWidgets('is disabled when enabled is false', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccounts.first]);

      await tester.pumpWidget(createTestWidget(
        enabled: false,
      ));

      final dropdown = tester.widget<DropdownButton<Account?>>(
        find.byType(DropdownButton<Account?>),
      );
      expect(dropdown.onChanged, isNull);
    });

    testWidgets('handles empty account list gracefully', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([]);

      await tester.pumpWidget(createTestWidget(
        showAddAccountOption: false,
      ));

      expect(find.text('No accounts available'), findsOneWidget);

      final dropdowns = find.byType(DropdownButton<Account?>);
      if (dropdowns.evaluate().isNotEmpty) {
        final dropdown = tester.widget<DropdownButton<Account?>>(dropdowns.first);
        expect(dropdown.onChanged, isNull);
      }
    });

    testWidgets('shows "Add Account" option when no accounts exist', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([]);

      await tester.pumpWidget(createTestWidget(
        onAddAccount: () {},
      ));

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<Account?>));
      await tester.pumpAndSettle();

      expect(find.text('Add Mastodon Account'), findsWidgets);
    });

    testWidgets('displays selected account correctly', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn(testAccounts.where((a) => a.isActive).toList());

      await tester.pumpWidget(createTestWidget(
        selectedAccount: testAccounts.first,
      ));

      // The selected account should be displayed in the dropdown button
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('applies custom width when provided', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccounts.first]);

      await tester.pumpWidget(createTestWidget(
        width: 300,
      ));

      final sizedBox = find.ancestor(
        of: find.byType(DropdownButton<Account?>),
        matching: find.byType(SizedBox),
      );

      expect(sizedBox, findsOneWidget);
      final sizedBoxWidget = tester.widget<SizedBox>(sizedBox);
      expect(sizedBoxWidget.width, equals(300));
    });

    testWidgets('shows account status indicators', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccounts.first]);

      await tester.pumpWidget(createTestWidget());

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<Account?>));
      await tester.pumpAndSettle();

      // Verify status indicator container is present
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('CompactAccountSelector', () {
    late MockAccountManager mockAccountManager;
    late List<Account> testAccounts;

    setUp(() {
      mockAccountManager = MockAccountManager();
      testAccounts = [
        Account(
          id: '1',
          platform: PlatformType.mastodon,
          displayName: 'John Doe',
          username: 'johndoe',
          createdAt: DateTime.now(),
          isActive: true,
        ),
        Account(
          id: '2',
          platform: PlatformType.mastodon,
          displayName: 'Jane Smith',
          username: 'janesmith',
          createdAt: DateTime.now(),
          isActive: true,
        ),
      ];
    });

    Widget createCompactTestWidget({
      PlatformType platform = PlatformType.mastodon,
      Account? selectedAccount,
      void Function(Account?)? onAccountSelected,
      void Function()? onAddAccount,
      bool enabled = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<AccountManager>.value(
            value: mockAccountManager,
            child: CompactAccountSelector(
              platform: platform,
              selectedAccount: selectedAccount,
              onAccountSelected: onAccountSelected ?? (account) {},
              onAddAccount: onAddAccount,
              enabled: enabled,
            ),
          ),
        ),
      );
    }

    testWidgets('displays compact dropdown with accounts', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn(testAccounts);

      await tester.pumpWidget(createCompactTestWidget());

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<Account>));
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('shows no accounts state when no accounts exist', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([]);

      await tester.pumpWidget(createCompactTestWidget());

      expect(find.text('No accounts'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('shows add button in no accounts state when callback provided', (tester) async {
      bool addAccountCalled = false;
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([]);

      await tester.pumpWidget(createCompactTestWidget(
        onAddAccount: () => addAccountCalled = true,
      ));

      expect(find.text('Add'), findsOneWidget);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(addAccountCalled, isTrue);
    });

    testWidgets('auto-selects single account when none selected', (tester) async {
      Account? selectedAccount;
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccounts.first]);

      await tester.pumpWidget(createCompactTestWidget(
        onAccountSelected: (account) => selectedAccount = account,
      ));

      await tester.pumpAndSettle();

      expect(selectedAccount, equals(testAccounts.first));
    });

    testWidgets('calls onAccountSelected when account is selected', (tester) async {
      Account? selectedAccount;
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn(testAccounts);

      await tester.pumpWidget(createCompactTestWidget(
        onAccountSelected: (account) => selectedAccount = account,
      ));

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<Account>));
      await tester.pumpAndSettle();

      // Select the second account
      await tester.tap(find.text('Jane Smith'));
      await tester.pumpAndSettle();

      expect(selectedAccount, equals(testAccounts[1]));
    });

    testWidgets('is disabled when enabled is false', (tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn(testAccounts);

      await tester.pumpWidget(createCompactTestWidget(
        enabled: false,
      ));

      final dropdown = tester.widget<DropdownButton<Account>>(
        find.byType(DropdownButton<Account>),
      );
      expect(dropdown.onChanged, isNull);
    });
  });

  group('AccountSelectorValidation Extension', () {
    testWidgets('hasValidSelection returns true when account is selected', (tester) async {
      final mockAccountManager = MockAccountManager();
      final testAccount = Account(
        id: '1',
        platform: PlatformType.mastodon,
        displayName: 'John Doe',
        username: 'johndoe',
        createdAt: DateTime.now(),
        isActive: true,
      );

      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccount]);

      final selector = AccountSelector(
        platform: PlatformType.mastodon,
        selectedAccount: testAccount,
        onAccountSelected: (account) {},
      );

      expect(selector.hasValidSelection, isTrue);
    });

    testWidgets('hasValidSelection returns false when no account is selected', (tester) async {
      final selector = AccountSelector(
        platform: PlatformType.mastodon,
        selectedAccount: null,
        onAccountSelected: (account) {},
      );

      expect(selector.hasValidSelection, isFalse);
    });

    testWidgets('validationMessage returns correct message when no account selected', (tester) async {
      final selector = AccountSelector(
        platform: PlatformType.mastodon,
        selectedAccount: null,
        onAccountSelected: (account) {},
      );

      expect(selector.validationMessage, equals('Please select an account for Mastodon'));
    });

    testWidgets('validationMessage returns null when account is selected', (tester) async {
      final testAccount = Account(
        id: '1',
        platform: PlatformType.mastodon,
        displayName: 'John Doe',
        username: 'johndoe',
        createdAt: DateTime.now(),
        isActive: true,
      );

      final selector = AccountSelector(
        platform: PlatformType.mastodon,
        selectedAccount: testAccount,
        onAccountSelected: (account) {},
      );

      expect(selector.validationMessage, isNull);
    });
  });
}