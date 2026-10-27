import 'package:flutter/material.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/models/quotation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppData data = AppData();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _addr1Ctrl;
  late TextEditingController _addr2Ctrl;
  late TextEditingController _addr3Ctrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _openingCashEnergyCtrl;
  late TextEditingController _openingCashElectricCtrl;
  late TextEditingController _openingBankCtrl;

  late String _logoPathEnergy;
  late String _logoPathElectric;

  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    data.addListener(_onDataChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final s = data.settings;
      _addr1Ctrl = TextEditingController(text: s.addressLine1);
      _addr2Ctrl = TextEditingController(text: s.addressLine2);
      _addr3Ctrl = TextEditingController(text: s.addressLine3);
      _phoneCtrl = TextEditingController(text: s.phone);
      _openingCashEnergyCtrl = TextEditingController(
          text: s.openingCashEnergy.toStringAsFixed(2));
      _openingCashElectricCtrl = TextEditingController(
          text: s.openingCashElectric.toStringAsFixed(2));
      _openingBankCtrl = TextEditingController(
          text: s.openingBankBalance.toStringAsFixed(2));
      _logoPathEnergy = s.logoPathEnergy.isNotEmpty
          ? s.logoPathEnergy
          : 'assets/images/logo.jpeg';
      _logoPathElectric = s.logoPathElectric.isNotEmpty
          ? s.logoPathElectric
          : 'assets/images/logo2.jpeg';
    }
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    _addr1Ctrl.dispose();
    _addr2Ctrl.dispose();
    _addr3Ctrl.dispose();
    _phoneCtrl.dispose();
    _openingCashEnergyCtrl.dispose();
    _openingCashElectricCtrl.dispose();
    _openingBankCtrl.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted && !_saving) setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final s = CompanySettings(
        addressLine1: _addr1Ctrl.text.trim(),
        addressLine2: _addr2Ctrl.text.trim(),
        addressLine3: _addr3Ctrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        openingCashEnergy:
            double.tryParse(_openingCashEnergyCtrl.text) ?? 0.0,
        openingCashElectric:
            double.tryParse(_openingCashElectricCtrl.text) ?? 0.0,
        openingBankBalance:
            double.tryParse(_openingBankCtrl.text) ?? 0.0,
        logoPathEnergy: _logoPathEnergy,
        logoPathElectric: _logoPathElectric,
      );
      await data.updateSettings(s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Settings saved successfully'),
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.headerBg,
        foregroundColor: AppColors.cardBg,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Company Logos ──
              const Text('Company Logos',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                'Each company uses its own logo on quotations, invoices, and PDFs.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _logoOptionCard(
                      title: 'Alternative Energy Solution',
                      assetPath: 'assets/images/logo.jpeg',
                      isSelected:
                          _logoPathEnergy == 'assets/images/logo.jpeg',
                      onTap: () {
                        setState(() {
                          _logoPathEnergy = 'assets/images/logo.jpeg';
                        });
                      },
                    ),
                    const SizedBox(width: 24),
                    _logoOptionCard(
                      title: 'Alternative Electric Solutions',
                      assetPath: 'assets/images/logo2.jpeg',
                      isSelected:
                          _logoPathElectric == 'assets/images/logo2.jpeg',
                      onTap: () {
                        setState(() {
                          _logoPathElectric = 'assets/images/logo2.jpeg';
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Shared Address ──
              const Text('Company Information (Shared)',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _addr1Ctrl,
                      decoration: const InputDecoration(
                          labelText: 'Address Line 1',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addr2Ctrl,
                      decoration: const InputDecoration(
                          labelText: 'Address Line 2',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addr3Ctrl,
                      decoration: const InputDecoration(
                          labelText: 'Address Line 3',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Opening Cash (per company) ──
              const Text('Opening Cash Balances',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                  'Each company has its own separate cash drawer.',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _openingCashEnergyCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Energy Solution – Opening Cash',
                            border: OutlineInputBorder(),
                            prefixText: 'Rs. '),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _openingCashElectricCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Electric Solutions – Opening Cash',
                            border: OutlineInputBorder(),
                            prefixText: 'Rs. '),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Default Bank Opening (legacy) ──
              const Text('Default Bank Opening Balance',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                  'Used only when creating the Default Bank for the first time.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextFormField(
                  controller: _openingBankCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Opening Bank Balance',
                      border: OutlineInputBorder(),
                      prefixText: 'Rs. '),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(height: 16),

              // ── Live balances ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bankBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.bankBlue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: AppColors.bankBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Current Cash:\n'
                        'Energy: Rs. ${data.getCashBalance(AppCompanies.energy).toStringAsFixed(2)}   |   '
                        'Electric: Rs. ${data.getCashBalance(AppCompanies.electric).toStringAsFixed(2)}\n'
                        'Total Banks: Rs. ${data.bankBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: AppColors.bankBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.cardBg))
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Saving...' : 'Save Settings'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cashGreen,
                        foregroundColor: AppColors.cardBg,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14)),
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoOptionCard({
    required String title,
    required String assetPath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.bankBlue.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.bankBlue : AppColors.border,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 70,
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: AppColors.textSecondary),
                    SizedBox(height: 4),
                    Text('Asset missing',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: isSelected
                      ? AppColors.bankBlue
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isSelected
                          ? AppColors.bankBlue
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}