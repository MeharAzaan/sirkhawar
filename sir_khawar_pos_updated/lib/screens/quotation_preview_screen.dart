import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import '../data/app_data.dart';
import '../models/quotation.dart';
import '../services/pdf_service.dart';

// Helper class to convert numbers into English words
class NumberToWordsConverter {
  static const _units = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
    'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
  ];

  static const _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  static String convert(double amount) {
    final int value = amount.toInt();
    if (value == 0) return 'In Words: PKR Zero Only.';

    String words = _convertChunk(value).trim();
    return 'In Words: PKR $words Only.';
  }

  static String _convertChunk(int n) {
    if (n < 20) return _units[n];
    if (n < 100) return '${_tens[n ~/ 10]}${n % 10 != 0 ? " ${_units[n % 10]}" : ""}';
    if (n < 1000) return '${_units[n ~/ 100]} Hundred${n % 100 != 0 ? " And ${_convertChunk(n % 100)}" : ""}';
    if (n < 1000000) return '${_convertChunk(n ~/ 1000)} Thousand${n % 1000 != 0 ? " ${_convertChunk(n % 1000)}" : ""}';
    if (n < 1000000000) return '${_convertChunk(n ~/ 1000000)} Million${n % 1000000 != 0 ? " ${_convertChunk(n % 1000000)}" : ""}';
    return '${_convertChunk(n ~/ 1000000000)} Billion${n % 1000000000 != 0 ? " ${_convertChunk(n % 1000000000)}" : ""}';
  }
}

class QuotationPreviewScreen extends StatelessWidget {
  final Quotation quotation;
  final VoidCallback onBack;
  final VoidCallback? onEdit;

  const QuotationPreviewScreen({
    super.key,
    required this.quotation,
    required this.onBack,
    this.onEdit,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(amount);
  }

  String _formatQty(int qty) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return '${formatter.format(qty)} Nos';
  }

  Widget _buildLogo(String logoPath, String companyName) {
    if (logoPath.isNotEmpty) {
      if (logoPath.startsWith('assets/')) {
        return Image.asset(
          logoPath,
          height: 120,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Text(
            companyName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        );
      }

      final file = File(logoPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          height: 120,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Text(
            companyName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        );
      }
    }

    return Text(
      companyName,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = AppData();
    final totalDiscount = quotation.items.fold(0.0, (sum, i) => sum + i.discount);
    final subtotal = quotation.items.fold(0.0, (sum, i) => sum + (i.unitPrice * i.quantity));
    final grandTotal = quotation.grandTotal;

    final companyKey = quotation.company;
    final companyName = AppCompanies.label(companyKey);
    final logoPath = data.settings.getLogoPath(companyKey);

    // Fixed right-column widths so numbers never stutter
    const double colNo = 40;
    const double colQty = 90;
    const double colRate = 100;
    const double colAmount = 110;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1024) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: AppColors.cardBg,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        onPressed: onBack,
                        tooltip: 'Back to Quotations',
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quotation ${quotation.id}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.desktop_windows_outlined, size: 64, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text(
                          'Window too small',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please resize the window to at least 1024px wide.',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: AppColors.cardBg,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                          onPressed: onBack,
                          tooltip: 'Back to Quotations',
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quotation ${quotation.id}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (onEdit != null) ...[
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              side: const BorderSide(color: AppColors.bankBlue, width: 1.5),
                            ),
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit, color: AppColors.bankBlue, size: 18),
                            label: const Text(
                              'Edit Quotation',
                              style: TextStyle(color: AppColors.bankBlue, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.expenseRed,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                          onPressed: () async {
                            await PdfService.generateAndSavePdf(quotation);
                          },
                          icon: const Icon(Icons.picture_as_pdf, color: AppColors.cardBg, size: 18),
                          label: const Text('Convert to PDF', style: TextStyle(color: AppColors.cardBg)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1500),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Center(child: _buildLogo(logoPath, companyName)),
                                const SizedBox(height: 16),
                                const Divider(height: 1, color: AppColors.border),
                                const SizedBox(height: 16),
                              ],
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Customer: ${quotation.customerName}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      if (quotation.customerPhone.isNotEmpty)
                                        Text('Phone: ${quotation.customerPhone}',
                                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                      if (quotation.customerAddress.isNotEmpty)
                                        Text('Address: ${quotation.customerAddress}',
                                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Date: ${DateFormat('yyyy-MM-dd').format(quotation.createdDate)}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // ── BOXED ITEMS TABLE ──
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  // Header
                                  Container(
                                    color: AppColors.background,
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                    child: Row(
                                      children: const [
                                        SizedBox(
                                          width: colNo,
                                          child: Text('No',
                                              style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12)),
                                        ),
                                        Expanded(
                                          child: Text('Item',
                                              style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12)),
                                        ),
                                        SizedBox(
                                          width: colQty,
                                          child: Text('Quantity',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12)),
                                        ),
                                        SizedBox(
                                          width: colRate,
                                          child: Text('Rate',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12)),
                                        ),
                                        SizedBox(
                                          width: colAmount,
                                          child: Text('Amount',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, color: AppColors.border),

                                  // Rows
                                  ...List.generate(quotation.items.length, (index) {
                                    final item = quotation.items[index];
                                    final isLast = index == quotation.items.length - 1;
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: index.isOdd
                                            ? AppColors.background.withOpacity(0.5)
                                            : AppColors.cardBg,
                                        border: isLast
                                            ? null
                                            : const Border(
                                                bottom: BorderSide(
                                                    color: AppColors.border, width: 0.5),
                                              ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: colNo,
                                            child: Text('${index + 1}',
                                                style: const TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 12)),
                                          ),
                                          // Item name wraps inside its cell only
                                          Expanded(
                                            child: Text(
                                              item.productName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w500,
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                          // Fixed numeric columns — no wrap
                                          SizedBox(
                                            width: colQty,
                                            child: Text(
                                              _formatQty(item.quantity),
                                              textAlign: TextAlign.right,
                                              softWrap: false,
                                              overflow: TextOverflow.visible,
                                              style: const TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 12),
                                            ),
                                          ),
                                          SizedBox(
                                            width: colRate,
                                            child: Text(
                                              _formatAmount(item.unitPrice),
                                              textAlign: TextAlign.right,
                                              softWrap: false,
                                              overflow: TextOverflow.visible,
                                              style: const TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 12),
                                            ),
                                          ),
                                          SizedBox(
                                            width: colAmount,
                                            child: Text(
                                              _formatAmount(item.total),
                                              textAlign: TextAlign.right,
                                              softWrap: false,
                                              overflow: TextOverflow.visible,
                                              style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Sub Total & Discount
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: 280,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Sub Total:',
                                            style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 13)),
                                        Text(_formatAmount(subtotal),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: AppColors.textPrimary)),
                                      ],
                                    ),
                                    if (totalDiscount > 0) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Discount (${((totalDiscount / (subtotal == 0 ? 1 : subtotal)) * 100).toStringAsFixed(0)}%):',
                                            style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 13),
                                          ),
                                          Text(_formatAmount(totalDiscount),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: AppColors.textPrimary)),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      NumberToWordsConverter.convert(grandTotal),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Grand Total:  ',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary),
                                      ),
                                      Text(
                                        _formatAmount(grandTotal),
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}