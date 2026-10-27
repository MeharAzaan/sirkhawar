import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';
import '../models/product.dart';
import '../models/vendor.dart';
import '../models/purchase.dart';
import '../models/quotation.dart';

class CreatePurchaseScreen extends StatefulWidget {
  const CreatePurchaseScreen({super.key});

  @override
  State<CreatePurchaseScreen> createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends State<CreatePurchaseScreen> {
  final AppData data = AppData();
  final _formKey = GlobalKey<FormState>();
  Vendor? _vendor;
  final _notesCtrl = TextEditingController();
  final _chequeNumberCtrl = TextEditingController();
  final _chequeBankNameCtrl = TextEditingController();
  String _paymentMethod = 'cash';
  String? _bankId;
  DateTime? _chequeDate;
  List<_PLine> _items = [_PLine.empty()];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    data.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    _notesCtrl.dispose();
    _chequeNumberCtrl.dispose();
    _chequeBankNameCtrl.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  double get _total =>
      _items.fold(0.0, (s, i) => s + (i.unitPrice * i.quantity));

  String _fmt(double v) => 'Rs. ${v.toStringAsFixed(2)}';

  void _addItem() => setState(() => _items.add(_PLine.empty()));

  void _removeItem(int i) {
    if (_items.length <= 1) return;
    setState(() => _items.removeAt(i));
  }

  Future<void> _pickChequeDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _chequeDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _chequeDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vendor'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }
    final validItems = _items
        .where((i) => i.productName.trim().isNotEmpty && i.quantity > 0)
        .toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one item'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }
    if ((_paymentMethod == 'bank' || _paymentMethod == 'cheque') &&
        (_bankId == null || _bankId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a bank account'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }
    if (_paymentMethod == 'cheque' &&
        _chequeNumberCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter cheque number'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final id = await data.generatePurchaseNumber();
      final purchase = Purchase(
        id: id,
        vendorId: _vendor!.id,
        vendorName: _vendor!.name,
        items: validItems
            .map((i) => PurchaseItem(
                  productId: i.productId,
                  productName: i.productName,
                  quantity: i.quantity,
                  unitPrice: i.unitPrice,
                  addedToInventory: i.productId.isNotEmpty,
                ))
            .toList(),
        purchaseDate: DateTime.now(),
        paymentMethod: _paymentMethod,
        bankId: (_paymentMethod == 'bank' || _paymentMethod == 'cheque')
            ? _bankId
            : null,
        notes: _notesCtrl.text.trim(),
        totalAmount: _total,
        chequeNumber: _paymentMethod == 'cheque'
            ? _chequeNumberCtrl.text.trim()
            : '',
        chequeDate: _paymentMethod == 'cheque' ? _chequeDate : null,
        chequeBankName: _paymentMethod == 'cheque'
            ? _chequeBankNameCtrl.text.trim()
            : '',
      );

      await data.addPurchase(purchase);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase $id saved'),
            backgroundColor: AppColors.cashGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check your internet connection'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _balanceChip(String label, double amount, {Color? color}) {
    final c = color ?? AppColors.bankBlue;
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Text(
        '$label: ${_fmt(amount)}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: c,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final energyCash = data.getCashBalance(AppCompanies.energy);
    final electricCash = data.getCashBalance(AppCompanies.electric);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Purchase'),
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vendor
              Autocomplete<Vendor>(
                displayStringForOption: (v) => v.name,
                optionsBuilder: (t) {
                  if (t.text.isEmpty) return data.vendors;
                  final q = t.text.toLowerCase();
                  return data.vendors.where((v) =>
                      v.name.toLowerCase().contains(q) ||
                      v.company.toLowerCase().contains(q));
                },
                onSelected: (v) => setState(() => _vendor = v),
                fieldViewBuilder: (ctx, ctrl, fn, _) {
                  return TextFormField(
                    controller: ctrl,
                    focusNode: fn,
                    decoration: InputDecoration(
                      labelText: 'Vendor *',
                      hintText: 'Search vendor...',
                      prefixIcon: const Icon(Icons.store),
                      border: const OutlineInputBorder(),
                      suffixIcon: _vendor != null
                          ? const Icon(Icons.check_circle,
                              color: AppColors.cashGreen)
                          : null,
                    ),
                  );
                },
                optionsViewBuilder: (ctx, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      color: AppColors.cardBg,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxHeight: 240, maxWidth: 500),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: options
                              .map((v) => ListTile(
                                    dense: true,
                                    title: Text(v.name),
                                    subtitle: Text(v.company.isNotEmpty
                                        ? v.company
                                        : v.phone),
                                    onTap: () => onSelected(v),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Payment method
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank')),
                  DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                ],
                onChanged: (v) => setState(() {
                  _paymentMethod = v ?? 'cash';
                  if (_paymentMethod == 'cash') {
                    _bankId = null;
                  }
                }),
              ),
              const SizedBox(height: 8),

              // Cash balances
              if (_paymentMethod == 'cash') ...[
                Wrap(
                  children: [
                    _balanceChip(
                      'Energy Cash',
                      energyCash,
                      color: AppColors.cashGreen,
                    ),
                    _balanceChip(
                      'Electric Cash',
                      electricCash,
                      color: AppColors.cashGreen,
                    ),
                    _balanceChip(
                      'Total Cash',
                      energyCash + electricCash,
                      color: AppColors.bankBlue,
                    ),
                  ],
                ),
              ],

              // Bank / Cheque bank picker with live balances
              if (_paymentMethod == 'bank' ||
                  _paymentMethod == 'cheque') ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _bankId,
                  decoration: const InputDecoration(
                    labelText: 'Bank Account *',
                    border: OutlineInputBorder(),
                  ),
                  items: data.banks.map((b) {
                    final bal = data.getBankBalance(b.id);
                    final companyLabel = b.company == AppCompanies.electric
                        ? 'Electric'
                        : 'Energy';
                    return DropdownMenuItem(
                      value: b.id,
                      child: Text(
                        '${b.name}'
                        '${b.accountTitle.isNotEmpty ? " — ${b.accountTitle}" : ""}'
                        ' ($companyLabel)  •  ${_fmt(bal)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _bankId = v),
                ),
                if (_bankId != null) ...[
                  const SizedBox(height: 6),
                  _balanceChip(
                    'Selected bank balance',
                    data.getBankBalance(_bankId!),
                    color: AppColors.bankBlue,
                  ),
                  if (_total > data.getBankBalance(_bankId!))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Warning: purchase total exceeds bank balance',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.expenseRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ],

              // Cheque details
              if (_paymentMethod == 'cheque') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _chequeNumberCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Cheque Number *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _chequeBankNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Cheque Bank Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickChequeDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Cheque Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            _chequeDate == null
                                ? 'Select date'
                                : DateFormat('dd MMM yyyy')
                                    .format(_chequeDate!),
                            style: TextStyle(
                              color: _chequeDate == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
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

              ...List.generate(_items.length, (idx) {
                final item = _items[idx];
                final existing = item.productId.isNotEmpty;
                return Card(
                  color: AppColors.cardBg,
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Autocomplete<Product>(
                                initialValue:
                                    TextEditingValue(text: item.productName),
                                displayStringForOption: (p) =>
                                    '${p.id} - ${p.name}',
                                optionsBuilder: (t) {
                                  if (t.text.isEmpty) return data.products;
                                  final q = t.text.toLowerCase();
                                  return data.products.where((p) =>
                                      p.id.toLowerCase().contains(q) ||
                                      p.name.toLowerCase().contains(q));
                                },
                                onSelected: (p) {
                                  setState(() {
                                    item.productId = p.id;
                                    item.productName = p.name;
                                    item.unitPrice = p.price;
                                  });
                                },
                                fieldViewBuilder: (ctx, ctrl, fn, _) {
                                  return TextFormField(
                                    controller: ctrl,
                                    focusNode: fn,
                                    decoration: const InputDecoration(
                                      labelText: 'Product',
                                      hintText:
                                          'Search or type new item name',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      prefixIcon:
                                          Icon(Icons.search, size: 20),
                                    ),
                                    onChanged: (v) {
                                      setState(() {
                                        item.productName = v;
                                        final match = data.products
                                            .where((p) =>
                                                '${p.id} - ${p.name}' == v)
                                            .toList();
                                        if (match.isEmpty) {
                                          item.productId = '';
                                        }
                                      });
                                    },
                                  );
                                },
                                optionsViewBuilder:
                                    (ctx, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 4,
                                      color: AppColors.cardBg,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxHeight: 240, maxWidth: 400),
                                        child: ListView(
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          children: options
                                              .map((p) => ListTile(
                                                    dense: true,
                                                    title: Text(
                                                      '${p.id} - ${p.name}',
                                                      style: const TextStyle(
                                                          fontSize: 13),
                                                    ),
                                                    subtitle: Text(
                                                      'Stock: ${p.quantity}',
                                                      style: const TextStyle(
                                                          fontSize: 11),
                                                    ),
                                                    onTap: () =>
                                                        onSelected(p),
                                                  ))
                                              .toList(),
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
                                decoration: const InputDecoration(
                                  labelText: 'Qty',
                                  border: OutlineInputBorder(),
                                  isDense: true,
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
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (v) => setState(() =>
                                    item.unitPrice =
                                        double.tryParse(v) ?? 0),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: AppColors.expenseRed),
                              onPressed: () => _removeItem(idx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: existing
                                    ? AppColors.cashGreen.withValues(alpha: 0.1)
                                    : AppColors.expenseRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                existing
                                    ? '✓ In inventory — stock +${item.quantity}'
                                    : '⚠ Not in inventory — add later',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: existing
                                      ? AppColors.cashGreen
                                      : AppColors.expenseRed,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Line: ${_fmt(item.quantity * item.unitPrice)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _fmt(_total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.bankBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cashGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Purchase'),
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

class _PLine {
  String productId;
  String productName;
  int quantity;
  double unitPrice;

  _PLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  _PLine.empty()
      : productId = '',
        productName = '',
        quantity = 1,
        unitPrice = 0.0;
}