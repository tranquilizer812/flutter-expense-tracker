import 'package:sqflite/sqflite.dart';
import '../database/database.dart';
import '../models/expense.dart';

class RepositoryException implements Exception {
  final String message;
  final dynamic originalError;

  RepositoryException({
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'RepositoryException: $message';
}

class ExpenseRepository {
  final AppDatabase database;

  ExpenseRepository(this.database);

  /// Insert a new expense
  /// Throws [RepositoryException] if insertion fails
  /// Returns the ID of the inserted expense
  Future<int> create(Expense expense) async {
    try {
      // Validate before inserting
      final validationError = expense.validate();
      if (validationError != null) {
        throw RepositoryException(
          message: 'Validation error: $validationError',
        );
      }

      final db = await database.database;
      final id = await db.insert(
        'expenses',
        expense.copyWith(createdAt: DateTime.now()).toJson(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
      return id;
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to create expense: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Retrieve an expense by ID
  /// Returns null if not found
  /// Throws [RepositoryException] if query fails
  Future<Expense?> getById(int id) async {
    try {
      final db = await database.database;
      final result = await db.query(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) {
        return null;
      }

      return Expense.fromJson(result.first);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to retrieve expense: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Retrieve all expenses, optionally sorted
  /// Throws [RepositoryException] if query fails
  Future<List<Expense>> getAll({
    bool sortByDateDesc = true,
  }) async {
    try {
      final db = await database.database;
      final result = await db.query(
        'expenses',
        orderBy: sortByDateDesc ? 'date DESC, id DESC' : 'date ASC, id ASC',
      );

      return result.map((json) => Expense.fromJson(json)).toList();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to retrieve expenses: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Retrieve expenses within a date range
  /// Throws [RepositoryException] if query fails
  Future<List<Expense>> getByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await database.database;
      final startStr = startDate.toIso8601String();
      final endStr = endDate.add(Duration(days: 1)).toIso8601String();

      final result = await db.query(
        'expenses',
        where: 'date >= ? AND date < ?',
        whereArgs: [startStr, endStr],
        orderBy: 'date DESC, id DESC',
      );

      return result.map((json) => Expense.fromJson(json)).toList();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to retrieve expenses by date range: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Update an existing expense
  /// Throws [RepositoryException] if update fails
  /// Returns the number of rows affected (should be 1)
  Future<int> update(Expense expense) async {
    try {
      if (expense.id == null) {
        throw RepositoryException(
          message: 'Cannot update expense without an ID',
        );
      }

      // Validate before updating
      final validationError = expense.validate();
      if (validationError != null) {
        throw RepositoryException(
          message: 'Validation error: $validationError',
        );
      }

      final db = await database.database;
      final updatedExpense = expense.copyWith(
        modifiedAt: DateTime.now(),
      );

      final rowsAffected = await db.update(
        'expenses',
        updatedExpense.toJson(),
        where: 'id = ?',
        whereArgs: [expense.id],
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      if (rowsAffected == 0) {
        throw RepositoryException(
          message: 'Expense not found',
        );
      }

      return rowsAffected;
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to update expense: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Delete an expense by ID
  /// Throws [RepositoryException] if deletion fails
  /// Returns the number of rows affected (should be 1)
  Future<int> delete(int id) async {
    try {
      final db = await database.database;
      final rowsAffected = await db.delete(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw RepositoryException(
          message: 'Expense not found',
        );
      }

      return rowsAffected;
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to delete expense: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get total expenses by category for a date range
  /// Throws [RepositoryException] if query fails
  Future<Map<ExpenseCategory, double>> getTotalsByCategory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await database.database;
      final startStr = startDate.toIso8601String();
      final endStr = endDate.add(Duration(days: 1)).toIso8601String();

      final result = await db.rawQuery('''
        SELECT category, SUM(amount) as total
        FROM expenses
        WHERE date >= ? AND date < ?
        GROUP BY category
      ''', [startStr, endStr]);

      final totals = <ExpenseCategory, double>{};
      for (final row in result) {
        final category = categoryFromString(row['category'] as String);
        final total = (row['total'] as num).toDouble();
        totals[category] = total;
      }

      return totals;
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get totals by category: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get monthly totals for the last N months (including partial current month)
  /// Returns a list of (month string in 'YYYY-MM', total) tuples
  Future<List<(String, double)>> getMonthlyTotals(int monthCount) async {
    try {
      final db = await database.database;
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - monthCount + 1, 1);

      final result = await db.rawQuery('''
        SELECT 
          strftime('%Y-%m', date) as month,
          SUM(amount) as total
        FROM expenses
        WHERE date >= ?
        GROUP BY month
        ORDER BY month ASC
      ''', [startDate.toIso8601String()]);

      // Create a complete list with zero values for missing months
      final monthlyTotals = <(String, double)>[];
      DateTime current = DateTime(startDate.year, startDate.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);

      final resultMap = {
        for (final row in result)
          row['month'] as String: (row['total'] as num).toDouble()
      };

      while (current.isBefore(end)) {
        final monthStr =
            '${current.year}-${current.month.toString().padLeft(2, '0')}';
        monthlyTotals.add((monthStr, resultMap[monthStr] ?? 0.0));
        current = DateTime(current.year, current.month + 1, 1);
      }

      return monthlyTotals;
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get monthly totals: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get monthly expense counts for the last N months
  /// Returns a list of (month string in 'YYYY-MM', count) tuples
  Future<List<(String, int)>> getMonthlyCounts(int monthCount) async {
    try {
      final db = await database.database;
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - monthCount + 1, 1);

      final result = await db.rawQuery('''
        SELECT 
          strftime('%Y-%m', date) as month,
          COUNT(*) as count
        FROM expenses
        WHERE date >= ?
        GROUP BY month
        ORDER BY month ASC
      ''', [startDate.toIso8601String()]);

      // Create a complete list with zero values for missing months
      final monthlyCounts = <(String, int)>[];
      DateTime current = DateTime(startDate.year, startDate.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);

      final resultMap = {
        for (final row in result)
          row['month'] as String: (row['count'] as int)
      };

      while (current.isBefore(end)) {
        final monthStr =
            '${current.year}-${current.month.toString().padLeft(2, '0')}';
        monthlyCounts.add((monthStr, resultMap[monthStr] ?? 0));
        current = DateTime(current.year, current.month + 1, 1);
      }

      return monthlyCounts;
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get monthly counts: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get the top N expenses by amount
  /// Throws [RepositoryException] if query fails
  Future<List<Expense>> getTopExpenses(int limit) async {
    try {
      final db = await database.database;
      final result = await db.query(
        'expenses',
        orderBy: 'amount DESC, date DESC',
        limit: limit,
      );

      return result.map((json) => Expense.fromJson(json)).toList();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get top expenses: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get total expenses for a date range
  /// Throws [RepositoryException] if query fails
  Future<double> getTotalByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final db = await database.database;
      final startStr = startDate.toIso8601String();
      final endStr = endDate.add(Duration(days: 1)).toIso8601String();

      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM expenses WHERE date >= ? AND date < ?',
        [startStr, endStr],
      );

      if (result.isEmpty || result.first['total'] == null) {
        return 0.0;
      }

      return (result.first['total'] as num).toDouble();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get total by date range: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get the count of expenses for a date range
  Future<int> getCountByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final db = await database.database;
      final startStr = startDate.toIso8601String();
      final endStr = endDate.add(Duration(days: 1)).toIso8601String();

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM expenses WHERE date >= ? AND date < ?',
        [startStr, endStr],
      );

      if (result.isEmpty) {
        return 0;
      }

      return (result.first['count'] as int);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get count by date range: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Delete all expenses (used for testing)
  /// Throws [RepositoryException] if deletion fails
  Future<int> deleteAll() async {
    try {
      final db = await database.database;
      return await db.delete('expenses');
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to delete all expenses: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get total count of all expenses
  Future<int> getTotalCount() async {
    try {
      final db = await database.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM expenses');
      if (result.isEmpty) {
        return 0;
      }
      return (result.first['count'] as int);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get total count: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
