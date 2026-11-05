import 'package:flutter/material.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';
import 'package:sir_khawar_pos_updated/models/quotation.dart';
import 'package:sir_khawar_pos_updated/models/bank_account.dart';

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
  /// 'cash_energy', 'cash_electric', or a bank ID like 'default_bank'
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

  /// Builds the full transaction list using the EXACT same logic as
  /// AppData.getCashBalance() and AppData.getBankBalance() so that
  /// the final running balance matches those methods perfectly.
  _LedgerData _computeLedger() {
    final accountId = widget.accountId;
    final bool isEnergyCash = accountId == 'cash_energy';
    final bool isElectricCash = accountId == 'cash_electric';
    final bool isBank = !isEnergyCash && !isElectricCash;

    double openingBalance = 0;

    if (isEnergyCash) {
      openingBalance = data.settings.getOpeningCash(AppCompanies.energy);
    } else if (isElectricCash) {
      openingBalance = data.settings.getOpeningCash(AppCompanies.electric);
    } else {
      final bank = data.banks.firstWhere(
        (b) => b.id == accountId,
        orElse: () => BankAccount(
            id: '', name: 'Unknown', company: '', openingBalance: 0),
      );
      openingBalance = bank.openingBalance;
    }

    final List<LedgerItem> items = [];

    // ── 1. SALES PAYMENTS (Inflows) ──
    // Matches AppData.getCashBalance() and AppData.getBankBalance() exactly
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

    // ── 2. EXPENSES (Outflows) ──
    // Matches AppData.getCashBalance() and AppData.getBankBalance() exactly
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

    // ── 3. SALARIES (Outflows) ──
    // Matches AppData.getCashBalance() and AppData.getBankBalance() exactly
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

    // ── 4. PURCHASES (Outflows — banks only) ──
    // Matches AppData.getBankBalance() exactly.
    // Cash purchases are shared across companies and NOT deducted per-company
    // in getCashBalance(), so they do NOT appear in cash ledgers.
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

    // Sort chronologically (oldest first) for running balance
    items.sort((a, b) => a.date.compareTo(b.date));

    // Compute running balances starting from opening
    double running = openingBalance;
    for (final item in items) {
      running += item.credit;
      running -= item.debit;
      item.balance = running;
    }

    return _LedgerData(
      openingBalance: openingBalance,
      items: items,
      finalBalance: running,
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
      ),
      body: Column(
        children: [
          // ── Summary Strip ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.cardBg,
            child: Row(
              children: [
                _summaryChip('Opening', ledger.openingBalance, accentColor),
                const SizedBox(width: 16),
                _summaryChip(
                  'In',
                  ledger.items.fold(0.0, (s, i) => s + i.credit),
                  AppColors.cashGreen,
                ),
                const SizedBox(width: 16),
                _summaryChip(
                  'Out',
                  ledger.items.fold(0.0, (s, i) => s + i.debit),
                  AppColors.expenseRed,
                ),
                const Spacer(),
                Text(
                  'Balance: Rs. ${ledger.finalBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: ledger.finalBalance >= 0
                        ? accentColor
                        : AppColors.expenseRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // ── Column Headers ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.background,
            child: Row(
              children: const [
                SizedBox(width: 72, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                SizedBox(width: 90, child: Text('Credit (In)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                SizedBox(width: 90, child: Text('Debit (Out)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                SizedBox(width: 100, child: Text('Balance', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
              ],
            ),
          ),

          // ── Transaction List ──
          Expanded(
            child: ListView.builder(
              itemCount: ledger.items.length + 1, // +1 for opening row
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _ledgerRow(
                    date: '-',
                    description: 'Opening Balance',
                    credit: null,
                    debit: null,
                    balance: ledger.openingBalance,
                    isBold: true,
                    accentColor: accentColor,
                  );
                }
                final item = ledger.items[index - 1];
                return _ledgerRow(
                  date: _formatDate(item.date),
                  description: item.description,
                  credit: item.credit > 0 ? item.credit : null,
                  debit: item.debit > 0 ? item.debit : null,
                  balance: item.balance,
                  isBold: false,
                  accentColor: accentColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        Text(
          'Rs. ${value.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _ledgerRow({
    required String date,
    required String description,
    required double? credit,
    required double? debit,
    required double balance,
    required bool isBold,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: isBold ? AppColors.textSecondary : AppColors.textPrimary,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              credit != null ? 'Rs. ${credit.toStringAsFixed(2)}' : '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: credit != null ? AppColors.cashGreen : AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              debit != null ? 'Rs. ${debit.toStringAsFixed(2)}' : '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: debit != null ? AppColors.expenseRed : AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'Rs. ${balance.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: balance >= 0 ? AppColors.textPrimary : AppColors.expenseRed,
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

  _LedgerData({
    required this.openingBalance,
    required this.items,
    required this.finalBalance,
  });
}