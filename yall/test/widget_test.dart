// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:yall/main.dart';

void main() {
  testWidgets('App starts and shows main window', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MultiPlatformPosterApp());

        // Verify that our counter starts at 0.
    expect(find.text('Welcome to Yall!'), findsOneWidget);
    expect(find.text('Yall'), findsOneWidget);

    // Verify that the posting widget is present
    expect(find.text('What\'s on your mind?'), findsOneWidget);
  });
}
