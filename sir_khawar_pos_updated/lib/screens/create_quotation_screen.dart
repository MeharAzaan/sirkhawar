// import 'package:flutter/material.dart';
// import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
// import 'package:sir_khawar_pos_updated/data/app_data.dart';

// import '../models/product.dart';
// import '../models/quotation.dart';

// class CreateQuotationScreen extends StatefulWidget {
//   const CreateQuotationScreen({super.key, this.quotation});
//   final Quotation? quotation;

//   @override
//   State<CreateQuotationScreen> createState() =>
//       _CreateQuotationScreenState();
// }

// class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
//   final AppData data = AppData();
//   final _formKey = GlobalKey<FormState>();

//   late TextEditingController _customerNameCtrl;
//   late TextEditingController _customerPhoneCtrl;
//   late TextEditingController _customerEmailCtrl;
//   late TextEditingController _customerAddressCtrl;
//   late TextEditingController _notesCtrl;

//   late String _selectedCompany;
//   List<_LineItem> _items = [];
//   bool _saving = false;
//   bool _isSending = false;
//   bool get _isEditing => widget.quotation != null;

//   @override
//   void initState() {
//     super.initState();
//     data.addListener(_onDataChanged);
//     final q = widget.quotation;

//     _selectedCompany = q?.company ?? AppCompanies.energy;

//     _customerNameCtrl =
//         TextEditingController(text: q?.customerName ?? '');
//     _customerPhoneCtrl =
//         TextEditingController(text: q?.customerPhone ?? '');
//     _customerEmailCtrl =
//         TextEditingController(text: q?.customerEmail ?? '');
//     _customerAddressCtrl =
//         TextEditingController(text: q?.customerAddress ?? '');
//     _notesCtrl = TextEditingController(text: q?.notes ?? '');

//     if (q != null && q.items.isNotEmpty) {
//       _items = q.items
//           .map((qi) => _LineItem(
//                 productId: qi.productId,
//                 productName: qi.productName,
//                 quantity: qi.quantity,
//                 unitPrice: qi.unitPrice,
//                 discount: qi.discount,
//               ))
//           .toList();
//     } else {
//       _items = [_LineItem.empty()];
//     }
//   }

//   @override
//   void dispose() {
//     data.removeListener(_onDataChanged);
//     _customerNameCtrl.dispose();
//     _customerPhoneCtrl.dispose();
//     _customerEmailCtrl.dispose();
//     _customerAddressCtrl.dispose();
//     _notesCtrl.dispose();
//     super.dispose();
//   }

//   void _onDataChanged() {
//     if (mounted) setState(() {});
//   }

//   double get _subtotal =>
//       _items.fold(0.0, (sum, i) => sum + i.total);

//   void _addItem() => setState(() => _items.add(_LineItem.empty()));

//   void _removeItem(int index) {
//     if (_items.length <= 1) return;
//     setState(() => _items.removeAt(index));
//   }

//   void _onProductSelected(int index, String? productId) {
//     if (productId == null) return;
//     final product =
//         data.products.firstWhere((p) => p.id == productId);
//     setState(() {
//       _items[index]
//         ..productId = product.id
//         ..productName = product.name
//         ..unitPrice = product.price;
//     });
//   }

//   Future<void> _save({required bool send}) async {
//     if (!_formKey.currentState!.validate()) return;
//     if (_items.any((i) => i.productId.isEmpty)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text('Select a product for all items'),
//             backgroundColor: AppColors.expenseRed),
//       );
//       return;
//     }

//     setState(() {
//       _saving = true;
//       _isSending = send;
//     });

//     try {
//       final quotationItems = _items
//           .map((i) => QuotationItem(
//                 productId: i.productId,
//                 productName: i.productName,
//                 quantity: i.quantity,
//                 unitPrice: i.unitPrice,
//                 discount: i.discount,
//               ))
//           .toList();

//       final status = send
//           ? QuotationStatus.sent
//           : (_isEditing
//               ? widget.quotation!.status
//               : QuotationStatus.draft);

//       if (_isEditing) {
//         final linkedSales = data.salesHistory
//             .where((s) => s.quotationId == widget.quotation!.id)
//             .toList();

