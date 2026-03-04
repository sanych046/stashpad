import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stashpad_android/main.dart';
import 'package:stashpad_android/services/database_service.dart';

void main() {
  testWidgets('Home screen UI test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DatabaseService>(
            create: (_) => DatabaseService(),
          ),
        ],
        child: const StashpadApp(),
      ),
    );

    // Verify that the title is present
    expect(find.text('Stashpad'), findsWidgets);
    
    // Verify buttons are present
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
