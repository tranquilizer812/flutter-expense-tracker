enum CurrencyCode {
  USD,
  EUR,
  GBP,
  JPY,
  CAD,
  AUD,
  CHF,
  CNY,
  INR,
  MXN,
}

extension CurrencyCodeExtension on CurrencyCode {
  String get code => toString().split('.').last;
  
  String get symbol {
    switch (this) {
      case CurrencyCode.USD:
        return '\$';
      case CurrencyCode.EUR:
        return '€';
      case CurrencyCode.GBP:
        return '£';
      case CurrencyCode.JPY:
        return '¥';
      case CurrencyCode.CAD:
        return 'C\$';
      case CurrencyCode.AUD:
        return 'A\$';
      case CurrencyCode.CHF:
        return 'CHF';
      case CurrencyCode.CNY:
        return '¥';
      case CurrencyCode.INR:
        return '₹';
      case CurrencyCode.MXN:
        return '\$';
    }
  }

  String format(double amount) => '$symbol${amount.toStringAsFixed(2)}';
}

CurrencyCode currencyFromString(String code) {
  return CurrencyCode.values.firstWhere(
    (c) => c.code == code,
    orElse: () => CurrencyCode.USD,
  );
}

enum ExpenseCategory {
  Food,
  Transport,
  Entertainment,
  Other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName => toString().split('.').last;
}

ExpenseCategory categoryFromString(String name) {
  return ExpenseCategory.values.firstWhere(
    (c) => c.displayName == name,
    orElse: () => ExpenseCategory.Other,
  );
}

class Expense {
  final int? id;
  final DateTime date;
  final double amount;
  final CurrencyCode currency;
  final ExpenseCategory category;
  final String? note;
  final String? receiptUri;
  final DateTime createdAt;
  final DateTime? modifiedAt;

  Expense({
    this.id,
    required this.date,
    required this.amount,
    required this.currency,
    required this.category,
    this.note,
    this.receiptUri,
    required this.createdAt,
    this.modifiedAt,
  });

  /// Validates the expense data
  /// Returns null if valid, or an error message if invalid
  String? validate() {
    // Validate date: not before 2024-01-01 and not in future
    final minDate = DateTime(2024, 1, 1);
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (dateOnly.isBefore(minDate)) {
      return 'Date must be on or after January 1, 2024';
    }
    if (dateOnly.isAfter(todayOnly)) {
      return 'Date cannot be in the future';
    }

    // Validate amount
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (amount >= 1000000) {
      return 'Amount must be less than 1,000,000';
    }

    // Validate note length
    if (note != null && note!.length > 500) {
      return 'Note must be 500 characters or less';
    }

    return null; // Valid
  }

  /// Create a copy with optional field replacements
  Expense copyWith({
    int? id,
    DateTime? date,
    double? amount,
    CurrencyCode? currency,
    ExpenseCategory? category,
    String? note,
    String? receiptUri,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      note: note ?? this.note,
      receiptUri: receiptUri ?? this.receiptUri,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'currency': currency.code,
      'category': category.displayName,
      'note': note?.trim(),
      'receipt_uri': receiptUri,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt?.toIso8601String(),
    };
  }

  /// Create an Expense from a database row
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int?,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      currency: currencyFromString(json['currency'] as String),
      category: categoryFromString(json['category'] as String),
      note: json['note'] as String?,
      receiptUri: json['receipt_uri'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      modifiedAt: json['modified_at'] != null
          ? DateTime.parse(json['modified_at'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'Expense(id: $id, date: $date, amount: $amount, currency: $currency, category: $category)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          amount == other.amount &&
          currency == other.currency &&
          category == other.category &&
          note == other.note &&
          receiptUri == other.receiptUri;

  @override
  int get hashCode =>
      id.hashCode ^
      date.hashCode ^
      amount.hashCode ^
      currency.hashCode ^
      category.hashCode ^
      note.hashCode ^
      receiptUri.hashCode;
}
