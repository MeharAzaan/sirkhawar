// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
// import 'package:sir_khawar_pos_updated/data/app_data.dart';

// import '../models/product.dart';
// import '../models/quotation_template.dart';
// import '../models/quotation.dart';

// class CreateTemplateScreen extends StatefulWidget {
//   const CreateTemplateScreen({super.key, this.template});
//   final QuotationTemplate? template;

//   @override
//   State<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
// }

// class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
//   final AppData data = AppData();
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _nameCtrl;
//   late TextEditingController _notesCtrl;
//   List<_TLine> _items = [];
//   bool _saving = false;
//   bool get _isEditing => widget.template != null;

//   @override
//   void initState() {
//     super.initState();
//     data.addListener(_onDataChanged);
//     final t = widget.template;
//     _nameCtrl = TextEditingController(text: t?.name ?? '');
//     _notesCtrl = TextEditingController(text: t?.notes ?? '');
//     if (t != null && t.items.isNotEmpty) {
//       _items = t.items
//           .map((i) => _TLine(
//               productId: i.productId,
//               productName: i.productName,
//               quantity: i.quantity,
//               unitPrice: i.unitPrice,
//               discount: i.discount))
//           .toList();
//     } else {
//       _items = [_TLine.empty()];
//     }
//   }

//   @override
//   void dispose() {
//     data.removeListener(_onDataChanged);
//     _nameCtrl.dispose();
//     _notesCtrl.dispose();
//     super.dispose();
//   }

//   void _onDataChanged() {
//     if (mounted) setState(() {});
//   }

//   void _addItem() => setState(() => _items.add(_TLine.empty()));
//   void _removeItem(int i) {
//     if (_items.length <= 1) return;
//     setState(() => _items.removeAt(i));
//   }

//   void _onProductSelected(int index, String? productId) {
//     if (productId == null) return;
//     final p = data.products.firstWhere((p) => p.id == productId);
//     setState(() {
//       _items[index]
//         ..productId = p.id
//         ..productName = p.name
//         ..unitPrice = p.price;
//     });
//   }

//   Future<void> _save() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _saving = true);
//     try {
//       final items = _items
//           .where((i) => i.productId.isNotEmpty)
//           .map((i) => QuotationItem(
//               productId: i.productId,
//               productName: i.productName,
//               quantity: i.quantity,
//               unitPrice: i.unitPrice,
//               discount: i.discount))
//           .toList();

