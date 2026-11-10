import 'package:flutter/material.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final Set<String> allowedKeys;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isCollapsed,
    required this.onToggle,
    required this.allowedKeys,
  });

  Future<void> _showClearCacheDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear App Cache'),
        content: const Text(
          'This will clear memory & image cache and re-sync fresh data from the server. Do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bankBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Clearing app cache...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );

        // Clear Flutter Image Cache from memory
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        // Refresh & re-fetch data from Firestore
        await AppData().initialize();

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('App cache cleared successfully'),
              backgroundColor: AppColors.cashGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please check your internet connection'),
              backgroundColor: AppColors.expenseRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'icon': Icons.grid_view_rounded, 'label': 'Dashboard', 'key': 'dashboard'},
      {'icon': Icons.receipt_long_outlined, 'label': 'Expenses', 'key': 'expenses'},
      {'icon': Icons.account_balance_outlined, 'label': 'Bank & Cash', 'key': 'bank_cash'},
      {'icon': Icons.credit_card_outlined, 'label': 'Customer Cheques', 'key': 'customer_cheques'},
      {'icon': Icons.inventory_2_outlined, 'label': 'Inventory', 'key': 'inventory'},
      {'icon': Icons.description_outlined, 'label': 'Quotations', 'key': 'quotations'},
      {'icon': Icons.receipt_outlined, 'label': 'Invoices', 'key': 'invoices'},
      {'icon': Icons.people_outline, 'label': 'Customers', 'key': 'customers'},
      {'icon': Icons.badge_outlined, 'label': 'Employees', 'key': 'employees'},
      {'icon': Icons.dashboard_customize_outlined, 'label': 'Templates', 'key': 'templates'},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'key': 'settings'},
      {'icon': Icons.store_outlined, 'label': 'Vendors', 'key': 'vendors'},
      {'icon': Icons.shopping_bag_outlined, 'label': 'Purchases', 'key': 'purchases'},
      {'icon': Icons.assessment_outlined, 'label': 'Reports', 'key': 'reports'},
    ];

    // Filter by allowed keys, preserve original index for correct screen routing
    final filteredItems = <Map<String, dynamic>>[];
    for (int i = 0; i < navItems.length; i++) {
      if (allowedKeys.contains(navItems[i]['key'])) {
        filteredItems.add({...navItems[i], 'originalIndex': i});
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 70 : 240,
      color: const Color(0xFF1A2332),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Colors.amber, size: 24),
                if (!isCollapsed) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AES Business', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis, maxLines: 1),
                        Text('Management System', style: TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 1),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final originalIndex = item['originalIndex'] as int;
                final isSelected = selectedIndex == originalIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: InkWell(
                    onTap: () => onItemSelected(originalIndex),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(item['icon'] as IconData, color: isSelected ? Colors.white : Colors.grey.shade400, size: 20),
                          if (!isCollapsed) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(item['label'] as String, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade400, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 1),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // ── Clear Cache Button ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: InkWell(
              onTap: () => _showClearCacheDialog(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_outlined, color: Colors.amber.shade300, size: 20),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Clear Cache',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Logout Button ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: InkWell(
              onTap: () {
                AppData().logout();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Collapse Button ──
          InkWell(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black12,
              child: Row(
                mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Icon(isCollapsed ? Icons.chevron_right : Icons.chevron_left, color: Colors.grey.shade400),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 8),
                    Expanded(child: Text('Collapse', style: TextStyle(color: Colors.grey.shade400, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 1)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}