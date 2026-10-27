// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
// import '../data/app_data.dart';
// import '../models/quotation.dart';
// import '../models/sale_history.dart';
// import 'create_quotation_screen.dart';
// import 'quotation_preview_screen.dart';

// class QuotationScreen extends StatefulWidget {
//   const QuotationScreen({super.key});

//   @override
//   State<QuotationScreen> createState() => _QuotationScreenState();
// }

// class _QuotationScreenState extends State<QuotationScreen> {
//   final AppData data = AppData();
//   final TextEditingController _searchCtrl = TextEditingController();
//   QuotationStatus? _statusFilter;
//   String _searchQuery = '';

//   @override
//   void initState() {
//     super.initState();
//     data.addListener(_onDataChanged);
//     _searchCtrl.addListener(() {
//       setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
//     });
//   }

//   @override
//   void dispose() {
//     data.removeListener(_onDataChanged);
//     _searchCtrl.dispose();
//     super.dispose();
//   }

//   void _onDataChanged() {
//     if (mounted) setState(() {});
//   }

//   List<Quotation> get _filtered {
//     var list = data.quotations.toList();
//     if (_statusFilter != null) {
//       list = list.where((q) => q.status == _statusFilter).toList();
//     }
//     if (_searchQuery.isNotEmpty) {
//       list = list
//           .where((q) =>
//               q.customerName.toLowerCase().contains(_searchQuery) ||
//               q.id.toLowerCase().contains(_searchQuery))
//           .toList();
//     }
//     list.sort((a, b) => b.createdDate.compareTo(a.createdDate));
//     return list;
//   }

//   Color _statusColor(QuotationStatus s) {
//     switch (s) {
//       case QuotationStatus.draft:
//         return AppColors.textSecondary;
//       case QuotationStatus.sent:
//         return AppColors.bankBlue;
//       case QuotationStatus.accepted:
//         return AppColors.cashGreen;
//       case QuotationStatus.partiallyPaid:
//         return AppColors.pendingOrange;
//       case QuotationStatus.invoiced:
//         return AppColors.sidebarActive;
//       case QuotationStatus.cancelled:
//         return AppColors.expenseRed;
//     }
//   }

//   String _statusLabel(QuotationStatus s) {
//     switch (s) {
//       case QuotationStatus.draft:
//         return 'Draft';
//       case QuotationStatus.sent:
//         return 'Sent';
//       case QuotationStatus.accepted:
//         return 'Accepted';
//       case QuotationStatus.partiallyPaid:
//         return 'Partially Paid';
//       case QuotationStatus.invoiced:
//         return 'Invoiced';
//       case QuotationStatus.cancelled:
//         return 'Cancelled';
//     }
//   }

//   Future<void> _convertToInvoice(Quotation q) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Convert to Invoice'),
//         content: Text(
//             'Convert quotation ${q.id} to an invoice?\n\nThis will deduct stock.'),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(ctx, false),
//               child: const Text('Cancel')),
//           ElevatedButton(
//               onPressed: () => Navigator.pop(ctx, true),
//               child: const Text('Convert')),
//         ],
//       ),
//     );
//     if (confirm != true) return;

//     try {
//       final invoiceNumber = await data.generateInvoiceNumber();
//       final saleId =
//           FirebaseFirestore.instance.collection('sales').doc().id;
//       final initialPayment = PaymentReceipt(
//         id: FirebaseFirestore.instance
//             .collection('payments')
//             .doc()
//             .id,
//         amount: 0,
//         date: DateTime.now(),
//         method: PaymentMethod.cash,
//         chequeNumber: '',
//         bankName: '',
//         transactionId: '',
//         chequeDate: null,
//       );

//       await data.convertQuotationToInvoice(
//         quotation: q,
//         payments: [initialPayment],
//         invoiceNumber: invoiceNumber,
//         saleId: saleId,
//         notes: '',
//       );

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Invoice $invoiceNumber created'),
//             backgroundColor: AppColors.cashGreen,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text('Error: $e'), backgroundColor: AppColors.expenseRed),
//         );
//       }
//     }
//   }

