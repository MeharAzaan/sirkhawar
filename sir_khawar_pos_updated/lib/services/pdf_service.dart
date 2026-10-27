import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/quotation.dart';
import '../data/app_data.dart';
import '../screens/quotation_preview_screen.dart';

class PdfService {
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

    // Load company logo if available
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Centered Logo or Company Name
              if (logoImage != null) ...[
                pw.Center(
                  child: pw.Image(logoImage, height: 120, fit: pw.BoxFit.contain),
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

              // Header
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

              // Table
              pw.TableHelper.fromTextArray(
                border: null,
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    color: PdfColors.grey800),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                cellHeight: 24,
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
                headers: ['No', 'Item', 'Quantity', 'Rate', 'Amount'],
                data: List.generate(quotation.items.length, (index) {
                  final item = quotation.items[index];
                  return [
                    '${index + 1}',
                    item.productName,
                    '${qtyFormatter.format(item.quantity)} Nos',
                    formatter.format(item.unitPrice),
                    formatter.format(item.total),
                  ];
                }),
              ),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 16),

              // Subtotal & Discount
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

              // In Words & Grand Total
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
            ],
          );
        },
      ),
    );

    // Triggers native desktop printing & save-to-pdf dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Quotation_${quotation.id}.pdf',
    );
  }
}