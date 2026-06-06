import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/expense.dart';
import '../utils/form_validator.dart';

class ExpenseForm extends StatelessWidget {
  final DateTime? selectedDate;
  final TextEditingController amountController;
  final ExpenseCategory? selectedCategory;
  final CurrencyCode? selectedCurrency;
  final TextEditingController noteController;
  final String? receiptPath;
  final FormValidationError validationErrors;
  final Function(DateTime) onDateChanged;
  final Function(String) onAmountChanged;
  final Function(ExpenseCategory?) onCategoryChanged;
  final Function(CurrencyCode?) onCurrencyChanged;
  final Function(String) onNoteChanged;
  final Function(bool) onPickImage;
  final VoidCallback? onRemoveReceipt;
  final VoidCallback onSubmit;
  final bool isSubmitEnabled;

  const ExpenseForm({
    Key? key,
    required this.selectedDate,
    required this.amountController,
    required this.selectedCategory,
    required this.selectedCurrency,
    required this.noteController,
    this.receiptPath,
    required this.validationErrors,
    required this.onDateChanged,
    required this.onAmountChanged,
    required this.onCategoryChanged,
    required this.onCurrencyChanged,
    required this.onNoteChanged,
    required this.onPickImage,
    this.onRemoveReceipt,
    required this.onSubmit,
    required this.isSubmitEnabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date field
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2024, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        onDateChanged(pickedDate);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: validationErrors.dateError != null
                              ? Colors.red
                              : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate != null
                                ? DateFormat('MMM dd, yyyy').format(selectedDate!)
                                : 'Select a date',
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  if (validationErrors.dateError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        validationErrors.dateError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Amount and Currency fields
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          onChanged: onAmountChanged,
                          decoration: InputDecoration(
                            hintText: '0.00',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: validationErrors.amountError != null
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        if (validationErrors.amountError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              validationErrors.amountError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Currency',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<CurrencyCode>(
                          value: selectedCurrency,
                          isExpanded: true,
                          onChanged: onCurrencyChanged,
                          items: CurrencyCode.values
                              .map((currency) => DropdownMenuItem(
                                    value: currency,
                                    child: Text(currency.code),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category field
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<ExpenseCategory>(
                    value: selectedCategory,
                    isExpanded: true,
                    onChanged: onCategoryChanged,
                    hint: const Text('Select a category'),
                    items: ExpenseCategory.values
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category.displayName),
                            ))
                        .toList(),
                  ),
                  if (validationErrors.categoryError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        validationErrors.categoryError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Note field
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Note',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${noteController.text.length}/500',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    onChanged: onNoteChanged,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add a note (optional)',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: validationErrors.noteError != null
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  if (validationErrors.noteError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        validationErrors.noteError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Receipt field
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Receipt Photo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (receiptPath != null)
                    Column(
                      children: [
                        Image.file(
                          File(receiptPath!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => onPickImage(true),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Replace'),
                            ),
                            ElevatedButton.icon(
                              onPressed: onRemoveReceipt,
                              icon: const Icon(Icons.delete),
                              label: const Text('Remove'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => onPickImage(true),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => onPickImage(false),
                          icon: const Icon(Icons.image),
                          label: const Text('Gallery'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitEnabled ? onSubmit : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Expense'),
            ),
          ),
        ],
      ),
    );
  }
}
