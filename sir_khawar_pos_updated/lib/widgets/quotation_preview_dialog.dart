import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/quotation.dart';

// Helper class to convert numbers into English words (e.g. PKR Three Hundred Million...)
class NumberToWordsConverter {
  static const _units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen'
  ];

  static const _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety'
  ];

  static String convert(double amount) {
    final int value = amount.toInt();
    if (value == 0) return 'Zero';

    String words = _convertChunk(value).trim();
    return 'In Words: PKR $words Only.';
  }

  static String _convertChunk(int n) {
    if (n < 20) return _units[n];
    if (n < 100) {
      return '${_tens[n ~/ 10]}${n % 10 != 0 ? " ${_units[n % 10]}" : ""}';
    }
    if (n < 1000) {
      return '${_units[n ~/ 100]} Hundred${n % 100 != 0 ? " And ${_convertChunk(n % 100)}" : ""}';
    }
    if (n < 1000000) {
      return '${_convertChunk(n ~/ 1000)} Thousand${n % 1000 != 0 ? " ${_convertChunk(n % 1000)}" : ""}';
    }
    if (n < 1000000000) {
      return '${_convertChunk(n ~/ 1000000)} Million${n % 1000000 != 0 ? " ${_convertChunk(n % 1000000)}" : ""}';
    }
    return '${_convertChunk(n ~/ 1000000000)} Billion${n % 1000000000 != 0 ? " ${_convertChunk(n % 1000000000)}" : ""}';
  }
}

class QuotationPreviewDialog extends StatelessWidget {
  final Quotation quotation;

  const QuotationPreviewDialog({super.key, required this.quotation});

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(amount);
  }

  String _formatQty(int qty) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return '${formatter.format(qty)} Nos';
  }

  @override
  Widget build(BuildContext context) {
    final totalDiscount = quotation.items.fold(0.0, (sum, i) => sum + i.discount);
    final subtotal = quotation.items.fold(0.0, (sum, i) => sum + (i.unitPrice * i.quantity));
    final grandTotal = quotation.grandTotal;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 950),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Dialog Controls (Close Button & Print Option)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a2332),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quotation View - ${quotation.id}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quotation View Document Area
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Header Information
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customer: ${quotation.customerName}',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                if (quotation.customerPhone.isNotEmpty)
                                  Text('Phone: ${quotation.customerPhone}',
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.grey.shade700)),
                                if (quotation.customerAddress.isNotEmpty)
                                  Text('Address: ${quotation.customerAddress}',
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.grey.shade700)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Date: ${DateFormat('yyyy-MM-dd').format(quotation.createdDate)}',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey.shade700),
                                ),
                                Text(
                                  'Status: ${quotation.status.name.toUpperCase()}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Table Header
                        Container(
                          color: const Color(0xFFFAFAFA),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          child: Row(
                            children: const [
                              SizedBox(
                                width: 40,
                                child: Text('No',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                              Expanded(
                                flex: 6,
                                child: Text('Item',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Quantity',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Rate',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text('Amount',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),

                        // Table Rows
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: quotation.items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, color: Color(0xFFF0F0F0)),
                          itemBuilder: (context, index) {
                            final item = quotation.items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text('${index + 1}',
                                        style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 13)),
                                  ),
                                  Expanded(
                                    flex: 6,
                                    child: Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      _formatQty(item.quantity),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      _formatAmount(item.unitPrice),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      _formatAmount(item.total),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 20),

                        // Sub Total & Discount Rows
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 350,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Sub Total:',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14)),
                                    Text(_formatAmount(subtotal),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        'Discount (${((totalDiscount / (subtotal == 0 ? 1 : subtotal)) * 100).toStringAsFixed(0)}%):',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14)),
                                    Text(_formatAmount(totalDiscount),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bottom Row: "In Words" on the Left & "Grand Total" on the Right
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // In Words (Left)
                              Expanded(
                                child: Text(
                                  NumberToWordsConverter.convert(grandTotal),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),

                              // Grand Total (Right)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Grand Total:  ',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _formatAmount(grandTotal),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
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
            ],
          ),
        ),
      ),
    );
  }
}