//         final updated = Quotation(
//           id: widget.quotation!.id,
//           customerName: _customerNameCtrl.text.trim(),
//           customerPhone: _customerPhoneCtrl.text.trim(),
//           customerEmail: _customerEmailCtrl.text.trim(),
//           customerAddress: _customerAddressCtrl.text.trim(),
//           items: quotationItems,
//           createdDate: widget.quotation!.createdDate,
//           status: status,
//           notes: _notesCtrl.text.trim(),
//           company: _selectedCompany,
//         );

//         if (linkedSales.isNotEmpty) {
//           await data.editConvertedQuotation(
//             oldQuotation: widget.quotation!,
//             newQuotation: updated,
//           );
//         } else {
//           await data.updateQuotation(updated);
//         }
//       } else {
//         final qNumber = await data.generateQuotationNumber();
//         final newQ = Quotation(
//           id: qNumber,
//           customerName: _customerNameCtrl.text.trim(),
//           customerPhone: _customerPhoneCtrl.text.trim(),
//           customerEmail: _customerEmailCtrl.text.trim(),
//           customerAddress: _customerAddressCtrl.text.trim(),
//           items: quotationItems,
//           createdDate: DateTime.now(),
//           status: status,
//           notes: _notesCtrl.text.trim(),
//           company: _selectedCompany,
//         );
//         await data.addQuotation(newQ);
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(_isEditing
//                 ? 'Quotation updated successfully!'
//                 : 'Quotation ${send ? "sent" : "saved"} successfully!'),
//             backgroundColor: AppColors.cashGreen,
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text(
//                 'Failed to save. Please check your internet connection and try again.'),
//             backgroundColor: AppColors.expenseRed,
//             duration: const Duration(seconds: 4),
//             action: SnackBarAction(
//               label: 'Dismiss',
//               textColor: Colors.white,
//               onPressed: () {},
//             ),
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _saving = false;
//           _isSending = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: AppColors.headerBg,
//         foregroundColor: Colors.white,
//         title: Text(_isEditing ? 'Edit Quotation' : 'New Quotation'),
//         elevation: 0,
//       ),
//       body: Form(
//         key: _formKey,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 🏢 COMPANY SELECTOR
//               const Text('Company Name',
//                   style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.textPrimary)),
//               const SizedBox(height: 8),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 decoration: BoxDecoration(
//                   color: AppColors.cardBg,
//                   borderRadius: BorderRadius.circular(4),
//                   border: Border.all(color: AppColors.border),
//                 ),
//                 child: DropdownButtonHideUnderline(
//                   child: DropdownButton<String>(
//                     isExpanded: true,
//                     value: _selectedCompany,
//                     focusColor: Colors.transparent,
//                     items: [
//                       DropdownMenuItem(
//                         value: AppCompanies.energy,
//                         child: Text(AppCompanies.label(AppCompanies.energy),
//                             style: const TextStyle(
//                                 color: AppColors.textPrimary,
//                                 fontWeight: FontWeight.bold)),
//                       ),
//                       DropdownMenuItem(
//                         value: AppCompanies.electric,
//                         child: Text(AppCompanies.label(AppCompanies.electric),
//                             style: const TextStyle(
//                                 color: AppColors.textPrimary,
//                                 fontWeight: FontWeight.bold)),
//                       ),
//                     ],
//                     onChanged: (val) {
//                       if (val != null) {
//                         setState(() => _selectedCompany = val);
//                       }
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),

//               const Text('Customer Information',
//                   style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.textPrimary)),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _customerNameCtrl,
//                       style: const TextStyle(color: AppColors.textPrimary),
//                       decoration: const InputDecoration(
//                         labelText: 'Customer Name *',
//                         labelStyle: TextStyle(color: AppColors.textSecondary),
//                         border: OutlineInputBorder(),
//                         enabledBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: AppColors.border),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: AppColors.sidebarActive, width: 1.5),
//                         ),
//                       ),
//                       validator: (v) =>
//                           v == null || v.trim().isEmpty
//                               ? 'Required'
//                               : null,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: TextFormField(
//                       controller: _customerPhoneCtrl,
//                       style: const TextStyle(color: AppColors.textPrimary),
//                       decoration: const InputDecoration(
//                         labelText: 'Phone',
//                         labelStyle: TextStyle(color: AppColors.textSecondary),
//                         border: OutlineInputBorder(),
//                         enabledBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: AppColors.border),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: AppColors.sidebarActive, width: 1.5),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _customerEmailCtrl,
//                       style: const TextStyle(color: AppColors.textPrimary),
//                       decoration: const InputDecoration(
//                         labelText: 'Email',
//                         labelStyle: TextStyle(color: AppColors.textSecondary),
//                         border: OutlineInputBorder(),
//                         enabledBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: AppColors.border),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: AppColors.sidebarActive, width: 1.5),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: TextFormField(
//                       controller: _customerAddressCtrl,
//                       style: const TextStyle(color: AppColors.textPrimary),
//                       decoration: const InputDecoration(
//                         labelText: 'Address',
//                         labelStyle: TextStyle(color: AppColors.textSecondary),
//                         border: OutlineInputBorder(),
//                         enabledBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: AppColors.border),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: AppColors.sidebarActive, width: 1.5),
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
//                   const Text('Line Items',
//                       style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: AppColors.textPrimary)),
//                   ElevatedButton.icon(
//                     icon: const Icon(Icons.add),
//                     label: const Text('Add Item'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.sidebarActive,
//                       foregroundColor: Colors.white,
//                     ),
//                     onPressed: _addItem,
//                   ),
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
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
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
//                                 style: const TextStyle(color: AppColors.textPrimary),
//                                 decoration: const InputDecoration(
//                                   hintText: 'Search product ID or name...',
//                                   hintStyle: TextStyle(color: AppColors.textSecondary),
//                                   labelText: 'Product',
//                                   labelStyle: TextStyle(color: AppColors.textSecondary),
//                                   border: OutlineInputBorder(),
//                                   enabledBorder: OutlineInputBorder(
//                                     borderSide: BorderSide(color: AppColors.border),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderSide: BorderSide(color: AppColors.sidebarActive, width: 1.5),
//                                   ),
//                                   prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
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
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: TextFormField(
//                             initialValue: item.quantity.toString(),
//                             style: const TextStyle(color: AppColors.textPrimary),
//                             decoration: const InputDecoration(
//                                 labelText: 'Qty',
//                                 labelStyle: TextStyle(color: AppColors.textSecondary),
//                                 border: OutlineInputBorder(),
//                                 enabledBorder: OutlineInputBorder(
//                                   borderSide: BorderSide(color: AppColors.border),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderSide: BorderSide(color: AppColors.sidebarActive, width: 1.5),
//                                 ),
//                                 isDense: true),
//                             keyboardType: TextInputType.number,
//                             onChanged: (v) => setState(
//                                 () => item.quantity =
//                                     int.tryParse(v) ?? 1),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: TextFormField(
//                             initialValue:
//                                 item.unitPrice.toStringAsFixed(2),
//                             style: const TextStyle(color: AppColors.textPrimary),
//                             decoration: const InputDecoration(
//                                 labelText: 'Price',
//                                 labelStyle: TextStyle(color: AppColors.textSecondary),
//                                 border: OutlineInputBorder(),
//                                 enabledBorder: OutlineInputBorder(
//                                   borderSide: BorderSide(color: AppColors.border),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderSide: BorderSide(color: AppColors.sidebarActive, width: 1.5),
//                                 ),
//                                 isDense: true),
//                             keyboardType:
//                                 const TextInputType.numberWithOptions(
//                                     decimal: true),
//                             onChanged: (v) => setState(
//                                 () => item.unitPrice =
//                                     double.tryParse(v) ?? 0),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: TextFormField(
//                             initialValue:
//                                 item.discount.toStringAsFixed(2),
//                             style: const TextStyle(color: AppColors.textPrimary),
//                             decoration: const InputDecoration(
//                                 labelText: 'Discount',
//                                 labelStyle: TextStyle(color: AppColors.textSecondary),
//                                 border: OutlineInputBorder(),
//                                 enabledBorder: OutlineInputBorder(
//                                   borderSide: BorderSide(color: AppColors.border),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderSide: BorderSide(color: AppColors.sidebarActive, width: 1.5),
//                                 ),
//                                 isDense: true),
//                             keyboardType:
//                                 const TextInputType.numberWithOptions(
//                                     decimal: true),
//                             onChanged: (v) => setState(
//                                 () => item.discount =
//                                     double.tryParse(v) ?? 0),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Padding(
//                           padding: const EdgeInsets.only(top: 12),
//                           child: SizedBox(
//                             width: 100,
//                             child: Text(
//                               'Rs. ${item.total.toStringAsFixed(2)}',
//                               style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: AppColors.textPrimary),
//                             ),
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.remove_circle,
//                               color: AppColors.expenseRed),
//                           onPressed: () => _removeItem(index),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }),
//               const SizedBox(height: 16),
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: SizedBox(
//                   width: 250,
//                   child: Column(
//                     children: [
//                       _totalRow('Subtotal', _subtotal),
//                       _totalRow('Grand Total', _subtotal, bold: true),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _notesCtrl,
//                 style: const TextStyle(color: AppColors.textPrimary),
//                 decoration: const InputDecoration(
//                   labelText: 'Notes',
//                   labelStyle: TextStyle(color: AppColors.textSecondary),
//                   border: OutlineInputBorder(),
//                   enabledBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: AppColors.border),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: AppColors.sidebarActive, width: 1.5),
//                   ),
//                 ),
//                 maxLines: 2,
//               ),
//               const SizedBox(height: 32),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   OutlinedButton(
//                     onPressed:
//                         _saving ? null : () => _save(send: false),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: AppColors.textPrimary,
//                       side: const BorderSide(color: AppColors.border),
//                     ),
//                     child: _saving && !_isSending
//                         ? const SizedBox(
//                             height: 20,
//                             width: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               color: AppColors.sidebarActive,
//                             ),
//                           )
//                         : Text(_isEditing
//                             ? 'Update Draft'
//                             : 'Save Draft'),
//                   ),
//                   const SizedBox(width: 12),
//                   ElevatedButton(
//                     onPressed:
//                         _saving ? null : () => _save(send: true),
//                     style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.cashGreen,
//                         foregroundColor: Colors.white),
//                     child: _saving && _isSending
//                         ? const SizedBox(
//                             height: 20,
//                             width: 20,
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2,
//                             ),
//                           )
//                         : Text(_isEditing ? 'Update & Send' : 'Send'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _totalRow(String label, double amount,
//       {bool bold = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label,
//               style: TextStyle(
//                   fontWeight:
//                       bold ? FontWeight.bold : FontWeight.normal,
//                   fontSize: bold ? 16 : 14,
//                   color: AppColors.textPrimary)),
//           Text('Rs. ${amount.toStringAsFixed(2)}',
//               style: TextStyle(
//                   fontWeight:
//                       bold ? FontWeight.bold : FontWeight.normal,
//                   fontSize: bold ? 16 : 14,
//                   color: AppColors.textPrimary)),
//         ],
//       ),
//     );
//   }
// }

// class _LineItem {
//   String productId;
//   String productName;
//   int quantity;
//   double unitPrice;
//   double discount;

//   _LineItem({
//     required this.productId,
//     required this.productName,
//     required this.quantity,
//     required this.unitPrice,
//     required this.discount,
//   });

//   _LineItem.empty()
//       : productId = '',
//         productName = '',
//         quantity = 1,
//         unitPrice = 0.0,
//         discount = 0.0;

//   double get total => (unitPrice * quantity) - discount;
// }
import 'package:flutter/material.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';

import '../models/product.dart';
import '../models/quotation.dart';

class CreateQuotationScreen extends StatefulWidget {
  const CreateQuotationScreen({super.key, this.quotation});
  final Quotation? quotation;

  @override
  State<CreateQuotationScreen> createState() =>
      _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
  final AppData data = AppData();
  final _formKey = GlobalKey<FormState>();

  // UI-only: shared const decorations (canonicalized by compiler).
  // Values are identical to the inline ones that were used before.
  static const _border = OutlineInputBorder();
  static const _enabledBorder = OutlineInputBorder(
    borderSide: BorderSide(color: AppColors.border),
  );
  static const _focusedBorder = OutlineInputBorder(
    borderSide: BorderSide(color: AppColors.sidebarActive, width: 1.5),
  );
  static const _labelStyle = TextStyle(color: AppColors.textSecondary);

  late TextEditingController _customerNameCtrl;
  late TextEditingController _customerPhoneCtrl;
  late TextEditingController _customerEmailCtrl;
  late TextEditingController _customerAddressCtrl;
  late TextEditingController _notesCtrl;

  late String _selectedCompany;
  List<_LineItem> _items = [];
  bool _saving = false;
  bool _isSending = false;
  bool get _isEditing => widget.quotation != null;

  @override
  void initState() {
    super.initState();
    data.addListener(_onDataChanged);
    final q = widget.quotation;

    _selectedCompany = q?.company ?? AppCompanies.energy;

    _customerNameCtrl =
        TextEditingController(text: q?.customerName ?? '');
    _customerPhoneCtrl =
        TextEditingController(text: q?.customerPhone ?? '');
    _customerEmailCtrl =
        TextEditingController(text: q?.customerEmail ?? '');
    _customerAddressCtrl =
        TextEditingController(text: q?.customerAddress ?? '');
    _notesCtrl = TextEditingController(text: q?.notes ?? '');

    if (q != null && q.items.isNotEmpty) {
      _items = q.items
          .map((qi) => _LineItem(
                productId: qi.productId,
                productName: qi.productName,
                quantity: qi.quantity,
                unitPrice: qi.unitPrice,
                discount: qi.discount,
              ))
          .toList();
    } else {
      _items = [_LineItem.empty()];
    }
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _customerEmailCtrl.dispose();
    _customerAddressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  double get _subtotal =>
      _items.fold(0.0, (sum, i) => sum + i.total);

  void _addItem() => setState(() => _items.add(_LineItem.empty()));

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() => _items.removeAt(index));
  }

  void _onProductSelected(int index, String? productId) {
    if (productId == null) return;
    final product =
        data.products.firstWhere((p) => p.id == productId);
    setState(() {
      _items[index]
        ..productId = product.id
        ..productName = product.name
        ..unitPrice = product.price;
    });
  }

  Future<void> _save({required bool send}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.any((i) => i.productId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select a product for all items'),
            backgroundColor: AppColors.expenseRed),
      );
      return;
    }

    setState(() {
      _saving = true;
      _isSending = send;
    });

    try {
      final quotationItems = _items
          .map((i) => QuotationItem(
                productId: i.productId,
                productName: i.productName,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
                discount: i.discount,
              ))
          .toList();

      final status = send
          ? QuotationStatus.sent
          : (_isEditing
              ? widget.quotation!.status
              : QuotationStatus.draft);

      if (_isEditing) {
        final linkedSales = data.salesHistory
            .where((s) => s.quotationId == widget.quotation!.id)
            .toList();

        final updated = Quotation(
          id: widget.quotation!.id,
          customerName: _customerNameCtrl.text.trim(),
          customerPhone: _customerPhoneCtrl.text.trim(),
          customerEmail: _customerEmailCtrl.text.trim(),
          customerAddress: _customerAddressCtrl.text.trim(),
          items: quotationItems,
          createdDate: widget.quotation!.createdDate,
          status: status,
          notes: _notesCtrl.text.trim(),
          company: _selectedCompany,
        );

        if (linkedSales.isNotEmpty) {
          await data.editConvertedQuotation(
            oldQuotation: widget.quotation!,
            newQuotation: updated,
          );
        } else {
          await data.updateQuotation(updated);
        }
      } else {
        final qNumber = await data.generateQuotationNumber();
        final newQ = Quotation(
          id: qNumber,
          customerName: _customerNameCtrl.text.trim(),
          customerPhone: _customerPhoneCtrl.text.trim(),
          customerEmail: _customerEmailCtrl.text.trim(),
          customerAddress: _customerAddressCtrl.text.trim(),
          items: quotationItems,
          createdDate: DateTime.now(),
          status: status,
          notes: _notesCtrl.text.trim(),
          company: _selectedCompany,
        );
        await data.addQuotation(newQ);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Quotation updated successfully!'
                : 'Quotation ${send ? "sent" : "saved"} successfully!'),
            backgroundColor: AppColors.cashGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Failed to save. Please check your internet connection and try again.'),
            backgroundColor: AppColors.expenseRed,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        title: Text(_isEditing ? 'Edit Quotation' : 'New Quotation'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🏢 COMPANY SELECTOR
              const Text('Company Name',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCompany,
                    focusColor: Colors.transparent,
                    items: [
                      DropdownMenuItem(
                        value: AppCompanies.energy,
                        child: Text(AppCompanies.label(AppCompanies.energy),
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold)),
                      ),
                      DropdownMenuItem(
                        value: AppCompanies.electric,
                        child: Text(AppCompanies.label(AppCompanies.electric),
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCompany = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Customer Information',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customerNameCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Customer Name *',
                        labelStyle: _labelStyle,
                        border: _border,
                        enabledBorder: _enabledBorder,
                        focusedBorder: _focusedBorder,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _customerPhoneCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        labelStyle: _labelStyle,
                        border: _border,
                        enabledBorder: _enabledBorder,
                        focusedBorder: _focusedBorder,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customerEmailCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: _labelStyle,
                        border: _border,
                        enabledBorder: _enabledBorder,
                        focusedBorder: _focusedBorder,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _customerAddressCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Address',
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
                  const Text('Line Items',
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
                    onPressed: _addItem,
                  ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: 'Search product ID or name...',
                                  hintStyle: TextStyle(color: AppColors.textSecondary),
                                  labelText: 'Product',
                                  labelStyle: _labelStyle,
                                  border: _border,
                                  enabledBorder: _enabledBorder,
                                  focusedBorder: _focusedBorder,
                                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
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
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: item.quantity.toString(),
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                                labelText: 'Qty',
                                labelStyle: _labelStyle,
                                border: _border,
                                enabledBorder: _enabledBorder,
                                focusedBorder: _focusedBorder,
                                isDense: true),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(
                                () => item.quantity =
                                    int.tryParse(v) ?? 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue:
                                item.unitPrice.toStringAsFixed(2),
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                                labelText: 'Price',
                                labelStyle: _labelStyle,
                                border: _border,
                                enabledBorder: _enabledBorder,
                                focusedBorder: _focusedBorder,
                                isDense: true),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (v) => setState(
                                () => item.unitPrice =
                                    double.tryParse(v) ?? 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue:
                                item.discount.toStringAsFixed(2),
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                                labelText: 'Discount',
                                labelStyle: _labelStyle,
                                border: _border,
                                enabledBorder: _enabledBorder,
                                focusedBorder: _focusedBorder,
                                isDense: true),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (v) => setState(
                                () => item.discount =
                                    double.tryParse(v) ?? 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: 100,
                            child: Text(
                              'Rs. ${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: AppColors.expenseRed),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 250,
                  child: Column(
                    children: [
                      _totalRow('Subtotal', _subtotal),
                      _totalRow('Grand Total', _subtotal, bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  labelStyle: _labelStyle,
                  border: _border,
                  enabledBorder: _enabledBorder,
                  focusedBorder: _focusedBorder,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _saving ? null : () => _save(send: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: _saving && !_isSending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.sidebarActive,
                            ),
                          )
                        : Text(_isEditing
                            ? 'Update Draft'
                            : 'Save Draft'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed:
                        _saving ? null : () => _save(send: true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cashGreen,
                        foregroundColor: Colors.white),
                    child: _saving && _isSending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(_isEditing ? 'Update & Send' : 'Send'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalRow(String label, double amount,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 16 : 14,
                  color: AppColors.textPrimary)),
          Text('Rs. ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 16 : 14,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _LineItem {
  String productId;
  String productName;
  int quantity;
  double unitPrice;
  double discount;

  _LineItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
  });

  _LineItem.empty()
      : productId = '',
        productName = '',
        quantity = 1,
        unitPrice = 0.0,
        discount = 0.0;

  double get total => (unitPrice * quantity) - discount;
}