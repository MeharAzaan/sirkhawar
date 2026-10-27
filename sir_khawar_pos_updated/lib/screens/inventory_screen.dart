import 'package:flutter/material.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';

import '../models/product.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
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

  List<Product> get _filtered {
    if (_searchQuery.isEmpty) return data.products;
    return data.products
        .where((p) =>
            p.name.toLowerCase().contains(_searchQuery) ||
            p.id.toLowerCase().contains(_searchQuery) ||
            p.category.toLowerCase().contains(_searchQuery))
        .toList();
  }

  Future<void> _showAddProductDialog({Product? existing}) async {
    final idCtrl = TextEditingController(text: existing?.id ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final categoryCtrl =
        TextEditingController(text: existing?.category ?? '');
    final priceCtrl = TextEditingController(
        text: existing != null
            ? existing.price.toStringAsFixed(2)
            : '');
    final qtyCtrl = TextEditingController(
        text: existing != null ? existing.quantity.toString() : '');
    final unitCtrl =
        TextEditingController(text: existing?.unit ?? 'pcs');
    final descCtrl =
        TextEditingController(text: existing?.description ?? '');

    final isEdit = existing != null;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(isEdit ? 'Edit Product' : 'Add Product',
            style: const TextStyle(color: AppColors.textPrimary)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isEdit)
                  TextField(
                    controller: idCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Product ID *',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: AppColors.sidebarActive, width: 1.5),
                      ),
                    ),
                  ),
                if (!isEdit) const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: AppColors.sidebarActive, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: AppColors.sidebarActive, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Price *',
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.sidebarActive, width: 1.5),
                          ),
                          prefixText: 'Rs. ',
                          prefixStyle: TextStyle(color: AppColors.textPrimary),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.sidebarActive, width: 1.5),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: unitCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.sidebarActive, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: AppColors.sidebarActive, width: 1.5),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sidebarActive,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Update' : 'Add')),
        ],
      ),
    );

    if (result != true) return;
    if (nameCtrl.text.trim().isEmpty) return;
    final price = double.tryParse(priceCtrl.text);
    if (price == null) return;

    try {
      final product = Product(
        id: isEdit ? existing!.id : idCtrl.text.trim(),
        name: nameCtrl.text.trim(),
        category: categoryCtrl.text.trim(),
        price: price,
        quantity: int.tryParse(qtyCtrl.text) ?? 0,
        unit: unitCtrl.text.trim(),
        description: descCtrl.text.trim(),
      );
      if (isEdit) {
        await data.updateProduct(product);
      } else {
        await data.addProduct(product);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(isEdit ? 'Product updated' : 'Product added'),
            backgroundColor: AppColors.cashGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.expenseRed),
        );
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Delete Product',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Delete "${product.name}"?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expenseRed,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await data.deleteProduct(product.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.expenseRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        title: const Text('Inventory'),
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sidebarActive,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showAddProductDialog(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search products...',
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
            child: products.isEmpty
                ? const Center(
                    child: Text('No products',
                        style: TextStyle(color: AppColors.textSecondary)))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
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
                                  label: Text('ID',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Name',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Category',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Price',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.bold)),
                                  numeric: true),
                              DataColumn(
                                  label: Text('Qty',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.bold)),
                                  numeric: true),
                              DataColumn(
                                  label: Text('Unit',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Actions',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.bold))),
                            ],
                            rows: products.map((p) {
                              return DataRow(cells: [
                                DataCell(Text(p.id,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary))),
                                DataCell(Text(p.name,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary))),
                                DataCell(Text(p.category,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary))),
                                DataCell(Text(
                                    'Rs. ${p.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: AppColors.textPrimary))),
                                DataCell(Text(
                                  p.quantity.toString(),
                                  style: TextStyle(
                                    color: p.quantity <= 5
                                        ? AppColors.expenseRed
                                        : AppColors.textPrimary,
                                    fontWeight: p.quantity <= 5
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                )),
                                DataCell(Text(p.unit,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary))),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          size: 20,
                                          color: AppColors.sidebarActive),
                                      onPressed: () =>
                                          _showAddProductDialog(
                                              existing: p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          size: 20,
                                          color: AppColors.expenseRed),
                                      onPressed: () =>
                                          _deleteProduct(p),
                                    ),
                                  ],
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
}