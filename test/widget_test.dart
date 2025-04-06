import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add the SharedPreferences import
import 'package:ConnectX/screens/homepageold.dart'; // Correct the import to homepageold.dart

void main() {
  testWidgets('Home page displays the correct title and welcome message', (WidgetTester tester) async {
    // Set up SharedPreferences mock
    SharedPreferences.setMockInitialValues({
      'userName': 'Test User', // Provide a sample userName in SharedPreferences
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(),
      ),
    );

    expect(find.text('ConnectX'), findsOneWidget);

    expect(find.text('Welcome, Test User!'), findsOneWidget);
  });
}
