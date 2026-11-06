import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';
import 'package:sir_khawar_pos_updated/models/purchase.dart';
import 'package:sir_khawar_pos_updated/services/pdf_service.dart';

import 'purchase_detail_screen.dart';

class VendorHistoryRow {
  final DateTime date;
  final String id;
  final String purchaseId;
  final String itemSummary;
  final String paymentMethod;
  final double amount;
  final bool isReturn;
  final Purchase? originalPurchase;

  VendorHistoryRow({
    required this.date,
    required this.id,
    required this.purchaseId,
    required this.itemSummary,
    required this.paymentMethod,
    required this.amount,
    required this.isReturn,
    this.originalPurchase,
  });
}

class VendorPurchaseHistoryScreen extends StatefulWidget {
  const VendorPurchaseHistoryScreen({super.key});

  @override
  State<VendorPurchaseHistoryScreen> createState() =>
      _VendorPurchaseHistoryScreenState();
}

class _VendorPurchaseHistoryScreenState
    extends State<VendorPurchaseHistoryScreen> {
  final AppData data = AppData();

  // Prepared data
  List<String> _vendorNames = [];
  List<VendorHistoryRow> _allVendorRows = [];
  List<VendorHistoryRow> _filteredRows = [];

  String? _selectedVendor;
  String _filterType = 'All Time';
  DateTime? _startDate;
  DateTime? _endDate;

  double _grossPurchased = 0;
  double _totalReturned = 0;
  double _netPurchased = 0;
  int _totalBills = 0;
  int _totalReturns = 0;

  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _prepareVendors();
    data.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (!mounted) return;
    _prepareVendors();
    setState(() {});
  }

  void _prepareVendors() {
    final names = <String>{};
    for (final p in data.purchases) {
      if (p.vendorName.trim().isNotEmpty) names.add(p.vendorName.trim());
    }
    for (final r in data.purchaseReturns) {
      if (r.vendorName.trim().isNotEmpty) names.add(r.vendorName.trim());
    }

    final sorted = names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    _vendorNames = sorted;

    if (_selectedVendor != null && !_vendorNames.contains(_selectedVendor)) {
      _selectedVendor = null;
      _allVendorRows = [];
      _filteredRows = [];
      _resetTotals();
    } else if (_selectedVendor != null) {
      _loadVendorData(_selectedVendor!);
    }
  }

  void _resetTotals() {
    _grossPurchased = 0;
    _totalReturned = 0;
    _netPurchased = 0;
    _totalBills = 0;
    _totalReturns = 0;
  }

  void _loadVendorData(String vendorName) {
    final List<VendorHistoryRow> rows = [];

    // 1. Add Purchases
    final purchases = data.purchases
        .where((p) => p.vendorName.trim() == vendorName)
        .toList();

    for (final p in purchases) {
      final summary = p.items.map((i) => '${i.productName} × ${i.quantity}').join(', ');
      rows.add(VendorHistoryRow(
        date: p.purchaseDate,
        id: p.id,
        purchaseId: p.id,
        itemSummary: summary,
        paymentMethod: p.paymentMethod,
        amount: p.totalAmount,
        isReturn: false,
        originalPurchase: p,
      ));
    }

    // 2. Add Purchase Returns
    final returns = data.purchaseReturns
        .where((r) => r.vendorName.trim() == vendorName)
        .toList();

    for (final r in returns) {
      final summary = r.items.map((i) => '${i.productName} × ${i.quantity}').join(', ');
      final origP = data.purchases.where((p) => p.id == r.purchaseId).firstOrNull;

      rows.add(VendorHistoryRow(
        date: r.returnDate,
        id: 'RET-${r.id.substring(0, r.id.length > 6 ? 6 : r.id.length).toUpperCase()}',
        purchaseId: r.purchaseId,
        itemSummary: 'RETURN: $summary',
        paymentMethod: r.paymentMethod,
        amount: r.totalAmount,
        isReturn: true,
        originalPurchase: origP,
      ));
    }

    // Sort newest first
    rows.sort((a, b) => b.date.compareTo(a.date));

    _allVendorRows = rows;
    _applyFilter();
  }

  void _applyFilter() {
    final filtered = <VendorHistoryRow>[];
    double gross = 0;
    double retSum = 0;
    int billCount = 0;
    int retCount = 0;

    for (final row in _allVendorRows) {
      final d = row.date;
      if (_startDate != null && d.isBefore(_startDate!)) continue;
      if (_endDate != null && d.isAfter(_endDate!)) continue;

      filtered.add(row);
      if (row.isReturn) {
        retSum += row.amount;
        retCount++;
      } else {
        gross += row.amount;
        billCount++;
      }
    }

    _filteredRows = filtered;
    _grossPurchased = gross;
    _totalReturned = retSum;
    _netPurchased = gross - retSum;
    _totalBills = billCount;
    _totalReturns = retCount;
  }

  void _onVendorChanged(String? vendor) {
    setState(() {
      _selectedVendor = vendor;
      if (vendor == null) {
        _allVendorRows = [];
        _filteredRows = [];
        _resetTotals();
      } else {
        _loadVendorData(vendor);
      }
    });
  }

  void _updateDateRange(String filter) {
    final now = DateTime.now();
    if (filter == 'All Time') {
      _startDate = null;
      _endDate = null;
    } else if (filter == 'This Month') {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (filter == 'Last Month') {
      _startDate = DateTime(now.year, now.month - 1, 1);
      _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
    } else if (filter == 'Last 3 Months') {
      _startDate = DateTime(now.year, now.month - 2, 1);
      _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }

    setState(() {
      _filterType = filter;
      _applyFilter();
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.textPrimary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filterType = 'Custom Range';
        _startDate = picked.start;
        _endDate = DateTime(
            picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        _applyFilter();
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedVendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vendor first'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    setState(() => _exporting = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating Vendor Purchase History PDF...'),
        backgroundColor: AppColors.bankBlue,
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final purchasesOnly = data.purchases
          .where((p) => p.vendorName.trim() == _selectedVendor)
          .toList()
        ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));

      await PdfService.generateVendorPurchaseHistoryPdf(
        vendorName: _selectedVendor!,
        periodLabel: _filterType,
        startDate: _startDate,
        endDate: _endDate,
        purchases: purchasesOnly,
        totalAmount: _netPurchased,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check your internet connection'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _formatDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  String _formatDateShort(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vendor Purchase History'),
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedVendor != null)
            IconButton(
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf),
              tooltip: 'Export Vendor History PDF',
              onPressed: _exporting ? null : _exportPdf,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Filters card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _selectedVendor,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Vendor',
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _vendorNames
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: _onVendorChanged,
                      hint: const Text('Choose vendor...'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _filterType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Period',
                        prefixIcon: Icon(Icons.date_range),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        'All Time',
                        'This Month',
                        'Last Month',
                        'Last 3 Months',
                        'Custom Range',
                      ]
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        if (val == 'Custom Range') {
                          _pickCustomRange();
                        } else {
                          _updateDateRange(val);
                        }
                      },
                    ),
                  ),
                  if (_startDate != null && _endDate != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.bankBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_formatDateShort(_startDate!)} — ${_formatDateShort(_endDate!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.bankBlue,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Summary Cards ──
            if (_selectedVendor != null)
              Row(
                children: [
                  _summaryCard('Bills / Returns', '$_totalBills / $_totalReturns', AppColors.bankBlue),
                  const SizedBox(width: 12),
                  _summaryCard('Gross Purchases', 'Rs. ${_grossPurchased.toStringAsFixed(2)}', AppColors.sidebarActive),
                  const SizedBox(width: 12),
                  _summaryCard('Total Returned (Debit)', '-Rs. ${_totalReturned.toStringAsFixed(2)}', AppColors.expenseRed),
                  const SizedBox(width: 12),
                  _summaryCard(
                    'Net Outflow',
                    'Rs. ${_netPurchased.toStringAsFixed(2)}',
                    AppColors.cashGreen,
                    highlight: true,
                  ),
                ],
              ),
            if (_selectedVendor != null) const SizedBox(height: 16),

            // ── List ──
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: _selectedVendor == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storefront_outlined,
                                size: 56,
                                color: AppColors.textSecondary.withOpacity(0.6)),
                            const SizedBox(height: 12),
                            const Text(
                              'Select a vendor to view purchase history',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : _filteredRows.isEmpty
                        ? Center(
                            child: Text(
                              'No transactions for $_selectedVendor in selected period',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary.withOpacity(0.7),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                color: AppColors.headerBg,
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 110,
                                      child: Text('Date',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.white)),
                                    ),
                                    SizedBox(
                                      width: 130,
                                      child: Text('Reference ID',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.white)),
                                    ),
                                    Expanded(
                                      child: Text('Items / Description',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.white)),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: Text('Type',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.white)),
                                    ),
                                    SizedBox(
                                      width: 130,
                                      child: Text('Amount',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _filteredRows.length,
                                  itemBuilder: (context, index) {
                                    final row = _filteredRows[index];
                                    final bg = index % 2 == 0
                                        ? AppColors.cardBg
                                        : const Color(0xFFF8FAFC);

                                    return InkWell(
                                      onTap: row.originalPurchase == null
                                          ? null
                                          : () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      PurchaseDetailScreen(
                                                          purchase:
                                                              row.originalPurchase!),
                                                ),
                                              ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: row.isReturn
                                              ? AppColors.expenseRed
                                                  .withOpacity(0.04)
                                              : bg,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: AppColors.border
                                                  .withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 110,
                                              child: Text(
                                                _formatDate(row.date),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 130,
                                              child: Text(
                                                row.id,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: row.isReturn
                                                      ? AppColors.expenseRed
                                                      : AppColors.bankBlue,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                row.itemSummary,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: row.isReturn
                                                      ? AppColors.expenseRed
                                                      : AppColors.textSecondary,
                                                  fontWeight: row.isReturn
                                                      ? FontWeight.w500
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 100,
                                              child: Center(
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: row.isReturn
                                                        ? AppColors.expenseRed
                                                            .withOpacity(0.12)
                                                        : AppColors.cashGreen
                                                            .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    row.isReturn
                                                        ? 'RETURN'
                                                        : row.paymentMethod
                                                            .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: row.isReturn
                                                          ? AppColors.expenseRed
                                                          : AppColors.cashGreen,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 130,
                                              child: Text(
                                                row.isReturn
                                                    ? '-Rs. ${row.amount.toStringAsFixed(2)}'
                                                    : 'Rs. ${row.amount.toStringAsFixed(2)}',
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: row.isReturn
                                                      ? AppColors.expenseRed
                                                      : AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color,
      {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: highlight ? color.withOpacity(0.08) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlight ? color : AppColors.border,
            width: highlight ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}