import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';
import 'package:sir_khawar_pos_updated/models/quotation.dart';

import '../models/sale_history.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({Key? key, required this.sale})
      : super(key: key);
  final SaleHistory sale;

  @override
  State<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
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

  SaleHistory get _currentSale {
    return data.salesHistory.firstWhere(
      (s) => s.id == widget.sale.id,
      orElse: () => widget.sale,
    );
  }

  double _paid(SaleHistory s) =>
      s.payments.fold(0.0, (sum, p) => sum + p.amount);

  Future<void> _addPaymentDialog() async {
    final sale = _currentSale;
    final paid = _paid(sale);
    final due = sale.totalAmount - paid;

    if (due <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Already fully paid'),
            backgroundColor: AppColors.pendingOrange),
      );
      return;
    }

    final amountCtrl =
        TextEditingController(text: due.toStringAsFixed(2));
    final supplierAmountCtrl = TextEditingController();
    PaymentMethod selectedMethod = PaymentMethod.cash;
    final chequeNoCtrl = TextEditingController();
    final bankNameCtrl = TextEditingController();
    final txnIdCtrl = TextEditingController();
    DateTime chequeDate =
        DateTime.now().add(const Duration(days: 30));

    bool paySupplierDirect = false;
    String? selectedSupplierId;
    String selectedSupplierName = '';

    final suppliers = List.of(data.vendors)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final paymentAmount =
              double.tryParse(amountCtrl.text.trim()) ?? 0.0;
          final supplierAmount = paySupplierDirect
              ? (double.tryParse(supplierAmountCtrl.text.trim()) ?? 0.0)
              : 0.0;
          final netToBusiness = paymentAmount - supplierAmount;

          return AlertDialog(
            backgroundColor: AppColors.cardBg,
            title: const Text('Record Payment',
                style: TextStyle(color: AppColors.textPrimary)),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Balance Due: Rs. ${due.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.expenseRed)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      style:
                          const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                          labelText: 'Amount *',
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
                          prefixText: 'Rs. ',
                          prefixStyle:
                              TextStyle(color: AppColors.textPrimary)),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PaymentMethod>(
                      dropdownColor: AppColors.cardBg,
                      value: selectedMethod,
                      isExpanded: true,
                      style:
                          const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                          labelText: 'Payment Method',
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
                          )),
                      items: PaymentMethod.values
                          .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.name.toUpperCase(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedMethod = v);
                        }
                      },
                    ),
                    if (selectedMethod == PaymentMethod.cheque) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: chequeNoCtrl,
                        style: const TextStyle(
                            color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                            labelText: 'Cheque Number',
                            labelStyle: TextStyle(
                                color: AppColors.textSecondary),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: AppColors.sidebarActive,
                                  width: 1.5),
                            )),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: bankNameCtrl,
                        style: const TextStyle(
                            color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                            labelText: 'Bank Name',
                            labelStyle: TextStyle(
                                color: AppColors.textSecondary),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: AppColors.sidebarActive,
                                  width: 1.5),
                            )),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: chequeDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => chequeDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              labelText: 'Cheque Date',
                              labelStyle: TextStyle(
                                  color: AppColors.textSecondary),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.sidebarActive,
                                    width: 1.5),
                              )),
                          child: Text(
                              '${chequeDate.day}/${chequeDate.month}/${chequeDate.year}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary)),
                        ),
                      ),
                    ],
                    if (selectedMethod == PaymentMethod.online) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: txnIdCtrl,
                        style: const TextStyle(
                            color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                            labelText: 'Transaction ID',
                            labelStyle: TextStyle(
                                color: AppColors.textSecondary),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: AppColors.sidebarActive,
                                  width: 1.5),
                            )),
                      ),
                    ],

                    // ── Direct Payment to Supplier ──
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border),
                    InkWell(
                      onTap: () => setDialogState(() {
                        paySupplierDirect = !paySupplierDirect;
                        if (!paySupplierDirect) {
                          selectedSupplierId = null;
                          selectedSupplierName = '';
                          supplierAmountCtrl.clear();
                        }
                      }),
                      child: Row(
                        children: [
                          Checkbox(
                            value: paySupplierDirect,
                            activeColor: AppColors.sidebarActive,
                            onChanged: (v) => setDialogState(() {
                              paySupplierDirect = v ?? false;
                              if (!paySupplierDirect) {
                                selectedSupplierId = null;
                                selectedSupplierName = '';
                                supplierAmountCtrl.clear();
                              }
                            }),
                          ),
                          const Expanded(
                            child: Text(
                              'Direct Payment to Supplier',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (paySupplierDirect) ...[
                      const SizedBox(height: 8),
                      if (suppliers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'No vendors found. Add a vendor first.',
                            style: TextStyle(
                                color: AppColors.expenseRed, fontSize: 12),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          dropdownColor: AppColors.cardBg,
                          value: selectedSupplierId,
                          isExpanded: true,
                          style: const TextStyle(
                              color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Supplier / Vendor *',
                            labelStyle: TextStyle(
                                color: AppColors.textSecondary),
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
                          items: suppliers
                              .map((v) => DropdownMenuItem<String>(
                                    value: v.id,
                                    child: Text(
                                      v.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            final match =
                                suppliers.where((e) => e.id == v).toList();
                            setDialogState(() {
                              selectedSupplierId = v;
                              selectedSupplierName = match.isNotEmpty
                                  ? match.first.name
                                  : '';
                            });
                          },
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: supplierAmountCtrl,
                        style: const TextStyle(
                            color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Amount to Supplier *',
                          labelStyle: TextStyle(
                              color: AppColors.textSecondary),
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
                          prefixText: 'Rs. ',
                          prefixStyle:
                              TextStyle(color: AppColors.textPrimary),
                          helperText:
                              'Portion of this payment sent directly to supplier',
                          helperStyle: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer invoice credit: Rs. ${paymentAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'To supplier: Rs. ${supplierAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppColors.expenseRed,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Net to business (cash/bank): Rs. ${netToBusiness.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppColors.cashGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel',
                      style:
                          TextStyle(color: AppColors.textSecondary))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cashGreen,
                    foregroundColor: Colors.white),
                onPressed: () {
                  final amount =
                      double.tryParse(amountCtrl.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a valid payment amount'),
                        backgroundColor: AppColors.expenseRed,
                      ),
                    );
                    return;
                  }
                  if (amount > due) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Amount exceeds balance due'),
                        backgroundColor: AppColors.expenseRed,
                      ),
                    );
                    return;
                  }
                  if (paySupplierDirect) {
                    if (selectedSupplierId == null ||
                        selectedSupplierId!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Select a supplier / vendor'),
                          backgroundColor: AppColors.expenseRed,
                        ),
                      );
                      return;
                    }
                    final sAmt = double.tryParse(
                        supplierAmountCtrl.text.trim());
                    if (sAmt == null || sAmt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Enter a valid supplier amount'),
                          backgroundColor: AppColors.expenseRed,
                        ),
                      );
                      return;
                    }
                    if (sAmt > amount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Supplier amount cannot exceed payment amount'),
                          backgroundColor: AppColors.expenseRed,
                        ),
                      );
                      return;
                    }
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Record'),
              ),
            ],
          );
        },
      ),
    );

    if (result != true) return;

    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;
    if (amount > due) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Amount exceeds balance due'),
            backgroundColor: AppColors.expenseRed),
      );
      return;
    }

    double supplierPayAmount = 0.0;
    if (paySupplierDirect) {
      supplierPayAmount =
          double.tryParse(supplierAmountCtrl.text.trim()) ?? 0.0;
      if (selectedSupplierId == null ||
          supplierPayAmount <= 0 ||
          supplierPayAmount > amount) {
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child:
            CircularProgressIndicator(color: AppColors.sidebarActive),
      ),
    );

    try {
      final payment = PaymentReceipt(
        id: FirebaseFirestore.instance.collection('payments').doc().id,
        amount: amount,
        date: DateTime.now(),
        method: selectedMethod,
        chequeNumber: selectedMethod == PaymentMethod.cheque
            ? chequeNoCtrl.text.trim()
            : '',
        bankName: selectedMethod == PaymentMethod.cheque
            ? bankNameCtrl.text.trim()
            : '',
        transactionId: selectedMethod == PaymentMethod.online
            ? txnIdCtrl.text.trim()
            : '',
        chequeDate:
            selectedMethod == PaymentMethod.cheque ? chequeDate : null,
        supplierId: paySupplierDirect ? (selectedSupplierId ?? '') : '',
        supplierName: paySupplierDirect ? selectedSupplierName : '',
        supplierPaymentAmount:
            paySupplierDirect ? supplierPayAmount : 0.0,
      );

      await data.addInstallmentPayment(sale: sale, payment: payment);

      if (mounted) {
        Navigator.of(context).pop(); // loader
        final net = amount - supplierPayAmount;
        final msg = paySupplierDirect && supplierPayAmount > 0
            ? 'Payment of Rs. ${amount.toStringAsFixed(2)} recorded '
                '(Rs. ${supplierPayAmount.toStringAsFixed(2)} → supplier, '
                'Rs. ${net.toStringAsFixed(2)} → business)'
            : 'Payment of Rs. ${amount.toStringAsFixed(2)} recorded';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(msg), backgroundColor: AppColors.cashGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('SocketException') ||
                      e.toString().toLowerCase().contains('network') ||
                      e.toString().contains('Unavailable')
                  ? 'Please check your internet connection'
                  : 'Error: $e',
            ),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sale = _currentSale;
    final paid = _paid(sale);
    final due = sale.totalAmount - paid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        title: Text('Invoice ${sale.invoiceNumber}'),
        elevation: 0,
        actions: [
          if (due > 0)
            ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text('Add Payment'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cashGreen,
                  foregroundColor: Colors.white),
              onPressed: _addPaymentDialog,
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: AppColors.cardBg,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sale.invoiceNumber,
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          Text(
                              'Date: ${sale.dateOfPurchase.day}/${sale.dateOfPurchase.month}/${sale.dateOfPurchase.year}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          if (sale.quotationId.isNotEmpty)
                            Text('Quotation: ${sale.quotationId}',
                                style: const TextStyle(
                                    color: AppColors.sidebarActive)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: AppColors.cardBg,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bill To',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(sale.customerName,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          if (sale.customerPhone.isNotEmpty)
                            Text(sale.customerPhone,
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                          if (sale.customerAddress.isNotEmpty)
                            Text(sale.customerAddress,
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              color: AppColors.cardBg,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Items',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                            AppColors.background),
                        columns: const [
                          DataColumn(
                              label: Text('Product',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Qty',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.bold)),
                              numeric: true),
                          DataColumn(
                              label: Text('Unit Price',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.bold)),
                              numeric: true),
                          DataColumn(
                              label: Text('Discount',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.bold)),
                              numeric: true),
                          DataColumn(
                              label: Text('Total',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.bold)),
                              numeric: true),
                        ],
                        rows: sale.items.map((item) {
                          final itemTotal =
                              (item.unitPrice * item.quantity) -
                                  item.discount;
                          return DataRow(cells: [
                            DataCell(Text(item.productName,
                                style: const TextStyle(
                                    color: AppColors.textPrimary))),
                            DataCell(Text(item.quantity.toString(),
                                style: const TextStyle(
                                    color: AppColors.textPrimary))),
                            DataCell(Text(
                                'Rs. ${item.unitPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: AppColors.textPrimary))),
                            DataCell(Text(
                                'Rs. ${item.discount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: AppColors.textPrimary))),
                            DataCell(Text(
                                'Rs. ${itemTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary))),
                          ]);
                        }).toList(),
                      ),
                    ),
                    const Divider(thickness: 2, color: AppColors.border),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 280,
                        child: Column(
                          children: [
                            _totalRow('Grand Total', sale.totalAmount,
                                bold: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: AppColors.cardBg,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: AppColors.cashGreen.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text('Amount Paid',
                              style:
                                  TextStyle(color: AppColors.cashGreen)),
                          Text('Rs. ${paid.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cashGreen)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: AppColors.cardBg,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: (due > 0
                                  ? AppColors.expenseRed
                                  : AppColors.cashGreen)
                              .withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text('Balance Due',
                              style: TextStyle(
                                  color: due > 0
                                      ? AppColors.expenseRed
                                      : AppColors.textSecondary)),
                          Text('Rs. ${due.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: due > 0
                                      ? AppColors.expenseRed
                                      : AppColors.cashGreen)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Payment History',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            sale.payments.isEmpty
                ? const Card(
                    color: AppColors.cardBg,
                    elevation: 1,
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                          child: Text('No payments recorded yet',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16))),
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
                      headingRowColor: WidgetStateProperty.all(
                          AppColors.background),
                      columns: const [
                        DataColumn(
                            label: Text('Date',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Method',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Cheque #',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Bank',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Txn ID',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Supplier',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Amount',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold)),
                            numeric: true),
                      ],
                      rows: sale.payments.map((p) {
                        final hasSupplier = p.hasSupplierDirectPayment;
                        return DataRow(cells: [
                          DataCell(Text(
                              '${p.date.day}/${p.date.month}/${p.date.year}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.method == PaymentMethod.cash
                                  ? AppColors.cashGreen.withOpacity(0.12)
                                  : p.method == PaymentMethod.cheque
                                      ? AppColors.pendingOrange
                                          .withValues(alpha: 0.12)
                                      : AppColors.bankBlue
                                          .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(p.method.name.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: p.method == PaymentMethod.cash
                                        ? AppColors.cashGreen
                                        : p.method ==
                                                PaymentMethod.cheque
                                            ? AppColors.pendingOrange
                                            : AppColors.bankBlue)),
                          )),
                          DataCell(Text(p.chequeNumber,
                              style: const TextStyle(
                                  color: AppColors.textPrimary))),
                          DataCell(Text(p.bankName,
                              style: const TextStyle(
                                  color: AppColors.textPrimary))),
                          DataCell(Text(p.transactionId,
                              style: const TextStyle(
                                  color: AppColors.textPrimary))),
                          DataCell(
                            hasSupplier
                                ? Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p.supplierName,
                                          style: const TextStyle(
                                              color:
                                                  AppColors.textPrimary,
                                              fontSize: 12)),
                                      Text(
                                        'Rs. ${p.supplierPaymentAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            color: AppColors.expenseRed,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  )
                                : const Text('—',
                                    style: TextStyle(
                                        color:
                                            AppColors.textSecondary)),
                          ),
                          DataCell(Text(
                              'Rs. ${p.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
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

  Widget _totalRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 16 : 14,
                  color: AppColors.textPrimary)),
          Text('Rs. ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 16 : 14,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}