import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/utils/form_validator.dart';
import 'package:expense_tracker/models/expense.dart';

void main() {
  group('FormValidator Tests', () {
    group('Date Validation Tests', () {
      test('Valid date passes validation', () {
        final validDate = DateTime.now();
        expect(FormValidator.validateDate(validDate), isNull);
      });

      test('Null date fails validation', () {
        expect(FormValidator.validateDate(null), isNotNull);
      });

      test('Date before 2024-01-01 fails validation', () {
        final invalidDate = DateTime(2023, 12, 31);
        final error = FormValidator.validateDate(invalidDate);
        expect(error, isNotNull);
        expect(error, contains('January 1, 2024'));
      });

      test('Date in future fails validation', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final error = FormValidator.validateDate(futureDate);
        expect(error, isNotNull);
        expect(error, contains('future'));
      });

      test('2024-01-01 passes validation', () {
        final minDate = DateTime(2024, 1, 1);
        expect(FormValidator.validateDate(minDate), isNull);
      });

      test('Today passes validation', () {
        final today = DateTime.now();
        expect(FormValidator.validateDate(today), isNull);
      });
    });

    group('Amount Validation Tests', () {
      test('Valid amount passes validation', () {
        expect(FormValidator.validateAmount('100.00'), isNull);
        expect(FormValidator.validateAmount('50'), isNull);
        expect(FormValidator.validateAmount('0.01'), isNull);
      });

      test('Null amount fails validation', () {
        expect(FormValidator.validateAmount(null), isNotNull);
      });

      test('Empty amount fails validation', () {
        expect(FormValidator.validateAmount(''), isNotNull);
        expect(FormValidator.validateAmount('   '), isNotNull);
      });

      test('Non-numeric amount fails validation', () {
        final error = FormValidator.validateAmount('abc');
        expect(error, isNotNull);
        expect(error, contains('valid number'));
      });

      test('Zero amount fails validation', () {
        final error = FormValidator.validateAmount('0');
        expect(error, isNotNull);
        expect(error, contains('greater than 0'));
      });

      test('Negative amount fails validation', () {
        final error = FormValidator.validateAmount('-50');
        expect(error, isNotNull);
        expect(error, contains('greater than 0'));
      });

      test('Amount >= 1,000,000 fails validation', () {
        final error = FormValidator.validateAmount('1000000');
        expect(error, isNotNull);
        expect(error, contains('less than 1,000,000'));
      });

      test('Amount < 1,000,000 passes validation', () {
        expect(FormValidator.validateAmount('999999.99'), isNull);
      });
    });

    group('Category Validation Tests', () {
      test('Valid category passes validation', () {
        expect(
          FormValidator.validateCategory(ExpenseCategory.Food),
          isNull,
        );
        expect(
          FormValidator.validateCategory(ExpenseCategory.Transport),
          isNull,
        );
      });

      test('Null category fails validation', () {
        expect(FormValidator.validateCategory(null), isNotNull);
      });
    });

    group('Note Validation Tests', () {
      test('Null note passes validation', () {
        expect(FormValidator.validateNote(null), isNull);
      });

      test('Empty note passes validation', () {
        expect(FormValidator.validateNote(''), isNull);
        expect(FormValidator.validateNote('   '), isNull);
      });

      test('Valid note passes validation', () {
        expect(FormValidator.validateNote('This is a test note'), isNull);
      });

      test('Note with 500 characters passes validation', () {
        final note = 'a' * 500;
        expect(FormValidator.validateNote(note), isNull);
      });

      test('Note with 501 characters fails validation', () {
        final note = 'a' * 501;
        final error = FormValidator.validateNote(note);
        expect(error, isNotNull);
        expect(error, contains('500 characters'));
      });
    });

    group('Form Validation Tests', () {
      test('Valid form passes validation', () {
        final validation = FormValidator.validateForm(
          selectedDate: DateTime.now(),
          amountStr: '100.00',
          selectedCategory: ExpenseCategory.Food,
          note: 'Test note',
        );

        expect(validation.isValid, isTrue);
      });

      test('Invalid date makes form invalid', () {
        final validation = FormValidator.validateForm(
          selectedDate: DateTime(2023, 12, 31),
          amountStr: '100.00',
          selectedCategory: ExpenseCategory.Food,
          note: null,
        );

        expect(validation.isValid, isFalse);
        expect(validation.dateError, isNotNull);
      });

      test('Invalid amount makes form invalid', () {
        final validation = FormValidator.validateForm(
          selectedDate: DateTime.now(),
          amountStr: 'invalid',
          selectedCategory: ExpenseCategory.Food,
          note: null,
        );

        expect(validation.isValid, isFalse);
        expect(validation.amountError, isNotNull);
      });

      test('Missing category makes form invalid', () {
        final validation = FormValidator.validateForm(
          selectedDate: DateTime.now(),
          amountStr: '100.00',
          selectedCategory: null,
          note: null,
        );

        expect(validation.isValid, isFalse);
        expect(validation.categoryError, isNotNull);
      });

      test('Multiple errors are captured', () {
        final validation = FormValidator.validateForm(
          selectedDate: DateTime(2023, 12, 31),
          amountStr: 'invalid',
          selectedCategory: null,
          note: 'a' * 501,
        );

        expect(validation.isValid, isFalse);
        expect(validation.dateError, isNotNull);
        expect(validation.amountError, isNotNull);
        expect(validation.categoryError, isNotNull);
        expect(validation.noteError, isNotNull);
      });
    });

    group('isFormValid Tests', () {
      test('Valid form returns true', () {
        expect(
          FormValidator.isFormValid(
            selectedDate: DateTime.now(),
            amountStr: '100.00',
            selectedCategory: ExpenseCategory.Food,
          ),
          isTrue,
        );
      });

      test('Invalid form returns false', () {
        expect(
          FormValidator.isFormValid(
            selectedDate: null,
            amountStr: '100.00',
            selectedCategory: ExpenseCategory.Food,
          ),
          isFalse,
        );
      });
    });
  });
}
