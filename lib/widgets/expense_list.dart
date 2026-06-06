import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../repositories/expense_repository.dart';

class ExpenseList extends StatelessWidget {
  final List<Expense> expenses;
  final Function(Expense) onEdit;
  final VoidCallback onRefresh;

  const ExpenseList({
    Key? key,
    required this.expenses,
    required this.onEdit,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return ExpenseListItem(
            expense: expense,
            onEdit: () => onEdit(expense),
            onDelete: () => _showDeleteConfirmation(context, expense),
            onRefresh: onRefresh,
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Delete ${expense.currency.symbol}${expense.amount.toStringAsFixed(2)} expense from ${DateFormat('MMM dd, yyyy').format(expense.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final repository = context.read<ExpenseRepository>();
                if (expense.id != null) {
                  await repository.delete(expense.id!);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense deleted'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    onRefresh();
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  const ExpenseListItem({
    Key? key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(),
          child: Icon(
            _getCategoryIcon(),
            color: Colors.white,
          ),
        ),
        title: Text(expense.category.displayName),
        subtitle: Text(
          DateFormat('MMM dd, yyyy').format(expense.date),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              expense.currency.format(expense.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (expense.note != null && expense.note!.isNotEmpty)
              Text(
                expense.note!.substring(0, math.min(20, expense.note!.length)),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        onTap: onEdit,
        onLongPress: onDelete,
      ),
    );
  }

  Color _getCategoryColor() {
    switch (expense.category) {
      case ExpenseCategory.Food:
        return Colors.orange;
      case ExpenseCategory.Transport:
        return Colors.blue;
      case ExpenseCategory.Entertainment:
        return Colors.purple;
      case ExpenseCategory.Other:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon() {
    switch (expense.category) {
      case ExpenseCategory.Food:
        return Icons.restaurant;
      case ExpenseCategory.Transport:
        return Icons.directions_car;
      case ExpenseCategory.Entertainment:
        return Icons.movie;
      case ExpenseCategory.Other:
        return Icons.category;
    }
  }
}

import 'dart:math' as math;
