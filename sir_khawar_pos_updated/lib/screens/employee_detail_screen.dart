import 'package:flutter/material.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';
import 'package:sir_khawar_pos_updated/models/quotation.dart';

import '../models/employee.dart';

class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({super.key, required this.employee});
  final Employee employee;

  @override
  State<EmployeeDetailScreen> createState() =>
      _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
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

  @override
  Widget build(BuildContext context) {
    final emp = widget.employee;
    final records = data.salaryRecords
        .where((r) => r.employeeId == emp.id)
        .toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    final totalPaid =
        records.fold(0.0, (sum, r) => sum + r.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        title: Text(emp.name),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.cardBg,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          AppColors.sidebarActive.withOpacity(0.15),
                      child: Text(
                          emp.name.isNotEmpty
                              ? emp.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sidebarActive)),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp.name,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(emp.role,
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Phone: ${emp.phone}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary)),
                          Text(
                              'Joined: ${emp.joinDate.day}/${emp.joinDate.month}/${emp.joinDate.year}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary)),
                          Text(
                              'Base Salary: Rs. ${emp.baseSalary.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.cashGreen.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.headerBg.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('Total Paid',
                              style: TextStyle(color: AppColors.cashGreen)),
                          Text('Rs. ${totalPaid.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cashGreen)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Salary History',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            records.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No salary records',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 16)),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(AppColors.background),
                      columns: const [
                        DataColumn(
                            label: Text('Payment Date',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('For Month',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Method',
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
                            label: Text('Notes',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold))),
                      ],
                      rows: records.map((r) {
                        return DataRow(cells: [
                          DataCell(Text(
                              '${r.paymentDate.day}/${r.paymentDate.month}/${r.paymentDate.year}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary))),
                          DataCell(Text(r.salaryMonth,
                              style: const TextStyle(
                                  color: AppColors.textPrimary))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: r.method == PaymentMethod.cash
                                  ? AppColors.cashGreen.withOpacity(0.12)
                                  : r.method == PaymentMethod.cheque
                                      ? AppColors.pendingOrange.withOpacity(0.12)
                                      : AppColors.bankBlue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(r.method.name.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: r.method == PaymentMethod.cash
                                        ? AppColors.cashGreen
                                        : r.method == PaymentMethod.cheque
                                            ? AppColors.pendingOrange
                                            : AppColors.bankBlue)),
                          )),
                          DataCell(Text('Rs. ${r.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary))),
                          DataCell(Text(r.notes,
                              style: const TextStyle(
                                  color: AppColors.textPrimary))),
                        ]);
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}