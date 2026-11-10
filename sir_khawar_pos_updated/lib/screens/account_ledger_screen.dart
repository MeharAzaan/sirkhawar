// import 'package:flutter/material.dart';
// import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
// import 'package:sir_khawar_pos_updated/data/app_data.dart';
// import 'package:sir_khawar_pos_updated/models/quotation.dart';
// import 'package:sir_khawar_pos_updated/models/bank_account.dart';
// import 'package:sir_khawar_pos_updated/services/pdf_service.dart';

// class LedgerItem {
//   final DateTime date;
//   final String description;
//   final double credit;
//   final double debit;
//   double balance;

//   LedgerItem({
//     required this.date,
//     required this.description,
//     this.credit = 0.0,
//     this.debit = 0.0,
//     this.balance = 0.0,
//   });
// }

// class AccountLedgerScreen extends StatefulWidget {
//   final String accountId;
//   final String accountName;

//   const AccountLedgerScreen({
//     super.key,
//     required this.accountId,
//     required this.accountName,
//   });

//   @override
//   State<AccountLedgerScreen> createState() => _AccountLedgerScreenState();
// }

// class _AccountLedgerScreenState extends State<AccountLedgerScreen> {
//   final AppData data = AppData();

//   List<LedgerItem> _rawItems = [];
//   List<LedgerItem> _filteredItems = [];
//   double _baseOpeningBalance = 0;
//   double _effectiveOpeningBalance = 0;
//   double _finalBalance = 0;
//   String _companyKey = AppCompanies.energy;

//   String _filterType = 'All Time';
//   DateTime? _startDate;
//   DateTime? _endDate;

//   @override
//   void initState() {
//     super.initState();
//     _prepareData();
//     data.addListener(_onDataChanged);
//   }

//   @override
//   void dispose() {
//     data.removeListener(_onDataChanged);
//     super.dispose();
//   }

//   void _onDataChanged() {
//     if (mounted) {
//       _prepareData();
//       setState(() {});
//     }
//   }

//   String _formatDate(DateTime d) {
//     return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
//   }

//   String _formatDateShort(DateTime d) {
//     return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
//   }

//   void _prepareData() {
//     final accountId = widget.accountId;
//     final bool isEnergyCash = accountId == 'cash_energy';
//     final bool isElectricCash = accountId == 'cash_electric';
//     final bool isBank = !isEnergyCash && !isElectricCash;

//     _baseOpeningBalance = 0;
//     _companyKey = AppCompanies.energy;

//     if (isEnergyCash) {
//       _baseOpeningBalance = data.settings.getOpeningCash(AppCompanies.energy);
//       _companyKey = AppCompanies.energy;
//     } else if (isElectricCash) {
//       _baseOpeningBalance = data.settings.getOpeningCash(AppCompanies.electric);
//       _companyKey = AppCompanies.electric;
//     } else {
//       final bank = data.banks.firstWhere(
//         (b) => b.id == accountId,
//         orElse: () => BankAccount(
//             id: '',
//             name: 'Unknown',
//             company: AppCompanies.energy,
//             openingBalance: 0),
//       );
//       _baseOpeningBalance = bank.openingBalance;
//       _companyKey = bank.company;
//     }

//     final List<LedgerItem> items = [];

//     // 1. SALES PAYMENTS (Inflow -> Credit)
//     for (final sale in data.salesHistory) {
//       for (final p in sale.payments) {
//         bool include = false;
//         if (isEnergyCash &&
//             sale.company == AppCompanies.energy &&
//             p.method == PaymentMethod.cash) {
//           include = true;
//         }
//         if (isElectricCash &&
//             sale.company == AppCompanies.electric &&
//             p.method == PaymentMethod.cash) {
//           include = true;
//         }
//         if (isBank) {
//           final bId = p.bankId.isNotEmpty ? p.bankId : 'default_bank';
//           if (bId == accountId &&
//               (p.method == PaymentMethod.online ||
//                   (p.method == PaymentMethod.cheque &&
//                       p.chequeDate != null &&
//                       !p.chequeDate!.isAfter(DateTime.now())))) {
//             include = true;
//           }
//         }
//         if (include) {
//           items.add(LedgerItem(
//             date: p.date,
//             description:
//                 'Payment Received (Inv #${sale.invoiceNumber} - ${sale.customerName})',
//             credit: p.amount,
//           ));
//         }
//       }
//     }