//   Future<void> _deleteQuotation(Quotation q) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Delete Quotation'),
//         content: Text('Delete ${q.id}?'),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(ctx, false),
//               child: const Text('Cancel')),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
//             onPressed: () => Navigator.pop(ctx, true),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//     if (confirm != true) return;
//     try {
//       await data.deleteQuotation(q.id);
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text('Error: $e'), backgroundColor: AppColors.expenseRed),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final quotations = _filtered;

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text('Quotations'),
//         backgroundColor: AppColors.headerBg,
//         foregroundColor: AppColors.cardBg,
//         actions: [
//           ElevatedButton.icon(
//             icon: const Icon(Icons.add),
//             label: const Text('New Quotation'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.sidebarActive,
//               foregroundColor: AppColors.cardBg,
//             ),
//             onPressed: () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                   builder: (_) => const CreateQuotationScreen()),
//             ),
//           ),
//           const SizedBox(width: 16),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _searchCtrl,
//                     decoration: InputDecoration(
//                       hintText: 'Search...',
//                       prefixIcon: const Icon(Icons.search),
//                       border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8)),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 16),

//                 // CLEAN DROPDOWN (NO GREY BOX / SHADOW)
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: AppColors.border),
//                     borderRadius: BorderRadius.circular(8),
//                     color: AppColors.cardBg,
//                   ),
//                   child: DropdownButtonHideUnderline(
//                     child: DropdownButton<QuotationStatus?>(
//                       value: _statusFilter,
//                       hint: const Text('All Statuses'),
//                       focusColor: Colors.transparent,
//                       dropdownColor: AppColors.cardBg,
//                       items: [
//                         const DropdownMenuItem<QuotationStatus?>(
//                             value: null, child: Text('All Statuses')),
//                         ...QuotationStatus.values.map((s) =>
//                             DropdownMenuItem(
//                                 value: s, child: Text(_statusLabel(s)))),
//                       ],
//                       onChanged: (v) => setState(() => _statusFilter = v),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: quotations.isEmpty
//                 ? const Center(child: Text('No quotations'))
//                 : SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: SingleChildScrollView(
//                       child: Container(
//                         margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: AppColors.border, width: 1),
//                           borderRadius: BorderRadius.circular(8),
//                           color: AppColors.cardBg,
//                         ),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: DataTable(
//                             border: TableBorder(
//                               horizontalInside: BorderSide(
//                                   color: AppColors.border.withValues(alpha: 0.5)),
//                               verticalInside: BorderSide(
//                                   color: AppColors.border.withValues(alpha: 0.5)),
//                             ),
//                             headingRowColor: WidgetStateProperty.all(
//                                 AppColors.background),
//                             columns: const [
//                               DataColumn(label: Text('Quotation #')),
//                               DataColumn(label: Text('Customer')),
//                               DataColumn(label: Text('Date')),
//                               DataColumn(
//                                   label: Text('Total'), numeric: true),
//                               DataColumn(label: Text('Status')),
//                               DataColumn(label: Text('Actions')),
//                             ],
//                             rows: quotations.map((q) {
//                               return DataRow(cells: [
//                                 DataCell(Text(q.id,
//                                     style: const TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: AppColors.textPrimary))),
//                                 DataCell(Text(q.customerName,
//                                     style: const TextStyle(
//                                         color: AppColors.textPrimary))),
//                                 DataCell(Text(
//                                     '${q.createdDate.day}/${q.createdDate.month}/${q.createdDate.year}',
//                                     style: const TextStyle(
//                                         color: AppColors.textSecondary))),
//                                 DataCell(Text(
//                                   'Rs. ${q.grandTotal.toStringAsFixed(2)}',
//                                   style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       color: AppColors.textPrimary),
//                                 )),
//                                 DataCell(Container(
//                                   padding: const EdgeInsets.symmetric(
//                                       horizontal: 12, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: _statusColor(q.status)
//                                         .withValues(alpha: 0.15),
//                                     borderRadius:
//                                         BorderRadius.circular(12),
//                                   ),
//                                   child: Text(_statusLabel(q.status),
//                                       style: TextStyle(
//                                           color: _statusColor(q.status),
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 12)),
//                                 )),
//                                 DataCell(Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     IconButton(
//                                       icon: const Icon(Icons.visibility,
//                                           size: 20,
//                                           color: AppColors.sidebarActive),
//                                       onPressed: () => Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (_) =>
//                                               QuotationPreviewScreen(
//                                                   quotation: q,
//                                                   onBack: () => Navigator.pop(context)),
//                                         ),
//                                       ),
//                                     ),
//                                     IconButton(
//                                       icon: const Icon(Icons.edit,
//                                           size: 20,
//                                           color: AppColors.bankBlue),
//                                       onPressed: () => Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (_) =>
//                                               CreateQuotationScreen(
//                                                   quotation: q),
//                                         ),
//                                       ),
//                                     ),
//                                     if (q.status !=
//                                             QuotationStatus.invoiced &&
//                                         q.status !=
//                                             QuotationStatus.cancelled)
//                                       IconButton(
//                                         icon: const Icon(
//                                             Icons.receipt_long,
//                                             size: 20,
//                                             color: AppColors.sidebarActive),
//                                         onPressed: () =>
//                                             _convertToInvoice(q),
//                                       ),
//                                     IconButton(
//                                       icon: const Icon(Icons.delete,
//                                           size: 20, color: AppColors.expenseRed),
//                                       onPressed: () =>
//                                           _deleteQuotation(q),
//                                     ),
//                                   ],
//                                 )),
//                               ]);
//                             }).toList(),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import '../data/app_data.dart';
import '../models/quotation.dart';
import '../models/sale_history.dart';
import 'create_quotation_screen.dart';
import 'quotation_preview_screen.dart';

