import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import '../data/app_data.dart';
import '../models/sale_history.dart';

class InvoiceFormatScreen extends StatelessWidget {
  final SaleHistory invoice;
  const InvoiceFormatScreen({super.key, required this.invoice});

  // Sum of all line-item discounts
  double get _totalDiscount =>
      invoice.items.fold(0.0, (sum, i) => sum + i.discount);

  Future<void> _generatePdf(BuildContext context) async {
    final settings = AppData().settings;
    final dateFormat = DateFormat('dd MMM, yy');
    final currency = NumberFormat('#,##0.00');

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load(
        settings.logoPath.isNotEmpty
            ? settings.logoPath
            : 'assets/images/logo.jpeg',
      );
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final pdf = pw.Document();
    final double paid = invoice.paidAmount;
    final double remaining = invoice.remainingAmount;
    final double discount = _totalDiscount;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // ===== MAIN CONTENT =====
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // LOGO + ADDRESS
                  pw.Center(
                    child: pw.Column(
                      children: [
                        if (logoImage != null)
                          pw.Image(logoImage, height: 80)
                        else
                          pw.Text(
                            'ALTERNATIVE ENERGY SOLUTIONS',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        pw.SizedBox(height: 8),
                        pw.Text(settings.addressLine1,
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(settings.addressLine2,
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(settings.addressLine3,
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(settings.phone,
                            style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 24),

                  // DATE + INVOICE #
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.SizedBox(
                      width: 200,
                      child: pw.Table(
                        border: pw.TableBorder.all(width: 1),
                        children: [
                          pw.TableRow(children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('Date:',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                dateFormat.format(invoice.dateOfPurchase),
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ]),
                          pw.TableRow(children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('Invoice #:',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                invoice.invoiceNumber,
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // INVOICE BANNER
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#DCE6F1'),
                      border: pw.Border.all(width: 1),
                    ),
                    child: pw.Text(
                      'INVOICE',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // BILL TO
                  pw.Text('Bill To:',
                      style: const pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    invoice.customerName,
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                  if (invoice.customerPhone.isNotEmpty)
                    pw.Text(invoice.customerPhone,
                        style: const pw.TextStyle(fontSize: 10)),
                  if (invoice.customerAddress.isNotEmpty)
                    pw.Text(invoice.customerAddress,
                        style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 20),

                  // ITEMS TABLE
                  pw.Table(
                    border: pw.TableBorder.all(width: 1),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(4),
                      1: const pw.FlexColumnWidth(1.5),
                      2: const pw.FlexColumnWidth(1),
                      3: const pw.FlexColumnWidth(1.5),
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#DCE6F1'),
                        ),
                        children: [
                          _pdfTh('Description'),
                          _pdfTh('Unit Price'),
                          _pdfTh('Qty'),
                          _pdfTh('Amount'),
                        ],
                      ),
                      ...invoice.items.map((item) {
                        final amount =
                            (item.unitPrice * item.quantity) - item.discount;
                        return pw.TableRow(children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item.productName,
                                style: const pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              currency.format(item.unitPrice),
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              item.quantity.toString(),
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              currency.format(amount),
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                        ]);
                      }),
                    ],
                  ),
                  pw.SizedBox(height: 24),

                  // ===== TOTALS TABLE (Total Bill / Discount / Paid / Balance) =====
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.SizedBox(
                      width: 280,
                      child: pw.Table(
                        border: pw.TableBorder.all(width: 1),
                        children: [
                          _pdfTotalRow('Total Bill:',
                              currency.format(invoice.totalAmount),
                              bold: true),
                          if (discount > 0)
                            _pdfTotalRow(
                                'Discount:', currency.format(discount)),
                          _pdfTotalRow(
                              'Paid Amount:', currency.format(paid)),
                          _pdfTotalRow(
                            'Balance Due:',
                            currency.format(remaining < 0 ? 0 : remaining),
                            bold: true,
                            highlight: remaining > 0,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Optional notes
                  if (invoice.notes.isNotEmpty) ...[
                    pw.SizedBox(height: 24),
                    pw.Text('Notes:',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(invoice.notes,
                        style: const pw.TextStyle(fontSize: 10)),
                  ],

                  // ===== SIGNATURES =====
                  pw.Spacer(),
                  pw.SizedBox(height: 40),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 180,
                            height: 1,
                            color: PdfColors.black,
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Customer Signature',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 180,
                            height: 1,
                            color: PdfColors.black,
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Owner / Authorized Signature',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${invoice.invoiceNumber}',
    );
  }

  // Helper for PDF totals rows
  pw.TableRow _pdfTotalRow(String label, String value,
      {bool bold = false, bool highlight = false}) {
    return pw.TableRow(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: 11,
            color: highlight ? PdfColors.red : PdfColors.black,
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          value,
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: 11,
            color: highlight ? PdfColors.red : PdfColors.black,
          ),
        ),
      ),
    ]);
  }

  pw.Widget _pdfTh(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppData().settings;
    final DateFormat dateFormat = DateFormat('dd MMM, yy');
    const Color headerColor = AppColors.background;
    final double paid = invoice.paidAmount;
    final double remaining = invoice.remainingAmount;
    final double discount = _totalDiscount;
    final currency = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        title: Text('Invoice: ${invoice.invoiceNumber}'),
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Convert to PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _generatePdf(context),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Print',
            onPressed: () => _generatePdf(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 800,
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              boxShadow: [
                BoxShadow(
                  color: AppColors.headerBg.withOpacity(0.08),
                  blurRadius: 10,
                )
              ],
            ),
            child: Stack(
              children: [
                // ===== MAIN CONTENT =====
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LOGO & ADDRESS
                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            settings.logoPath.isNotEmpty
                                ? settings.logoPath
                                : 'assets/images/logo.jpeg',
                            height: 100,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 100,
                              width: 200,
                              color: AppColors.background,
                              alignment: Alignment.center,
                              child: const Text('Logo image missing',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(settings.addressLine1,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textPrimary)),
                          Text(settings.addressLine2,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textPrimary)),
                          Text(settings.addressLine3,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textPrimary)),
                          Text(settings.phone,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // DATE & INVOICE TABLE
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 250,
                        child: Table(
                          border:
                              TableBorder.all(color: AppColors.textPrimary, width: 1),
                          children: [
                            TableRow(children: [
                              const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Date:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.textPrimary)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  dateFormat.format(invoice.dateOfPurchase),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.textPrimary),
                                ),
                              ),
                            ]),
                            TableRow(children: [
                              const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Invoice #:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.textPrimary)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  invoice.invoiceNumber,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.textPrimary),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // INVOICE BANNER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: headerColor,
                        border: Border.all(color: AppColors.textPrimary, width: 1),
                      ),
                      child: const Text(
                        'INVOICE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // BILL TO
                    const Text('Bill To:',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(invoice.customerName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    if (invoice.customerPhone.isNotEmpty)
                      Text(invoice.customerPhone,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary)),
                    if (invoice.customerAddress.isNotEmpty)
                      Text(invoice.customerAddress,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 24),

                    // ITEMS TABLE
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(4),
                        1: FlexColumnWidth(1.5),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1.5),
                      },
                      border: TableBorder.all(color: AppColors.textPrimary, width: 1),
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(color: headerColor),
                          children: [
                            _th('Description'),
                            _th('Unit\nPrice'),
                            _th('Qty'),
                            _th('Amount'),
                          ],
                        ),
                        ...invoice.items.map((item) {
                          final amount = (item.unitPrice * item.quantity) -
                              item.discount;
                          return TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(item.productName,
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.textPrimary)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                currency.format(item.unitPrice),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textPrimary),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                item.quantity.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textPrimary),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                currency.format(amount),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textPrimary),
                              ),
                            ),
                          ]);
                        }),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ===== TOTALS TABLE =====
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 340,
                        child: Table(
                          border:
                              TableBorder.all(color: AppColors.textPrimary, width: 1),
                          children: [
                            _uiTotalRow(
                              'Total Bill:',
                              currency.format(invoice.totalAmount),
                              bold: true,
                            ),
                            if (discount > 0)
                              _uiTotalRow(
                                'Discount:',
                                currency.format(discount),
                              ),
                            _uiTotalRow(
                              'Paid Amount:',
                              currency.format(paid),
                            ),
                            _uiTotalRow(
                              'Balance Due:',
                              currency.format(remaining < 0 ? 0 : remaining),
                              bold: true,
                              highlight: remaining > 0,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ===== SIGNATURES =====
                    const SizedBox(height: 80),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 200,
                              height: 1,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Customer Signature',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              width: 200,
                              height: 1,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Owner / Authorized Signature',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for on-screen totals rows
  TableRow _uiTotalRow(String label, String value,
      {bool bold = false, bool highlight = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 15 : 14,
      color: highlight ? AppColors.expenseRed : AppColors.textPrimary,
    );
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(label, style: style),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: style,
        ),
      ),
    ]);
  }

  Widget _th(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            fontSize: 13),
      ),
    );
  }
}