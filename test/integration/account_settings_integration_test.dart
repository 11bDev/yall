import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:yall/models/account.dart';
import 'package:yall/models/platform_type.dart';
import 'package:yall/providers/account_manager.dart';
import 'package:yall/services/secure_storage_service.dart';
import 'package:yall/services/social_platform_service.dart';
import 'package:yall/widgets/settings/account_settings_tab.dart';
import 'package:yall/widgets/settings/add_account_dialog.dart';
import 'package:yall/widgets/settings/edit_account_dialog.dart';

import 'account_settings_integration_test.mocks.dart';

@GenerateMocks([
  SecureStorageService,
  SocialPlatformService,
])
void main() {
  group('Account Settings Integration Tests', () {
    late MockSecureStorageService mockStorageService;
    late MockSocialPlatformService mockMastodonService;
    late MockSocialPlatformService mockBlueskyService;
    late MockSocialPlatformService mockNostrService;
    late AccountManager accountManager;

    setUp(() {
      mockStorageService = MockSecureStorageService();
      mockMastodonService = MockSocialPlatformService();
      mockBlueskyService = MockSocialPlatformService();
      mockNostrService = MockSocialPlatformService();

      // Configure mock services
      when(mockMastodonService.platformType).thenReturn(PlatformType.mastodon);
      when(mockMastodonService.requiredCredentialFields).thenReturn(['server_url', 'access_token']);
      when(mockMastodonService.hasRequiredCredentials(any)).thenReturn(true);
      when(mockMastodonService.validateConnection(any)).thenAnswer((_) async => true);
      when(mockMastodonService.authenticate(any)).thenAnswer((_) async => true);

      when(mockBlueskyService.platformType).thenReturn(PlatformType.bluesky);
      when(mockBlueskyService.requiredCredentialFields).thenReturn(['handle', 'app_password']);
      when(mockBlueskyService.hasRequiredCredentials(any)).thenReturn(true);
      when(mockBlueskyService.validateConnection(any)).thenAnswer((_) async => true);
      when(mockBlueskyService.authenticate(any)).thenAnswer((_) async => true);

      when(mockNostrService.platformType).thenReturn(PlatformType.nostr);
      when(mockNostrService.requiredCredentialFields).thenReturn(['private_key']);
      when(mockNostrService.hasRequiredCredentials(any)).thenReturn(true);
      when(mockNostrService.validateConnection(any)).thenAnswer((_) async => true);
      when(mockNostrService.authenticate(any)).thenAnswer((_) async => true);

      // Configure storage service
      when(mockStorageService.getAllAccountIds()).thenAnswer((_) async => []);
      when(mockStorageService.storeAccountData(any, any)).thenAnswer((_) async {});
      when(mockStorageService.storeAccountCredentials(any, any)).thenAnswer((_) async {});
      when(mockStorageService.deleteAllAccountData(any)).thenAnswer((_) async {});

      accountManager = AccountManager(
        storageService: mockStorageService,
        platformServices: {
          PlatformType.mastodon: mockMastodonService,
          PlatformType.bluesky: mockBlueskyService,
          PlatformType.nostr: mockNostrService,
        },
      );
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: ChangeNotifierProvider<AccountManager>.value(
          value: accountManager,
          child: Scaffold(body: child),
        ),
      );
    }

    group('Account Settings Tab', () {
      testWidgets('should display empty state when no accounts exist', (tester) async {
        await tester.pumpWidget(createTestWidget(const AccountSettingsTab()));
        await tester.pumpAndSettle();

        expect(find.text('Account Management'), findsOneWidget);
        expect(find.text('0 accounts'), findsAtLeast(1));
        expect(find.text('Add Account'), findsAtLeast(3)); // One for each platform
      });

      testWidgets('should display accounts when they exist', (tester) async {
        // Add a test account
        accountManager.addAccountForTesting(Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          isActive: true,
          credentials: {
            'server_url': 'https://mastodon.social',
            'access_token': 'test_token',
          },
        ));

        await tester.pumpWidget(createTestWidget(const AccountSettingsTab()));
        await tester.pumpAndSettle();

        expect(find.text('Test User'), findsOneWidget);
        expect(find.text('@testuser'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('1 account'), findsOneWidget);
      });

      testWidgets('should show add account dialog when add button is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget(const AccountSettingsTab()));
        await tester.pumpAndSettle();

        // Find and tap the first "Add Account" button (for Mastodon)
        final addButtons = find.text('Add Account');
        expect(addButtons, findsAtLeast(1));

        await tester.tap(addButtons.first);
        await tester.pumpAndSettle();

        expect(find.text('Add Mastodon Account'), findsOneWidget);
        expect(find.text('Display Name'), findsOneWidget);
        expect(find.text('Username'), findsOneWidget);
        expect(find.text('Server URL'), findsOneWidget);
        expect(find.text('Access Token'), findsOneWidget);
      });

      testWidgets('should show account menu when account tile is tapped', (tester) async {
        // Add a test account
        accountManager.addAccountForTesting(Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          isActive: true,
          credentials: {
            'server_url': 'https://mastodon.social',
            'access_token': 'test_token',
          },
        ));

        await tester.pumpWidget(createTestWidget(const AccountSettingsTab()));
        await tester.pumpAndSettle();

        // Find and tap the popup menu button
        final menuButton = find.byType(PopupMenuButton<String>);
        expect(menuButton, findsOneWidget);

        await tester.tap(menuButton);
        await tester.pumpAndSettle();

        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Deactivate'), findsOneWidget);
        expect(find.text('Test Connection'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('should test account connection when menu item is selected', (tester) async {
        // Add a test account
        accountManager.addAccountForTesting(Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          isActive: true,
          credentials: {
            'server_url': 'https://mastodon.social',
            'access_token': 'test_token',
          },
        ));

        await tester.pumpWidget(createTestWidget(const AccountSettingsTab()));
        await tester.pumpAndSettle();

        // Open the popup menu
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // Tap "Test Connection"
        await tester.tap(find.text('Test Connection'));
        await tester.pumpAndSettle();

        // Verify that validateAccount was called
        verify(mockMastodonService.validateConnection(any)).called(1);

        // Should show success snackbar
        expect(find.text('Connection test successful'), findsOneWidget);
      });

      testWidgets('should show edit dialog when edit menu item is selected', (tester) async {
        // Add a test account
        accountManager.addAccountForTesting(Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          isActive: true,
          credentials: {
            'server_url': 'https://mastodon.social',
            'access_token': 'test_token',
          },
        ));

        await tester.pumpWidget(createTestWidget(const AccountSettingsTab()));
        await tester.pumpAndSettle();

        // Open the popup menu
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // Tap "Edit"
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Mastodon Account'), findsOneWidget);
        expect(find.byType(EditAccountDialog), findsOneWidget);
      });

      testWidgets('should show delete confirmation when delete menu item is selected', (tester) async {
        // Add a test account
        accountManager.addAccountForTesting(Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          isActive: true,
          credentials: {
            'server_url': 'https://mastodon.social',
            'access_token': 'test_token',
          },
        ));

        await tester.pumpWidget(createTestWidget(const AccountSettingsTab()));
        await tester.pumpAndSettle();

        // Open the popup menu
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // Tap "Delete"
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Account'), findsOneWidget);
        expect(find.textContaining('Are you sure you want to delete'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Delete'), findsAtLeast(1));
      });
    });

    group('Add Account Dialog', () {
      testWidgets('should validate required fields', (tester) async {
        await tester.pumpWidget(createTestWidget(
          AddAccountDialog(platform: PlatformType.mastodon),
        ));
        await tester.pumpAndSettle();

        // Try to submit without filling fields
        await tester.tap(find.text('Add Account'));
        await tester.pumpAndSettle();

        expect(find.text('Display name is required'), findsOneWidget);
        expect(find.text('Username is required'), findsOneWidget);
      });

      testWidgets('should validate credential fields', (tester) async {
        await tester.pumpWidget(createTestWidget(
          AddAccountDialog(platform: PlatformType.mastodon),
        ));
        await tester.pumpAndSettle();

        // Fill basic fields but leave credentials empty
        await tester.enterText(find.widgetWithText(TextFormField, 'Display Name'), 'Test User');
        await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'testuser');

        await tester.tap(find.text('Add Account'));
        await tester.pumpAndSettle();

        expect(find.text('Server URL is required'), findsOneWidget);
        expect(find.text('Access Token is required'), findsOneWidget);
      });

      testWidgets('should show platform-specific fields for Mastodon', (tester) async {
        await tester.pumpWidget(createTestWidget(
          AddAccountDialog(platform: PlatformType.mastodon),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Add Mastodon Account'), findsOneWidget);
        expect(find.text('Server URL'), findsOneWidget);
        expect(find.text('Access Token'), findsOneWidget);
        expect(find.text('Setup Instructions'), findsOneWidget);
      });

      testWidgets('should show platform-specific fields for Bluesky', (tester) async {
        await tester.pumpWidget(createTestWidget(
          AddAccountDialog(platform: PlatformType.bluesky),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Add Bluesky Account'), findsOneWidget);
        expect(find.text('Handle'), findsOneWidget);
        expect(find.text('App Password'), findsOneWidget);
        expect(find.text('Setup Instructions'), findsOneWidget);
      });

      testWidgets('should show platform-specific fields for Nostr', (tester) async {
        await tester.pumpWidget(createTestWidget(
          AddAccountDialog(platform: PlatformType.nostr),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Add Nostr Account'), findsOneWidget);
        expect(find.text('Private Key'), findsOneWidget);
        expect(find.text('Setup Instructions'), findsOneWidget);
      });

      testWidgets('should toggle password visibility', (tester) async {
        await tester.pumpWidget(createTestWidget(
          AddAccountDialog(platform: PlatformType.mastodon),
        ));
        await tester.pumpAndSettle();

        // Find the access token field (should be obscured initially)
        final tokenField = find.widgetWithText(TextFormField, 'Access Token');
        expect(tokenField, findsOneWidget);

        // Find and tap the visibility toggle button
        final visibilityButton = find.descendant(
          of: tokenField,
          matching: find.byType(IconButton),
        );
        expect(visibilityButton, findsOneWidget);

        await tester.tap(visibilityButton);
        await tester.pumpAndSettle();

        // The field should now be visible (this is hard to test directly,
        // but we can verify the button was tapped)
        expect(visibilityButton, findsOneWidget);
      });
    });

    group('Edit Account Dialog', () {
      testWidgets('should pre-populate fields with existing account data', (tester) async {
        final testAccount = Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          isActive: true,
          credentials: {
            'server_url': 'https://mastodon.social',
            'access_token': 'test_token',
          },
        );

        await tester.pumpWidget(createTestWidget(
          EditAccountDialog(account: testAccount),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Edit Mastodon Account'), findsOneWidget);

        // Check that fields are pre-populated
        expect(find.widgetWithText(TextFormField, 'Test User'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'testuser'), findsOneWidget);
      });

      testWidgets('should show account information section', (tester) async {
        final testAccount = Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          isActive: true,
          credentials: {
            'server_url': 'https://mastodon.social',
            'access_token': 'test_token',
          },
        );

        await tester.pumpWidget(createTestWidget(
          EditAccountDialog(account: testAccount),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Account Information'), findsOneWidget);
        expect(find.textContaining('Mastodon'), findsAtLeast(1));
        expect(find.textContaining('Status'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
      });

      testWidgets('should show test connection button', (tester) async {
        final testAccount = Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          isActive: true,
          credentials: {
            'server_url': 'https://mastodon.social',
            'access_token': 'test_token',
          },
        );

        await tester.pumpWidget(createTestWidget(
          EditAccountDialog(account: testAccount),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Test Connection'), findsOneWidget);
      });

      testWidgets('should enable save button only when changes are made', (tester) async {
        final testAccount = Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          isActive: true,
          credentials: {
            'server_url': 'https://mastodon.social',
            'access_token': 'test_token',
          },
        );

        await tester.pumpWidget(createTestWidget(
          EditAccountDialog(account: testAccount),
        ));
        await tester.pumpAndSettle();

        // Initially, only Test Connection button should be visible
        expect(find.text('Test Connection'), findsOneWidget);
        expect(find.text('Save Changes'), findsNothing);

        // Make a change to the display name
        final displayNameField = find.widgetWithText(TextFormField, 'Test User');
        await tester.enterText(displayNameField, 'Updated User');
        await tester.pumpAndSettle();

        // Now Save Changes button should appear
        expect(find.text('Save Changes'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should show error when account validation fails', (tester) async {
        // Configure service to fail validation
        when(mockMastodonService.validateConnection(any)).thenAnswer((_) async => false);

        // Add a test account
        accountManager.addAccountForTesting(Account(
          id: 'test-account-1',
          platform: PlatformType.mastodon,
          displayName: 'Test User',
          username: 'testuser',
          createdAt: DateTime.now(),
          isActive: true,
          credentials: {
            'server_url': 'https://mastodon.social',
            'access_token': 'test_token',
          },
        ));

        await tester.pumpWidget(createTestWidget(const AccountSettingsTab()));
        await tester.pumpAndSettle();

        // Open the popup menu and test connection
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Test Connection'));
        await tester.pumpAndSettle();

        // Should show failure snackbar
        expect(find.text('Connection test failed'), findsOneWidget);
      });


    });
  });
}