import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';
import 'package:sir_khawar_pos_updated/models/quotation.dart';
import '../models/bank_account.dart';
import '../models/product.dart';
import '../models/purchase.dart';

class PurchaseDetailScreen extends StatefulWidget {
  const PurchaseDetailScreen({super.key, required this.purchase});
  final Purchase purchase;

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  final AppData data = AppData();
  bool _returning = false;

  // UI-only: reusable formatters (constructed once, reused).
  // Same patterns as before — output is identical.
  static final _dateFmtLong  = DateFormat('dd MMM yyyy, hh:mm a');
  static final _dateFmtShort = DateFormat('dd MMM yyyy');

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

  Purchase get _purchase =>
      data.purchases.firstWhere((p) => p.id == widget.purchase.id,
          orElse: () => widget.purchase);

  List<PurchaseReturn> get _relatedReturns =>
      data.purchaseReturns.where((r) => r.purchaseId == _purchase.id).toList();

  Future<void> _showReturnDialog() async {
    final p = _purchase;
    final List<TextEditingController> qtyControllers = List.generate(
      p.items.length,
      (i) => TextEditingController(text: '0'),
    );
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Initial default refund payment method & bank selection
    String selectedRefundMethod =
        p.paymentMethod == 'cheque' ? 'cash' : p.paymentMethod;
    String? selectedRefundBankId = p.bankId;

    if (selectedRefundMethod == 'bank' &&
        (selectedRefundBankId == null || selectedRefundBankId.isEmpty)) {
      final matchingBanks =
          data.banks.where((b) => b.company == p.company).toList();
      if (matchingBanks.isNotEmpty) {
        selectedRefundBankId = matchingBanks.first.id;
      } else if (data.banks.isNotEmpty) {
        selectedRefundBankId = data.banks.first.id;
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          double calculatedRefund = 0.0;
          for (int i = 0; i < p.items.length; i++) {
            final parsed = int.tryParse(qtyControllers[i].text.trim()) ?? 0;
            calculatedRefund += parsed * p.items[i].unitPrice;
          }

          final availableBanks = data.banks;

          return AlertDialog(
            backgroundColor: AppColors.cardBg,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Return Purchase Items',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  'Original Purchase: ${p.id} • Vendor: ${p.vendorName}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            content: Container(
              width: MediaQuery.of(ctx).size.width * 0.8,
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bankBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.bankBlue.withOpacity(0.3)),
                        ),
                        child: const Text(
                          '• Original purchase record will NOT be deleted.\n'
                          '• Returned amount will generate a CREDIT refund into the selected account.\n'
                          '• Stock will be reduced for returned items in inventory.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.bankBlue,
                              height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Select Refund Deposit Account
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Deposit Refund Into Account',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedRefundMethod = 'cash';
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Radio<String>(
                                            value: 'cash',
                                            groupValue: selectedRefundMethod,
                                            onChanged: (val) {
                                              if (val != null) {
                                                setDialogState(() {
                                                  selectedRefundMethod = val;
                                                });
                                              }
                                            },
                                          ),
                                          Expanded(
                                            child: Text(
                                              'Cash Drawer (${AppCompanies.label(p.company)})',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedRefundMethod = 'bank';
                                        if (selectedRefundBankId == null ||
                                            selectedRefundBankId!.isEmpty) {
                                          final companyBanks = data.banks
                                              .where((b) =>
                                                  b.company == p.company)
                                              .toList();
                                          if (companyBanks.isNotEmpty) {
                                            selectedRefundBankId =
                                                companyBanks.first.id;
                                          } else if (data.banks.isNotEmpty) {
                                            selectedRefundBankId =
                                                data.banks.first.id;
                                          }
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Radio<String>(
                                            value: 'bank',
                                            groupValue: selectedRefundMethod,
                                            onChanged: (val) {
                                              if (val != null) {
                                                setDialogState(() {
                                                  selectedRefundMethod = val;
                                                  if (selectedRefundBankId ==
                                                          null ||
                                                      selectedRefundBankId!
                                                          .isEmpty) {
                                                    final companyBanks = data
                                                        .banks
                                                        .where((b) =>
                                                            b.company ==
                                                            p.company)
                                                        .toList();
                                                    if (companyBanks
                                                        .isNotEmpty) {
                                                      selectedRefundBankId =
                                                          companyBanks.first.id;
                                                    } else if (data
                                                        .banks.isNotEmpty) {
                                                      selectedRefundBankId =
                                                          data.banks.first.id;
                                                    }
                                                  }
                                                });
                                              }
                                            },
                                          ),
                                          const Text(
                                            'Bank Account',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (selectedRefundMethod == 'bank') ...[
                              const SizedBox(height: 6),
                              if (availableBanks.isEmpty)
                                const Text(
                                  'No bank accounts registered. Please add a bank account in Bank Ledger.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.expenseRed),
                                )
                              else
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: availableBanks.any(
                                          (b) => b.id == selectedRefundBankId)
                                      ? selectedRefundBankId
                                      : availableBanks.first.id,
                                  decoration: const InputDecoration(
                                    labelText: 'Select Refund Bank Account *',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: availableBanks.map((b) {
                                    return DropdownMenuItem<String>(
                                      value: b.id,
                                      child: Text(
                                        '${b.name} - ${b.accountTitle} (${b.accountNumber})',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      selectedRefundBankId = val;
                                    });
                                  },
                                  validator: (v) {
                                    if (selectedRefundMethod == 'bank' &&
                                        (v == null || v.isEmpty)) {
                                      return 'Select bank account';
                                    }
                                    return null;
                                  },
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Select Items & Quantities to Return',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                          TextButton.icon(
                            icon: const Icon(Icons.select_all, size: 16),
                            label: const Text('Return All Remaining'),
                            onPressed: () {
                              setDialogState(() {
                                for (int i = 0; i < p.items.length; i++) {
                                  qtyControllers[i].text =
                                      p.items[i].remainingQuantity.toString();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      ...List.generate(p.items.length, (i) {
                        final item = p.items[i];
                        final rem = item.remainingQuantity;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: AppColors.border, width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Bought: ${item.quantity} | Prev Returned: ${item.returnedQuantity} | Avail to Return: $rem',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: rem > 0
                                              ? AppColors.textSecondary
                                              : AppColors.expenseRed),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Rs. ${item.unitPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                child: TextFormField(
                                  controller: qtyControllers[i],
                                  keyboardType: TextInputType.number,
                                  enabled: rem > 0,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 8),
                                    border: const OutlineInputBorder(),
                                    suffixText: '/$rem',
                                    suffixStyle: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary),
                                  ),
                                  onChanged: (_) => setDialogState(() {}),
                                  validator: (v) {
                                    final val = int.tryParse(v ?? '') ?? 0;
                                    if (val < 0) return 'Invalid';
                                    if (val > rem) return 'Max $rem';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Return Reason / Notes (Optional)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cashGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.cashGreen),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Refund (Credit In):',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary),
                            ),
                            Text(
                              'Rs. ${calculatedRefund.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.cashGreen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expenseRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final Map<int, int> returnMap = {};
                  for (int i = 0; i < p.items.length; i++) {
                    final qty =
                        int.tryParse(qtyControllers[i].text.trim()) ?? 0;
                    if (qty > 0) {
                      returnMap[i] = qty;
                    }
                  }

                  if (returnMap.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select at least 1 item to return'),
                        backgroundColor: AppColors.expenseRed,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  setState(() => _returning = true);

                  try {
                    await data.processPurchaseReturn(
                      purchaseId: p.id,
                      returnQuantities: returnMap,
                      paymentMethod: selectedRefundMethod,
                      bankId: selectedRefundMethod == 'bank'
                          ? selectedRefundBankId
                          : null,
                      notes: notesCtrl.text.trim(),
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Return processed! Money credited back into selected account.'),
                        backgroundColor: AppColors.cashGreen,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please check your internet connection'),
                        backgroundColor: AppColors.expenseRed,
                      ),
                    );
                  } finally {
                    if (mounted) setState(() => _returning = false);
                  }
                },
                child: const Text('Confirm Return'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addItemToInventory(int index, PurchaseItem item) async {
    final nameCtrl = TextEditingController(text: item.productName);
    final categoryCtrl = TextEditingController();
    final priceCtrl =
        TextEditingController(text: item.unitPrice.toStringAsFixed(2));
    final unitCtrl = TextEditingController(text: 'pcs');
    final descriptionCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: const Text('Add to Inventory'),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          border: OutlineInputBorder()),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder()),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Sale Price *',
                                border: OutlineInputBorder()),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            validator: (v) {
                              final d = double.tryParse(v ?? '');
                              if (d == null || d < 0) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: unitCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cashGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Initial stock will be set to ${item.remainingQuantity} (available from this purchase)',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.cashGreen,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cashGreen,
                  foregroundColor: Colors.white),
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        final newId = FirebaseFirestore.instance
                            .collection('products')
                            .doc()
                            .id;
                        final newProduct = Product(
                          id: newId,
                          name: nameCtrl.text.trim(),
                          category: categoryCtrl.text.trim(),
                          price: double.parse(priceCtrl.text.trim()),
                          quantity: item.remainingQuantity,
                          unit: unitCtrl.text.trim().isEmpty
                              ? 'pcs'
                              : unitCtrl.text.trim(),
                          description: descriptionCtrl.text.trim(),
                        );
                        await data.addPurchaseItemToInventory(
                          purchaseId: _purchase.id,
                          itemIndex: index,
                          newProduct: newProduct,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Item added to inventory'),
                              backgroundColor: AppColors.cashGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please check your internet connection'),
                            backgroundColor: AppColors.expenseRed,
                          ),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Add to Inventory'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _purchase;
    final returns = _relatedReturns;

    BankAccount? selectedBank;
    if (p.bankId != null && p.bankId!.isNotEmpty) {
      try {
        selectedBank = data.banks.firstWhere((b) => b.id == p.bankId);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Purchase Details (${p.id})'),
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        actions: [
          if (!p.isFullyReturned)
            TextButton.icon(
              onPressed: _returning ? null : _showReturnDialog,
              icon: _returning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.undo, color: Colors.white),
              label: Text(
                p.totalReturnedQuantity > 0 ? 'Return More Items' : 'Return Items',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 8),
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
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.vendorName,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(
                              _dateFmtLong.format(p.purchaseDate),
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: p.paymentMethod == 'cash'
                                      ? AppColors.cashGreen.withOpacity(0.1)
                                      : p.paymentMethod == 'bank'
                                          ? AppColors.bankBlue.withOpacity(0.1)
                                          : Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: p.paymentMethod == 'cash'
                                        ? AppColors.cashGreen
                                        : p.paymentMethod == 'bank'
                                            ? AppColors.bankBlue
                                            : Colors.purple,
                                  ),
                                ),
                                child: Text(
                                  p.paymentMethod.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: p.paymentMethod == 'cash'
                                        ? AppColors.cashGreen
                                        : p.paymentMethod == 'bank'
                                            ? AppColors.bankBlue
                                            : Colors.purple,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.bankBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border:
                                      Border.all(color: AppColors.bankBlue),
                                ),
                                child: Text(
                                  AppCompanies.label(p.company),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.bankBlue,
                                  ),
                                ),
                              ),
                              if (p.isFullyReturned)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.expenseRed.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: AppColors.expenseRed),
                                  ),
                                  child: const Text(
                                    'FULLY RETURNED',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.expenseRed,
                                    ),
                                  ),
                                )
                              else if (p.isPartiallyReturned)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.orange),
                                  ),
                                  child: const Text(
                                    'PARTIALLY RETURNED',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Original: Rs. ${p.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.bankBlue)),
                          if (p.totalReturnedAmount > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Returned (Credit Refund): +Rs. ${p.totalReturnedAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cashGreen),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Net Outflow: Rs. ${(p.totalAmount - p.totalReturnedAmount).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  if (selectedBank != null || p.paymentMethod == 'cheque') ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Payment Details',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    if (selectedBank != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.account_balance,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Bank Account: ${selectedBank.name} (${selectedBank.accountTitle} - ${selectedBank.accountNumber})',
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (p.paymentMethod == 'cheque') ...[
                      if (p.chequeNumber.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text('Cheque No: ${p.chequeNumber}',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (p.chequeBankName.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.apartment,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text('Cheque Issuing Bank: ${p.chequeBankName}',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (p.chequeDate != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              'Cheque Date: ${_dateFmtShort.format(p.chequeDate!)}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                  if (p.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Notes: ${p.notes}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ],
              ),
            ),

            if (returns.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Return History (Credit Refunds)',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ...returns.map((ret) {
                final refundBankName = ret.bankId != null && ret.bankId!.isNotEmpty
                    ? data.getBankName(ret.bankId!)
                    : '';
                return Card(
                  color: AppColors.cardBg,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Return Date: ${_dateFmtLong.format(ret.returnDate)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary),
                            ),
                            Text(
                              'Refund (Credit In): +Rs. ${ret.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.cashGreen),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Deposited To: ${ret.paymentMethod.toUpperCase()}${refundBankName.isNotEmpty ? ' ($refundBankName)' : ''}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.bankBlue),
                        ),
                        if (ret.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Reason: ${ret.notes}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          children: ret.items.map((ri) {
                            return Text(
                              '• ${ri.productName} × ${ri.quantity} (Rs. ${ri.total.toStringAsFixed(2)})',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),
            const Text('Items',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            ...List.generate(p.items.length, (i) {
              final item = p.items[i];
              final inInventory = item.productId.isNotEmpty &&
                  data.products.any((pr) => pr.id == item.productId);

              return Card(
                color: AppColors.cardBg,
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 15)),
                            const SizedBox(height: 4),
                            if (inInventory)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.cashGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                    '✓ In Inventory (stock synced)',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.cashGreen,
                                        fontWeight: FontWeight.w600)),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.expenseRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('⚠ Not in Inventory',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.expenseRed,
                                        fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bought: ${item.quantity}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                            if (item.returnedQuantity > 0)
                              Text('Returned: ${item.returnedQuantity}',
                                  style: const TextStyle(
                                      color: AppColors.expenseRed,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            Text('Remaining: ${item.remainingQuantity}',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                            'Rs. ${item.unitPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                      ),
                      Expanded(
                        child: Text('Rs. ${item.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                      ),
                      if (!inInventory && item.remainingQuantity > 0)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add to Inventory'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sidebarActive,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _addItemToInventory(i, item),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}