import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../repositories/expense_repository.dart';
import '../utils/statistics_calculator.dart';

class StatisticsPanel extends StatefulWidget {
  final List<Expense> expenses;

  const StatisticsPanel({
    Key? key,
    required this.expenses,
  }) : super(key: key);

  @override
  State<StatisticsPanel> createState() => _StatisticsPanelState();
}

class _StatisticsPanelState extends State<StatisticsPanel> {
  late ExpenseRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = ExpenseRepository(AppDatabase());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Weekly Average
            _buildWeeklyAverageCard(),
            const SizedBox(height: 16),

            // Monthly Totals Chart
            _buildMonthlyTotalsCard(),
            const SizedBox(height: 16),

            // Category Breakdown
            _buildCategoryBreakdownCard(),
            const SizedBox(height: 16),

            // 12-Month Trend
            _build12MonthTrendCard(),
            const SizedBox(height: 16),

            // Top 5 Largest
            _buildTop5Card(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyAverageCard() {
    final lastWeekExpenses =
        StatisticsCalculator.getExpensesFromLastWeek(widget.expenses);
    final average = StatisticsCalculator.calculateWeeklyAverage(lastWeekExpenses);

    // Get primary currency from expenses or default to USD
    final primaryCurrency = widget.expenses.isNotEmpty
        ? widget.expenses.first.currency
        : CurrencyCode.USD;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Average',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              average > 0 ? primaryCurrency.format(average) : '—',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last 7 days (${lastWeekExpenses.length} expenses)',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTotalsCard() {
    return FutureBuilder<List<(String, double)>>(
      future: _repository.getMonthlyTotals(12),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Totals',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? 'Loading...'
                            : 'No data',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final monthlyData = snapshot.data!;
        final primaryCurrency = widget.expenses.isNotEmpty
            ? widget.expenses.first.currency
            : CurrencyCode.USD;

        final chartData =
            StatisticsCalculator.calculateMonthlyTotals(monthlyData, primaryCurrency.code);

        // Convert to bar chart data
        final barGroups = <BarChartGroupData>[];
        for (int i = 0; i < chartData.length; i++) {
          final (month, total, _) = chartData[i];
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: total,
                  color: Colors.blue,
                ),
              ],
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Totals (Last 12 Months)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      barGroups: barGroups,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: true, horizontalInterval: 50),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < chartData.length) {
                                return Text(
                                  chartData[value.toInt()].$1,
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryBreakdownCard() {
    final categoryTotals =
        StatisticsCalculator.groupByCategory(widget.expenses);

    if (categoryTotals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Category Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'No data yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final percentages =
        StatisticsCalculator.calculateCategoryPercentages(widget.expenses);

    final sections = <PieChartSectionData>[];
    final colors = <Color>[
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.grey,
    ];

    percentages.entries.asMap().entries.forEach((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final percentage = entry.value.value;

      sections.add(
        PieChartSectionData(
          color: colors[index % colors.length],
          value: percentage,
          title: '${percentage.toStringAsFixed(1)}%',
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          radius: 50,
        ),
      );
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(sections: sections),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: percentages.entries.map((entry) {
                      final index = percentages.keys.toList().indexOf(entry.key);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(entry.key.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build12MonthTrendCard() {
    return FutureBuilder<List<(String, int)>>(
      future: _repository.getMonthlyCounts(12),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '12-Month Trend',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? 'Loading...'
                            : 'No expenses yet',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final monthlyData = snapshot.data!;

        final spots = <FlSpot>[];
        for (int i = 0; i < monthlyData.length; i++) {
          final (_, count) = monthlyData[i];
          spots.add(FlSpot(i.toDouble(), count.toDouble()));
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '12-Month Trend (Expense Count)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      spots: spots,
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < monthlyData.length) {
                                final monthStr = monthlyData[value.toInt()].$1;
                                final parts = monthStr.split('-');
                                final month = int.parse(parts[1]);
                                return Text(
                                  DateFormat('MMM').format(
                                    DateTime(2024, month),
                                  ),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTop5Card() {
    final topExpenses = StatisticsCalculator.getExpensesFromLastDays(
      widget.expenses,
      365,
    );
    topExpenses.sort((a, b) {
      final amountCompare = b.amount.compareTo(a.amount);
      if (amountCompare != 0) return amountCompare;
      return b.date.compareTo(a.date);
    });

    final top5 = topExpenses.take(5).toList();

    if (top5.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top 5 Largest Expenses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No expenses yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 5 Largest Expenses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...top5.asMap().entries.map((entry) {
              final index = entry.key;
              final expense = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. ${expense.category.displayName}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy').format(expense.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      expense.currency.format(expense.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

import '../database/database.dart';
