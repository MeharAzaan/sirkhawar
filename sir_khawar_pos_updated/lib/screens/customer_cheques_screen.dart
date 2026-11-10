import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import '../data/app_data.dart';
import '../models/quotation.dart';
import '../models/sale_history.dart';

class CustomerChequesScreen extends StatefulWidget {
  const CustomerChequesScreen({super.key});
  @override
  State<CustomerChequesScreen> createState() => _CustomerChequesScreenState();
}

class _CustomerChequesScreenState extends State<CustomerChequesScreen> {
  final data = AppData();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  bool _isSaving = false;

  // Cached lists to save memory/CPU on low RAM devices
  List<Map<String, dynamic>> _allCheques = [];
  List<Map<String, dynamic>> _filteredCheques = [];

  @override
  void initState() {
    super.initState();
    _prepareData(); // Load data once on start
    data.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      _prepareData(); // Rebuild cache only when database changes
    }
  }

  // --- OPTIMIZATION: Process data outside the build method ---
  void _prepareData() {
    final List<Map<String, dynamic>> list = [];
    for (var sale in data.salesHistory) {
      for (var payment in sale.payments) {
        if (payment.method == PaymentMethod.cheque) {
          list.add({
            'saleId': sale.id,
            'invoice': sale.invoiceNumber,
            'customer': sale.customerName,
            'company': sale.company,
            'payment': payment,
          });
        }
      }
    }
    _allCheques = list;
    _applyFilter();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredCheques = List.from(_allCheques);
    } else {
      final q = _searchQuery.toLowerCase();
      _filteredCheques = _allCheques.where((row) {
        final PaymentReceipt p = row['payment'];
        final depositBank = _depositBankLabel(p).toLowerCase();
        return row['invoice'].toString().toLowerCase().contains(q) ||
            row['customer'].toString().toLowerCase().contains(q) ||
            p.chequeNumber.toLowerCase().contains(q) ||
            p.bankName.toLowerCase().contains(q) ||
            depositBank.contains(q);
      }).toList();
    }
    if (mounted) setState(() {});
  }

  String formatCurrency(double amount) {
    return 'Rs. ${NumberFormat('#,##0.00', 'en_US').format(amount)}';
  }

  /// Active company for new cheque records
  String get _activeCompany {
    if (data.selectedCompanyFilter == AppCompanies.electric) {
      return AppCompanies.electric;
    }
    return AppCompanies.energy;
  }

  // Lazy generation to save memory
  List<String> _uniqueCustomerNames() {
    final names = <String>{};
    for (final sale in data.salesHistory) {
      if (sale.customerName.trim().isNotEmpty) {
        names.add(sale.customerName.trim());
      }
    }
    for (final q in data.quotations) {
      if (q.customerName.trim().isNotEmpty) {
        names.add(q.customerName.trim());
      }
    }
    return names.toList()..sort();
  }

  Future<void> _markDone(String saleId, String paymentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          'Mark Cheque as Cleared?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This will move the cheque amount into your Bank Balance immediately.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sidebarActive,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark Done'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await data.clearCheque(saleId, paymentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cheque marked as cleared'),
              backgroundColor: AppColors.cashGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please check your internet connection'),
              backgroundColor: AppColors.expenseRed,
            ),
          );
        }
      }
    }
  }

  void _showAddChequeDialog() {
    final formKey = GlobalKey<FormState>();
    final customerNameCtrl = TextEditingController();
    final customerPhoneCtrl = TextEditingController();
    final chequeNumberCtrl = TextEditingController();
    final issuingBankCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime chequeDate = DateTime.now();

    String selectedCompany = _activeCompany;
    final initialCompanyBanks =
        data.banks.where((b) => b.company == selectedCompany).toList();
    String? selectedBankId =
        initialCompanyBanks.isNotEmpty ? initialCompanyBanks.first.id : null;

    final customers = _uniqueCustomerNames();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final companyBanks = data.banks
                .where((b) => b.company == selectedCompany)
                .toList();

            if (companyBanks.isNotEmpty &&
                !companyBanks.any((b) => b.id == selectedBankId)) {
              selectedBankId = companyBanks.first.id;
            } else if (companyBanks.isEmpty) {
              selectedBankId = null;
            }

            return AlertDialog(
              backgroundColor: AppColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  const Icon(Icons.add_card, color: AppColors.bankBlue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Add Customer Cheque',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company Selection Dropdown
                        const Text('Company',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCompany,
                          dropdownColor: AppColors.cardBg,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: AppCompanies.energy,
                              child: Text('Alternative Energy Solution',
                                  style: TextStyle(color: AppColors.textPrimary)),
                            ),
                            DropdownMenuItem(
                              value: AppCompanies.electric,
                              child: Text('Alternative Electric Solutions',
                                  style: TextStyle(color: AppColors.textPrimary)),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModal(() {
                                selectedCompany = val;
                                final updatedBanks = data.banks
                                    .where((b) => b.company == selectedCompany)
                                    .toList();
                                selectedBankId = updatedBanks.isNotEmpty
                                    ? updatedBanks.first.id
                                    : null;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        // Customer Name (searchable)
                        const Text('Customer Name',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Autocomplete<String>(
                          optionsBuilder: (value) {
                            if (value.text.isEmpty) return customers;
                            return customers.where((c) => c
                                .toLowerCase()
                                .contains(value.text.toLowerCase()));
                          },
                          onSelected: (v) => customerNameCtrl.text = v,
                          fieldViewBuilder:
                              (context, controller, focusNode, onComplete) {
                            controller.addListener(() {
                              customerNameCtrl.text = controller.text;
                            });
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              style: const TextStyle(
                                  color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Enter or search customer...',
                                hintStyle: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                                prefixIcon: const Icon(Icons.person,
                                    color: AppColors.bankBlue, size: 20),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: AppColors.border),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Phone
                        const Text('Customer Phone (Optional)',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: customerPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          style:
                              const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'e.g. 0300-1234567',
                            hintStyle: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                            prefixIcon: const Icon(Icons.phone,
                                color: AppColors.bankBlue, size: 20),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Cheque # + Amount
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Cheque Number',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: chequeNumberCtrl,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary),
                                    decoration: InputDecoration(
                                      hintText: 'Cheque #',
                                      hintStyle: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13),
                                      filled: true,
                                      fillColor: AppColors.background,
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: AppColors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: AppColors.border),
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Required'
                                            : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Amount (PKR)',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: amountCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary),
                                    decoration: InputDecoration(
                                      hintText: '0.00',
                                      hintStyle: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13),
                                      filled: true,
                                      fillColor: AppColors.background,
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: AppColors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: AppColors.border),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(v.trim()) == null) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Issuing bank + Due date
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Customer's Issuing Bank",
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: issuingBankCtrl,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. HBL, Meezan',
                                      hintStyle: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13),
                                      filled: true,
                                      fillColor: AppColors.background,
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: AppColors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: AppColors.border),
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Required'
                                            : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Cheque Due Date',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: ctx,
                                        initialDate: chequeDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) {
                                        setModal(() => chequeDate = picked);
                                      }
                                    },
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                            color: AppColors.border),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              size: 16,
                                              color: AppColors.bankBlue),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat('dd MMM yyyy')
                                                .format(chequeDate),
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Deposit To Bank (your company bank) + live balance
                        const Text('Deposit To (Your Bank Account)',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        if (companyBanks.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bannerBg,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: AppColors.bannerBorder),
                            ),
                            child: const Text(
                              'No bank accounts found for this company. Please add a bank in Bank & Cash first.',
                              style: TextStyle(
                                  color: AppColors.bannerText, fontSize: 13),
                            ),
                          )
                        else
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedBankId,
                                isExpanded: true,
                                dropdownColor: AppColors.cardBg,
                                items: companyBanks.map((b) {
                                  final bal = data.getBankBalance(b.id);
                                  return DropdownMenuItem<String>(
                                    value: b.id,
                                    child: Text(
                                      '${b.name}${b.accountNumber.isNotEmpty ? " • ${b.accountNumber}" : ""}  |  Bal: ${formatCurrency(bal)}',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setModal(() => selectedBankId = val);
                                },
                              ),
                            ),
                          ),

                        if (selectedBankId != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Selected bank balance: ${formatCurrency(data.getBankBalance(selectedBankId!))}',
                            style: const TextStyle(
                              color: AppColors.bankBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Note: Bank balance updates when the cheque is due/cleared (Mark Done). Future-dated cheques stay Pending until cleared.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sidebarActive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(_isSaving ? 'Saving...' : 'Save Cheque'),
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          if (selectedBankId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please select a bank account to deposit into.'),
                                backgroundColor: AppColors.expenseRed,
                              ),
                            );
                            return;
                          }

                          final amount =
                              double.parse(amountCtrl.text.trim());
                          final now = DateTime.now();
                          final receipt = PaymentReceipt(
                            id: now.millisecondsSinceEpoch.toString(),
                            amount: amount,
                            date: now,
                            method: PaymentMethod.cheque,
                            chequeNumber: chequeNumberCtrl.text.trim(),
                            bankName: issuingBankCtrl.text.trim(),
                            chequeDate: chequeDate,
                            bankId: selectedBankId!, // links to YOUR bank
                          );

                          final invNum =
                              'CHQ-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';

                          final newSale = SaleHistory(
                            id: '${now.millisecondsSinceEpoch}',
                            invoiceNumber: invNum,
                            customerName: customerNameCtrl.text.trim(),
                            customerPhone: customerPhoneCtrl.text.trim(),
                            customerAddress: '',
                            items: const [],
                            totalAmount: amount,
                            payments: [receipt],
                            dateOfPurchase: now,
                            company: selectedCompany,
                            notes: 'Direct Customer Cheque record',
                          );

                          setModal(() {});
                          setState(() => _isSaving = true);
                          try {
                            await data.addSale(newSale);
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    chequeDate.isAfter(DateTime.now())
                                        ? 'Cheque saved as Pending. Bank balance will update when marked Done.'
                                        : 'Cheque saved. Amount added to selected bank balance.',
                                  ),
                                  backgroundColor: AppColors.cashGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please check your internet connection'),
                                  backgroundColor: AppColors.expenseRed,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isSaving = false);
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _depositBankLabel(PaymentReceipt p) {
    if (p.bankId.isEmpty) return '-';
    final bank = data.banks.where((b) => b.id == p.bankId).toList();
    if (bank.isEmpty) return p.bankId;
    return bank.first.name;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1024) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.desktop_windows_outlined,
                    size: 64, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text('Window too small',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary)),
                SizedBox(height: 8),
                Text('Please resize the window to at least 1024px wide.',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Customer Cheques',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sidebarActive,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onPressed: _showAddChequeDialog,
                    icon: const Icon(Icons.add_card, size: 18),
                    label: const Text('Add Customer Cheque'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total Cheques: ${_allCheques.length} | Pending: ${data.pendingChequeCount}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // SEARCH BAR
              SizedBox(
                width: 360,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search invoice, customer, cheque #, bank...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery = '';
                              _applyFilter();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColors.sidebarActive, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    _searchQuery = v.trim();
                    _applyFilter();
                  },
                ),
              ),
              const SizedBox(height: 20),

              // OPTIMIZED RENDER
              Expanded(
                child: _filteredCheques.isEmpty
                    ? const Center(
                        child: Text('No cheque payments recorded.',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : Container(
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
                              headingRowColor: WidgetStateProperty.all(
                                  AppColors.background),
                              columns: const [
                                DataColumn(
                                    label: Text('Invoice',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Customer',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Cheque #',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Issuing Bank',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Deposit To',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Amount',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Cheque Date',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Status',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Action',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold))),
                              ],
                              rows: _filteredCheques.map((dataRow) {
                                final PaymentReceipt p = dataRow['payment'];
                                final isPending = p.chequeDate != null &&
                                    p.chequeDate!.isAfter(DateTime.now());
                                return DataRow(cells: [
                                  DataCell(Text(dataRow['invoice'],
                                      style: const TextStyle(
                                          color: AppColors.textPrimary))),
                                  DataCell(Text(dataRow['customer'],
                                      style: const TextStyle(
                                          color: AppColors.textPrimary))),
                                  DataCell(Text(p.chequeNumber,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary))),
                                  DataCell(Text(p.bankName,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary))),
                                  DataCell(Text(
                                    _depositBankLabel(p),
                                    style: const TextStyle(
                                        color: AppColors.bankBlue,
                                        fontWeight: FontWeight.w600),
                                  )),
                                  DataCell(Text(formatCurrency(p.amount),
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold))),
                                  DataCell(Text(
                                      p.chequeDate != null
                                          ? DateFormat('yyyy-MM-dd')
                                              .format(p.chequeDate!)
                                          : '-',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPending
                                            ? AppColors.pendingOrange
                                                .withOpacity(0.12)
                                            : AppColors.cashGreen
                                                .withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isPending ? 'Pending' : 'Cleared',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isPending
                                              ? AppColors.pendingOrange
                                              : AppColors.cashGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    isPending
                                        ? TextButton.icon(
                                            onPressed: () => _markDone(
                                              dataRow['saleId'],
                                              p.id,
                                            ),
                                            icon: const Icon(
                                                Icons.check_circle,
                                                size: 16,
                                                color: AppColors.cashGreen),
                                            label: const Text('Mark Done',
                                                style: TextStyle(
                                                    color:
                                                        AppColors.cashGreen)),
                                          )
                                        : const Text('-',
                                            style: TextStyle(
                                                color:
                                                    AppColors.textSecondary)),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}