//       if (_isEditing) {
//         await data.updateTemplate(QuotationTemplate(
//             id: widget.template!.id,
//             name: _nameCtrl.text.trim(),
//             items: items,
//             notes: _notesCtrl.text.trim()));
//       } else {
//         final newId =
//             FirebaseFirestore.instance.collection('templates').doc().id;
//         await data.addTemplate(QuotationTemplate(
//             id: newId,
//             name: _nameCtrl.text.trim(),
//             items: items,
//             notes: _notesCtrl.text.trim()));
//       }
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('Template saved'),
//               backgroundColor: AppColors.cashGreen),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text('Error: $e'),
//               backgroundColor: AppColors.expenseRed),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: AppColors.headerBg,
//         foregroundColor: Colors.white,
//         title: Text(_isEditing ? 'Edit Template' : 'New Template'),
//         elevation: 0,
//       ),
//       body: Form(
//         key: _formKey,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _nameCtrl,
//                       style: const TextStyle(color: AppColors.textPrimary),
//                       decoration: const InputDecoration(
//                         labelText: 'Template Name *',
//                         labelStyle: TextStyle(color: AppColors.textSecondary),
//                         border: OutlineInputBorder(),
//                         enabledBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: AppColors.border),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderSide: BorderSide(
//                               color: AppColors.sidebarActive, width: 1.5),
//                         ),
//                       ),
//                       validator: (v) =>
//                           v == null || v.trim().isEmpty ? 'Required' : null,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: TextFormField(
//                       controller: _notesCtrl,
//                       style: const TextStyle(color: AppColors.textPrimary),
//                       decoration: const InputDecoration(
//                         labelText: 'Notes',
//                         labelStyle: TextStyle(color: AppColors.textSecondary),
//                         border: OutlineInputBorder(),
//                         enabledBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: AppColors.border),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderSide: BorderSide(
//                               color: AppColors.sidebarActive, width: 1.5),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text('Default Items',
//                       style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: AppColors.textPrimary)),
//                   ElevatedButton.icon(
//                       icon: const Icon(Icons.add),
//                       label: const Text('Add Item'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.sidebarActive,
//                         foregroundColor: Colors.white,
//                       ),
//                       onPressed: _addItem),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               ...List.generate(_items.length, (index) {
//                 final item = _items[index];
//                 return Card(
//                   color: AppColors.cardBg,
//                   elevation: 1,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     side: const BorderSide(color: AppColors.border),
//                   ),
//                   margin: const EdgeInsets.only(bottom: 8),
//                   child: Padding(
//                     padding: const EdgeInsets.all(12),
//                     child: Row(
//                       children: [
//                         // 🔍 SEARCHABLE PRODUCT FIELD (replaced dropdown)
//                         Expanded(
//                           flex: 3,
//                           child: Autocomplete<Product>(
//                             initialValue: TextEditingValue(
//                               text: item.productId.isNotEmpty
//                                   ? '${item.productId} - ${item.productName}'
//                                   : '',
//                             ),
//                             displayStringForOption: (Product p) =>
//                                 '${p.id} - ${p.name}',
//                             optionsBuilder:
//                                 (TextEditingValue textEditingValue) {
//                               if (textEditingValue.text.isEmpty) {
//                                 return data.products;
//                               }
//                               final q =
//                                   textEditingValue.text.toLowerCase();
//                               return data.products.where((p) =>
//                                   p.id.toLowerCase().contains(q) ||
//                                   p.name.toLowerCase().contains(q) ||
//                                   p.category.toLowerCase().contains(q));
//                             },
//                             onSelected: (Product p) {
//                               _onProductSelected(index, p.id);
//                             },
//                             fieldViewBuilder: (context, controller,
//                                 focusNode, onFieldSubmitted) {
//                               return TextFormField(
//                                 controller: controller,
//                                 focusNode: focusNode,
//                                 style: const TextStyle(
//                                     color: AppColors.textPrimary),
//                                 decoration: const InputDecoration(
//                                   hintText: 'Search product ID or name...',
//                                   hintStyle: TextStyle(
//                                       color: AppColors.textSecondary),
//                                   labelText: 'Product',
//                                   labelStyle: TextStyle(
//                                       color: AppColors.textSecondary),
//                                   border: OutlineInputBorder(),
//                                   enabledBorder: OutlineInputBorder(
//                                     borderSide: BorderSide(
//                                         color: AppColors.border),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderSide: BorderSide(
//                                         color: AppColors.sidebarActive,
//                                         width: 1.5),
//                                   ),
//                                   prefixIcon: Icon(Icons.search,
//                                       color: AppColors.textSecondary),
//                                   isDense: true,
//                                 ),
//                                 onChanged: (v) {
//                                   if (v.isEmpty &&
//                                       item.productId.isNotEmpty) {
//                                     setState(() {
//                                       item.productId = '';
//                                       item.productName = '';
//                                       item.unitPrice = 0.0;
//                                     });
//                                   }
//                                 },
//                               );
//                             },
//                             optionsViewBuilder:
//                                 (context, onSelected, options) {
//                               return Align(
//                                 alignment: Alignment.topLeft,
//                                 child: Material(
//                                   elevation: 4,
//                                   color: AppColors.cardBg,
//                                   borderRadius: BorderRadius.circular(8),
//                                   child: ConstrainedBox(
//                                     constraints: const BoxConstraints(
//                                         maxHeight: 240, maxWidth: 400),
//                                     child: ListView.builder(
//                                       padding: EdgeInsets.zero,
//                                       shrinkWrap: true,
//                                       itemCount: options.length,
//                                       itemBuilder: (context, i) {
//                                         final p = options.elementAt(i);
//                                         return ListTile(
//                                           dense: true,
//                                           title: Text(
//                                             '${p.id} - ${p.name}',
//                                             style: const TextStyle(
//                                                 color:
//                                                     AppColors.textPrimary,
//                                                 fontSize: 13),
//                                           ),
//                                           subtitle: Text(
//                                             p.category,
//                                             style: const TextStyle(
//                                                 color: AppColors
//                                                     .textSecondary,
//                                                 fontSize: 11),
//                                           ),
//                                           onTap: () => onSelected(p),
//                                         );
//                                       },
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: TextFormField(
//                             initialValue: item.quantity.toString(),
//                             style: const TextStyle(
//                                 color: AppColors.textPrimary),
//                             decoration: const InputDecoration(
//                               labelText: 'Qty',
//                               labelStyle: TextStyle(
//                                   color: AppColors.textSecondary),
//                               border: OutlineInputBorder(),
//                               enabledBorder: OutlineInputBorder(
//                                 borderSide:
//                                     BorderSide(color: AppColors.border),
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderSide: BorderSide(
//                                     color: AppColors.sidebarActive,
//                                     width: 1.5),
//                               ),
//                             ),
//                             keyboardType: TextInputType.number,
//                             onChanged: (v) => setState(() =>
//                                 item.quantity = int.tryParse(v) ?? 1),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: TextFormField(
//                             initialValue:
//                                 item.unitPrice.toStringAsFixed(2),
//                             style: const TextStyle(
//                                 color: AppColors.textPrimary),
//                             decoration: const InputDecoration(
//                               labelText: 'Price',
//                               labelStyle: TextStyle(
//                                   color: AppColors.textSecondary),
//                               border: OutlineInputBorder(),
//                               enabledBorder: OutlineInputBorder(
//                                 borderSide:
//                                     BorderSide(color: AppColors.border),
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderSide: BorderSide(
//                                     color: AppColors.sidebarActive,
//                                     width: 1.5),
//                               ),
//                             ),
//                             keyboardType:
//                                 const TextInputType.numberWithOptions(
//                                     decimal: true),
//                             onChanged: (v) => setState(() => item
//                                 .unitPrice = double.tryParse(v) ?? 0),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: TextFormField(
//                             initialValue:
//                                 item.discount.toStringAsFixed(2),
//                             style: const TextStyle(
//                                 color: AppColors.textPrimary),
//                             decoration: const InputDecoration(
//                               labelText: 'Discount',
//                               labelStyle: TextStyle(
//                                   color: AppColors.textSecondary),
//                               border: OutlineInputBorder(),
//                               enabledBorder: OutlineInputBorder(
//                                 borderSide:
//                                     BorderSide(color: AppColors.border),
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderSide: BorderSide(
//                                     color: AppColors.sidebarActive,
//                                     width: 1.5),
//                               ),
//                             ),
//                             keyboardType:
//                                 const TextInputType.numberWithOptions(
//                                     decimal: true),
//                             onChanged: (v) => setState(() => item
//                                 .discount = double.tryParse(v) ?? 0),
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.delete,
//                               color: AppColors.expenseRed),
//                           onPressed: () => _removeItem(index),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }),
//               const SizedBox(height: 32),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   ElevatedButton(
//                     onPressed: _saving ? null : _save,
//                     style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.cashGreen,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 32, vertical: 12)),
//                     child: _saving
//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                                 strokeWidth: 2, color: Colors.white))
//                         : Text(_isEditing
//                             ? 'Update Template'
//                             : 'Save Template'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _TLine {
//   String productId;
//   String productName;
//   int quantity;
//   double unitPrice;
//   double discount;

//   _TLine({
//     required this.productId,
//     required this.productName,
//     required this.quantity,
//     required this.unitPrice,
//     required this.discount,
//   });

//   _TLine.empty()
//       : productId = '',
//         productName = '',
//         quantity = 1,
//         unitPrice = 0.0,
//         discount = 0.0;
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';

import '../models/product.dart';
import '../models/quotation_template.dart';
import '../models/quotation.dart';

class CreateTemplateScreen extends StatefulWidget {
  const CreateTemplateScreen({super.key, this.template});
  final QuotationTemplate? template;

  @override
  State<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
  final AppData data = AppData();
  final _formKey = GlobalKey<FormState>();

  // UI-only: shared const decorations (canonicalized by compiler).
  static const _border = OutlineInputBorder();
  static const _enabledBorder = OutlineInputBorder(
    borderSide: BorderSide(color: AppColors.border),
  );
  static const _focusedBorder = OutlineInputBorder(
    borderSide: BorderSide(color: AppColors.sidebarActive, width: 1.5),
  );
  static const _labelStyle = TextStyle(color: AppColors.textSecondary);

  late TextEditingController _nameCtrl;
  late TextEditingController _notesCtrl;
  List<_TLine> _items = [];
  bool _saving = false;
  bool get _isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    data.addListener(_onDataChanged);
    final t = widget.template;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    if (t != null && t.items.isNotEmpty) {
      _items = t.items
          .map((i) => _TLine(
              productId: i.productId,
              productName: i.productName,
              quantity: i.quantity,
              unitPrice: i.unitPrice,
              discount: i.discount))
          .toList();
    } else {
      _items = [_TLine.empty()];
    }
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _addItem() => setState(() => _items.add(_TLine.empty()));
  void _removeItem(int i) {
    if (_items.length <= 1) return;
    setState(() => _items.removeAt(i));
  }

  void _onProductSelected(int index, String? productId) {
    if (productId == null) return;
    final p = data.products.firstWhere((p) => p.id == productId);
    setState(() {
      _items[index]
        ..productId = p.id
        ..productName = p.name
        ..unitPrice = p.price;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final items = _items
          .where((i) => i.productId.isNotEmpty)
          .map((i) => QuotationItem(
              productId: i.productId,
              productName: i.productName,
              quantity: i.quantity,
              unitPrice: i.unitPrice,
              discount: i.discount))
          .toList();

      if (_isEditing) {
        await data.updateTemplate(QuotationTemplate(
            id: widget.template!.id,
            name: _nameCtrl.text.trim(),
            items: items,
            notes: _notesCtrl.text.trim()));
      } else {
        final newId =
            FirebaseFirestore.instance.collection('templates').doc().id;
        await data.addTemplate(QuotationTemplate(
            id: newId,
            name: _nameCtrl.text.trim(),
            items: items,
            notes: _notesCtrl.text.trim()));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Template saved'),
              backgroundColor: AppColors.cashGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.expenseRed),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        title: Text(_isEditing ? 'Edit Template' : 'New Template'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Template Name *',
                        labelStyle: _labelStyle,
                        border: _border,
                        enabledBorder: _enabledBorder,
                        focusedBorder: _focusedBorder,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _notesCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        labelStyle: _labelStyle,
                        border: _border,
                        enabledBorder: _enabledBorder,
                        focusedBorder: _focusedBorder,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Default Items',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sidebarActive,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _addItem),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(_items.length, (index) {
                final item = _items[index];
                return Card(
                  color: AppColors.cardBg,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // 🔍 SEARCHABLE PRODUCT FIELD
                        Expanded(
                          flex: 3,
                          child: Autocomplete<Product>(
                            initialValue: TextEditingValue(
                              text: item.productId.isNotEmpty
                                  ? '${item.productId} - ${item.productName}'
                                  : '',
                            ),
                            displayStringForOption: (Product p) =>
                                '${p.id} - ${p.name}',
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return data.products;
                              }
                              final q =
                                  textEditingValue.text.toLowerCase();
                              return data.products.where((p) =>
                                  p.id.toLowerCase().contains(q) ||
                                  p.name.toLowerCase().contains(q) ||
                                  p.category.toLowerCase().contains(q));
                            },
                            onSelected: (Product p) {
                              _onProductSelected(index, p.id);
                            },
                            fieldViewBuilder: (context, controller,
                                focusNode, onFieldSubmitted) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                style: const TextStyle(
                                    color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: 'Search product ID or name...',
                                  hintStyle: TextStyle(
                                      color: AppColors.textSecondary),
                                  labelText: 'Product',
                                  labelStyle: _labelStyle,
                                  border: _border,
                                  enabledBorder: _enabledBorder,
                                  focusedBorder: _focusedBorder,
                                  prefixIcon: Icon(Icons.search,
                                      color: AppColors.textSecondary),
                                  isDense: true,
                                ),
                                onChanged: (v) {
                                  if (v.isEmpty &&
                                      item.productId.isNotEmpty) {
                                    setState(() {
                                      item.productId = '';
                                      item.productName = '';
                                      item.unitPrice = 0.0;
                                    });
                                  }
                                },
                              );
                            },
                            optionsViewBuilder:
                                (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4,
                                  color: AppColors.cardBg,
                                  borderRadius: BorderRadius.circular(8),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                        maxHeight: 240, maxWidth: 400),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (context, i) {
                                        final p = options.elementAt(i);
                                        return ListTile(
                                          dense: true,
                                          title: Text(
                                            '${p.id} - ${p.name}',
                                            style: const TextStyle(
                                                color:
                                                    AppColors.textPrimary,
                                                fontSize: 13),
                                          ),
                                          subtitle: Text(
                                            p.category,
                                            style: const TextStyle(
                                                color: AppColors
                                                    .textSecondary,
                                                fontSize: 11),
                                          ),
                                          onTap: () => onSelected(p),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: item.quantity.toString(),
                            style: const TextStyle(
                                color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Qty',
                              labelStyle: _labelStyle,
                              border: _border,
                              enabledBorder: _enabledBorder,
                              focusedBorder: _focusedBorder,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() =>
                                item.quantity = int.tryParse(v) ?? 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue:
                                item.unitPrice.toStringAsFixed(2),
                            style: const TextStyle(
                                color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              labelStyle: _labelStyle,
                              border: _border,
                              enabledBorder: _enabledBorder,
                              focusedBorder: _focusedBorder,
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (v) => setState(() => item
                                .unitPrice = double.tryParse(v) ?? 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue:
                                item.discount.toStringAsFixed(2),
                            style: const TextStyle(
                                color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Discount',
                              labelStyle: _labelStyle,
                              border: _border,
                              enabledBorder: _enabledBorder,
                              focusedBorder: _focusedBorder,
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (v) => setState(() => item
                                .discount = double.tryParse(v) ?? 0),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: AppColors.expenseRed),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cashGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12)),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isEditing
                            ? 'Update Template'
                            : 'Save Template'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TLine {
  String productId;
  String productName;
  int quantity;
  double unitPrice;
  double discount;

  _TLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
  });

  _TLine.empty()
      : productId = '',
        productName = '',
        quantity = 1,
        unitPrice = 0.0,
        discount = 0.0;
}