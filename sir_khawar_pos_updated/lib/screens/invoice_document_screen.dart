import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import '../data/app_data.dart';
import '../models/sale_history.dart';

class InvoiceDocumentScreen extends StatelessWidget {
  final SaleHistory invoice;
  final VoidCallback onBack;

  const InvoiceDocumentScreen({
    super.key,
    required this.invoice,
    required this.onBack,
  });

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppData().settings;
    const lightBlue = AppColors.background;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1024) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: AppColors.cardBg,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        onPressed: onBack,
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Invoice Document',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.desktop_windows_outlined,
                            size: 64, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text(
                          'Window too small',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please resize the window to at least 1024px wide.',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
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
              // Top Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                color: AppColors.cardBg,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: onBack,
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Invoice Document',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),

              // Printable A4 Document View
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Container(
                      width: 800,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.headerBg.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section (Logo & Company Address)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/logo.jpeg',
                                  width: 250,
                                  fit: BoxFit.contain,
                                  errorBuilder: (ctx, _, __) {
                                    return Image.asset(
                                      'images/logo.jpeg',
                                      width: 250,
                                      errorBuilder: (c, __, ___) => const SizedBox(
                                        height: 80,
                                        width: 250,
                                        child: Center(
                                          child: Text(
                                            'AES LOGO',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: AppColors.sidebarActive,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Text(settings.addressLine1,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textPrimary)),
                                if (settings.addressLine2.isNotEmpty)
                                  Text(settings.addressLine2,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textPrimary)),
                                if (settings.addressLine3.isNotEmpty)
                                  Text(settings.addressLine3,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textPrimary)),
                                Text(settings.phone,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Date & Invoice Number Box
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 250,
                              child: Table(
                                border: TableBorder.all(
                                    color: AppColors.textPrimary, width: 1),
                                children: [
                                  TableRow(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Date:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: AppColors.textPrimary)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          DateFormat('dd MMM, yy')
                                              .format(invoice.dateOfPurchase),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Invoice #:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: AppColors.textPrimary)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          invoice.invoiceNumber,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // INVOICE Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: lightBlue,
                              border: Border.all(
                                  color: AppColors.textPrimary, width: 1),
                            ),
                            child: const Center(
                              child: Text(
                                'INVOICE',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Bill To Section
                          const Text('Bill To:',
                              style: TextStyle(
                                  fontSize: 14, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(
                            invoice.customerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (invoice.customerPhone.isNotEmpty)
                            Text('Phone: ${invoice.customerPhone}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPrimary)),
                          if (invoice.customerAddress.isNotEmpty)
                            Text('Address: ${invoice.customerAddress}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPrimary)),
                          const SizedBox(height: 20),

                          // Items Table
                          Table(
                            border: TableBorder.all(
                                color: AppColors.textPrimary, width: 1),
                            columnWidths: const {
                              0: FlexColumnWidth(4),
                              1: FlexColumnWidth(1.2),
                              2: FlexColumnWidth(0.8),
                              3: FlexColumnWidth(1.2),
                            },
                            children: [
                              TableRow(
                                decoration: const BoxDecoration(color: lightBlue),
                                children: [
                                  _buildTableHeader('Description'),
                                  _buildTableHeader('Unit Price'),
                                  _buildTableHeader('Qty'),
                                  _buildTableHeader('Amount'),
                                ],
                              ),
                              ...invoice.items.map((item) => TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(item.productName,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textPrimary)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(_formatAmount(item.unitPrice),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textPrimary)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(item.quantity.toString(),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textPrimary)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(_formatAmount(item.total),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textPrimary)),
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Financial Summary & Notes Section
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (invoice.notes.isNotEmpty) ...[
                                      SizedBox(
                                        width: 300,
                                        child: Text(
                                          'Notes: ${invoice.notes}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                              fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Right side: Subtotal & Total Table
                              SizedBox(
                                width: 280,
                                child: Table(
                                  border: TableBorder.all(
                                    color: AppColors.textPrimary,
                                    width: 1,
                                  ),
                                  children: [
                                    TableRow(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Grand Total:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: AppColors.textPrimary)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Rs. ${_formatAmount(invoice.totalAmount)}',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: AppColors.textPrimary),
                                          ),
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Amount Paid:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: AppColors.cashGreen)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Rs. ${_formatAmount(invoice.paidAmount)}',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: AppColors.cashGreen),
                                          ),
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Balance Due:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: AppColors.expenseRed)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Rs. ${_formatAmount(invoice.remainingAmount)}',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: AppColors.expenseRed),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 80),

                          // Signatures Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 200,
                                    height: 1,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Customer Signature',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Container(
                                    width: 200,
                                    height: 1,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Authorized Signature',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontSize: 12,
        ),
      ),
    );
  }
}