import 'package:flutter/material.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/models/quotation.dart';
import 'package:sir_khawar_pos_updated/models/app_user.dart';

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

  // ============ USER ACCESS MANAGEMENT (ADDED) ============

  Future<void> _showAddUserDialog() async {
    final nameCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    String role = 'employee';
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Add New User'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: idCtrl,
                  decoration: const InputDecoration(
                    labelText: 'User ID (unique, no spaces)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. ali, ahmed, staff1',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'employee', child: Text('Employee')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setD(() => role = v ?? 'employee'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final id = idCtrl.text.trim();
                      final name = nameCtrl.text.trim();
                      if (id.isEmpty || name.isEmpty) return;
                      if (data.users.any((u) => u.id == id)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User ID already exists'),
                            backgroundColor: AppColors.expenseRed,
                          ),
                        );
                        return;
                      }
                      setD(() => saving = true);
                      try {
                        await data.addUser(AppUser(
                          id: id,
                          name: name,
                          role: role,
                          allowedScreens:
                              role == 'admin' ? [] : ['dashboard'],
                        ));
                        if (mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Please check your internet connection'),
                              backgroundColor: AppColors.expenseRed,
                            ),
                          );
                        }
                      } finally {
                        setD(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPermissionsDialog(AppUser user) async {
    final selected = Set<String>.from(user.allowedScreens);
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Permissions: ${user.name}'),
          content: SizedBox(
            width: 450,
            height: 500,
            child: user.isAdmin
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.admin_panel_settings,
                            size: 60, color: Colors.amber),
                        SizedBox(height: 12),
                        Text(
                          'Admin has full access to all screens.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      const Text(
                        'Tick the screens this user can access:',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          children: AppData.allScreenKeys.map((screen) {
                            final key = screen['key']!;
                            final label = screen['label']!;
                            final checked = selected.contains(key);
                            return CheckboxListTile(
                              title: Text(label),
                              value: checked,
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (v) {
                                setD(() {
                                  if (v == true) {
                                    selected.add(key);
                                  } else {
                                    selected.remove(key);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            if (!user.isAdmin)
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        setD(() => saving = true);
                        try {
                          await data.updateUserPermissions(
                              user.id, selected.toList());
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Permissions updated'),
                                backgroundColor: AppColors.cashGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please check your internet connection'),
                                backgroundColor: AppColors.expenseRed,
                              ),
                            );
                          }
                        } finally {
                          setD(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Permissions'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteUser(AppUser user) async {
    if (user.id == data.currentUser?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete yourself'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Remove "${user.name}" from this system?'),
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
    if (ok == true) {
      try {
        await data.deleteUser(user.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please check your internet connection'),
              backgroundColor: AppColors.expenseRed,
            ),
          );
        }
      }
    }
  }

  Widget _buildUserAccessSection() {
    final isAdmin = data.currentUser?.isAdmin ?? false;
    if (!isAdmin) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'User Access Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Add User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bankBlue,
                foregroundColor: AppColors.cardBg,
              ),
              onPressed: _showAddUserDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Add users and control which screens they can see. Changes sync in real time.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: data.users.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No users yet')),
                  )
                : Column(
                    children: data.users.map((user) {
                      final isMe = user.id == data.currentUser?.id;
                      return Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: AppColors.border, width: 0.5),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: user.isAdmin
                                ? Colors.amber.withOpacity(0.2)
                                : AppColors.bankBlue.withOpacity(0.15),
                            child: Icon(
                              user.isAdmin
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                              color: user.isAdmin
                                  ? Colors.amber.shade800
                                  : AppColors.bankBlue,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: user.isAdmin
                                      ? Colors.amber.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  user.isAdmin ? 'ADMIN' : 'EMPLOYEE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: user.isAdmin
                                        ? Colors.amber.shade800
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.cashGreen.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'YOU',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.cashGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            user.isAdmin
                                ? 'Full access to all screens'
                                : '${user.allowedScreens.length} screen(s) allowed',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.security,
                                    color: AppColors.bankBlue),
                                tooltip: 'Manage Permissions',
                                onPressed: () => _showPermissionsDialog(user),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: isMe
                                      ? Colors.grey
                                      : AppColors.expenseRed,
                                ),
                                tooltip: isMe
                                    ? 'Cannot delete yourself'
                                    : 'Delete User',
                                onPressed:
                                    isMe ? null : () => _confirmDeleteUser(user),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  // ============ END USER ACCESS MANAGEMENT ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.headerBg,
        foregroundColor: AppColors.cardBg,
        actions: [
          if (data.currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 18),
                  const SizedBox(width: 6),
                  Text(data.currentUser!.name,
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.logout,
                        color: Colors.white, size: 18),
                    label: const Text('Logout',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () => data.logout(),
                  ),
                ],
              ),
            ),
        ],
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

              // ── User Access Management (Admin only) ──
              _buildUserAccessSection(),
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