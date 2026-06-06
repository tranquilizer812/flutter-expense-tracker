import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/utils/statistics_calculator.dart';
import 'package:expense_tracker/models/expense.dart';

void main() {
  group('StatisticsCalculator Tests', () {
    group('Weekly Average Calculation Tests', () {
      test('Empty expense list returns 0.0', () {
        final average = StatisticsCalculator.calculateWeeklyAverage([]);
        expect(average, equals(0.0));
      });

      test('Single expense calculates average correctly', () {
        final expense = Expense(
          id: 1,
          date: DateTime.now(),
          amount: 70.0,
          currency: CurrencyCode.USD,
          category: ExpenseCategory.Food,
          createdAt: DateTime.now(),
        );

        final average = StatisticsCalculator.calculateWeeklyAverage([expense]);
        expect(average, equals(10.0)); // 70 / 7
      });

      test('Multiple expenses calculate average correctly', () {
        final expenses = [
          Expense(
            id: 1,
            date: DateTime.now(),
            amount: 35.0,
            currency: CurrencyCode.USD,
            category: ExpenseCategory.Food,
            createdAt: DateTime.now(),
          ),
          Expense(
            id: 2,
            date: DateTime.now().subtract(const Duration(days: 1)),
            amount: 35.0,
            currency: CurrencyCode.USD,
            category: ExpenseCategory.Transport,
            createdAt: DateTime.now(),
          ),
        ];

        final average = StatisticsCalculator.calculateWeeklyAverage(expenses);
        expect(average, equals(10.0)); // 70 / 7
      });
    });

    group('Category Grouping Tests', () {
      test('Empty expense list returns empty map', () {
        final grouped = StatisticsCalculator.groupByCategory([]);
        expect(grouped, isEmpty);
      });

      test('Single category groups correctly', () {
        final expenses = [
          Expense(
            id: 1,
            date: DateTime.now(),
            amount: 50.0,
            currency: CurrencyCode.USD,
            category: ExpenseCategory.Food,
            createdAt: DateTime.now(),
          ),
          Expense(
            id: 2,
            date: DateTime.now(),
            amount: 30.0,
            currency: CurrencyCode.USD,
            category: ExpenseCategory.Food,
            createdAt: DateTime.now(),
          ),
        ];

        final grouped = StatisticsCalculator.groupByCategory(expenses);
        expect(grouped.length, equals(1));
        expect(grouped[ExpenseCategory.Food], equals(80.0));
      });

      test('Multiple categories group correctly', () {
        final expenses = [
          Expense(
            id: 1,
            date: DateTime.now(),
            amount: 50.0,
            currency: CurrencyCode.USD,
            category: ExpenseCategory.Food,
            createdAt: DateTime.now(),
          ),
          Expense(
            id: 2,
            date: DateTime.now(),
            amount: 30.0,
            currency: CurrencyCode.USD,
            category: ExpenseCategory.Transport,
            createdAt: DateTime.now(),
          ),
        ];

        final grouped = StatisticsCalculator.groupByCategory(expenses);
        expect(grouped.length, equals(2));
        expect(grouped[ExpenseCategory.Food], equals(50.0));
        expect(grouped[ExpenseCategory.Transport], equals(30.0));
      });
    });

    group('Category Percentage Calculation Tests', () {
      test('Empty list returns empty percentages', () {
        final percentages = StatisticsCalculator.calculateCategoryPercentages([]);
        expect(percentages, isEmpty);
      });

      test('Single category is 100%', () {
        final expenses = [
          Expense(
            id: 1,
            date: DateTime.now(),
            amount: 100.0,
            currency: CurrencyCode.USD,
            category: ExpenseCategory.Food,
            createdAt: DateTime.now(),
          ),
        ];

        final percentages = StatisticsCalculator.calculateCategoryPercentages(expenses);
        expect(percentages.length, equals(1));
        expect(percentages[ExpenseCategory.Food], closeTo(100.0, 0.01));
      });

      test('Multiple categories calculate percentages correctly', () {
        final expenses = [
          Expense(
            id: 1,
            date: DateTime.now(),
            amount: 50.0,
            currency: CurrencyCode.USD,
            category: ExpenseCategory.Food,
            createdAt: DateTime.now(),
          ),
          Expense(
            id: 2,
            date: DateTime.now(),
            amount: 50.0,
            currency: CurrencyCode.USD,
            category: ExpenseCategory.Transport,
            createdAt: DateTime.now(),
          ),
        ];

        final percentages = StatisticsCalculator.calculateCategoryPercentages(expenses);
        expect(percentages.length, equals(2));
        expect(percentages[ExpenseCategory.Food], closeTo(50.0, 0.01));
        expect(percentages[ExpenseCategory.Transport], closeTo(50.0, 0.01));
      });
    });

    group('Last N Days Expenses Tests', () {
      test('Empty list returns empty', () {
        final expenses = StatisticsCalculator.getExpensesFromLastDays([], 7);
        expect(expenses, isEmpty);
      });

      test('All expenses within range are included', () {
        final now = DateTime.now();
        final expenses = [
          Expense(
            id: 1,
            date: now,
            amount: 50.0,
            currency: CurrencyCode.USD,
            category: ExpenseCategory.Food,
            createdAt: DateTime.now(),
          ),
          Expense(
            id: 2,
            date: now.subtract(const Duration(days: 3)),
            amount: 30.0,
            currency: CurrencyCode.USD,
            category: ExpenseCategory.Transport,
            createdAt: DateTime.now(),
          ),
        ];

        final lastWeek = StatisticsCalculator.getExpensesFromLastDays(expenses, 7);
        expect(lastWeek.length, equals(2));
      });

      test('Expenses outside range are excluded', () {
        final now = DateTime.now();
        final expenses = [
          Expense(
            id: 1,
            date: now,
            amount: 50.0,
            currency: CurrencyCode.USD,
            category: ExpenseCategory.Food,
            createdAt: DateTime.now(),
          ),
          Expense(
            id: 2,
            date: now.subtract(const Duration(days: 10)),
            amount: 30.0,
            currency: CurrencyCode.USD,
            category: ExpenseCategory.Transport,
            createdAt: DateTime.now(),
          ),
        ];

        final lastWeek = StatisticsCalculator.getExpensesFromLastDays(expenses, 7);
        expect(lastWeek.length, equals(1));
        expect(lastWeek.first.id, equals(1));
      });
    });

    group('Date Formatting Tests', () {
      test('Date formats correctly as YYYY-MM-DD', () {
        final date = DateTime(2024, 3, 15);
        final formatted = StatisticsCalculator.formatDate(date);
        expect(formatted, equals('2024-03-15'));
      });

      test('Date with leading zeros formats correctly', () {
        final date = DateTime(2024, 1, 5);
        final formatted = StatisticsCalculator.formatDate(date);
        expect(formatted, equals('2024-01-05'));
      });

      test('Date parses correctly from string', () {
        final parsed = StatisticsCalculator.parseDate('2024-03-15');
        expect(parsed.year, equals(2024));
        expect(parsed.month, equals(3));
        expect(parsed.day, equals(15));
      });
    });

    group('Amount Formatting Tests', () {
      test('USD formats with dollar sign', () {
        final formatted =
            StatisticsCalculator.formatAmountWithCurrency(100.0, CurrencyCode.USD);
        expect(formatted, equals('\$100.00'));
      });

      test('EUR formats with euro symbol', () {
        final formatted =
            StatisticsCalculator.formatAmountWithCurrency(100.0, CurrencyCode.EUR);
        expect(formatted, equals('€100.00'));
      });

      test('Decimal places are preserved', () {
        final formatted =
            StatisticsCalculator.formatAmountWithCurrency(99.99, CurrencyCode.USD);
        expect(formatted, equals('\$99.99'));
      });
    });

    group('Month Name Formatting Tests', () {
      test('Month name formats correctly', () {
        final monthName = StatisticsCalculator.formatMonthName('2024-03');
        expect(monthName, equals('Mar'));
      });

      test('January formats correctly', () {
        final monthName = StatisticsCalculator.formatMonthName('2024-01');
        expect(monthName, equals('Jan'));
      });

      test('December formats correctly', () {
        final monthName = StatisticsCalculator.formatMonthName('2024-12');
        expect(monthName, equals('Dec'));
      });
    });
  });
}