//     // 2. EXPENSES (Outflow -> Debit)
//     for (final exp in data.expenses) {
//       bool include = false;
//       if (isEnergyCash &&
//           exp.company == AppCompanies.energy &&
//           exp.paidFrom == 'cash') {
//         include = true;
//       }
//       if (isElectricCash &&
//           exp.company == AppCompanies.electric &&
//           exp.paidFrom == 'cash') {
//         include = true;
//       }
//       if (isBank && data.normalizeBankId(exp.paidFrom) == accountId) {
//         include = true;
//       }
//       if (include) {
//         items.add(LedgerItem(
//           date: exp.date,
//           description:
//               'Expense Paid (${exp.category} - ${exp.description})',
//           debit: exp.amount,
//         ));
//       }
//     }

//     // 3. SALARIES (Outflow -> Debit)
//     for (final sal in data.salaryRecords) {
//       bool include = false;
//       if (isEnergyCash &&
//           sal.company == AppCompanies.energy &&
//           sal.method == PaymentMethod.cash) {
//         include = true;
//       }
//       if (isElectricCash &&
//           sal.company == AppCompanies.electric &&
//           sal.method == PaymentMethod.cash) {
//         include = true;
//       }
//       if (isBank && sal.method == PaymentMethod.online) {
//         final bId = sal.bankId.isNotEmpty ? sal.bankId : 'default_bank';
//         if (bId == accountId) include = true;
//       }
//       if (include) {
//         items.add(LedgerItem(
//           date: sal.paymentDate,
//           description:
//               'Salary Paid (${sal.employeeName} - ${sal.salaryMonth})',
//           debit: sal.amount,
//         ));
//       }
//     }

//     // 4. PURCHASES (Outflow -> Debit)
//     for (final pur in data.purchases) {
//       bool include = false;
//       if (isEnergyCash &&
//           pur.company == AppCompanies.energy &&
//           pur.paymentMethod == 'cash') {
//         include = true;
//       } else if (isElectricCash &&
//           pur.company == AppCompanies.electric &&
//           pur.paymentMethod == 'cash') {
//         include = true;
//       } else if (isBank && pur.bankId != null && pur.bankId!.isNotEmpty) {
//         final pBankId = data.normalizeBankId(pur.bankId!);
//         if (pBankId == accountId) {
//           if (pur.paymentMethod == 'bank') {
//             include = true;
//           } else if (pur.paymentMethod == 'cheque') {
//             if (pur.chequeDate == null ||
//                 !pur.chequeDate!.isAfter(DateTime.now())) {
//               include = true;
//             }
//           }
//         }
//       }

//       if (include) {
//         final chequeInfo =
//             pur.paymentMethod == 'cheque' && pur.chequeNumber.isNotEmpty
//                 ? ' Chq #${pur.chequeNumber}'
//                 : '';
//         items.add(LedgerItem(
//           date: pur.purchaseDate,
//           description: 'Purchase Paid (${pur.vendorName}$chequeInfo)',
//           debit: pur.totalAmount, // Outflow
//         ));
//       }
//     }

//     // 5. PURCHASE RETURNS (Inflow -> CREDIT REFUND back into Account)
//     for (final ret in data.purchaseReturns) {
//       final parentP =
//           data.purchases.where((p) => p.id == ret.purchaseId).firstOrNull;

//       final effectivePaymentMethod = ret.paymentMethod.isNotEmpty
//           ? ret.paymentMethod
//           : (parentP?.paymentMethod ?? 'cash');

//       final effectiveCompany = ret.company.isNotEmpty
//           ? ret.company
//           : (parentP?.company ?? AppCompanies.energy);

//       final rawBankId = (ret.bankId != null && ret.bankId!.isNotEmpty)
//           ? ret.bankId!
//           : (parentP?.bankId ?? '');

