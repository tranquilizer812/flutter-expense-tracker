import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/widgets/empty_state.dart';

void main() {
  group('EmptyState Widget Tests', () {
    testWidgets('EmptyState displays correct message', (WidgetTester tester) async {
      var callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              onAddExpense: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No expenses yet'), findsOneWidget);
      expect(find.text('Start tracking your expenses'), findsOneWidget);
    });

    testWidgets('EmptyState button calls callback when pressed',
        (WidgetTester tester) async {
      var callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              onAddExpense: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(callbackCalled, isTrue);
    });

    testWidgets('EmptyState displays add button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              onAddExpense: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Add First Expense'), findsOneWidget);
    });

    testWidgets('EmptyState displays icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              onAddExpense: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
    });
  });
}
