import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import '../data/app_data.dart';
import '../models/quotation.dart';
import '../models/sale_history.dart';

class CustomerChequesScreen extends StatefulWidget {
  const CustomerChequesScreen({super.key});
  @override
  State<CustomerChequesScreen> createState() => _CustomerChequesScreenState();
}

class _CustomerChequesScreenState extends State<CustomerChequesScreen> {
  final data = AppData();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    data.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  String formatCurrency(double amount) {
    return 'Rs. ${NumberFormat('#,##0.00', 'en_US').format(amount)}';
  }

  Future<void> _markDone(String saleId, String paymentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          'Mark Cheque as Cleared?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This will move the cheque amount into your Bank Balance immediately.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sidebarActive,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark Done'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await data.clearCheque(saleId, paymentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cheque marked as cleared'),
            backgroundColor: AppColors.cashGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> chequeData = [];
    for (var sale in data.salesHistory) {
      for (var payment in sale.payments) {
        if (payment.method == PaymentMethod.cheque) {
          chequeData.add({
            'saleId': sale.id,
            'invoice': sale.invoiceNumber,
            'customer': sale.customerName,
            'payment': payment,
          });
        }
      }
    }

    // Search filter
    final filtered = chequeData.where((row) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final PaymentReceipt p = row['payment'];
      return row['invoice'].toString().toLowerCase().contains(q) ||
          row['customer'].toString().toLowerCase().contains(q) ||
          p.chequeNumber.toLowerCase().contains(q) ||
          p.bankName.toLowerCase().contains(q);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1024) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.desktop_windows_outlined,
                    size: 64, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text('Window too small',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary)),
                SizedBox(height: 8),
                Text('Please resize the window to at least 1024px wide.',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Customer Cheques',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Total Cheques: ${chequeData.length} | Pending: ${data.pendingChequeCount}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // 🔍 SEARCH BAR
              SizedBox(
                width: 360,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search invoice, customer, cheque #, bank...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColors.sidebarActive, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('No cheque payments recorded.',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                  AppColors.background),
                              columns: const [
                                DataColumn(
                                    label: Text('Invoice',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Customer',
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
                                    label: Text('Amount',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Cheque Date',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Status',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Action',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold))),
                              ],
                              rows: filtered.map((dataRow) {
                                final PaymentReceipt p = dataRow['payment'];
                                final isPending = p.chequeDate != null &&
                                    p.chequeDate!.isAfter(DateTime.now());
                                return DataRow(cells: [
                                  DataCell(Text(dataRow['invoice'],
                                      style: const TextStyle(
                                          color: AppColors.textPrimary))),
                                  DataCell(Text(dataRow['customer'],
                                      style: const TextStyle(
                                          color: AppColors.textPrimary))),
                                  DataCell(Text(p.chequeNumber,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary))),
                                  DataCell(Text(p.bankName,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary))),
                                  DataCell(Text(formatCurrency(p.amount),
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold))),
                                  DataCell(Text(
                                      p.chequeDate != null
                                          ? DateFormat('yyyy-MM-dd')
                                              .format(p.chequeDate!)
                                          : '-',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPending
                                            ? AppColors.pendingOrange
                                                .withOpacity(0.12)
                                            : AppColors.cashGreen
                                                .withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isPending ? 'Pending' : 'Cleared',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isPending
                                              ? AppColors.pendingOrange
                                              : AppColors.cashGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // ✅ MARK DONE BUTTON
                                  DataCell(
                                    isPending
                                        ? TextButton.icon(
                                            onPressed: () => _markDone(
                                              dataRow['saleId'],
                                              p.id,
                                            ),
                                            icon: const Icon(
                                                Icons.check_circle,
                                                size: 16,
                                                color: AppColors.cashGreen),
                                            label: const Text('Mark Done',
                                                style: TextStyle(
                                                    color:
                                                        AppColors.cashGreen)),
                                          )
                                        : const Text('-',
                                            style: TextStyle(
                                                color:
                                                    AppColors.textSecondary)),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}