//       bool include = false;
//       if (isEnergyCash &&
//           effectiveCompany == AppCompanies.energy &&
//           effectivePaymentMethod == 'cash') {
//         include = true;
//       } else if (isElectricCash &&
//           effectiveCompany == AppCompanies.electric &&
//           effectivePaymentMethod == 'cash') {
//         include = true;
//       } else if (isBank && rawBankId.isNotEmpty) {
//         final rBankId = data.normalizeBankId(rawBankId);
//         if (rBankId == accountId) {
//           include = true;
//         }
//       }

//       if (include) {
//         items.add(LedgerItem(
//           date: ret.returnDate,
//           description:
//               'Purchase Return Refund (${ret.vendorName} - ${ret.purchaseId})',
//           credit: ret.totalAmount, // Credit Inflow -> Money returned back to you!
//         ));
//       }
//     }

//     // Sort chronologically
//     items.sort((a, b) => a.date.compareTo(b.date));
//     _rawItems = items;

//     _applyFilter();
//   }

//   void _applyFilter() {
//     double running = _baseOpeningBalance;
//     double effectiveStart = _baseOpeningBalance;
//     List<LedgerItem> displayItems = [];

//     for (final item in _rawItems) {
//       bool beforeStart = _startDate != null && item.date.isBefore(_startDate!);
//       bool afterEnd = _endDate != null && item.date.isAfter(_endDate!);

//       if (beforeStart) {
//         running += item.credit;
//         running -= item.debit;
//         effectiveStart = running;
//       } else if (afterEnd) {
//         continue;
//       } else {
//         running += item.credit;
//         running -= item.debit;
//         displayItems.add(LedgerItem(
//           date: item.date,
//           description: item.description,
//           credit: item.credit,
//           debit: item.debit,
//           balance: running,
//         ));
//       }
//     }

//     _filteredItems = displayItems.reversed.toList();
//     _effectiveOpeningBalance = effectiveStart;
//     _finalBalance = running;
//   }

//   void _updateDateRange(String filter) {
//     final now = DateTime.now();
//     if (filter == 'All Time') {
//       _startDate = null;
//       _endDate = null;
//     } else if (filter == 'This Month') {
//       _startDate = DateTime(now.year, now.month, 1);
//       _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
//     } else if (filter == 'Last Month') {
//       _startDate = DateTime(now.year, now.month - 1, 1);
//       _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
//     } else if (filter == 'Last 3 Months') {
//       _startDate = DateTime(now.year, now.month - 3, 1);
//       _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
//     }
    
//     setState(() {
//       _filterType = filter;
//       _applyFilter();
//     });
//   }

//   Future<void> _pickCustomRange() async {
//     final picked = await showDateRangePicker(
//       context: context,
//       initialDateRange: (_startDate != null && _endDate != null)
//           ? DateTimeRange(start: _startDate!, end: _endDate!)
//           : null,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: AppColors.textPrimary,
//               onPrimary: Colors.white,
//               onSurface: AppColors.textPrimary,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() {
//         _filterType = 'Custom Range';
//         _startDate = picked.start;
//         _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
//         _applyFilter();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isCash = widget.accountId.startsWith('cash_');
//     final accentColor = isCash ? AppColors.cashGreen : AppColors.bankBlue;

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: AppColors.headerBg,
//         foregroundColor: Colors.white,
//         title: Text(widget.accountName),
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             tooltip: 'Export Statement to PDF',
//             onPressed: () async {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Generating PDF Statement...'),
//                   backgroundColor: AppColors.bankBlue,
//                   duration: Duration(seconds: 1),
//                 ),
//               );

//               final chronologicalItems = _filteredItems.reversed.toList();

