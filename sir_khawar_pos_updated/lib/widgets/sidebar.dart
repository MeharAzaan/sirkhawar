import 'package:flutter/material.dart';

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