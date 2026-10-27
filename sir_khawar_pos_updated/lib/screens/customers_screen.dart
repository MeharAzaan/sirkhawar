import 'package:flutter/material.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';

import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final AppData data = AppData();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

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

  List<_CustomerSummary> get _customers {
    final map = <String, _CustomerSummary>{};

    for (final sale in data.salesHistory) {
      final name = sale.customerName;
      if (name.isEmpty) continue;
      map.putIfAbsent(name,
          () => _CustomerSummary(name: name, phone: sale.customerPhone));
      map[name]!.totalPurchases += sale.totalAmount;
      map[name]!.totalPaid +=
          sale.payments.fold(0.0, (s, p) => s + p.amount);
      map[name]!.invoiceCount++;
    }

    for (final q in data.quotations) {
      final name = q.customerName;
      if (name.isEmpty) continue;
      map.putIfAbsent(name,
          () => _CustomerSummary(name: name, phone: q.customerPhone));
      map[name]!.quotationCount++;
    }

    var list = map.values.toList();
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((c) => c.name.toLowerCase().contains(_searchQuery))
          .toList();
    }
    list.sort((a, b) => b.totalPurchases.compareTo(a.totalPurchases));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final customers = _customers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        title: const Text('Customers'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search customers...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textSecondary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppColors.sidebarActive, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? const Center(
                    child: Text('No customers found',
                        style: TextStyle(
                            fontSize: 18, color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final c = customers[index];
                      final outstanding =
                          c.totalPurchases - c.totalPaid;
                      return Card(
                        color: AppColors.cardBg,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.sidebarActive.withOpacity(0.15),
                            child: Text(
                              c.name.isNotEmpty
                                  ? c.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sidebarActive),
                            ),
                          ),
                          title: Text(c.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          subtitle: Text(
                              '${c.phone} • ${c.invoiceCount} invoices • ${c.quotationCount} quotations',
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                  'Rs. ${c.totalPurchases.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary)),
                              if (outstanding > 0)
                                Text(
                                    'Due: Rs. ${outstanding.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: AppColors.expenseRed,
                                        fontSize: 12)),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CustomerDetailScreen(
                                    customerName: c.name),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CustomerSummary {
  final String name;
  final String phone;
  double totalPurchases = 0;
  double totalPaid = 0;
  int invoiceCount = 0;
  int quotationCount = 0;

  _CustomerSummary({required this.name, required this.phone});
}