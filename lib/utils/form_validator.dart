import '../models/expense.dart';

class FormValidationError {
  final String? dateError;
  final String? amountError;
  final String? categoryError;
  final String? noteError;
  final String? receiptError;

  FormValidationError({
    this.dateError,
    this.amountError,
    this.categoryError,
    this.noteError,
    this.receiptError,
  });

  bool get isValid =>
      dateError == null &&
      amountError == null &&
      categoryError == null &&
      noteError == null &&
      receiptError == null;

  bool get hasErrors => !isValid;
}

class FormValidator {
  /// Validate date field
  /// Returns null if valid, error message if invalid
  static String? validateDate(DateTime? selectedDate) {
    if (selectedDate == null) {
      return 'Please select a date';
    }

    final minDate = DateTime(2024, 1, 1);
    final today = DateTime.now();
    final dateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (dateOnly.isBefore(minDate)) {
      return 'Date must be on or after January 1, 2024';
    }

    if (dateOnly.isAfter(todayOnly)) {
      return 'Date cannot be in the future';
    }

    return null;
  }

  /// Validate amount field
  /// Returns null if valid, error message if invalid
  static String? validateAmount(String? amountStr) {
    if (amountStr == null || amountStr.trim().isEmpty) {
      return 'Please enter an amount';
    }

    try {
      final amount = double.parse(amountStr);

      if (amount <= 0) {
        return 'Amount must be greater than 0';
      }

      if (amount >= 1000000) {
        return 'Amount must be less than 1,000,000';
      }

      return null;
    } catch (e) {
      return 'Please enter a valid number';
    }
  }

  /// Validate category field
  /// Returns null if valid, error message if invalid
  static String? validateCategory(ExpenseCategory? category) {
    if (category == null) {
      return 'Please select a category';
    }
    return null;
  }

  /// Validate note field
  /// Returns null if valid, error message if invalid
  static String? validateNote(String? note) {
    if (note == null) {
      return null; // Note is optional
    }

    final trimmedNote = note.trim();
    if (trimmedNote.isEmpty) {
      return null; // Empty is treated as no note
    }

    if (trimmedNote.length > 500) {
      return 'Note must be 500 characters or less';
    }

    return null;
  }

  /// Validate the entire form
  static FormValidationError validateForm({
    required DateTime? selectedDate,
    required String? amountStr,
    required ExpenseCategory? selectedCategory,
    required String? note,
  }) {
    return FormValidationError(
      dateError: validateDate(selectedDate),
      amountError: validateAmount(amountStr),
      categoryError: validateCategory(selectedCategory),
      noteError: validateNote(note),
    );
  }

  /// Check if a form is ready to submit (all required fields valid)
  static bool isFormValid({
    required DateTime? selectedDate,
    required String? amountStr,
    required ExpenseCategory? selectedCategory,
  }) {
    final validation = validateForm(
      selectedDate: selectedDate,
      amountStr: amountStr,
      selectedCategory: selectedCategory,
      note: null,
    );
    return validation.isValid;
  }
}