//               await PdfService.generateLedgerStatementPdf(
//                 accountName: widget.accountName,
//                 companyKey: _companyKey,
//                 openingBalance: _effectiveOpeningBalance,
//                 finalBalance: _finalBalance,
//                 items: chronologicalItems,
//                 periodLabel: _filterType,
//                 startDate: _startDate,
//                 endDate: _endDate,
//               );
//             },
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             // Filter Row
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               margin: const EdgeInsets.only(bottom: 16),
//               decoration: BoxDecoration(
//                 color: AppColors.cardBg,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: AppColors.border),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.date_range, color: AppColors.textSecondary, size: 20),
//                   const SizedBox(width: 12),
//                   DropdownButtonHideUnderline(
//                     child: DropdownButton<String>(
//                       value: _filterType,
//                       icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
//                       items: ['All Time', 'This Month', 'Last Month', 'Last 3 Months', 'Custom Range']
//                           .map((e) => DropdownMenuItem(
//                                 value: e,
//                                 child: Text(e, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
//                               ))
//                           .toList(),
//                       onChanged: (val) {
//                         if (val != null) {
//                           if (val == 'Custom Range') {
//                             _pickCustomRange();
//                           } else {
//                             _updateDateRange(val);
//                           }
//                         }
//                       },
//                     ),
//                   ),
//                   const Spacer(),
//                   if (_startDate != null && _endDate != null)
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: accentColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         '${_formatDateShort(_startDate!)}  —  ${_formatDateShort(_endDate!)}',
//                         style: TextStyle(fontSize: 13, color: accentColor, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//             // Summary Cards
//             Row(
//               children: [
//                 _summaryCard('Opening', _effectiveOpeningBalance, accentColor),
//                 const SizedBox(width: 12),
//                 _summaryCard(
//                   'Total In (Credit)',
//                   _filteredItems.fold(0.0, (s, i) => s + i.credit),
//                   AppColors.cashGreen,
//                 ),
//                 const SizedBox(width: 12),
//                 _summaryCard(
//                   'Total Out (Debit)',
//                   _filteredItems.fold(0.0, (s, i) => s + i.debit),
//                   AppColors.expenseRed,
//                 ),
//                 const SizedBox(width: 12),
//                 _summaryCard(
//                   'Balance',
//                   _finalBalance,
//                   _finalBalance >= 0 ? accentColor : AppColors.expenseRed,
//                   highlight: true,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),

//             // Table Card
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: AppColors.cardBg,
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: AppColors.border, width: 1.5),
//                 ),
//                 clipBehavior: Clip.antiAlias,
//                 child: Column(
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 16, vertical: 12),
//                       decoration: BoxDecoration(
//                         color: accentColor.withOpacity(0.08),
//                         border: Border(
//                           bottom: BorderSide(
//                             color: AppColors.border.withOpacity(0.8),
//                             width: 1,
//                           ),
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               _filterType == 'All Time' ? 'Opening Balance' : 'Calculated Opening Balance',
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                                 color: AppColors.textPrimary,
//                               ),
//                             ),
//                           ),
//                           Text(
//                             'Rs. ${_effectiveOpeningBalance.toStringAsFixed(2)}',
//                             style: TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.bold,
//                               color: accentColor,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 16, vertical: 14),
//                       color: AppColors.headerBg,
//                       child: const Row(
//                         children: [
//                           SizedBox(
//                             width: 100,
//                             child: Text('Date',
//                                 style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 13,
//                                     color: Colors.white)),
//                           ),
//                           Expanded(
//                             flex: 3,
//                             child: Text('Description',
//                                 style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 13,
//                                     color: Colors.white)),
//                           ),
//                           SizedBox(
//                             width: 130,
//                             child: Text('Credit (In)',
//                                 textAlign: TextAlign.right,
//                                 style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 13,
//                                     color: Colors.white)),
//                           ),
//                           SizedBox(
//                             width: 130,
//                             child: Text('Debit (Out)',
//                                 textAlign: TextAlign.right,
//                                 style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 13,
//                                     color: Colors.white)),
//                           ),
//                           SizedBox(
//                             width: 150,
//                             child: Text('Balance',
//                                 textAlign: TextAlign.right,
//                                 style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 13,
//                                     color: Colors.white)),
//                           ),
//                         ],
//                       ),
//                     ),

