import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense.dart';

void main() {
  group('Expense Model Tests', () {
    group('Validation Tests', () {
      test('Valid expense passes validation', () {
        final expense = Expense(
          id: 1,
          date: DateTime.now(),
          amount: 100.0,
          currency: CurrencyCode.USD,
          category: ExpenseCategory.Food,
          note: 'Test expense',
          createdAt: DateTime.now(),
        );

        expect(expense.validate(), isNull);
      });

      test('Expense with date before 2024-01-01 fails validation', () {
        final expense = Expense(
          id: 1,
          date: DateTime(2023, 12, 31),
          amount: 100.0,
          currency: CurrencyCode.USD,
          category: ExpenseCategory.Food,
          createdAt: DateTime.now(),
        );

        final error = expense.validate();
        expect(error, isNotNull);
        expect(error, contains('January 1, 2024'));
      });

      test('Expense with future date fails validation', () {
        final expense = Expense(
          id: 1,
          date: DateTime.now().add(const Duration(days: 1)),
          amount: 100.0,
          currency: CurrencyCode.USD,
          category: ExpenseCategory.Food,
          createdAt: DateTime.now(),
        );

        final error = expense.validate();
        expect(error, isNotNull);
        expect(error, contains('future'));
      });

      test('Expense with zero amount fails validation', () {
        final expense = Expense(
          id: 1,
          date: DateTime.now(),
          amount: 0.0,
          currency: CurrencyCode.USD,
          category: ExpenseCategory.Food,
          createdAt: DateTime.now(),
        );

        final error = expense.validate();
        expect(error, isNotNull);
        expect(error, contains('greater than 0'));
      });

      test('Expense with negative amount fails validation', () {
        final expense = Expense(
          id: 1,
          date: DateTime.now(),
          amount: -50.0,
          currency: CurrencyCode.USD,
          category: ExpenseCategory.Food,
          createdAt: DateTime.now(),
        );

        final error = expense.validate();
        expect(error, isNotNull);
        expect(error, contains('greater than 0'));
      });

      test('Expense with amount >= 1,000,000 fails validation', () {
        final expense = Expense(
          id: 1,
          date: DateTime.now(),
          amount: 1000000.0,
          currency: CurrencyCode.USD,
          category: ExpenseCategory.Food,
          createdAt: DateTime.now(),
        );

        final error = expense.validate();
        expect(error, isNotNull);
        expect(error, contains('less than 1,000,000'));
      });

      test('Expense with note > 500 chars fails validation', () {
        final longNote = 'a' * 501;
        final expense = Expense(
          id: 1,
          date: DateTime.now(),
          amount: 100.0,
          currency: CurrencyCode.USD,
          category: ExpenseCategory.Food,
          note: longNote,
          createdAt: DateTime.now(),
        );

        final error = expense.validate();
        expect(error, isNotNull);
        expect(error, contains('500 characters'));
      });

      test('Expense with note exactly 500 chars passes validation', () {
        final exactNote = 'a' * 500;
        final expense = Expense(
          id: 1,
          date: DateTime.now(),
          amount: 100.0,
          currency: CurrencyCode.USD,
          category: ExpenseCategory.Food,
          note: exactNote,
          createdAt: DateTime.now(),
        );

        expect(expense.validate(), isNull);
      });

      test('All valid currency codes are supported', () {
        for (final currency in CurrencyCode.values) {
          expect(currency.code, isNotEmpty);
          expect(currency.symbol, isNotEmpty);
        }
      });

      test('All expense categories are valid', () {
        for (final category in ExpenseCategory.values) {
          expect(category.displayName, isNotEmpty);
        }
      });
    });

    group('JSON Serialization Tests', () {
      test('Expense correctly serializes to JSON', () {
        final expense = Expense(
          id: 1,
          date: DateTime(2024, 3, 15),
          amount: 99.99,
          currency: CurrencyCode.EUR,
          category: ExpenseCategory.Food,
          note: 'Lunch',
          createdAt: DateTime(2024, 3, 15, 12, 0, 0),
        );

        final json = expense.toJson();

        expect(json['id'], equals(1));
        expect(json['amount'], equals(99.99));
        expect(json['currency'], equals('EUR'));
        expect(json['category'], equals('Food'));
        expect(json['note'], equals('Lunch'));
      });

      test('Expense correctly deserializes from JSON', () {
        final json = {
          'id': 2,
          'date': '2024-04-20T00:00:00.000Z',
          'amount': 50.5,
          'currency': 'GBP',
          'category': 'Transport',
          'note': 'Taxi',
          'receipt_uri': null,
          'created_at': '2024-04-20T10:30:00.000Z',
          'modified_at': null,
        };

        final expense = Expense.fromJson(json);

        expect(expense.id, equals(2));
        expect(expense.amount, equals(50.5));
        expect(expense.currency, equals(CurrencyCode.GBP));
        expect(expense.category, equals(ExpenseCategory.Transport));
        expect(expense.note, equals('Taxi'));
      });
    });

    group('copyWith Tests', () {
      test('copyWith creates a new instance with updated fields', () {
        final original = Expense(
          id: 1,
          date: DateTime(2024, 3, 15),
          amount: 100.0,
          currency: CurrencyCode.USD,
          category: ExpenseCategory.Food,
          createdAt: DateTime.now(),
        );

        final updated = original.copyWith(
          amount: 150.0,
          category: ExpenseCategory.Transport,
        );

        expect(original.amount, equals(100.0));
        expect(original.category, equals(ExpenseCategory.Food));
        expect(updated.amount, equals(150.0));
        expect(updated.category, equals(ExpenseCategory.Transport));
        expect(updated.id, equals(original.id));
      });
    });

    group('Currency Code Tests', () {
      test('Currency format includes correct symbol', () {
        expect(CurrencyCode.USD.format(100.0), equals('\$100.00'));
        expect(CurrencyCode.EUR.format(100.0), equals('€100.00'));
        expect(CurrencyCode.GBP.format(100.0), equals('£100.00'));
      });

      test('currencyFromString returns correct currency', () {
        expect(currencyFromString('USD'), equals(CurrencyCode.USD));
        expect(currencyFromString('EUR'), equals(CurrencyCode.EUR));
        expect(currencyFromString('JPY'), equals(CurrencyCode.JPY));
      });

      test('currencyFromString defaults to USD for invalid code', () {
        expect(currencyFromString('INVALID'), equals(CurrencyCode.USD));
      });
    });

    group('Category Tests', () {
      test('categoryFromString returns correct category', () {
        expect(categoryFromString('Food'), equals(ExpenseCategory.Food));
        expect(categoryFromString('Transport'), equals(ExpenseCategory.Transport));
        expect(categoryFromString('Entertainment'), equals(ExpenseCategory.Entertainment));
        expect(categoryFromString('Other'), equals(ExpenseCategory.Other));
      });

      test('categoryFromString defaults to Other for invalid category', () {
        expect(categoryFromString('Invalid'), equals(ExpenseCategory.Other));
      });
    });

    group('Equality Tests', () {
      test('Two expenses with same data are equal', () {
        final date = DateTime(2024, 3, 15);
        final now = DateTime.now();

        final expense1 = Expense(
          id: 1,
          date: date,
          amount: 100.0,
          currency: CurrencyCode.USD,
          category: ExpenseCategory.Food,
          note: 'Test',
          createdAt: now,
        );

        final expense2 = Expense(
          id: 1,
          date: date,
          amount: 100.0,
          currency: CurrencyCode.USD,
          category: ExpenseCategory.Food,
          note: 'Test',
          createdAt: now,
        );

        expect(expense1, equals(expense2));
      });

      test('Two expenses with different data are not equal', () {
        final date = DateTime(2024, 3, 15);
        final now = DateTime.now();

        final expense1 = Expense(
          id: 1,
          date: date,
          amount: 100.0,
          currency: CurrencyCode.USD,
          category: ExpenseCategory.Food,
          createdAt: now,
        );

        final expense2 = Expense(
          id: 1,
          date: date,
          amount: 150.0,
          currency: CurrencyCode.USD,
          category: ExpenseCategory.Food,
          createdAt: now,
        );

        expect(expense1, isNot(equals(expense2)));
      });
    });
  });
}
