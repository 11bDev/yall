import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yall/widgets/settings/about_settings_tab.dart';

void main() {
  group('AboutSettingsTab', () {
    testWidgets('should display app information', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AboutSettingsTab(),
          ),
        ),
      );

      // Wait for async operations
      await tester.pumpAndSettle();

      // Verify that key elements are present
      expect(find.text('YaLL'), findsOneWidget);
      expect(find.text('Yet another Link Logger'), findsOneWidget);
      expect(find.text('Multi-Platform Social Media Poster'), findsOneWidget);
      
      // Check for section headers
      expect(find.text('Version Information'), findsOneWidget);
      expect(find.text('System Information'), findsOneWidget);
      expect(find.text('Features'), findsOneWidget);
      expect(find.text('Platform Character Limits'), findsOneWidget);
      expect(find.text('Support & Development'), findsOneWidget);
      expect(find.text('Support Development'), findsOneWidget);
      expect(find.text('License'), findsOneWidget);
    });

    testWidgets('should display correct character limits', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AboutSettingsTab(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify character limits are displayed correctly
      expect(find.text('500 characters'), findsOneWidget); // Mastodon
      expect(find.text('300 characters'), findsOneWidget); // Bluesky
      expect(find.text('800 characters'), findsOneWidget); // Nostr
    });

    testWidgets('should display features list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AboutSettingsTab(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for key features
      expect(find.text('Multi-Platform Posting'), findsOneWidget);
      expect(find.text('Secure Storage'), findsOneWidget);
      expect(find.text('System Tray'), findsOneWidget);
      expect(find.text('Character Limits'), findsOneWidget);
      expect(find.text('Keyboard Shortcuts'), findsOneWidget);
      expect(find.text('Dark/Light Themes'), findsOneWidget);
    });

    testWidgets('should display donation placeholder', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AboutSettingsTab(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for donation section
      expect(find.text('Donation Options Coming Soon'), findsOneWidget);
      expect(find.text('We\'re working on setting up donation options.'), findsOneWidget);
    });

    testWidgets('should display license information', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AboutSettingsTab(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for license info
      expect(find.text('MIT'), findsOneWidget);
      expect(find.text('2024-2025 Tim Apple'), findsOneWidget);
    });

    testWidgets('should display system information', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AboutSettingsTab(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for system info
      expect(find.text('Flutter Version'), findsOneWidget);
      expect(find.text('3.32.7'), findsOneWidget);
      expect(find.text('Dart Version'), findsOneWidget);
      expect(find.text('3.8.1'), findsOneWidget);
    });
  });
}