//                     Expanded(
//                       child: _filteredItems.isEmpty
//                           ? Center(
//                               child: Text(
//                                 'No transactions for selected period',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   color: AppColors.textSecondary
//                                       .withOpacity(0.7),
//                                 ),
//                               ),
//                             )
//                           : ListView.builder(
//                               itemCount: _filteredItems.length,
//                               itemBuilder: (context, index) {
//                                 final item = _filteredItems[index];
//                                 return _tableRow(
//                                   date: _formatDate(item.date),
//                                   description: item.description,
//                                   credit: item.credit > 0 ? item.credit : null,
//                                   debit: item.debit > 0 ? item.debit : null,
//                                   balance: item.balance,
//                                   index: index,
//                                 );
//                               },
//                             ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _summaryCard(String label, double value, Color color,
//       {bool highlight = false}) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         decoration: BoxDecoration(
//           color: highlight ? color.withOpacity(0.08) : AppColors.cardBg,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: highlight ? color : AppColors.border,
//             width: highlight ? 1.5 : 1,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(label,
//                 style: const TextStyle(
//                     fontSize: 12, color: AppColors.textSecondary)),
//             const SizedBox(height: 4),
//             Text(
//               'Rs. ${value.toStringAsFixed(2)}',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _tableRow({
//     required String date,
//     required String description,
//     required double? credit,
//     required double? debit,
//     required double balance,
//     required int index,
//   }) {
//     final bgColor =
//         index % 2 == 0 ? AppColors.cardBg : const Color(0xFFF8FAFC);

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
//       decoration: BoxDecoration(
//         color: bgColor,
//         border: Border(
//           bottom: BorderSide(
//             color: AppColors.border.withOpacity(0.8),
//             width: 1,
//           ),
//         ),
//       ),
//       child: Row(
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               date,
//               style: const TextStyle(
//                 fontSize: 13,
//                 color: AppColors.textPrimary,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 3,
//             child: Text(
//               description,
//               style: const TextStyle(
//                 fontSize: 13,
//                 color: AppColors.textPrimary,
//                 fontWeight: FontWeight.w500,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           SizedBox(
//             width: 130,
//             child: Text(
//               credit != null ? 'Rs. ${credit.toStringAsFixed(2)}' : '—',
//               textAlign: TextAlign.right,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: credit != null
//                     ? AppColors.cashGreen
//                     : AppColors.textSecondary,
//                 fontWeight:
//                     credit != null ? FontWeight.bold : FontWeight.normal,
//               ),
//             ),
//           ),
//           SizedBox(
//             width: 130,
//             child: Text(
//               debit != null ? 'Rs. ${debit.toStringAsFixed(2)}' : '—',
//               textAlign: TextAlign.right,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: debit != null
//                     ? AppColors.expenseRed
//                     : AppColors.textSecondary,
//                 fontWeight:
//                     debit != null ? FontWeight.bold : FontWeight.normal,
//               ),
//             ),
//           ),
//           SizedBox(
//             width: 150,
//             child: Text(
//               'Rs. ${balance.toStringAsFixed(2)}',
//               textAlign: TextAlign.right,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: balance >= 0
//                     ? AppColors.textPrimary
//                     : AppColors.expenseRed,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';
import 'package:sir_khawar_pos_updated/models/quotation.dart';
import 'package:sir_khawar_pos_updated/models/bank_account.dart';
import 'package:sir_khawar_pos_updated/services/pdf_service.dart';

class LedgerItem {
  final DateTime date;
  final String description;
  final double credit;
  final double debit;
  double balance;

  LedgerItem({
    required this.date,
    required this.description,
    this.credit = 0.0,
    this.debit = 0.0,
    this.balance = 0.0,
  });
}

class AccountLedgerScreen extends StatefulWidget {
  final String accountId;
  final String accountName;

  const AccountLedgerScreen({
    super.key,
    required this.accountId,
    required this.accountName,
  });

  @override
  State<AccountLedgerScreen> createState() => _AccountLedgerScreenState();
}

class _AccountLedgerScreenState extends State<AccountLedgerScreen> {
  final AppData data = AppData();

  static const List<String> _filterOptions = [
    'All Time',
    'This Month',
    'Last Month',
    'Last 3 Months',
    'Custom Range',
  ];

  List<LedgerItem> _rawItems = [];
  List<LedgerItem> _filteredItems = [];
  double _baseOpeningBalance = 0;
  double _effectiveOpeningBalance = 0;
  double _finalBalance = 0;
  String _companyKey = AppCompanies.energy;

