import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';

import 'create_purchase_screen.dart';
import 'purchase_detail_screen.dart';
import 'vendor_purchase_history_screen.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final AppData data = AppData();
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    data.addListener(_onDataChanged);
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

  @override
  Widget build(BuildContext context) {
    final filtered = data.purchases.where((p) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return p.id.toLowerCase().contains(q) ||
          p.vendorName.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Purchases'),
        backgroundColor: AppColors.headerBg,
        foregroundColor: AppColors.cardBg,
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.history),
            label: const Text('Vendor History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bankBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VendorPurchaseHistoryScreen(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('New Purchase'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sidebarActive,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CreatePurchaseScreen()),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.cardBg,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search by purchase ID or vendor...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text('No purchases yet',
                            style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final p = filtered[i];
                      final notAdded = p.items
                          .where((it) =>
                              it.productId.isEmpty && !it.addedToInventory)
                          .length;
                      return Card(
                        color: AppColors.cardBg,
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PurchaseDetailScreen(purchase: p),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: AppColors.bankBlue,
                                  child: Icon(Icons.shopping_bag,
                                      color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p.id,
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              color: AppColors
                                                  .textPrimary)),
                                      const SizedBox(height: 4),
                                      Text(p.vendorName,
                                          style: const TextStyle(
                                              color: AppColors
                                                  .textSecondary)),
                                      Text(
                                        DateFormat('dd MMM yyyy, hh:mm a')
                                            .format(p.purchaseDate),
                                        style: const TextStyle(
                                            color: AppColors
                                                .textSecondary,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                        'Rs. ${p.totalAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                            color:
                                                AppColors.bankBlue,
                                            fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(
                                        '${p.items.length} item${p.items.length != 1 ? "s" : ""}',
                                        style: const TextStyle(
                                            color: AppColors
                                                .textSecondary,
                                            fontSize: 12)),
                                    if (notAdded > 0) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 6,
                                            vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.expenseRed
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '$notAdded not in inventory',
                                          style: const TextStyle(
                                              color: AppColors
                                                  .expenseRed,
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
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