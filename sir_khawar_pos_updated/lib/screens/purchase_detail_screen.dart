import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';
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
                        'Initial stock will be set to ${item.quantity} (from this purchase)',
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
                          quantity: item.quantity,
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
                              DateFormat('dd MMM yyyy, hh:mm a')
                                  .format(p.purchaseDate),
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
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
                        ],
                      ),
                      Text('Rs. ${p.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.bankBlue)),
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
                              'Cheque Date: ${DateFormat('dd MMM yyyy').format(p.chequeDate!)}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            if (p.chequeDate!.isAfter(DateTime.now()))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Future Dated (Pending)',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.cashGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Cleared',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.cashGreen),
                                ),
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
                                  color: AppColors.cashGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                    '✓ In Inventory (stock increased)',
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
                                  color: AppColors.expenseRed.withValues(alpha: 0.1),
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
                        child: Text('Qty: ${item.quantity}',
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
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
                      if (!inInventory)
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