  String _filterType = 'All Time';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _prepareData();
    data.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      _prepareData();
      setState(() {});
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatDateShort(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  void _prepareData() {
    final accountId = widget.accountId;
    final bool isEnergyCash = accountId == 'cash_energy';
    final bool isElectricCash = accountId == 'cash_electric';
    final bool isBank = !isEnergyCash && !isElectricCash;

    _baseOpeningBalance = 0;
    _companyKey = AppCompanies.energy;

    if (isEnergyCash) {
      _baseOpeningBalance = data.settings.getOpeningCash(AppCompanies.energy);
      _companyKey = AppCompanies.energy;
    } else if (isElectricCash) {
      _baseOpeningBalance = data.settings.getOpeningCash(AppCompanies.electric);
      _companyKey = AppCompanies.electric;
    } else {
      final bank = data.banks.firstWhere(
        (b) => b.id == accountId,
        orElse: () => BankAccount(
            id: '',
            name: 'Unknown',
            company: AppCompanies.energy,
            openingBalance: 0),
      );
      _baseOpeningBalance = bank.openingBalance;
      _companyKey = bank.company;
    }

    final List<LedgerItem> items = [];

    // 1. SALES PAYMENTS (Inflow -> Credit)
    for (final sale in data.salesHistory) {
      for (final p in sale.payments) {
        bool include = false;
        if (isEnergyCash &&
            sale.company == AppCompanies.energy &&
            p.method == PaymentMethod.cash) {
          include = true;
        }
        if (isElectricCash &&
            sale.company == AppCompanies.electric &&
            p.method == PaymentMethod.cash) {
          include = true;
        }
        if (isBank) {
          final bId = p.bankId.isNotEmpty ? p.bankId : 'default_bank';
          if (bId == accountId &&
              (p.method == PaymentMethod.online ||
                  (p.method == PaymentMethod.cheque &&
                      p.chequeDate != null &&
                      !p.chequeDate!.isAfter(DateTime.now())))) {
            include = true;
          }
        }
        if (include) {
          items.add(LedgerItem(
            date: p.date,
            description:
                'Payment Received (Inv #${sale.invoiceNumber} - ${sale.customerName})',
            credit: p.amount,
          ));
        }
      }
    }

    // 2. EXPENSES (Outflow -> Debit)
    for (final exp in data.expenses) {
      bool include = false;
      if (isEnergyCash &&
          exp.company == AppCompanies.energy &&
          exp.paidFrom == 'cash') {
        include = true;
      }
      if (isElectricCash &&
          exp.company == AppCompanies.electric &&
          exp.paidFrom == 'cash') {
        include = true;
      }
      if (isBank && data.normalizeBankId(exp.paidFrom) == accountId) {
        include = true;
      }
      if (include) {
        items.add(LedgerItem(
          date: exp.date,
          description:
              'Expense Paid (${exp.category} - ${exp.description})',
          debit: exp.amount,
        ));
      }
    }

    // 3. SALARIES (Outflow -> Debit)
    for (final sal in data.salaryRecords) {
      bool include = false;
      if (isEnergyCash &&
          sal.company == AppCompanies.energy &&
          sal.method == PaymentMethod.cash) {
        include = true;
      }
      if (isElectricCash &&
          sal.company == AppCompanies.electric &&
          sal.method == PaymentMethod.cash) {
        include = true;
      }
      if (isBank && sal.method == PaymentMethod.online) {
        final bId = sal.bankId.isNotEmpty ? sal.bankId : 'default_bank';
        if (bId == accountId) include = true;
      }
      if (include) {
        items.add(LedgerItem(
          date: sal.paymentDate,
          description:
              'Salary Paid (${sal.employeeName} - ${sal.salaryMonth})',
          debit: sal.amount,
        ));
      }
    }

    // 4. PURCHASES (Outflow -> Debit)
    for (final pur in data.purchases) {
      bool include = false;
      if (isEnergyCash &&
          pur.company == AppCompanies.energy &&
          pur.paymentMethod == 'cash') {
        include = true;
      } else if (isElectricCash &&
          pur.company == AppCompanies.electric &&
          pur.paymentMethod == 'cash') {
        include = true;
      } else if (isBank && pur.bankId != null && pur.bankId!.isNotEmpty) {
        final pBankId = data.normalizeBankId(pur.bankId!);
        if (pBankId == accountId) {
          if (pur.paymentMethod == 'bank') {
            include = true;
          } else if (pur.paymentMethod == 'cheque') {
            if (pur.chequeDate == null ||
                !pur.chequeDate!.isAfter(DateTime.now())) {
              include = true;
            }
          }
        }
      }

      if (include) {
        final chequeInfo =
            pur.paymentMethod == 'cheque' && pur.chequeNumber.isNotEmpty
                ? ' Chq #${pur.chequeNumber}'
                : '';
        items.add(LedgerItem(
          date: pur.purchaseDate,
          description: 'Purchase Paid (${pur.vendorName}$chequeInfo)',
          debit: pur.totalAmount, // Outflow
        ));
      }
    }

    // 5. PURCHASE RETURNS (Inflow -> CREDIT REFUND back into Account)
    for (final ret in data.purchaseReturns) {
      final parentP =
          data.purchases.where((p) => p.id == ret.purchaseId).firstOrNull;

      final effectivePaymentMethod = ret.paymentMethod.isNotEmpty
          ? ret.paymentMethod
          : (parentP?.paymentMethod ?? 'cash');

      final effectiveCompany = ret.company.isNotEmpty
          ? ret.company
          : (parentP?.company ?? AppCompanies.energy);

      final rawBankId = (ret.bankId != null && ret.bankId!.isNotEmpty)
          ? ret.bankId!
          : (parentP?.bankId ?? '');

      bool include = false;
      if (isEnergyCash &&
          effectiveCompany == AppCompanies.energy &&
          effectivePaymentMethod == 'cash') {
        include = true;
      } else if (isElectricCash &&
          effectiveCompany == AppCompanies.electric &&
          effectivePaymentMethod == 'cash') {
        include = true;
      } else if (isBank && rawBankId.isNotEmpty) {
        final rBankId = data.normalizeBankId(rawBankId);
        if (rBankId == accountId) {
          include = true;
        }
      }

      if (include) {
        items.add(LedgerItem(
          date: ret.returnDate,
          description:
              'Purchase Return Refund (${ret.vendorName} - ${ret.purchaseId})',
          credit: ret.totalAmount, // Credit Inflow -> Money returned back to you!
        ));
      }
    }

    // Sort chronologically
    items.sort((a, b) => a.date.compareTo(b.date));
    _rawItems = items;

    _applyFilter();
  }

  void _applyFilter() {
    double running = _baseOpeningBalance;
    double effectiveStart = _baseOpeningBalance;
    List<LedgerItem> displayItems = [];

    for (final item in _rawItems) {
      bool beforeStart = _startDate != null && item.date.isBefore(_startDate!);
      bool afterEnd = _endDate != null && item.date.isAfter(_endDate!);

      if (beforeStart) {
        running += item.credit;
        running -= item.debit;
        effectiveStart = running;
      } else if (afterEnd) {
        continue;
      } else {
        running += item.credit;
        running -= item.debit;
        displayItems.add(LedgerItem(
          date: item.date,
          description: item.description,
          credit: item.credit,
          debit: item.debit,
          balance: running,
        ));
      }
    }

    _filteredItems = displayItems.reversed.toList();
    _effectiveOpeningBalance = effectiveStart;
    _finalBalance = running;
  }

  void _updateDateRange(String filter) {
    final now = DateTime.now();
    if (filter == 'All Time') {
      _startDate = null;
      _endDate = null;
    } else if (filter == 'This Month') {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (filter == 'Last Month') {
      _startDate = DateTime(now.year, now.month - 1, 1);
      _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
    } else if (filter == 'Last 3 Months') {
      _startDate = DateTime(now.year, now.month - 3, 1);
      _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }

    setState(() {
      _filterType = filter;
      _applyFilter();
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.textPrimary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filterType = 'Custom Range';
        _startDate = picked.start;
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        _applyFilter();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCash = widget.accountId.startsWith('cash_');
    final accentColor = isCash ? AppColors.cashGreen : AppColors.bankBlue;

    // UI-only caches — recomputed each build, but avoid repeated Color allocs
    final accentTint10 = accentColor.withOpacity(0.1);
    final accentTint08 = accentColor.withOpacity(0.08);
    final borderFaded = AppColors.border.withOpacity(0.8);

    final totalIn = _filteredItems.fold(0.0, (s, i) => s + i.credit);
    final totalOut = _filteredItems.fold(0.0, (s, i) => s + i.debit);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        title: Text(widget.accountName),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Statement to PDF',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Generating PDF Statement...'),
                  backgroundColor: AppColors.bankBlue,
                  duration: Duration(seconds: 1),
                ),
              );

              final chronologicalItems = _filteredItems.reversed.toList();

              await PdfService.generateLedgerStatementPdf(
                accountName: widget.accountName,
                companyKey: _companyKey,
                openingBalance: _effectiveOpeningBalance,
                finalBalance: _finalBalance,
                items: chronologicalItems,
                periodLabel: _filterType,
                startDate: _startDate,
                endDate: _endDate,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Filter Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range,
                      color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterType,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: AppColors.textSecondary),
                      items: _filterOptions
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          if (val == 'Custom Range') {
                            _pickCustomRange();
                          } else {
                            _updateDateRange(val);
                          }
                        }
                      },
                    ),
                  ),
                  const Spacer(),
                  if (_startDate != null && _endDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentTint10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_formatDateShort(_startDate!)}  —  ${_formatDateShort(_endDate!)}',
                        style: TextStyle(
                            fontSize: 13,
                            color: accentColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            // Summary Cards
            Row(
              children: [
                _summaryCard('Opening', _effectiveOpeningBalance, accentColor),
                const SizedBox(width: 12),
                _summaryCard(
                  'Total In (Credit)',
                  totalIn,
                  AppColors.cashGreen,
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  'Total Out (Debit)',
                  totalOut,
                  AppColors.expenseRed,
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  'Balance',
                  _finalBalance,
                  _finalBalance >= 0 ? accentColor : AppColors.expenseRed,
                  highlight: true,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table Card
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: accentTint08,
                        border: Border(
                          bottom: BorderSide(
                            color: borderFaded,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _filterType == 'All Time'
                                  ? 'Opening Balance'
                                  : 'Calculated Opening Balance',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            'Rs. ${_effectiveOpeningBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      color: AppColors.headerBg,
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text('Date',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('Description',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white)),
                          ),
                          SizedBox(
                            width: 130,
                            child: Text('Credit (In)',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white)),
                          ),
                          SizedBox(
                            width: 130,
                            child: Text('Debit (Out)',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white)),
                          ),
                          SizedBox(
                            width: 150,
                            child: Text('Balance',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white)),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _filteredItems.isEmpty
                          ? Center(
                              child: Text(
                                'No transactions for selected period',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary
                                      .withOpacity(0.7),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                return RepaintBoundary(
                                  child: _tableRow(
                                    date: _formatDate(item.date),
                                    description: item.description,
                                    credit:
                                        item.credit > 0 ? item.credit : null,
                                    debit: item.debit > 0 ? item.debit : null,
                                    balance: item.balance,
                                    index: index,
                                    borderFaded: borderFaded,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, double value, Color color,
      {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: highlight ? color.withOpacity(0.08) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlight ? color : AppColors.border,
            width: highlight ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              'Rs. ${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableRow({
    required String date,
    required String description,
    required double? credit,
    required double? debit,
    required double balance,
    required int index,
    required Color borderFaded,
  }) {
    final bgColor =
        index % 2 == 0 ? AppColors.cardBg : const Color(0xFFF8FAFC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: borderFaded,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              date,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              credit != null ? 'Rs. ${credit.toStringAsFixed(2)}' : '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                color: credit != null
                    ? AppColors.cashGreen
                    : AppColors.textSecondary,
                fontWeight:
                    credit != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              debit != null ? 'Rs. ${debit.toStringAsFixed(2)}' : '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                color: debit != null
                    ? AppColors.expenseRed
                    : AppColors.textSecondary,
                fontWeight:
                    debit != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              'Rs. ${balance.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: balance >= 0
                    ? AppColors.textPrimary
                    : AppColors.expenseRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}