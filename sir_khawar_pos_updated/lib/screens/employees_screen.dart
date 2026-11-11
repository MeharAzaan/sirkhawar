import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';

import '../models/employee.dart';
import '../models/quotation.dart';

import 'employee_detail_screen.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
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

  Future<void> _showAddEmployeeDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final designationCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Add Employee',
            style: TextStyle(color: AppColors.textPrimary)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Name *',
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
                controller: phoneCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Phone',
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
                controller: designationCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Designation',
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
                controller: salaryCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Monthly Salary',
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sidebarActive,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != true) return;
    if (nameCtrl.text.trim().isEmpty) return;

    try {
      final newId =
          FirebaseFirestore.instance.collection('employees').doc().id;
      final employee = Employee(
        id: newId,
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        role: designationCtrl.text.trim(),
        baseSalary: double.tryParse(salaryCtrl.text) ?? 0.0,
        joinDate: DateTime.now(),
      );
      await data.addEmployee(employee);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee added'),
            backgroundColor: AppColors.cashGreen,
          ),
        );
      }
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

  Future<void> _showPaySalaryDialog(Employee employee) async {
    final amountCtrl =
        TextEditingController(text: employee.baseSalary.toStringAsFixed(2));
    PaymentMethod selectedMethod = PaymentMethod.cash;

    // Filter company & banks for salary payment
    String selectedCompany = 'energy';
    final initialMatchingBanks = data.banks
        .where((b) => b.company == selectedCompany)
        .toList();
    String selectedBankId = initialMatchingBanks.isNotEmpty
        ? initialMatchingBanks.first.id
        : (data.banks.isNotEmpty ? data.banks.first.id : 'default_bank');

    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final filteredBanks = data.banks
              .where((b) => b.company == selectedCompany)
              .toList();

          if (filteredBanks.isNotEmpty &&
              !filteredBanks.any((b) => b.id == selectedBankId)) {
            selectedBankId = filteredBanks.first.id;
          }

          // Live cash balance for selected company drawer
          final availableCash = data.getCashBalance(selectedCompany);

          return AlertDialog(
            backgroundColor: AppColors.cardBg,
            title: Text('Pay Salary - ${employee.name}',
                style: const TextStyle(color: AppColors.textPrimary)),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Amount *',
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PaymentMethod>(
                      dropdownColor: AppColors.cardBg,
                      value: selectedMethod,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
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
                      items: PaymentMethod.values
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.name.toUpperCase(),
                                    style: const TextStyle(
                                        color: AppColors.textPrimary)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedMethod = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Company Selection for Cash, Bank/Online & Cheque
                    DropdownButtonFormField<String>(
                      dropdownColor: AppColors.cardBg,
                      value: selectedCompany,
                      isExpanded: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: selectedMethod == PaymentMethod.cash
                            ? 'Pay From Cash Drawer'
                            : 'Company',
                        labelStyle:
                            const TextStyle(color: AppColors.textSecondary),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: AppColors.sidebarActive, width: 1.5),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'energy',
                          child: Text('Alternative Energy Solution',
                              style: TextStyle(color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'electric',
                          child: Text('Alternative Electric Solutions',
                              style: TextStyle(color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() {
                            selectedCompany = v;
                            final updatedBanks = data.banks
                                .where((b) => b.company == selectedCompany)
                                .toList();
                            if (updatedBanks.isNotEmpty) {
                              selectedBankId = updatedBanks.first.id;
                            }
                          });
                        }
                      },
                    ),

                    // ── Available Cash Balance (when paying from cash) ──
                    if (selectedMethod == PaymentMethod.cash) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Available Cash: Rs. ${availableCash.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: availableCash > 0
                                ? AppColors.cashGreen
                                : AppColors.expenseRed,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    // Bank picker for Bank/Online & Cheque payments
                    if (selectedMethod == PaymentMethod.online ||
                        selectedMethod == PaymentMethod.cheque) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        dropdownColor: AppColors.cardBg,
                        value: filteredBanks
                                .any((b) => b.id == selectedBankId)
                            ? selectedBankId
                            : (filteredBanks.isNotEmpty
                                ? filteredBanks.first.id
                                : null),
                        isExpanded: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: selectedMethod == PaymentMethod.cheque
                              ? 'Pay From Bank (Cheque)'
                              : 'Pay From Bank',
                          labelStyle:
                              const TextStyle(color: AppColors.textSecondary),
                          border: const OutlineInputBorder(),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.sidebarActive, width: 1.5),
                          ),
                        ),
                        items: filteredBanks
                            .map((b) => DropdownMenuItem(
                                  value: b.id,
                                  child: Text(
                                    b.name,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => selectedBankId = v);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      if (filteredBanks.any((b) => b.id == selectedBankId))
                        Text(
                          'Available Balance: Rs. ${data.getBankBalance(selectedBankId).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: data.getBankBalance(selectedBankId) > 0
                                ? AppColors.cashGreen
                                : AppColors.expenseRed,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            dropdownColor: AppColors.cardBg,
                            value: selectedMonth,
                            isExpanded: true,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Month',
                              labelStyle:
                                  TextStyle(color: AppColors.textSecondary),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.sidebarActive,
                                    width: 1.5),
                              ),
                            ),
                            items: List.generate(
                              12,
                              (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text(_monthName(i + 1),
                                    style: const TextStyle(
                                        color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ),
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => selectedMonth = v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            dropdownColor: AppColors.cardBg,
                            value: selectedYear,
                            isExpanded: true,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Year',
                              labelStyle:
                                  TextStyle(color: AppColors.textSecondary),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.sidebarActive,
                                    width: 1.5),
                              ),
                            ),
                            items: List.generate(
                              5,
                              (i) => DropdownMenuItem(
                                value: DateTime.now().year - 2 + i,
                                child: Text(
                                  (DateTime.now().year - 2 + i).toString(),
                                  style: const TextStyle(
                                      color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => selectedYear = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Notes',
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
                  backgroundColor: AppColors.cashGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: saving
                    ? null
                    : () async {
                        final amount = double.tryParse(amountCtrl.text);
                        if (amount == null || amount <= 0) return;

                        // ── CASH: block if more than available drawer balance ──
                        if (selectedMethod == PaymentMethod.cash) {
                          final cashAvailable =
                              data.getCashBalance(selectedCompany);
                          if (amount > cashAvailable) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Insufficient cash in ${selectedCompany == 'electric' ? 'Electric' : 'Energy'} drawer. Available: Rs. ${cashAvailable.toStringAsFixed(2)}',
                                ),
                                backgroundColor: AppColors.expenseRed,
                              ),
                            );
                            return;
                          }
                        }

                        // ── BANK / CHEQUE: existing balance check ──
                        if (selectedMethod != PaymentMethod.cash) {
                          if (filteredBanks.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'No bank account found for this company. Please add a bank account first.'),
                                backgroundColor: AppColors.expenseRed,
                              ),
                            );
                            return;
                          }
                          final available =
                              data.getBankBalance(selectedBankId);
                          if (amount > available) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Insufficient balance in ${data.getBankName(selectedBankId)}. Available: Rs. ${available.toStringAsFixed(2)}'),
                                backgroundColor: AppColors.expenseRed,
                              ),
                            );
                            return;
                          }
                        }

                        setDialogState(() => saving = true);
                        try {
                          final newId = FirebaseFirestore.instance
                              .collection('salaryRecords')
                              .doc()
                              .id;
                          final salaryMonthStr =
                              '${_monthName(selectedMonth)} $selectedYear';
                          final record = SalaryRecord(
                            id: newId,
                            employeeId: employee.id,
                            employeeName: employee.name,
                            amount: amount,
                            salaryMonth: salaryMonthStr,
                            paymentDate: selectedDate,
                            method: selectedMethod,
                            notes: notesCtrl.text.trim(),
                            company: selectedCompany,
                            bankId: selectedMethod != PaymentMethod.cash
                                ? selectedBankId
                                : 'default_bank',
                          );
                          await data.addSalaryRecord(record);
                          if (mounted) Navigator.pop(ctx, true);
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
                    : const Text('Pay'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      final amount = double.tryParse(amountCtrl.text) ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Salary of Rs. ${amount.toStringAsFixed(2)} paid to ${employee.name}',
          ),
          backgroundColor: AppColors.cashGreen,
        ),
      );
    }
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Delete Employee',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Are you sure you want to delete ${employee.name}?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
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
      await data.deleteEmployee(employee.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee deleted'),
            backgroundColor: AppColors.cashGreen,
          ),
        );
      }
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

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final employees = data.employees;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        title: const Text('Employees'),
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Employee'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sidebarActive,
              foregroundColor: Colors.white,
            ),
            onPressed: _showAddEmployeeDialog,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: employees.isEmpty
          ? const Center(
              child: Text(
                'No employees found',
                style: TextStyle(
                    fontSize: 18, color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final emp = employees[index];
                return Card(
                  color: AppColors.cardBg,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.sidebarActive.withOpacity(0.15),
                      child: Text(
                        emp.name.isNotEmpty
                            ? emp.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.sidebarActive),
                      ),
                    ),
                    title: Text(
                      emp.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      '${emp.role} • ${emp.phone}\n'
                      'Salary: Rs. ${emp.baseSalary.toStringAsFixed(2)}',
                      style:
                          const TextStyle(color: AppColors.textSecondary),
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.payments, size: 18),
                          label: const Text('Pay Salary'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cashGreen,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showPaySalaryDialog(emp),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: AppColors.expenseRed),
                          onPressed: () => _deleteEmployee(emp),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EmployeeDetailScreen(employee: emp),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}