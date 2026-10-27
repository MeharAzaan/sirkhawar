import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';

import '../data/app_data.dart';
import '../models/quotation.dart';
import '../services/pdf_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final AppData data = AppData();
  String _selectedCompany = 'All'; // 'All', 'energy', 'electric'
  String _selectedDateRange = 'This Month';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    data.addListener(_onDataChanged);
    _updateDateRange();
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _updateDateRange() {
    final now = DateTime.now();
    if (_selectedDateRange == 'Today') {
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_selectedDateRange == 'This Week') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      _startDate = DateTime(monday.year, monday.month, monday.day);
      _endDate = _startDate.add(const Duration(days: 6, hours: 23, minutes: 59));
    } else if (_selectedDateRange == 'This Month') {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (_selectedDateRange == 'Last Month') {
      _startDate = DateTime(now.year, now.month - 1, 1);
      _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
    } else if (_selectedDateRange == 'Last 3 Months') {
      _startDate = DateTime(now.year, now.month - 3, 1);
      _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
    } else if (_selectedDateRange == 'This Year') {
      _startDate = DateTime(now.year, 1, 1);
      _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
    }
    setState(() {});
  }

  Future<void> _selectCustomDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.bankBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() {
        _selectedDateRange = 'Custom Range';
        _startDate = DateTime(range.start.year, range.start.month, range.start.day);
        _endDate = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
      });
    }
  }

  bool _isWithinRange(DateTime date) {
    return date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
        date.isBefore(_endDate.add(const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final filteredSales = data.salesHistory.where((s) =>
        _isWithinRange(s.dateOfPurchase) &&
        (_selectedCompany == 'All' || s.company == _selectedCompany)).toList();

    final filteredQuots = data.quotations.where((q) =>
        _isWithinRange(q.createdDate) &&
        (_selectedCompany == 'All' || q.company == _selectedCompany)).toList();

    final filteredExpenses = data.expenses.where((e) =>
        _isWithinRange(e.date) &&
        (_selectedCompany == 'All' || e.company == _selectedCompany)).toList();

    final filteredSalaries = data.salaryRecords.where((s) =>
        _isWithinRange(s.paymentDate) &&
        (_selectedCompany == 'All' || s.company == _selectedCompany)).toList();

    final filteredPurchases = data.purchases.where((p) => _isWithinRange(p.purchaseDate)).toList();

    final Set<String> activeCustomers = {};
    for (var s in filteredSales) {
      if (s.customerName.isNotEmpty) activeCustomers.add(s.customerName);
    }
    for (var q in filteredQuots) {
      if (q.customerName.isNotEmpty) activeCustomers.add(q.customerName);
    }

    final double totalSales = filteredSales.fold(0, (sum, s) => sum + s.totalAmount);
    final double totalPurchases = filteredPurchases.fold(0, (sum, p) => sum + p.totalAmount);
    final double totalExpenses = filteredExpenses.fold(0, (sum, e) => sum + e.amount);
    final double totalSalaries = filteredSalaries.fold(0, (sum, s) => sum + s.amount);
    final double netProfitLoss = totalSales - (totalPurchases + totalExpenses + totalSalaries);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity Reports'),
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        actions: [
          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text('Download PDF', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                setState(() => _isGenerating = true);
                try {
                  await PdfService.generateActivityReport(
                    start: _startDate,
                    end: _endDate,
                    companyFilter: _selectedCompany,
                    sales: filteredSales,
                    quotations: filteredQuots,
                    purchases: filteredPurchases,
                    expenses: filteredExpenses,
                    salaries: filteredSalaries,
                    activeCustomers: activeCustomers.toList(),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please check your internet connection'),
                        backgroundColor: AppColors.expenseRed,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isGenerating = false);
                }
              },
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCompany,
                      decoration: const InputDecoration(
                        labelText: 'Company Filter',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All (Merged)')),
                        DropdownMenuItem(value: AppCompanies.energy, child: Text('Alternative Energy Solution')),
                        DropdownMenuItem(value: AppCompanies.electric, child: Text('Alternative Electric Solutions')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedCompany = v);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDateRange,
                      decoration: const InputDecoration(
                        labelText: 'Date Range',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Today', child: Text('Today')),
                        DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                        DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                        DropdownMenuItem(value: 'Last Month', child: Text('Last Month')),
                        DropdownMenuItem(value: 'Last 3 Months', child: Text('Last 3 Months')),
                        DropdownMenuItem(value: 'This Year', child: Text('This Year')),
                        DropdownMenuItem(value: 'Custom Range', child: Text('Custom Range...')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          if (v == 'Custom Range') {
                            _selectCustomDateRange();
                          } else {
                            setState(() {
                              _selectedDateRange = v;
                              _updateDateRange();
                            });
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Showing records from ${DateFormat('dd MMM yyyy').format(_startDate)} to ${DateFormat('dd MMM yyyy').format(_endDate)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            const Text('Financial Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Total Sales', totalSales, AppColors.cashGreen, '${filteredSales.length} Invoices'),
                const SizedBox(width: 16),
                _buildStatCard('Total Purchases', totalPurchases, AppColors.pendingOrange, '${filteredPurchases.length} Purchases (Shared)'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Total Expenses', totalExpenses, AppColors.expenseRed, '${filteredExpenses.length} Records'),
                const SizedBox(width: 16),
                _buildStatCard('Total Salaries', totalSalaries, AppColors.sidebarActive, '${filteredSalaries.length} Records'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: netProfitLoss >= 0 ? AppColors.cashGreen.withOpacity(0.1) : AppColors.expenseRed.withOpacity(0.1),
                border: Border.all(color: netProfitLoss >= 0 ? AppColors.cashGreen : AppColors.expenseRed),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Profit / Loss',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: netProfitLoss >= 0 ? AppColors.cashGreen : AppColors.expenseRed),
                  ),
                  Text(
                    'Rs. ${netProfitLoss.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: netProfitLoss >= 0 ? AppColors.cashGreen : AppColors.expenseRed),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Activity & Documents Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.cardBg, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        const Text('Quotations Created', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text('${filteredQuots.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.cardBg, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        const Text('Active Customers in Period', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text('${activeCustomers.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, double amount, Color color, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Rs. ${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}