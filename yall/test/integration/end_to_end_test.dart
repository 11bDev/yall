import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yall/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End User Workflow Tests', () {
    testWidgets('Complete application lifecycle test', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify main window is displayed
      expect(find.text('Multi-Platform Poster'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);

      // Test keyboard shortcuts
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/keyevent',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('keydown', {
            'type': 'keydown',
            'keymap': 'linux',
            'toolkit': 'gtk',
            'unicodeScalarValues': 0,
            'keyCode': 67, // 'c' key
            'scanCode': 54,
            'modifiers': 4, // Control key
          }),
        ),
        (data) {},
      );
      await tester.pump();
    });

    testWidgets('Settings window navigation test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Open settings using keyboard shortcut
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.comma);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Should navigate to settings - verify by checking for settings-specific widgets
      // Note: This depends on the settings window implementation
      await tester.pump(const Duration(seconds: 1));

      // Navigate back
      if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }

      // Verify we're back at main screen
      expect(find.text('Multi-Platform Poster'), findsOneWidget);
    });

    testWidgets('Help dialog keyboard shortcut test', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // Press F1 to open help
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();

      // Verify help dialog is shown
      expect(find.text('Keyboard Shortcuts'), findsOneWidget);
      expect(find.text('Ctrl+N: Focus on new post input'), findsOneWidget);
      expect(find.text('Ctrl+Enter: Submit post'), findsOneWidget);

      // Close help dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Keyboard Shortcuts'), findsNothing);
    });

    testWidgets('Post content validation test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find and interact with the text input
      final textField = find.byType(TextField).first;
      await tester.tap(textField);
      await tester.pumpAndSettle();

      // Enter some test content
      const testContent = 'This is a test post for all platforms!';
      await tester.enterText(textField, testContent);
      await tester.pumpAndSettle();

      // Verify content is entered
      expect(find.text(testContent), findsOneWidget);

      // Test character counter if present
      // The character counter should show the length
      // This depends on the posting widget implementation
    });

    testWidgets('Platform selection test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find platform checkboxes (assuming they exist)
      final platformCheckboxes = find.byType(Checkbox);

      if (platformCheckboxes.evaluate().isNotEmpty) {
        // Test selecting/deselecting platforms
        await tester.tap(platformCheckboxes.first);
        await tester.pumpAndSettle();

        // Verify state changed (this would depend on implementation)
        // The specific verification depends on how platform selection is displayed
      }
    });

    testWidgets('Error handling display test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // This test would verify that errors are properly displayed to users
      // The specific implementation depends on how errors are shown

      // For now, just verify the app doesn't crash during normal operation
      expect(find.text('Multi-Platform Poster'), findsOneWidget);

      // Test that the app handles navigation gracefully
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        // Navigate back
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Accessibility test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test semantic labels and accessibility
      final semanticsHandle = tester.binding.pipelineOwner.semanticsOwner!;

      // Verify semantic information is available
      expect(semanticsHandle.rootSemanticsNode, isNotNull);

      // Test tooltips are present on important buttons
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        // Long press to show tooltip
        await tester.longPress(settingsButton);
        await tester.pumpAndSettle();

        // Verify tooltip appears
        expect(find.text('Open Settings (Ctrl+,)'), findsOneWidget);

        // Dismiss tooltip
        await tester.tap(find.byType(Scaffold));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Window lifecycle test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test window state management
      expect(find.text('Multi-Platform Poster'), findsOneWidget);

      // Simulate window resize or state changes
      // This would require platform-specific testing

      // For now, verify the app maintains state correctly
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Multi-Platform Poster'), findsOneWidget);
    });
  });
}
