import 'package:flutter/material.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';

import '../models/sale_history.dart';
import '../models/quotation.dart'; // AppCompanies
import 'invoice_format_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final AppData data = AppData();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _companyFilter = 'all';

  @override
  void initState() {
    super.initState();
    data.addListener(_onDataChanged);
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  double _paidFor(SaleHistory s) =>
      s.payments.fold(0.0, (sum, p) => sum + p.amount);

  List<SaleHistory> get _filtered {
    var list = data.salesHistory.toList();

    if (_companyFilter != 'all') {
      list = list.where((s) => s.company == _companyFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((s) {
        return s.customerName.toLowerCase().contains(_searchQuery) ||
            s.invoiceNumber.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    if (_statusFilter != 'all') {
      list = list.where((s) {
        final paid = _paidFor(s);
        final due = s.totalAmount - paid;
        switch (_statusFilter) {
          case 'paid':
            return due <= 0;
          case 'partial':
            return due > 0 && paid > 0;
          case 'unpaid':
            return paid <= 0;
          default:
            return true;
        }
      }).toList();
    }

    list.sort((a, b) => b.dateOfPurchase.compareTo(a.dateOfPurchase));
    return list;
  }

  Color _statusColor(SaleHistory s) {
    final paid = _paidFor(s);
    final due = s.totalAmount - paid;
    if (due <= 0) return AppColors.cashGreen;
    if (paid > 0) return AppColors.pendingOrange;
    return AppColors.expenseRed;
  }

  String _statusLabel(SaleHistory s) {
    final paid = _paidFor(s);
    final due = s.totalAmount - paid;
    if (due <= 0) return 'Paid';
    if (paid > 0) return 'Partial';
    return 'Unpaid';
  }

  @override
  Widget build(BuildContext context) {
    final sales = _filtered;

    final companySales = _companyFilter == 'all'
        ? data.salesHistory
        : data.salesHistory.where((s) => s.company == _companyFilter);

    final totalRevenue =
        companySales.fold(0.0, (s, x) => s + x.totalAmount);
    final totalCollected =
        companySales.fold(0.0, (s, x) => s + _paidFor(x));
    final totalOutstanding = totalRevenue - totalCollected;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invoices'),
        backgroundColor: AppColors.headerBg,
        foregroundColor: AppColors.cardBg,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _chip('Total Revenue',
                    'Rs. ${totalRevenue.toStringAsFixed(2)}', AppColors.bankBlue),
                const SizedBox(width: 12),
                _chip('Collected',
                    'Rs. ${totalCollected.toStringAsFixed(2)}',
                    AppColors.cashGreen),
                const SizedBox(width: 12),
                _chip('Outstanding',
                    'Rs. ${totalOutstanding.toStringAsFixed(2)}',
                    AppColors.expenseRed),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // COMPANY FILTER DROPDOWN
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.cardBg,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _companyFilter,
                      focusColor: Colors.transparent,
                      dropdownColor: AppColors.cardBg,
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Companies')),
                        DropdownMenuItem(
                            value: AppCompanies.energy,
                            child: Text('Alternative Energy Solution')),
                        DropdownMenuItem(
                            value: AppCompanies.electric,
                            child: Text('Alternative Electric Solutions Pvt. Ltd.')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _companyFilter = v);
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // STATUS FILTER DROPDOWN
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.cardBg,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      focusColor: Colors.transparent,
                      dropdownColor: AppColors.cardBg,
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Statuses')),
                        DropdownMenuItem(value: 'paid', child: Text('Paid')),
                        DropdownMenuItem(
                            value: 'partial', child: Text('Partial')),
                        DropdownMenuItem(
                            value: 'unpaid', child: Text('Unpaid')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _statusFilter = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: sales.isEmpty
                ? const Center(child: Text('No invoices'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border, width: 1),
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.cardBg,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: DataTable(
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                  color: AppColors.border.withValues(alpha: 0.5)),
                              verticalInside: BorderSide(
                                  color: AppColors.border.withValues(alpha: 0.5)),
                            ),
                            headingRowColor: WidgetStateProperty.all(
                                AppColors.background),
                            columns: const [
                              DataColumn(label: Text('Invoice #')),
                              DataColumn(label: Text('Company')),
                              DataColumn(label: Text('Customer')),
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Total'), numeric: true),
                              DataColumn(label: Text('Paid'), numeric: true),
                              DataColumn(label: Text('Due'), numeric: true),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: sales.map((s) {
                              final paid = _paidFor(s);
                              final due = s.totalAmount - paid;
                              final companyLabel =
                                  s.company == AppCompanies.electric
                                      ? 'Electric'
                                      : 'Energy';
                              return DataRow(cells: [
                                DataCell(Text(s.invoiceNumber,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary))),
                                DataCell(Text(companyLabel,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary))),
                                DataCell(Text(s.customerName,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary))),
                                DataCell(Text(
                                    '${s.dateOfPurchase.day}/${s.dateOfPurchase.month}/${s.dateOfPurchase.year}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary))),
                                DataCell(Text(
                                    'Rs. ${s.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary))),
                                DataCell(Text(
                                    'Rs. ${paid.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: AppColors.cashGreen))),
                                DataCell(Text(
                                  'Rs. ${due.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: due > 0
                                          ? AppColors.expenseRed
                                          : AppColors.cashGreen,
                                      fontWeight: FontWeight.bold),
                                )),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(s)
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Text(_statusLabel(s),
                                      style: TextStyle(
                                          color: _statusColor(s),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                )),
                                DataCell(IconButton(
                                  icon: const Icon(Icons.visibility,
                                      size: 20,
                                      color: AppColors.sidebarActive),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            InvoiceFormatScreen(invoice: s),
                                      ),
                                    );
                                  },
                                )),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}