import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';
import '../repositories/expense_repository.dart';
import '../utils/form_validator.dart';
import '../utils/image_handler.dart';
import '../widgets/expense_form.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormScreen({Key? key, this.expense}) : super(key: key);

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  DateTime? _selectedDate;
  ExpenseCategory? _selectedCategory;
  CurrencyCode? _selectedCurrency;
  String? _receiptPath;
  FormValidationError _validationErrors = FormValidationError();
  bool _hasUnsavedChanges = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _selectedDate = DateTime.now();
    _loadDefaultCurrency();

    if (widget.expense != null) {
      _populateFormWithExpense(widget.expense!);
    }
  }

  void _populateFormWithExpense(Expense expense) {
    _selectedDate = expense.date;
    _amountController.text = expense.amount.toString();
    _selectedCategory = expense.category;
    _selectedCurrency = expense.currency;
    _noteController.text = expense.note ?? '';
    _receiptPath = expense.receiptUri;
  }

  Future<void> _loadDefaultCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString('default_currency') ?? 'USD';
    setState(() {
      _selectedCurrency = currencyFromString(currencyCode);
    });
  }

  Future<void> _saveCurrency() async {
    if (_selectedCurrency != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_currency', _selectedCurrency!.code);
    }
  }

  void _validateForm() {
    final errors = FormValidator.validateForm(
      selectedDate: _selectedDate,
      amountStr: _amountController.text,
      selectedCategory: _selectedCategory,
      note: _noteController.text,
    );

    setState(() {
      _validationErrors = errors;
    });
  }

  Future<void> _submitForm() async {
    _validateForm();

    if (!_validationErrors.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = context.read<ExpenseRepository>();

      final expense = Expense(
        id: widget.expense?.id,
        date: _selectedDate!,
        amount: double.parse(_amountController.text),
        currency: _selectedCurrency!,
        category: _selectedCategory!,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        receiptUri: _receiptPath,
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
      );

      if (widget.expense == null) {
        // Create new expense
        await repository.create(expense);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense saved successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Update existing expense
        await repository.update(expense);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      await _saveCurrency();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    try {
      String? imagePath;

      if (fromCamera) {
        imagePath = await ImageHandler.pickImageFromCamera();
      } else {
        imagePath = await ImageHandler.pickImageFromGallery();
      }

      if (imagePath != null) {
        setState(() {
          _receiptPath = imagePath;
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _removeReceipt() async {
    if (_receiptPath != null) {
      try {
        await ImageHandler.deleteImage(_receiptPath!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting image: ${e.toString()}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }

    setState(() {
      _receiptPath = null;
      _hasUnsavedChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text('Do you want to discard your changes?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Discard'),
                ),
              ],
            ),
          ) ??
              false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ExpenseForm(
                selectedDate: _selectedDate,
                amountController: _amountController,
                selectedCategory: _selectedCategory,
                selectedCurrency: _selectedCurrency,
                noteController: _noteController,
                receiptPath: _receiptPath,
                validationErrors: _validationErrors,
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                    _hasUnsavedChanges = true;
                    _validateForm();
                  });
                },
                onAmountChanged: (amount) {
                  setState(() {
                    _hasUnsavedChanges = true;
                    _validateForm();
                  });
                },
                onCategoryChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                    _hasUnsavedChanges = true;
                    _validateForm();
                  });
                },
                onCurrencyChanged: (currency) {
                  setState(() {
                    _selectedCurrency = currency;
                    _hasUnsavedChanges = true;
                  });
                },
                onNoteChanged: (note) {
                  setState(() {
                    _hasUnsavedChanges = true;
                    _validateForm();
                  });
                },
                onPickImage: _pickImage,
                onRemoveReceipt: _receiptPath != null ? _removeReceipt : null,
                onSubmit: _submitForm,
                isSubmitEnabled: _validationErrors.isValid && !_isLoading,
              ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
