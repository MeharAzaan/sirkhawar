import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';

import '../models/expense.dart';
import '../models/quotation.dart'; // AppCompanies

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final AppData data = AppData();

  @override
  void initState() {
    super.initState();
    data.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _showAddExpenseDialog() async {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'General';
    String paidFrom = 'cash';
    // Default company: active filter if specific, otherwise Energy
    String company = (data.selectedCompanyFilter == AppCompanies.electric ||
            data.selectedCompanyFilter == AppCompanies.energy)
        ? data.selectedCompanyFilter
        : AppCompanies.energy;
    DateTime selectedDate = DateTime.now();
    bool saving = false;

    List<dynamic> banksForCompany() =>
        data.banks.where((b) => b.company == company).toList();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: const Text('Add Expense',
              style: TextStyle(color: AppColors.textPrimary)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Company selection
                  DropdownButtonFormField<String>(
                    dropdownColor: AppColors.cardBg,
                    value: company,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Company *',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: AppColors.sidebarActive, width: 1.5),
                      ),
                    ),
                    items: AppCompanies.all
                        .map((id) => DropdownMenuItem(
                              value: id,
                              child: Text(
                                AppCompanies.label(id),
                                style: const TextStyle(
                                    color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() {
                        company = v;
                        // Reset paid-from if current bank is not in this company
                        final validIds =
                            banksForCompany().map((b) => b.id).toSet();
                        if (paidFrom != 'cash' && !validIds.contains(paidFrom)) {
                          paidFrom = 'cash';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: AppColors.sidebarActive, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Amount *',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      prefixText: 'Rs. ',
                      prefixStyle: TextStyle(color: AppColors.textPrimary),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: AppColors.sidebarActive, width: 1.5),
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: AppColors.cardBg,
                    value: category,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: AppColors.sidebarActive, width: 1.5),
                      ),
                    ),
                    items: [
                      'General',
                      'Rent',
                      'Utilities',
                      'Salary',
                      'Transport',
                      'Supplies',
                      'Other'
                    ]
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(
                                    color: AppColors.textPrimary))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => category = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Cash + banks for selected company only
                  DropdownButtonFormField<String>(
                    dropdownColor: AppColors.cardBg,
                    value: paidFrom,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Paid From',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: AppColors.sidebarActive, width: 1.5),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: 'cash',
                          child: Text('Cash',
                              style:
                                  TextStyle(color: AppColors.textPrimary))),
                      ...banksForCompany().map((b) => DropdownMenuItem(
                            value: b.id as String,
                            child: Text(b.name as String,
                                style: const TextStyle(
                                    color: AppColors.textPrimary)),
                          )),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => paidFrom = v);
                    },
                  ),
                  // Available balance for selected source
                  const SizedBox(height: 8),
                  Builder(
                    builder: (_) {
                      final double available = paidFrom == 'cash'
                          ? data.getCashBalance(company)
                          : data.getBankBalance(paidFrom);
                      final label = paidFrom == 'cash'
                          ? 'Cash (${AppCompanies.label(company)})'
                          : data.getBankName(paidFrom);
                      return Text(
                        'Available ($label): Rs. ${available.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: available > 0
                              ? AppColors.cashGreen
                              : AppColors.expenseRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: AppColors.sidebarActive, width: 1.5),
                        ),
                      ),
                      child: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sidebarActive,
                foregroundColor: Colors.white,
              ),
              onPressed: saving
                  ? null
                  : () async {
                      if (descCtrl.text.trim().isEmpty) return;
                      final amount = double.tryParse(amountCtrl.text);
                      if (amount == null || amount <= 0) return;

                      // Balance check (company cash or bank)
                      if (paidFrom == 'cash') {
                        final available = data.getCashBalance(company);
                        if (amount > available) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Insufficient cash for ${AppCompanies.label(company)}. Available: Rs. ${available.toStringAsFixed(2)}'),
                              backgroundColor: AppColors.expenseRed,
                            ),
                          );
                          return;
                        }
                      } else {
                        final available = data.getBankBalance(paidFrom);
                        if (amount > available) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Insufficient balance in ${data.getBankName(paidFrom)}. Available: Rs. ${available.toStringAsFixed(2)}'),
                              backgroundColor: AppColors.expenseRed,
                            ),
                          );
                          return;
                        }
                      }

                      setDialogState(() => saving = true);
                      try {
                        final newId = FirebaseFirestore.instance
                            .collection('expenses')
                            .doc()
                            .id;
                        final expense = Expense(
                          id: newId,
                          description: descCtrl.text.trim(),
                          amount: amount,
                          date: selectedDate,
                          category: category,
                          paidFrom: paidFrom,
                          company: company,
                        );
                        await data.addExpense(expense);
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Failed to save. Please check your internet connection.'),
                              backgroundColor: AppColors.expenseRed,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense added'),
          backgroundColor: AppColors.cashGreen,
        ),
      );
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Delete Expense',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await data.deleteExpense(expense.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please check your internet connection'),
              backgroundColor: AppColors.expenseRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtered by global company filter (energy / electric / all)
    final expenses = data.filteredExpenses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        title: const Text('Expenses'),
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sidebarActive,
              foregroundColor: Colors.white,
            ),
            onPressed: _showAddExpenseDialog,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: expenses.isEmpty
          ? const Center(
              child: Text('No expenses',
                  style: TextStyle(
                      fontSize: 18, color: AppColors.textSecondary)))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(AppColors.background),
                      columns: const [
                        DataColumn(
                            label: Text('Date',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Company',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Description',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Category',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Paid From',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Amount',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold)),
                            numeric: true),
                        DataColumn(
                            label: Text('Actions',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold))),
                      ],
                      rows: expenses.map((e) {
                        final paidFromLabel = e.paidFrom == 'cash'
                            ? 'CASH'
                            : data.getBankName(e.paidFrom).toUpperCase();
                        // Short label for table
                        final companyLabel =
                            e.company == AppCompanies.electric
                                ? 'Electric'
                                : 'Energy';
                        return DataRow(cells: [
                          DataCell(Text(
                              '${e.date.day}/${e.date.month}/${e.date.year}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary))),
                          DataCell(Text(companyLabel,
                              style: const TextStyle(
                                  color: AppColors.textPrimary))),
                          DataCell(Text(e.description,
                              style: const TextStyle(
                                  color: AppColors.textPrimary))),
                          DataCell(Text(e.category,
                              style: const TextStyle(
                                  color: AppColors.textPrimary))),
                          DataCell(Text(paidFromLabel,
                              style: const TextStyle(
                                  color: AppColors.textPrimary))),
                          DataCell(Text(
                            'Rs. ${e.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.expenseRed),
                          )),
                          DataCell(IconButton(
                            icon: const Icon(Icons.delete,
                                color: AppColors.expenseRed, size: 20),
                            onPressed: () => _deleteExpense(e),
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}