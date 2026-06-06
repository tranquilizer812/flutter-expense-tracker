import 'package:intl/intl.dart';
import '../models/expense.dart';

class StatisticsCalculator {
  /// Calculate monthly totals with currency information
  /// Returns list of (month name, total, currency code) for last 12 months
  static List<(String, double, String)> calculateMonthlyTotals(
    List<(String, double)> monthlyData,
    String defaultCurrency,
  ) {
    final result = <(String, double, String)>[];

    for (final (monthStr, total) in monthlyData) {
      final parts = monthStr.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);

      // Format as "Jan", "Feb", etc.
      final date = DateTime(year, month);
      final monthName = DateFormat('MMM').format(date);

      result.add((monthName, total, defaultCurrency));
    }

    return result;
  }

  /// Calculate weekly average from expenses in the last 7 days
  static double calculateWeeklyAverage(
    List<Expense> recentExpenses,
  ) {
    if (recentExpenses.isEmpty) {
      return 0.0;
    }

    double total = 0.0;
    for (final expense in recentExpenses) {
      total += expense.amount;
    }

    return total / 7.0;
  }

  /// Group expenses by category and calculate totals
  /// Returns a map of category to total amount, only including categories with expenses
  static Map<ExpenseCategory, double> groupByCategory(
    List<Expense> expenses,
  ) {
    final result = <ExpenseCategory, double>{};

    for (final expense in expenses) {
      result[expense.category] = (result[expense.category] ?? 0.0) + expense.amount;
    }

    return result;
  }

  /// Calculate category percentages from expenses
  /// Only includes categories that have expenses
  static Map<ExpenseCategory, double> calculateCategoryPercentages(
    List<Expense> expenses,
  ) {
    final totals = groupByCategory(expenses);
    
    if (totals.isEmpty) {
      return {};
    }

    final grandTotal = totals.values.fold<double>(0.0, (sum, val) => sum + val);
    
    final percentages = <ExpenseCategory, double>{};
    for (final (category, total) in totals.entries) {
      percentages[category] = (total / grandTotal) * 100.0;
    }

    return percentages;
  }

  /// Get month name from YYYY-MM string
  static String formatMonthName(String monthStr) {
    final parts = monthStr.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final date = DateTime(year, month);
    return DateFormat('MMM').format(date);
  }

  /// Format amount with currency symbol
  static String formatAmountWithCurrency(double amount, CurrencyCode currency) {
    return '${currency.symbol}${amount.toStringAsFixed(2)}';
  }

  /// Get expenses from the last N days
  static List<Expense> getExpensesFromLastDays(
    List<Expense> allExpenses,
    int days,
  ) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return allExpenses.where((e) => e.date.isAfter(cutoffDate)).toList();
  }

  /// Get expenses from last 7 days
  static List<Expense> getExpensesFromLastWeek(List<Expense> allExpenses) {
    return getExpensesFromLastDays(allExpenses, 7);
  }

  /// Format a date as YYYY-MM-DD
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Parse a date string in format YYYY-MM-DD
  static DateTime parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
