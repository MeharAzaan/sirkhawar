
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';

import '../models/sale_history.dart';
import '../models/quotation.dart';
import 'invoice_format_screen.dart';
import 'quotation_preview_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerName});
  final String customerName;

  @override
  State<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  final AppData data = AppData();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    data.addListener(_onDataChanged);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  List<SaleHistory> get _customerSales => data.salesHistory
      .where((s) => s.customerName == widget.customerName)
      .toList()
    ..sort((a, b) => b.dateOfPurchase.compareTo(a.dateOfPurchase));

  List<Quotation> get _customerQuotations => data.quotations
      .where((q) => q.customerName == widget.customerName)
      .toList()
    ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

  // ============ ADD INSTALLMENT / PAYMENT ============
  Future<void> _showAddPaymentDialog(SaleHistory sale) async {
    final paid = sale.payments.fold(0.0, (s, p) => s + p.amount);
    final due = sale.totalAmount - paid;
    if (due <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This invoice is already fully paid'),
          backgroundColor: AppColors.cashGreen,
        ),
      );
      return;
    }

    final amountCtrl = TextEditingController(
        text: due > 0 ? due.toStringAsFixed(2) : '');
    final chequeNoCtrl = TextEditingController();
    final bankNameCtrl = TextEditingController();
    final txnCtrl = TextEditingController();
    PaymentMethod method = PaymentMethod.cash;
    String selectedBankId = data.banks.isNotEmpty
        ? data.banks.first.id
        : 'default_bank'; // 👈 NEW
    DateTime? chequeDate;
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBg,
              title: Text('Add Payment — ${sale.invoiceNumber}',
                  style: const TextStyle(color: AppColors.textPrimary)),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due: Rs. ${due.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.expenseRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount *',
                          border: OutlineInputBorder(),
                          prefixText: 'Rs. ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<PaymentMethod>(
                        value: method,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: PaymentMethod.cash,
                              child: Text('Cash')),
                          DropdownMenuItem(
                              value: PaymentMethod.online,
                              child: Text('Bank / Online')),
                          DropdownMenuItem(
                              value: PaymentMethod.cheque,
                              child: Text('Cheque')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => method = v);
                          }
                        },
                      ),
                      // 👇 NEW: Bank picker for online payments (money goes INTO this bank)
                      if (method == PaymentMethod.online) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedBankId,
                          decoration: const InputDecoration(
                            labelText: 'Received In Bank',
                            border: OutlineInputBorder(),
                          ),
                          items: data.banks
                              .map((b) => DropdownMenuItem(
                                    value: b.id,
                                    child: Text(b.name),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => selectedBankId = v);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: txnCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Transaction ID (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (method == PaymentMethod.cheque) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: chequeNoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cheque Number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: bankNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Customer\'s Bank Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        // 👇 NEW: Bank picker for cheque (which of YOUR banks will it deposit into)
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedBankId,
                          decoration: const InputDecoration(
                            labelText: 'Deposit Into Bank',
                            border: OutlineInputBorder(),
                          ),
                          items: data.banks
                              .map((b) => DropdownMenuItem(
                                    value: b.id,
                                    child: Text(b.name),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => selectedBankId = v);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            chequeDate == null
                                ? 'Cheque Date (optional)'
                                : 'Cheque Date: ${DateFormat('dd/MM/yyyy').format(chequeDate!)}',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate:
                                  DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 365)),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365 * 2)),
                            );
                            if (picked != null) {
                              setDialogState(() => chequeDate = picked);
                            }
                          },
                        ),
                      ],
                    ],
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
                    foregroundColor: Colors.white,
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          final amount =
                              double.tryParse(amountCtrl.text.trim()) ?? 0;
                          if (amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enter a valid amount'),
                                backgroundColor: AppColors.expenseRed,
                              ),
                            );
                            return;
                          }
                          if (amount > due + 0.01) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Amount cannot exceed due (Rs. ${due.toStringAsFixed(2)})'),
                                backgroundColor: AppColors.expenseRed,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => saving = true);
                          try {
                            final payment = PaymentReceipt(
                              id: FirebaseFirestore.instance
                                  .collection('payments')
                                  .doc()
                                  .id,
                              amount: amount,
                              date: DateTime.now(),
                              method: method,
                              chequeNumber: chequeNoCtrl.text.trim(),
                              bankName: bankNameCtrl.text.trim(),
                              transactionId: txnCtrl.text.trim(),
                              chequeDate: method == PaymentMethod.cheque
                                  ? chequeDate
                                  : null,
                              bankId: method != PaymentMethod.cash
                                  ? selectedBankId
                                  : 'default_bank', // 👈 NEW
                            );

                            await data.addInstallmentPayment(
                              sale: sale,
                              payment: payment,
                            );

                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Payment added successfully'),
                                  backgroundColor: AppColors.cashGreen,
                                ),
                              );
                            }
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
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============ GENERATE CUSTOMER HISTORY PDF ============
  Future<void> _generateCustomerPdf() async {
    final settings = data.settings;
    final sales = _customerSales;
    final quotations = _customerQuotations;
    final currency = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('dd MMM yyyy');

    final totalPurchases =
        sales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final totalPaid = sales.fold(
        0.0,
        (sum, s) =>
            sum + s.payments.fold(0.0, (ps, p) => ps + p.amount));
    final outstanding = totalPurchases - totalPaid;

    pw.MemoryImage? logoImage;
    try {
      final bytes = await rootBundle.load(
        settings.logoPath.isNotEmpty
            ? settings.logoPath
            : 'assets/images/logo.jpeg',
      );
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Center(
            child: pw.Column(children: [
              if (logoImage != null)
                pw.Image(logoImage, height: 70)
              else
                pw.Text('ALTERNATIVE ENERGY SOLUTIONS',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(settings.addressLine1,
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text(settings.addressLine2,
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text(settings.addressLine3,
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text(settings.phone,
                  style: const pw.TextStyle(fontSize: 9)),
            ]),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#DCE6F1'),
              border: pw.Border.all(width: 1),
            ),
            child: pw.Text(
              'CUSTOMER ACCOUNT STATEMENT',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Customer:',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(widget.customerName,
                      style: pw.TextStyle(
                          fontSize: 13, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Text('Date: ${dateFmt.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(width: 1),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#DCE6F1')),
                children: [
                  _pdfCell('Total Purchases', bold: true),
                  _pdfCell('Total Paid', bold: true),
                  _pdfCell('Outstanding', bold: true),
                ],
              ),
              pw.TableRow(children: [
                _pdfCell('Rs. ${currency.format(totalPurchases)}'),
                _pdfCell('Rs. ${currency.format(totalPaid)}'),
                _pdfCell('Rs. ${currency.format(outstanding)}',
                    bold: true),
              ]),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text('INVOICES / SALES HISTORY',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (sales.isEmpty)
            pw.Text('No invoices found.',
                style: const pw.TextStyle(fontSize: 10))
          else
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.4),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.2),
                5: const pw.FlexColumnWidth(1.0),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#DCE6F1')),
                  children: [
                    _pdfCell('Invoice #', bold: true, size: 9),
                    _pdfCell('Date', bold: true, size: 9),
                    _pdfCell('Total', bold: true, size: 9),
                    _pdfCell('Paid', bold: true, size: 9),
                    _pdfCell('Due', bold: true, size: 9),
                    _pdfCell('Status', bold: true, size: 9),
                  ],
                ),
                ...sales.map((s) {
                  final paid =
                      s.payments.fold(0.0, (a, p) => a + p.amount);
                  final dueAmt = s.totalAmount - paid;
                  final status = dueAmt <= 0
                      ? 'Paid'
                      : (paid > 0 ? 'Partial' : 'Unpaid');
                  return pw.TableRow(children: [
                    _pdfCell(s.invoiceNumber, size: 9),
                    _pdfCell(dateFmt.format(s.dateOfPurchase), size: 9),
                    _pdfCell(currency.format(s.totalAmount), size: 9),
                    _pdfCell(currency.format(paid), size: 9),
                    _pdfCell(currency.format(dueAmt), size: 9),
                    _pdfCell(status, size: 9),
                  ]);
                }),
              ],
            ),
          if (sales.any((s) => s.payments.isNotEmpty)) ...[
            pw.SizedBox(height: 20),
            pw.Text('PAYMENT DETAILS',
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.3),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.0),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#DCE6F1')),
                  children: [
                    _pdfCell('Invoice #', bold: true, size: 9),
                    _pdfCell('Date', bold: true, size: 9),
                    _pdfCell('Method', bold: true, size: 9),
                    _pdfCell('Amount', bold: true, size: 9),
                    _pdfCell('Cheque / Ref', bold: true, size: 9),
                  ],
                ),
                ...sales.expand((s) => s.payments.map((p) {
                      final ref = p.method.name == 'cheque'
                          ? '${p.chequeNumber} (${p.bankName})'
                          : (p.transactionId.isNotEmpty
                              ? p.transactionId
                              : '-');
                      return pw.TableRow(children: [
                        _pdfCell(s.invoiceNumber, size: 9),
                        _pdfCell(dateFmt.format(p.date), size: 9),
                        _pdfCell(p.method.name.toUpperCase(), size: 9),
                        _pdfCell(currency.format(p.amount), size: 9),
                        _pdfCell(ref, size: 9),
                      ]);
                    })),
              ],
            ),
          ],
          pw.SizedBox(height: 20),
          pw.Text('QUOTATIONS',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (quotations.isEmpty)
            pw.Text('No quotations found.',
                style: const pw.TextStyle(fontSize: 10))
          else
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.4),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#DCE6F1')),
                  children: [
                    _pdfCell('Quotation #', bold: true, size: 9),
                    _pdfCell('Date', bold: true, size: 9),
                    _pdfCell('Amount', bold: true, size: 9),
                    _pdfCell('Status', bold: true, size: 9),
                  ],
                ),
                ...quotations.map((q) => pw.TableRow(children: [
                      _pdfCell(q.id, size: 9),
                      _pdfCell(dateFmt.format(q.createdDate), size: 9),
                      _pdfCell(currency.format(q.grandTotal), size: 9),
                      _pdfCell(q.status.name, size: 9),
                    ])),
              ],
            ),
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.SizedBox(height: 4),
          pw.Text(
            'This is a computer-generated statement. For queries contact ${settings.phone}',
            style:
                const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          'Customer_Statement_${widget.customerName.replaceAll(' ', '_')}',
    );
  }

  pw.Widget _pdfCell(String text, {bool bold = false, double size = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: size,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sales = _customerSales;
    final quotations = _customerQuotations;

    final totalPurchases =
        sales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final totalPaid = sales.fold(
        0.0,
        (sum, s) =>
            sum + s.payments.fold(0.0, (ps, p) => ps + p.amount));
    final outstanding = totalPurchases - totalPaid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        title: Text(widget.customerName),
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Export PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
            ),
            onPressed: _generateCustomerPdf,
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.sidebarInactive,
          indicatorColor: AppColors.sidebarActive,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Invoices (${sales.length})'),
            Tab(text: 'Quotations (${quotations.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _summaryCard(
                    'Total Purchases',
                    'Rs. ${totalPurchases.toStringAsFixed(2)}',
                    AppColors.bankBlue),
                const SizedBox(width: 16),
                _summaryCard('Total Paid',
                    'Rs. ${totalPaid.toStringAsFixed(2)}',
                    AppColors.cashGreen),
                const SizedBox(width: 16),
                _summaryCard(
                    'Outstanding',
                    'Rs. ${outstanding.toStringAsFixed(2)}',
                    outstanding > 0
                        ? AppColors.expenseRed
                        : AppColors.textSecondary),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                sales.isEmpty
                    ? const Center(
                        child: Text('No invoices',
                            style:
                                TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sales.length,
                        itemBuilder: (context, index) {
                          final sale = sales[index];
                          final paid = sale.payments
                              .fold(0.0, (s, p) => s + p.amount);
                          final due = sale.totalAmount - paid;
                          return Card(
                            color: AppColors.cardBg,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                  color: AppColors.border),
                            ),
                            child: ListTile(
                              title: Text(sale.invoiceNumber,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary)),
                              subtitle: Text(
                                  '${sale.dateOfPurchase.day}/${sale.dateOfPurchase.month}/${sale.dateOfPurchase.year} • Due: Rs. ${due.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                      'Rs. ${sale.totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(width: 8),
                                  if (due > 0)
                                    IconButton(
                                      tooltip: 'Add Payment',
                                      icon: const Icon(
                                          Icons.payment,
                                          color: AppColors.cashGreen),
                                      onPressed: () =>
                                          _showAddPaymentDialog(sale),
                                    ),
                                  IconButton(
                                    tooltip: 'View Invoice',
                                    icon: const Icon(Icons.visibility,
                                        color: AppColors.sidebarActive),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              InvoiceFormatScreen(
                                                  invoice: sale),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => InvoiceFormatScreen(
                                        invoice: sale),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                quotations.isEmpty
                    ? const Center(
                        child: Text('No quotations',
                            style:
                                TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: quotations.length,
                        itemBuilder: (context, index) {
                          final q = quotations[index];
                          return Card(
                            color: AppColors.cardBg,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                  color: AppColors.border),
                            ),
                            child: ListTile(
                              title: Text(q.id,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary)),
                              subtitle: Text(
                                  '${q.createdDate.day}/${q.createdDate.month}/${q.createdDate.year} • ${q.status.name}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                              trailing: Text(
                                  'Rs. ${q.grandTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.textPrimary)),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        QuotationPreviewScreen(
                                      quotation: q,
                                      onBack: () =>
                                          Navigator.pop(context),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.headerBg.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: _getTextColorForValue(color),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Color _getTextColorForValue(Color accentColor) {
    if (accentColor == AppColors.textSecondary) {
      return AppColors.textPrimary;
    }
    return accentColor;
  }
}