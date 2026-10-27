import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggle;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'icon': Icons.grid_view_rounded, 'label': 'Dashboard'},
      {'icon': Icons.receipt_long_outlined, 'label': 'Expenses'},
      {'icon': Icons.account_balance_outlined, 'label': 'Bank & Cash'},
      {'icon': Icons.credit_card_outlined, 'label': 'Customer Cheques'},
      {'icon': Icons.inventory_2_outlined, 'label': 'Inventory'},
      {'icon': Icons.description_outlined, 'label': 'Quotations'},
      {'icon': Icons.receipt_outlined, 'label': 'Invoices'},
      {'icon': Icons.people_outline, 'label': 'Customers'},
      {'icon': Icons.badge_outlined, 'label': 'Employees'},
      {'icon': Icons.dashboard_customize_outlined, 'label': 'Templates'},
      {'icon': Icons.settings_outlined, 'label': 'Settings'},
      {'icon': Icons.store_outlined, 'label': 'Vendors'},
      {'icon': Icons.shopping_bag_outlined, 'label': 'Purchases'},
      {'icon': Icons.assessment_outlined, 'label': 'Reports'},
    ];

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
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;
                final item = navItems[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: InkWell(
                    onTap: () => onItemSelected(index),
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