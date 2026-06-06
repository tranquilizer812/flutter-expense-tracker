import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/expense.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  Database? _database;

  factory AppDatabase() {
    return _instance;
  }

  AppDatabase._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'expense_tracker.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        receipt_uri TEXT,
        created_at TEXT NOT NULL,
        modified_at TEXT
      )
    ''');

    // Create index on date for efficient queries
    await db.execute(
      'CREATE INDEX idx_expenses_date ON expenses(date)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle schema migrations here
    // For version 1, no migration needed as it's the initial version
    if (oldVersion < 1) {
      await _onCreate(db, newVersion);
    }
  }

  Future<void> close() async {
    _database?.close();
    _database = null;
  }

  /// Executes a function within a transaction
  /// If the function throws an exception, the transaction is rolled back
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }
}

Future<AppDatabase> initializeDatabase() async {
  return AppDatabase();
}
