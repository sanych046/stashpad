import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stashpad_android/main.dart';

void main() {
  testWidgets('Welcome screen UI test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StashpadApp());

    // Verify that the title and key elements are present
    expect(find.text('Stashpad Secure Notes'), findsOneWidget);
    expect(find.text('Your Data, Encrypted.'), findsOneWidget);
    
    // Verify buttons are present
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
  });
}
