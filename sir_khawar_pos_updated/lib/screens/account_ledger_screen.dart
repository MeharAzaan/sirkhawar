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

  @override
  void initState() {
    super.initState();
    data.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  _LedgerData _computeLedger() {
    final accountId = widget.accountId;
    final bool isEnergyCash = accountId == 'cash_energy';
    final bool isElectricCash = accountId == 'cash_electric';
    final bool isBank = !isEnergyCash && !isElectricCash;

    double openingBalance = 0;
    String companyKey = AppCompanies.energy;

    if (isEnergyCash) {
      openingBalance = data.settings.getOpeningCash(AppCompanies.energy);
      companyKey = AppCompanies.energy;
    } else if (isElectricCash) {
      openingBalance = data.settings.getOpeningCash(AppCompanies.electric);
      companyKey = AppCompanies.electric;
    } else {
      final bank = data.banks.firstWhere(
        (b) => b.id == accountId,
        orElse: () => BankAccount(
            id: '',
            name: 'Unknown',
            company: AppCompanies.energy,
            openingBalance: 0),
      );
      openingBalance = bank.openingBalance;
      companyKey = bank.company;
    }

    final List<LedgerItem> items = [];

    // 1. SALES PAYMENTS (Inflows)
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

    // 2. EXPENSES (Outflows)
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

    // 3. SALARIES (Outflows)
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

    // 4. PURCHASES (Outflows — banks only)
    for (final pur in data.purchases) {
      bool include = false;
      if (isBank && pur.bankId != null && pur.bankId!.isNotEmpty) {
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
          debit: pur.totalAmount,
        ));
      }
    }

    // Chronological for accurate running balance
    items.sort((a, b) => a.date.compareTo(b.date));

    double running = openingBalance;
    for (final item in items) {
      running += item.credit;
      running -= item.debit;
      item.balance = running;
    }

    final finalBalance = running;
    final reversed = items.reversed.toList();

    return _LedgerData(
      openingBalance: openingBalance,
      items: reversed,
      finalBalance: finalBalance,
      companyKey: companyKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ledger = _computeLedger();
    final isCash = widget.accountId.startsWith('cash_');
    final accentColor = isCash ? AppColors.cashGreen : AppColors.bankBlue;

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

              final chronologicalItems = ledger.items.reversed.toList();

              await PdfService.generateLedgerStatementPdf(
                accountName: widget.accountName,
                companyKey: ledger.companyKey,
                openingBalance: ledger.openingBalance,
                finalBalance: ledger.finalBalance,
                items: chronologicalItems,
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
            // ── Summary Cards ──
            Row(
              children: [
                _summaryCard('Opening', ledger.openingBalance, accentColor),
                const SizedBox(width: 12),
                _summaryCard(
                  'Total In',
                  ledger.items.fold(0.0, (s, i) => s + i.credit),
                  AppColors.cashGreen,
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  'Total Out',
                  ledger.items.fold(0.0, (s, i) => s + i.debit),
                  AppColors.expenseRed,
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  'Balance',
                  ledger.finalBalance,
                  ledger.finalBalance >= 0
                      ? accentColor
                      : AppColors.expenseRed,
                  highlight: true,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Table Card ──
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
                    // ── FIXED Opening Balance (never scrolls) ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.08),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.border.withOpacity(0.8),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Opening Balance',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            'Rs. ${ledger.openingBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── FIXED Column Headers (never scrolls) ──
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

                    // ── SCROLLABLE Transactions only ──
                    Expanded(
                      child: ledger.items.isEmpty
                          ? Center(
                              child: Text(
                                'No transactions yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary
                                      .withOpacity(0.7),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: ledger.items.length,
                              itemBuilder: (context, index) {
                                final item = ledger.items[index];
                                return _tableRow(
                                  date: _formatDate(item.date),
                                  description: item.description,
                                  credit: item.credit > 0
                                      ? item.credit
                                      : null,
                                  debit: item.debit > 0
                                      ? item.debit
                                      : null,
                                  balance: item.balance,
                                  index: index,
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
  }) {
    final bgColor =
        index % 2 == 0 ? AppColors.cardBg : const Color(0xFFF8FAFC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(0.8),
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

class _LedgerData {
  final double openingBalance;
  final List<LedgerItem> items;
  final double finalBalance;
  final String companyKey;

  _LedgerData({
    required this.openingBalance,
    required this.items,
    required this.finalBalance,
    required this.companyKey,
  });
}