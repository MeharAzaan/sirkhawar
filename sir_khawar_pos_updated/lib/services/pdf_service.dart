import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../models/quotation.dart';
import '../models/sale_history.dart';
import '../models/expense.dart';
import '../models/purchase.dart';
import '../models/employee.dart';
import '../data/app_data.dart';
import '../screens/quotation_preview_screen.dart';

// IMPORT needed for the PDF statement
import '../screens/account_ledger_screen.dart';

class PdfService {
  
  // ==========================================
  // FUNCTION: Quotations PDF (Fixed Layout & Wrapping)
  // ==========================================
  static Future<void> generateAndSavePdf(Quotation quotation) async {
    final pdf = pw.Document();

    final formatter = NumberFormat('#,##0.00', 'en_US');
    final qtyFormatter = NumberFormat('#,##0', 'en_US');

    final totalDiscount =
        quotation.items.fold(0.0, (sum, i) => sum + i.discount);
    final subtotal = quotation.items
        .fold(0.0, (sum, i) => sum + (i.unitPrice * i.quantity));
    final grandTotal = quotation.grandTotal;

    final companyKey = quotation.company;
    final companyName = AppCompanies.label(companyKey);
    final logoPath = AppData().settings.getLogoPath(companyKey);

    pw.MemoryImage? logoImage;
    if (logoPath.isNotEmpty) {
      if (logoPath.startsWith('assets/')) {
        try {
          final bytes = (await rootBundle.load(logoPath)).buffer.asUint8List();
          logoImage = pw.MemoryImage(bytes);
        } catch (_) {}
      } else {
        final file = File(logoPath);
        if (file.existsSync()) {
          try {
            final bytes = await file.readAsBytes();
            logoImage = pw.MemoryImage(bytes);
          } catch (_) {}
        }
      }
    }

    pw.Widget buildHeaderCell(String text, {pw.Alignment align = pw.Alignment.centerLeft}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: pw.Align(
          alignment: align,
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColors.grey900,
            ),
          ),
        ),
      );
    }

    pw.Widget buildCell(
      String text, {
      pw.Alignment align = pw.Alignment.centerLeft,
      bool bold = false,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: pw.Align(
          alignment: align,
          child: pw.Text(
            text,
            textAlign: align == pw.Alignment.centerRight
                ? pw.TextAlign.right
                : (align == pw.Alignment.center ? pw.TextAlign.center : pw.TextAlign.left),
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColors.blueGrey900,
            ),
          ),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Company Logo / Name Header
            if (logoImage != null) ...[
              pw.Center(
                child: pw.Image(logoImage, height: 110, fit: pw.BoxFit.contain),
              ),
            ] else ...[
              pw.Center(
                child: pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
              ),
            ],
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 12),

            // Quotation Title and Date
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'QUOTATION',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Quotation #: ${quotation.id}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Date: ${DateFormat('yyyy-MM-dd').format(quotation.createdDate)}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 12),

            // Customer Info
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Customer: ${quotation.customerName}',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
                if (quotation.customerPhone.isNotEmpty)
                  pw.Text('Phone: ${quotation.customerPhone}',
                      style: const pw.TextStyle(fontSize: 10)),
                if (quotation.customerAddress.isNotEmpty)
                  pw.Text('Address: ${quotation.customerAddress}',
                      style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── CLEAN NATIVE BOXED TABLE ──
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.6,
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),   // No
                1: const pw.FlexColumnWidth(1.0),   // Item Name (Flexible, absorbs remaining space)
                2: const pw.FixedColumnWidth(65),   // Quantity
                3: const pw.FixedColumnWidth(80),   // Rate
                4: const pw.FixedColumnWidth(85),   // Amount
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    buildHeaderCell('No', align: pw.Alignment.center),
                    buildHeaderCell('Item', align: pw.Alignment.centerLeft),
                    buildHeaderCell('Quantity', align: pw.Alignment.centerRight),
                    buildHeaderCell('Rate', align: pw.Alignment.centerRight),
                    buildHeaderCell('Amount', align: pw.Alignment.centerRight),
                  ],
                ),

                // Data Rows
                ...List.generate(quotation.items.length, (index) {
                  final item = quotation.items[index];
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: index.isOdd ? PdfColors.grey100 : PdfColors.white,
                    ),
                    children: [
                      buildCell('${index + 1}', align: pw.Alignment.center),
                      buildCell(item.productName, align: pw.Alignment.centerLeft),
                      buildCell('${qtyFormatter.format(item.quantity)} Nos', align: pw.Alignment.centerRight),
                      buildCell(formatter.format(item.unitPrice), align: pw.Alignment.centerRight),
                      buildCell(formatter.format(item.total), align: pw.Alignment.centerRight, bold: true),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 16),

            // Totals Summary
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 260,
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Sub Total:',
                            style: const pw.TextStyle(fontSize: 11)),
                        pw.Text(formatter.format(subtotal),
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    if (totalDiscount > 0) ...[
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Discount (${((totalDiscount / (subtotal == 0 ? 1 : subtotal)) * 100).toStringAsFixed(0)}%):',
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                          pw.Text(formatter.format(totalDiscount),
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 11)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Grand Total Box + Amount In Words
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      NumberToWordsConverter.convert(grandTotal),
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800),
                    ),
                  ),
                  pw.Row(
                    children: [
                      pw.Text('Grand Total:  ',
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text(formatter.format(grandTotal),
                          style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Quotation_${quotation.id}.pdf',
    );
  }

  // ==========================================
  // EXISTING FUNCTION: Activity Report
  // ==========================================
  static Future<void> generateActivityReport({
    required DateTime start,
    required DateTime end,
    required String companyFilter,
    required List<SaleHistory> sales,
    required List<Quotation> quotations,
    required List<Purchase> purchases,
    required List<Expense> expenses,
    required List<SalaryRecord> salaries,
    required List<String> activeCustomers,
  }) async {
    final pdf = pw.Document();

    final formatter = NumberFormat('#,##0.00', 'en_US');
    final qtyFormatter = NumberFormat('#,##0', 'en_US');

    final companyName = companyFilter == 'All'
        ? 'All Companies (Merged)'
        : AppCompanies.label(companyFilter);
    final logoPath = companyFilter == 'All'
        ? ''
        : AppData().settings.getLogoPath(companyFilter);

    pw.MemoryImage? logoImage;
    if (logoPath.isNotEmpty) {
      if (logoPath.startsWith('assets/')) {
        try {
          final bytes = (await rootBundle.load(logoPath)).buffer.asUint8List();
          logoImage = pw.MemoryImage(bytes);
        } catch (_) {}
      } else {
        final file = File(logoPath);
        if (file.existsSync()) {
          try {
            final bytes = await file.readAsBytes();
            logoImage = pw.MemoryImage(bytes);
          } catch (_) {}
        }
      }
    }

    final totalSales = sales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final totalPurchases = purchases.fold(0.0, (sum, p) => sum + p.totalAmount);
    final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalSalaries = salaries.fold(0.0, (sum, s) => sum + s.amount);
    final netProfitLoss =
        totalSales - (totalPurchases + totalExpenses + totalSalaries);

    pw.Widget sectionHeader(String title) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(top: 16, bottom: 8),
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        child: pw.Row(
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            if (logoImage != null) ...[
              pw.Center(
                child: pw.Image(logoImage, height: 100, fit: pw.BoxFit.contain),
              ),
            ] else ...[
              pw.Center(
                child: pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
              ),
            ],
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'COMPREHENSIVE ACTIVITY REPORT',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Period: ${DateFormat('yyyy-MM-dd').format(start)} to ${DateFormat('yyyy-MM-dd').format(end)}',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey300),

            sectionHeader('1. Financial Summary'),
            pw.TableHelper.fromTextArray(
              border: null,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.grey800,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellHeight: 22,
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
              },
              headers: ['Category', 'Records Count', 'Amount (Rs)'],
              data: [
                ['Total Sales (Invoices)', '${sales.length}', formatter.format(totalSales)],
                ['Total Purchases (Shared)', '${purchases.length}', formatter.format(totalPurchases)],
                ['Total Expenses', '${expenses.length}', formatter.format(totalExpenses)],
                ['Total Salaries Disbursed', '${salaries.length}', formatter.format(totalSalaries)],
                ['NET PROFIT / LOSS', '', formatter.format(netProfitLoss)],
              ],
            ),

            sectionHeader('2. Active Customers (${activeCustomers.length})'),
            if (activeCustomers.isEmpty)
              pw.Text('No active customer transactions in this period.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
            else
              pw.Wrap(
                spacing: 12,
                runSpacing: 4,
                children: activeCustomers
                    .map((c) => pw.Text('• $c',
                        style: const pw.TextStyle(fontSize: 10)))
                    .toList(),
              ),

            if (sales.isNotEmpty) ...[
              sectionHeader('3. Sales / Invoices Line-Item Details'),
              ...sales.map((sale) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Invoice #${sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : sale.id} | Date: ${DateFormat('yyyy-MM-dd').format(sale.dateOfPurchase)} | Customer: ${sale.customerName} | Total: Rs. ${formatter.format(sale.totalAmount)}',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 3),
                      pw.TableHelper.fromTextArray(
                        border: null,
                        cellStyle: const pw.TextStyle(fontSize: 8),
                        headerStyle: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold),
                        headerDecoration:
                            const pw.BoxDecoration(color: PdfColors.grey100),
                        cellHeight: 18,
                        headers: [
                          'Item Description',
                          'Qty',
                          'Unit Price',
                          'Total'
                        ],
                        cellAlignments: {
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.centerRight,
                          2: pw.Alignment.centerRight,
                          3: pw.Alignment.centerRight,
                        },
                        data: sale.items
                            .map((item) => [
                                  item.productName,
                                  qtyFormatter.format(item.quantity),
                                  formatter.format(item.unitPrice),
                                  formatter.format(item.total),
                                ])
                            .toList(),
                      ),
                    ],
                  ),
                );
              }),
            ],

            if (purchases.isNotEmpty) ...[
              sectionHeader('4. Purchases Line-Item Details'),
              ...purchases.map((pur) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Purchase #${pur.id} | Date: ${DateFormat('yyyy-MM-dd').format(pur.purchaseDate)} | Vendor: ${pur.vendorName} | Payment: ${pur.paymentMethod.toUpperCase()} | Total: Rs. ${formatter.format(pur.totalAmount)}',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 3),
                      pw.TableHelper.fromTextArray(
                        border: null,
                        cellStyle: const pw.TextStyle(fontSize: 8),
                        headerStyle: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold),
                        headerDecoration:
                            const pw.BoxDecoration(color: PdfColors.grey100),
                        cellHeight: 18,
                        headers: ['Product Item', 'Qty', 'Unit Price', 'Total'],
                        cellAlignments: {
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.centerRight,
                          2: pw.Alignment.centerRight,
                          3: pw.Alignment.centerRight,
                        },
                        data: pur.items
                            .map((item) => [
                                  item.productName,
                                  qtyFormatter.format(item.quantity),
                                  formatter.format(item.unitPrice),
                                  formatter.format(item.total),
                                ])
                            .toList(),
                      ),
                    ],
                  ),
                );
              }),
            ],

            if (expenses.isNotEmpty) ...[
              sectionHeader('5. Expenses Breakdown'),
              pw.TableHelper.fromTextArray(
                border: null,
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerStyle: pw.TextStyle(
                    fontSize: 8, fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey100),
                cellHeight: 18,
                headers: ['Date', 'Category', 'Description', 'Amount (Rs)'],
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                },
                data: expenses
                    .map((e) => [
                          DateFormat('yyyy-MM-dd').format(e.date),
                          e.category,
                          e.description,
                          formatter.format(e.amount),
                        ])
                    .toList(),
              ),
            ],

            if (salaries.isNotEmpty) ...[
              sectionHeader('6. Salary Disbursements'),
              pw.TableHelper.fromTextArray(
                border: null,
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerStyle: pw.TextStyle(
                    fontSize: 8, fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey100),
                cellHeight: 18,
                headers: [
                  'Date Paid',
                  'Employee Name',
                  'Salary Month',
                  'Amount (Rs)'
                ],
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                },
                data: salaries
                    .map((s) => [
                          DateFormat('yyyy-MM-dd').format(s.paymentDate),
                          s.employeeName,
                          s.salaryMonth,
                          formatter.format(s.amount),
                        ])
                    .toList(),
              ),
            ],

            if (quotations.isNotEmpty) ...[
              sectionHeader('7. Quotations Created'),
              pw.TableHelper.fromTextArray(
                border: null,
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerStyle: pw.TextStyle(
                    fontSize: 8, fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey100),
                cellHeight: 18,
                headers: [
                  'Date',
                  'Quotation #',
                  'Customer Name',
                  'Grand Total (Rs)'
                ],
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                },
                data: quotations
                    .map((q) => [
                          DateFormat('yyyy-MM-dd').format(q.createdDate),
                          q.id,
                          q.customerName,
                          formatter.format(q.grandTotal),
                        ])
                    .toList(),
              ),
            ],
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'ActivityReport_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  // ==========================================
  // Ledger Statement PDF
  // ==========================================
  static Future<void> generateLedgerStatementPdf({
    required String accountName,
    required String companyKey,
    required double openingBalance,
    required double finalBalance,
    required List<LedgerItem> items,
    String periodLabel = 'All Time',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final formatter = NumberFormat('#,##0.00', 'en_US');
    final dateFmt = DateFormat('yyyy-MM-dd');

    final companyName = AppCompanies.label(companyKey);
    final logoPath = AppData().settings.getLogoPath(companyKey);

    pw.MemoryImage? logoImage;
    if (logoPath.isNotEmpty) {
      if (logoPath.startsWith('assets/')) {
        try {
          final bytes = (await rootBundle.load(logoPath)).buffer.asUint8List();
          logoImage = pw.MemoryImage(bytes);
        } catch (_) {}
      } else {
        final file = File(logoPath);
        if (file.existsSync()) {
          try {
            final bytes = await file.readAsBytes();
            logoImage = pw.MemoryImage(bytes);
          } catch (_) {}
        }
      }
    }

    final totalIn = items.fold(0.0, (sum, i) => sum + i.credit);
    final totalOut = items.fold(0.0, (sum, i) => sum + i.debit);

    String periodText;
    if (startDate != null && endDate != null) {
      periodText =
          '$periodLabel  (${dateFmt.format(startDate)}  to  ${dateFmt.format(endDate)})';
    } else if (periodLabel != 'All Time') {
      periodText = periodLabel;
    } else {
      periodText = 'All Time';
    }

    final openingLabel =
        (startDate != null) ? 'Opening Balance (as of period start)' : 'Opening Balance';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            if (logoImage != null) ...[
              pw.Center(
                child: pw.Image(logoImage, height: 80, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(height: 16),
            ] else ...[
              pw.Center(
                child: pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
            ],

            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ACCOUNT STATEMENT',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Text('Account: $accountName',
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Period: $periodText',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(
                    'Date Generated: ${dateFmt.format(DateTime.now())}',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
            pw.SizedBox(height: 16),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _pdfSummaryCol(
                      openingLabel, formatter.format(openingBalance)),
                  _pdfSummaryCol(
                      'Total Credit (In)', formatter.format(totalIn)),
                  _pdfSummaryCol(
                      'Total Debit (Out)', formatter.format(totalOut)),
                  _pdfSummaryCol('Closing Balance',
                      formatter.format(finalBalance),
                      isBold: true),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            if (items.isEmpty)
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 24),
                  child: pw.Text(
                    'No transactions for selected period',
                    style: const pw.TextStyle(
                        fontSize: 11, color: PdfColors.grey600),
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: null,
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    color: PdfColors.grey800),
                headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                    border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey400))),
                cellHeight: 22,
                cellStyle: const pw.TextStyle(fontSize: 9),
                rowDecoration: const pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(
                            color: PdfColors.grey300, width: 0.5))),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(4.0),
                  2: const pw.FlexColumnWidth(2.0),
                  3: const pw.FlexColumnWidth(2.0),
                  4: const pw.FlexColumnWidth(2.5),
                },
                headers: [
                  'Date',
                  'Description',
                  'Credit (In)',
                  'Debit (Out)',
                  'Balance'
                ],
                data: [
                  [
                    startDate != null ? dateFmt.format(startDate) : '-',
                    openingLabel,
                    '-',
                    '-',
                    formatter.format(openingBalance),
                  ],
                  ...items.map((item) => [
                        dateFmt.format(item.date),
                        item.description,
                        item.credit > 0 ? formatter.format(item.credit) : '-',
                        item.debit > 0 ? formatter.format(item.debit) : '-',
                        formatter.format(item.balance),
                      ]),
                ],
              ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${accountName.replaceAll(' ', '_')}_Statement.pdf',
    );
  }

  // ==========================================
  // Vendor Purchase History PDF
  // ==========================================
  static Future<void> generateVendorPurchaseHistoryPdf({
    required String vendorName,
    required String periodLabel,
    DateTime? startDate,
    DateTime? endDate,
    required List<Purchase> purchases,
    required double totalAmount,
  }) async {
    final pdf = pw.Document();
    final formatter = NumberFormat('#,##0.00', 'en_US');
    final qtyFormatter = NumberFormat('#,##0', 'en_US');
    final dateFmt = DateFormat('yyyy-MM-dd');

    String periodText;
    if (startDate != null && endDate != null) {
      periodText =
          '$periodLabel  (${dateFmt.format(startDate)}  to  ${dateFmt.format(endDate)})';
    } else {
      periodText = periodLabel;
    }

    final totalItems =
        purchases.fold<int>(0, (sum, p) => sum + p.items.length);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Text(
                'VENDOR PURCHASE HISTORY',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Vendor: $vendorName',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Period: $periodText',
                style: const pw.TextStyle(
                    fontSize: 11, color: PdfColors.grey700),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Generated: ${dateFmt.format(DateTime.now())}',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey600),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 12),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Bills: ${purchases.length}',
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Total Line Items: $totalItems',
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      'Grand Total: Rs. ${formatter.format(totalAmount)}',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            if (purchases.isEmpty)
              pw.Center(
                child: pw.Text(
                  'No purchases for selected period',
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey600),
                ),
              )
            else
              ...purchases.map((pur) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 14),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey200),
                        child: pw.Text(
                          'Purchase #${pur.id}  |  Date: ${dateFmt.format(pur.purchaseDate)}  |  Payment: ${pur.paymentMethod.toUpperCase()}  |  Total: Rs. ${formatter.format(pur.totalAmount)}',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.TableHelper.fromTextArray(
                        border: null,
                        cellStyle: const pw.TextStyle(fontSize: 9),
                        headerStyle: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold),
                        headerDecoration: const pw.BoxDecoration(
                            color: PdfColors.grey100),
                        cellHeight: 18,
                        headers: [
                          'Item',
                          'Qty',
                          'Unit Price',
                          'Amount'
                        ],
                        cellAlignments: {
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.centerRight,
                          2: pw.Alignment.centerRight,
                          3: pw.Alignment.centerRight,
                        },
                        data: pur.items
                            .map((item) => [
                                  item.productName,
                                  qtyFormatter.format(item.quantity),
                                  formatter.format(item.unitPrice),
                                  formatter.format(item.total),
                                ])
                            .toList(),
                      ),
                      if (pur.notes.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('Notes: ${pur.notes}',
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.grey600)),
                      ],
                    ],
                  ),
                );
              }),

            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey400),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'GRAND TOTAL: Rs. ${formatter.format(totalAmount)}',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Vendor_${vendorName.replaceAll(' ', '_')}_Purchase_History.pdf',
    );
  }

  static pw.Widget _pdfSummaryCol(String title, String amount,
      {bool isBold = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(amount,
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight:
                    isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    );
  }
}