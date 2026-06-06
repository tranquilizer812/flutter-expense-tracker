import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/database/database.dart';
import 'package:expense_tracker/main.dart';

void main() {
  testWidgets('Expense Tracker app initialization smoke test',
      (WidgetTester tester) async {
    final database = AppDatabase();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(database: database));

    // Verify that the app renders without crashing
    expect(find.byType(MyApp), findsOneWidget);

    await database.close();
  });
}
