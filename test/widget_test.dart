import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Home page displays the correct title and welcome message',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'userName': 'Test User',
    });

    expect(find.text('ConnectX'), findsOneWidget);
    expect(find.text('Welcome, Test User!'), findsOneWidget);
  });
}
