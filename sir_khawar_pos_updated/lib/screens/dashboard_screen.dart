import 'package:flutter/material.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AppData data = AppData();

  @override
  void initState() {
    super.initState();
    data.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  // ---------- Date helpers (read-only, no logic changes) ----------
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());

  bool _isYesterday(DateTime d) {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return _isSameDay(d, y);
  }

  @override
  Widget build(BuildContext context) {
    // Always merged (both companies) — no company filter on dashboard
    final totalRevenue = data.totalInvoiceAmount;
    final totalCollected = data.salesHistory.fold(
      0.0,
      (s, sale) =>
          s + sale.payments.fold(0.0, (ps, p) => ps + p.amount),
    );
    final outstanding = totalRevenue - totalCollected;

    // ---------- STATS (computed from existing Firestore data) ----------
    final todayQuotations =
        data.quotations.where((q) => _isToday(q.createdDate)).length;
    final yesterdayQuotations =
        data.quotations.where((q) => _isYesterday(q.createdDate)).length;
    final allQuotations = data.quotations.length;

    final todayInvoices =
        data.salesHistory.where((s) => _isToday(s.dateOfPurchase)).length;
    final yesterdayInvoices =
        data.salesHistory.where((s) => _isYesterday(s.dateOfPurchase)).length;
    final allInvoices = data.salesHistory.length;

    final todaySales = data.salesHistory
        .where((s) => _isToday(s.dateOfPurchase))
        .fold(0.0, (sum, s) => sum + s.totalAmount);
    final yesterdaySales = data.salesHistory
        .where((s) => _isYesterday(s.dateOfPurchase))
        .fold(0.0, (sum, s) => sum + s.totalAmount);
    final allSales = totalRevenue;

    final todayCollected = data.salesHistory.fold(0.0, (sum, sale) {
      return sum +
          sale.payments
              .where((p) => _isToday(p.date))
              .fold(0.0, (ps, p) => ps + p.amount);
    });
    final yesterdayCollected = data.salesHistory.fold(0.0, (sum, sale) {
      return sum +
          sale.payments
              .where((p) => _isYesterday(p.date))
              .fold(0.0, (ps, p) => ps + p.amount);
    });

    // Unique customer names from quotations + invoices
    final todayCustomers = <String>{
      ...data.quotations
          .where((q) => _isToday(q.createdDate))
          .map((q) => q.customerName.trim().toLowerCase()),
      ...data.salesHistory
          .where((s) => _isToday(s.dateOfPurchase))
          .map((s) => s.customerName.trim().toLowerCase()),
    }..removeWhere((n) => n.isEmpty);

    final yesterdayCustomers = <String>{
      ...data.quotations
          .where((q) => _isYesterday(q.createdDate))
          .map((q) => q.customerName.trim().toLowerCase()),
      ...data.salesHistory
          .where((s) => _isYesterday(s.dateOfPurchase))
          .map((s) => s.customerName.trim().toLowerCase()),
    }..removeWhere((n) => n.isEmpty);

    final allCustomers = <String>{
      ...data.quotations.map((q) => q.customerName.trim().toLowerCase()),
      ...data.salesHistory.map((s) => s.customerName.trim().toLowerCase()),
    }..removeWhere((n) => n.isEmpty);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        title: const Text('Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===================== EXISTING UI (UNCHANGED) =====================
            const Text(
              'Overview',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _card('Cash Balance', 'Rs. ${data.cashBalance.toStringAsFixed(2)}',
                    AppColors.cashGreen, Icons.account_balance_wallet),
                const SizedBox(width: 16),
                _card('Bank Balance', 'Rs. ${data.bankBalance.toStringAsFixed(2)}',
                    AppColors.bankBlue, Icons.account_balance),
                const SizedBox(width: 16),
                _card('Total Revenue', 'Rs. ${totalRevenue.toStringAsFixed(2)}',
                    AppColors.sidebarActive, Icons.trending_up),
                const SizedBox(width: 16),
                _card('Outstanding', 'Rs. ${outstanding.toStringAsFixed(2)}',
                    AppColors.expenseRed, Icons.money_off),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _card('Total Expenses',
                    'Rs. ${data.totalExpenses.toStringAsFixed(2)}',
                    AppColors.pendingOrange, Icons.receipt_long),
                const SizedBox(width: 16),
                _card('Pending Cheques',
                    '${data.pendingChequeCount}',
                    AppColors.pendingOrange, Icons.schedule),
                const SizedBox(width: 16),
                _card('Total Stock', '${data.totalStock} items',
                    AppColors.sidebarActive, Icons.inventory),
                const SizedBox(width: 16),
                _card('Invoices', '${data.salesHistory.length}',
                    AppColors.bankBlue, Icons.description),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _card('Quotations', '${data.quotations.length}',
                    AppColors.sidebarActive, Icons.request_quote),
                const SizedBox(width: 16),
                const Spacer(flex: 3),
              ],
            ),

            // ===================== NEW STATS SECTION =====================
            const SizedBox(height: 36),
            const Text(
              'Stats',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.headerBg.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Table(
                border: TableBorder.symmetric(
                  inside: const BorderSide(color: AppColors.border),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(2.2),
                  1: FlexColumnWidth(1.4),
                  2: FlexColumnWidth(1.4),
                  3: FlexColumnWidth(1.4),
                },
                children: [
                  // Header
                  TableRow(
                    decoration: const BoxDecoration(color: AppColors.background),
                    children: const [
                      _StatHeader(''),
                      _StatHeader('Today'),
                      _StatHeader('Yesterday'),
                      _StatHeader('All Time'),
                    ],
                  ),
                  _statRow(
                    'Customers',
                    '${todayCustomers.length}',
                    '${yesterdayCustomers.length}',
                    '${allCustomers.length}',
                  ),
                  _statRow(
                    'Quotations',
                    '$todayQuotations',
                    '$yesterdayQuotations',
                    '$allQuotations',
                  ),
                  _statRow(
                    'Invoices',
                    '$todayInvoices',
                    '$yesterdayInvoices',
                    '$allInvoices',
                  ),
                  _statRow(
                    'Sales (Rs.)',
                    todaySales.toStringAsFixed(0),
                    yesterdaySales.toStringAsFixed(0),
                    allSales.toStringAsFixed(0),
                  ),
                  _statRow(
                    'Collected (Rs.)',
                    todayCollected.toStringAsFixed(0),
                    yesterdayCollected.toStringAsFixed(0),
                    totalCollected.toStringAsFixed(0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _statRow(String label, String today, String yesterday, String all) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Text(today,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Text(yesterday,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Text(all,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  Widget _card(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: AppColors.headerBg.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _StatHeader extends StatelessWidget {
  final String text;
  const _StatHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}