class QuotationScreen extends StatefulWidget {
  const QuotationScreen({super.key});

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  final AppData data = AppData();
  final TextEditingController _searchCtrl = TextEditingController();
  QuotationStatus? _statusFilter;
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

  List<Quotation> get _filtered {
    var list = data.quotations.toList();
    if (_statusFilter != null) {
      list = list.where((q) => q.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((q) =>
              q.customerName.toLowerCase().contains(_searchQuery) ||
              q.id.toLowerCase().contains(_searchQuery))
          .toList();
    }
    list.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    return list;
  }

  Color _statusColor(QuotationStatus s) {
    switch (s) {
      case QuotationStatus.draft:
        return AppColors.textSecondary;
      case QuotationStatus.sent:
        return AppColors.bankBlue;
      case QuotationStatus.accepted:
        return AppColors.cashGreen;
      case QuotationStatus.partiallyPaid:
        return AppColors.pendingOrange;
      case QuotationStatus.invoiced:
        return AppColors.sidebarActive;
      case QuotationStatus.cancelled:
        return AppColors.expenseRed;
    }
  }

  String _statusLabel(QuotationStatus s) {
    switch (s) {
      case QuotationStatus.draft:
        return 'Draft';
      case QuotationStatus.sent:
        return 'Sent';
      case QuotationStatus.accepted:
        return 'Accepted';
      case QuotationStatus.partiallyPaid:
        return 'Partially Paid';
      case QuotationStatus.invoiced:
        return 'Invoiced';
      case QuotationStatus.cancelled:
        return 'Cancelled';
    }
  }

  Future<void> _convertToInvoice(Quotation q) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Convert to Invoice'),
        content: Text(
            'Convert quotation ${q.id} to an invoice?\n\nThis will deduct stock.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Convert')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final invoiceNumber = await data.generateInvoiceNumber();
      final saleId =
          FirebaseFirestore.instance.collection('sales').doc().id;
      final initialPayment = PaymentReceipt(
        id: FirebaseFirestore.instance
            .collection('payments')
            .doc()
            .id,
        amount: 0,
        date: DateTime.now(),
        method: PaymentMethod.cash,
        chequeNumber: '',
        bankName: '',
        transactionId: '',
        chequeDate: null,
        bankId: 'default_bank', // 👈 NEW: added for multi-bank compatibility
      );

      await data.convertQuotationToInvoice(
        quotation: q,
        payments: [initialPayment],
        invoiceNumber: invoiceNumber,
        saleId: saleId,
        notes: '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice $invoiceNumber created'),
            backgroundColor: AppColors.cashGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please check your internet connection'),
              backgroundColor: AppColors.expenseRed),
        );
      }
    }
  }

  Future<void> _deleteQuotation(Quotation q) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quotation'),
        content: Text('Delete ${q.id}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await data.deleteQuotation(q.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please check your internet connection'),
              backgroundColor: AppColors.expenseRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quotations = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quotations'),
        backgroundColor: AppColors.headerBg,
        foregroundColor: AppColors.cardBg,
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('New Quotation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sidebarActive,
              foregroundColor: AppColors.cardBg,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CreateQuotationScreen()),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // CLEAN DROPDOWN (NO GREY BOX / SHADOW)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.cardBg,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<QuotationStatus?>(
                      value: _statusFilter,
                      hint: const Text('All Statuses'),
                      focusColor: Colors.transparent,
                      dropdownColor: AppColors.cardBg,
                      items: [
                        const DropdownMenuItem<QuotationStatus?>(
                            value: null, child: Text('All Statuses')),
                        ...QuotationStatus.values.map((s) =>
                            DropdownMenuItem(
                                value: s, child: Text(_statusLabel(s)))),
                      ],
                      onChanged: (v) => setState(() => _statusFilter = v),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: quotations.isEmpty
                ? const Center(child: Text('No quotations'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border, width: 1),
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.cardBg,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: DataTable(
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                  color: AppColors.border.withValues(alpha: 0.5)),
                              verticalInside: BorderSide(
                                  color: AppColors.border.withValues(alpha: 0.5)),
                            ),
                            headingRowColor: WidgetStateProperty.all(
                                AppColors.background),
                            columns: const [
                              DataColumn(label: Text('Quotation #')),
                              DataColumn(label: Text('Customer')),
                              DataColumn(label: Text('Date')),
                              DataColumn(
                                  label: Text('Total'), numeric: true),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: quotations.map((q) {
                              return DataRow(cells: [
                                DataCell(Text(q.id,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary))),
                                DataCell(Text(q.customerName,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary))),
                                DataCell(Text(
                                    '${q.createdDate.day}/${q.createdDate.month}/${q.createdDate.year}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary))),
                                DataCell(Text(
                                  'Rs. ${q.grandTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary),
                                )),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(q.status)
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Text(_statusLabel(q.status),
                                      style: TextStyle(
                                          color: _statusColor(q.status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                )),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility,
                                          size: 20,
                                          color: AppColors.sidebarActive),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              QuotationPreviewScreen(
                                                  quotation: q,
                                                  onBack: () => Navigator.pop(context)),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          size: 20,
                                          color: AppColors.bankBlue),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CreateQuotationScreen(
                                                  quotation: q),
                                        ),
                                      ),
                                    ),
                                    if (q.status !=
                                            QuotationStatus.invoiced &&
                                        q.status !=
                                            QuotationStatus.cancelled)
                                      IconButton(
                                        icon: const Icon(
                                            Icons.receipt_long,
                                            size: 20,
                                            color: AppColors.sidebarActive),
                                        onPressed: () =>
                                            _convertToInvoice(q),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          size: 20, color: AppColors.expenseRed),
                                      onPressed: () =>
                                          _deleteQuotation(q),
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