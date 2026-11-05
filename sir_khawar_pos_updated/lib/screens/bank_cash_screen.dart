import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';
import 'package:sir_khawar_pos_updated/models/quotation.dart';
import 'package:sir_khawar_pos_updated/models/bank_account.dart';
import 'package:sir_khawar_pos_updated/screens/account_ledger_screen.dart';

class BankCashScreen extends StatefulWidget {
  const BankCashScreen({super.key});

  @override
  State<BankCashScreen> createState() => _BankCashScreenState();
}

class _BankCashScreenState extends State<BankCashScreen> {
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

  void _openLedger(String accountId, String accountName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountLedgerScreen(
          accountId: accountId,
          accountName: accountName,
        ),
      ),
    );
  }

  Future<void> _adjustCashBalance(String company) async {
    final current = data.settings.getOpeningCash(company);
    final ctrl = TextEditingController(text: current.toStringAsFixed(2));
    final label = AppCompanies.label(company);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Adjust Opening Cash – $label',
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Opening Balance',
            border: OutlineInputBorder(),
            prefixText: 'Rs. ',
          ),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sidebarActive),
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Save', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (result != true) return;
    final value = double.tryParse(ctrl.text);
    if (value == null) return;
    try {
      final s = data.settings;
      await data.updateSettings(CompanySettings(
        addressLine1: s.addressLine1,
        addressLine2: s.addressLine2,
        addressLine3: s.addressLine3,
        phone: s.phone,
        openingCashEnergy:
            company == AppCompanies.energy ? value : s.openingCashEnergy,
        openingCashElectric:
            company == AppCompanies.electric ? value : s.openingCashElectric,
        openingBankBalance: s.openingBankBalance,
        logoPathEnergy: s.logoPathEnergy,
        logoPathElectric: s.logoPathElectric,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cash balance updated'),
              backgroundColor: AppColors.cashGreen),
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

  Future<void> _adjustBankBalance(BankAccount bank) async {
    final ctrl = TextEditingController(
      text: bank.openingBalance.toStringAsFixed(2),
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Adjust ${bank.name} Opening Balance',
            style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Opening Balance',
            border: OutlineInputBorder(),
            prefixText: 'Rs. ',
          ),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sidebarActive),
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Save', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (result != true) return;
    final value = double.tryParse(ctrl.text);
    if (value == null) return;
    try {
      bank.openingBalance = value;
      await data.updateBank(bank);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${bank.name} balance updated'),
              backgroundColor: AppColors.cashGreen),
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

  Future<void> _showBankDialog({BankAccount? existing}) async {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final accNoCtrl =
        TextEditingController(text: existing?.accountNumber ?? '');
    final accTitleCtrl =
        TextEditingController(text: existing?.accountTitle ?? '');
    final openingCtrl = TextEditingController(
      text: existing != null
          ? existing.openingBalance.toStringAsFixed(2)
          : '0.00',
    );
    String selectedCompany = existing?.company ?? AppCompanies.energy;
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: Text(isEditing ? 'Edit Bank' : 'Add New Bank',
              style: const TextStyle(color: AppColors.textPrimary)),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedCompany,
                      focusColor: Colors.transparent,
                      items: [
                        DropdownMenuItem(
                          value: AppCompanies.energy,
                          child: Text(
                              AppCompanies.label(AppCompanies.energy),
                              style: const TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: AppCompanies.electric,
                          child: Text(
                              AppCompanies.label(AppCompanies.electric),
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                      onChanged: isEditing
                          ? null
                          : (v) {
                              if (v != null) {
                                setDialogState(() => selectedCompany = v);
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Bank Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accNoCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accTitleCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Account Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: openingCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Opening Balance',
                    border: OutlineInputBorder(),
                    prefixText: 'Rs. ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sidebarActive),
              onPressed: saving
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setDialogState(() => saving = true);
                      try {
                        final bank = BankAccount(
                          id: existing?.id ??
                              FirebaseFirestore.instance
                                  .collection('banks')
                                  .doc()
                                  .id,
                          name: nameCtrl.text.trim(),
                          accountNumber: accNoCtrl.text.trim(),
                          accountTitle: accTitleCtrl.text.trim(),
                          openingBalance:
                              double.tryParse(openingCtrl.text) ?? 0.0,
                          company: selectedCompany,
                        );
                        if (isEditing) {
                          await data.updateBank(bank);
                        } else {
                          await data.addBank(bank);
                        }
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please check your internet connection'),
                                backgroundColor: AppColors.expenseRed),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(isEditing ? 'Update' : 'Add',
                      style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isEditing ? 'Bank updated' : 'Bank added'),
            backgroundColor: AppColors.cashGreen),
      );
    }
  }

  Future<void> _deleteBank(BankAccount bank) async {
    if (bank.id == 'default_bank') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot delete the Default Bank'),
            backgroundColor: AppColors.expenseRed),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Delete Bank',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Delete "${bank.name}"?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expenseRed),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await data.deleteBank(bank.id);
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

  List<BankAccount> _banksFor(String company) {
    return data.banks.where((b) => b.company == company).toList();
  }

  @override
  Widget build(BuildContext context) {
    final energyCash = data.getCashBalance(AppCompanies.energy);
    final electricCash = data.getCashBalance(AppCompanies.electric);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        title: const Text('Bank & Cash'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cash Balances',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                _cashBalanceCard(
                  'Energy Solution – Cash',
                  energyCash,
                  AppCompanies.energy,
                ),
                const SizedBox(width: 16),
                _cashBalanceCard(
                  'Electric Solutions – Cash',
                  electricCash,
                  AppCompanies.electric,
                ),
                const SizedBox(width: 16),
                _balanceCard(
                  'Total Bank Balance',
                  data.bankBalance,
                  AppColors.bankBlue,
                  null,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Your Banks',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                ElevatedButton.icon(
                  icon:
                      const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Add Bank',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sidebarActive),
                  onPressed: () => _showBankDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _companyBanksSection(
              AppCompanies.energy,
              AppCompanies.label(AppCompanies.energy),
            ),
            const SizedBox(height: 20),
            _companyBanksSection(
              AppCompanies.electric,
              AppCompanies.label(AppCompanies.electric),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cashBalanceCard(String label, double value, String company) {
    final accountId = company == AppCompanies.energy
        ? 'cash_energy'
        : 'cash_electric';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cashGreen.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.cashGreen, fontSize: 12)),
            const SizedBox(height: 6),
            Text('Rs. ${value.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _adjustCashBalance(company),
              child: const Text('Adjust opening',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      decoration: TextDecoration.underline)),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _openLedger(accountId, label),
              child: const Text('View History →',
                  style: TextStyle(
                      color: AppColors.cashGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _companyBanksSection(String company, String title) {
    final banks = _banksFor(company);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.bankBlue)),
        const SizedBox(height: 8),
        if (banks.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('No banks yet for this company',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: banks.map((bank) {
              final bal = data.getBankBalance(bank.id);
              return GestureDetector(
                onTap: () => _openLedger(
                  bank.id,
                  '${bank.name} (${AppCompanies.label(bank.company)})',
                ),
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.bankBlue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(bank.name,
                                style: const TextStyle(
                                    color: AppColors.bankBlue,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                size: 16,
                                color: AppColors.textSecondary),
                            onPressed: () =>
                                _showBankDialog(existing: bank),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          if (bank.id != 'default_bank')
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 16,
                                  color: AppColors.expenseRed),
                              onPressed: () => _deleteBank(bank),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      if (bank.accountNumber.isNotEmpty)
                        Text('A/C: ${bank.accountNumber}',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11)),
                      const SizedBox(height: 6),
                      Text('Rs. ${bal.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: bal >= 0
                                  ? AppColors.textPrimary
                                  : AppColors.expenseRed,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => _adjustBankBalance(bank),
                        child: const Text('Adjust opening balance',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                decoration: TextDecoration.underline)),
                      ),
                      const SizedBox(height: 2),
                      const Text('Tap card to view history →',
                          style: TextStyle(
                              color: AppColors.bankBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _balanceCard(
      String label, double value, Color color, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontSize: 12)),
              const SizedBox(height: 6),
              Text('Rs. ${value.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Tap to adjust',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}