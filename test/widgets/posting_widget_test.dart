import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:yall/widgets/posting_widget.dart';
import 'package:yall/providers/post_manager.dart';
import 'package:yall/providers/account_manager.dart';
import 'package:yall/models/platform_type.dart';
import 'package:yall/models/account.dart';
import 'package:yall/models/post_result.dart';

import 'posting_widget_test.mocks.dart';

@GenerateMocks([PostManager, AccountManager])
void main() {
  group('PostingWidget', () {
    late MockPostManager mockPostManager;
    late MockAccountManager mockAccountManager;

    setUp(() {
      mockPostManager = MockPostManager();
      mockAccountManager = MockAccountManager();

      // Set up default mock behaviors
      when(mockPostManager.isPosting).thenReturn(false);
      when(mockPostManager.error).thenReturn(null);
      when(mockPostManager.canPost(any, any)).thenReturn(true);
      when(mockPostManager.getCharacterLimit(any)).thenReturn(800);
      when(mockPostManager.getRemainingCharacters(any, any)).thenReturn(800);

      when(mockAccountManager.getActiveAccountsForPlatform(any)).thenReturn([]);
      when(mockAccountManager.getDefaultAccountForPlatform(any)).thenReturn(null);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<PostManager>.value(value: mockPostManager),
            ChangeNotifierProvider<AccountManager>.value(value: mockAccountManager),
          ],
          child: const Scaffold(
            body: SingleChildScrollView(
              child: PostingWidget(),
            ),
          ),
        ),
      );
    }

    testWidgets('displays text input area', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('What\'s on your mind?'), findsOneWidget);
    });

    testWidgets('displays platform checkboxes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Select Platforms'), findsOneWidget);
      expect(find.text('Mastodon'), findsOneWidget);
      expect(find.text('Bluesky'), findsOneWidget);
      expect(find.text('Nostr'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(3));
    });

    testWidgets('displays post button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.widgetWithText(ElevatedButton, 'Post'), findsOneWidget);
    });

    testWidgets('post button is disabled when no platforms selected', (WidgetTester tester) async {
      when(mockPostManager.canPost(any, any)).thenReturn(false);

      await tester.pumpWidget(createTestWidget());

      final postButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Post'),
      );
      expect(postButton.onPressed, isNull);
    });

    testWidgets('shows character counter when platforms selected', (WidgetTester tester) async {
      // Set up mock to return character limit
      when(mockPostManager.getCharacterLimit(any)).thenReturn(800);
      when(mockPostManager.getRemainingCharacters(any, any)).thenReturn(800);

      await tester.pumpWidget(createTestWidget());

      // Type some text to trigger character counter display
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.pump();

      expect(find.text('Character limit: 800'), findsOneWidget);
      expect(find.textContaining('remaining'), findsOneWidget);
    });

    testWidgets('shows warning when character limit exceeded', (WidgetTester tester) async {
      when(mockPostManager.getCharacterLimit(any)).thenReturn(10);
      when(mockPostManager.getRemainingCharacters(any, any)).thenReturn(-5);

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'This is a very long message');
      await tester.pump();

      // Find the remaining characters text and check its color
      final remainingText = tester.widget<Text>(
        find.textContaining('remaining'),
      );
      expect(remainingText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('platform checkbox toggles selection', (WidgetTester tester) async {
      final testAccount = Account(
        id: 'test-id',
        platform: PlatformType.mastodon,
        displayName: 'Test Account',
        username: 'test@example.com',
        createdAt: DateTime.now(),
      );

      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccount]);
      when(mockAccountManager.getDefaultAccountForPlatform(PlatformType.mastodon))
          .thenReturn(testAccount);

      await tester.pumpWidget(createTestWidget());

      // Find and tap the Mastodon checkbox
      final mastodonCheckbox = find.byType(Checkbox).first;
      await tester.tap(mastodonCheckbox);
      await tester.pump();

      // Verify checkbox is now checked
      final checkbox = tester.widget<Checkbox>(mastodonCheckbox);
      expect(checkbox.value, isTrue);
    });

    testWidgets('shows account dropdown when platform selected and has accounts', (WidgetTester tester) async {
      final testAccount = Account(
        id: 'test-id',
        platform: PlatformType.mastodon,
        displayName: 'Test Account',
        username: 'test@example.com',
        createdAt: DateTime.now(),
      );

      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccount]);
      when(mockAccountManager.getDefaultAccountForPlatform(PlatformType.mastodon))
          .thenReturn(testAccount);

      await tester.pumpWidget(createTestWidget());

      // Select Mastodon platform
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      // Should show dropdown
      expect(find.byType(DropdownButton<Account?>), findsOneWidget);
    });

    testWidgets('shows "No accounts configured" when platform has no accounts', (WidgetTester tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(any)).thenReturn([]);

      await tester.pumpWidget(createTestWidget());

      expect(find.text('No accounts configured'), findsNWidgets(3));
    });

    testWidgets('disables platform checkbox when no accounts available', (WidgetTester tester) async {
      when(mockAccountManager.getActiveAccountsForPlatform(any)).thenReturn([]);

      await tester.pumpWidget(createTestWidget());

      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      for (final checkbox in checkboxes) {
        expect(checkbox.onChanged, isNull);
      }
    });

    testWidgets('shows loading indicator when posting', (WidgetTester tester) async {
      when(mockPostManager.isPosting).thenReturn(true);

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when error occurs', (WidgetTester tester) async {
      when(mockPostManager.error).thenReturn('Test error message');

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Test error message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('has close button for error message', (WidgetTester tester) async {
      when(mockPostManager.error).thenReturn('Test error message');

      await tester.pumpWidget(createTestWidget());

      // Verify error message and close button are present
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('calls publishToSelectedPlatforms when post button pressed', (WidgetTester tester) async {
      final testAccount = Account(
        id: 'test-id',
        platform: PlatformType.mastodon,
        displayName: 'Test Account',
        username: 'test@example.com',
        createdAt: DateTime.now(),
      );

      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccount]);
      when(mockAccountManager.getDefaultAccountForPlatform(PlatformType.mastodon))
          .thenReturn(testAccount);

      final mockResult = PostResult.empty('Test content');
      when(mockPostManager.publishToSelectedPlatforms(any, any, any))
          .thenAnswer((_) async => mockResult);

      await tester.pumpWidget(createTestWidget());

      // Enter text
      await tester.enterText(find.byType(TextField), 'Test content');
      await tester.pump();

      // Select platform
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      // Tap post button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Post'));
      await tester.pump();

      verify(mockPostManager.publishToSelectedPlatforms(
        'Test content',
        any,
        any,
      )).called(1);
    });

    testWidgets('clears text field on successful post', (WidgetTester tester) async {
      final testAccount = Account(
        id: 'test-id',
        platform: PlatformType.mastodon,
        displayName: 'Test Account',
        username: 'test@example.com',
        createdAt: DateTime.now(),
      );

      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccount]);
      when(mockAccountManager.getDefaultAccountForPlatform(PlatformType.mastodon))
          .thenReturn(testAccount);

      // Mock successful result
      final mockResult = PostResult.empty('Test content')
          .addPlatformResult(PlatformType.mastodon, true);
      when(mockPostManager.publishToSelectedPlatforms(any, any, any))
          .thenAnswer((_) async => mockResult);

      await tester.pumpWidget(createTestWidget());

      // Enter text
      await tester.enterText(find.byType(TextField), 'Test content');
      await tester.pump();

      // Select platform
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      // Tap post button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Post'));
      await tester.pumpAndSettle();

      // Check that text field is cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('shows success message on successful post', (WidgetTester tester) async {
      final testAccount = Account(
        id: 'test-id',
        platform: PlatformType.mastodon,
        displayName: 'Test Account',
        username: 'test@example.com',
        createdAt: DateTime.now(),
      );

      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccount]);
      when(mockAccountManager.getDefaultAccountForPlatform(PlatformType.mastodon))
          .thenReturn(testAccount);

      // Mock successful result
      final mockResult = PostResult.empty('Test content')
          .addPlatformResult(PlatformType.mastodon, true);
      when(mockPostManager.publishToSelectedPlatforms(any, any, any))
          .thenAnswer((_) async => mockResult);

      await tester.pumpWidget(createTestWidget());

      // Enter text
      await tester.enterText(find.byType(TextField), 'Test content');
      await tester.pump();

      // Select platform
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      // Tap post button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Post'));
      await tester.pumpAndSettle();

      // Check for success message
      expect(find.text('Post published successfully!'), findsOneWidget);
    });

    testWidgets('account dropdown selection updates selected account', (WidgetTester tester) async {
      final testAccount1 = Account(
        id: 'test-id-1',
        platform: PlatformType.mastodon,
        displayName: 'Test Account 1',
        username: 'test1@example.com',
        createdAt: DateTime.now(),
      );

      final testAccount2 = Account(
        id: 'test-id-2',
        platform: PlatformType.mastodon,
        displayName: 'Test Account 2',
        username: 'test2@example.com',
        createdAt: DateTime.now(),
      );

      when(mockAccountManager.getActiveAccountsForPlatform(PlatformType.mastodon))
          .thenReturn([testAccount1, testAccount2]);
      when(mockAccountManager.getDefaultAccountForPlatform(PlatformType.mastodon))
          .thenReturn(testAccount1);

      await tester.pumpWidget(createTestWidget());

      // Select Mastodon platform
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      // Tap dropdown to open it
      await tester.tap(find.byType(DropdownButton<Account?>));
      await tester.pumpAndSettle();

      // Select second account
      await tester.tap(find.text('Test Account 2').last);
      await tester.pumpAndSettle();

      // Verify the dropdown shows the selected account
      expect(find.text('Test Account 2'), findsOneWidget);
    });

    testWidgets('updates character counter when text changes', (WidgetTester tester) async {
      when(mockPostManager.getCharacterLimit(any)).thenReturn(800);
      when(mockPostManager.getRemainingCharacters('', any)).thenReturn(800);
      when(mockPostManager.getRemainingCharacters('Hello', any)).thenReturn(795);

      await tester.pumpWidget(createTestWidget());

      // Initially should show 800 remaining
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      // Enter text
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      // Verify character counter updated
      verify(mockPostManager.getRemainingCharacters('Hello', any)).called(greaterThan(0));
    });
  });
}