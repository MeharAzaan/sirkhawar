import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/quotation.dart';
import '../models/sale_history.dart';
import '../models/expense.dart';
import '../models/quotation_template.dart';
import '../models/employee.dart';
import '../models/bank_account.dart';
import '../models/vendor.dart';
import '../models/purchase.dart';
import '../models/app_user.dart';

class CompanySettings {
  String addressLine1;
  String addressLine2;
  String addressLine3;
  String phone;
  double openingCashEnergy;
  double openingCashElectric;
  double openingBankBalance;
  String logoPathEnergy;
  String logoPathElectric;

  CompanySettings({
    this.addressLine1 = 'Office # 1-2, Mezzanine Floor, Falcon Arcade Plot # 169,',
    this.addressLine2 = 'Spring North, Phase VII, Bahria Town, Rawalpindi',
    this.addressLine3 = 'Phase-VII, Rawalpindi.',
    this.phone = 'Ph: 051-8748733',
    this.openingCashEnergy = 46500.00,
    this.openingCashElectric = 0.00,
    this.openingBankBalance = 500000.00,
    this.logoPathEnergy = 'assets/images/logo.jpeg',
    this.logoPathElectric = '',
  });

  double get openingCashBalance => openingCashEnergy;
  set openingCashBalance(double val) => openingCashEnergy = val;

  String get logoPath => logoPathEnergy;
  set logoPath(String val) => logoPathEnergy = val;

  String getLogoPath(String company) {
    if (company == AppCompanies.electric) {
      return logoPathElectric;
    }
    return logoPathEnergy;
  }

  double getOpeningCash(String company) {
    if (company == AppCompanies.electric) return openingCashElectric;
    return openingCashEnergy;
  }
}

class AppData {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Product> products = [];
  List<Quotation> quotations = [];
  List<SaleHistory> salesHistory = [];
  List<Expense> expenses = [];
  List<Employee> employees = [];
  List<SalaryRecord> salaryRecords = [];
  List<QuotationTemplate> quotationTemplates = [];
  List<BankAccount> banks = [];
  List<Vendor> vendors = [];
  List<Purchase> purchases = [];
  List<PurchaseReturn> purchaseReturns = [];
  CompanySettings settings = CompanySettings();

  // ============ ACCESS CONTROL ============
  List<AppUser> users = [];
  AppUser? currentUser;

  static const List<Map<String, String>> allScreenKeys = [
    {'key': 'dashboard', 'label': 'Dashboard'},
    {'key': 'expenses', 'label': 'Expenses'},
    {'key': 'bank_cash', 'label': 'Bank & Cash'},
    {'key': 'customer_cheques', 'label': 'Customer Cheques'},
    {'key': 'inventory', 'label': 'Inventory'},
    {'key': 'quotations', 'label': 'Quotations'},
    {'key': 'invoices', 'label': 'Invoices'},
    {'key': 'customers', 'label': 'Customers'},
    {'key': 'employees', 'label': 'Employees'},
    {'key': 'templates', 'label': 'Templates'},
    {'key': 'settings', 'label': 'Settings'},
    {'key': 'vendors', 'label': 'Vendors'},
    {'key': 'purchases', 'label': 'Purchases'},
    {'key': 'reports', 'label': 'Reports'},
  ];

  bool canAccess(String screenKey) {
    if (currentUser == null) return false;
    if (currentUser!.isAdmin) return true;
    return currentUser!.allowedScreens.contains(screenKey);
  }

  Set<String> get allowedScreenKeys {
    if (currentUser == null) return {};
    if (currentUser!.isAdmin) {
      return allScreenKeys.map((e) => e['key']!).toSet();
    }
    return currentUser!.allowedScreens.toSet();
  }

  void login(AppUser user) {
    currentUser = user;
    _notify();
  }

  void logout() {
    currentUser = null;
    _notify();
  }

  Future<void> addUser(AppUser user) async {
    await _db.collection('users').doc(user.id).set(_userToMap(user));
  }

  Future<void> updateUserPermissions(
      String userId, List<String> allowedScreens) async {
    await _db.collection('users').doc(userId).update({
      'allowedScreens': allowedScreens,
    });
  }

  Future<void> updateUserName(String userId, String name) async {
    await _db.collection('users').doc(userId).update({'name': name});
  }

  Future<void> deleteUser(String id) async {
    await _db.collection('users').doc(id).delete();
  }

  AppUser _userFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      id: d['id']?.toString() ?? doc.id,
      name: d['name']?.toString() ?? '',
      role: d['role']?.toString() ?? 'employee',
      allowedScreens: (d['allowedScreens'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> _userToMap(AppUser u) => {
        'id': u.id,
        'name': u.name,
        'role': u.role,
        'allowedScreens': u.allowedScreens,
      };
  // ============ END ACCESS CONTROL ============

  String selectedCompanyFilter = 'all';

  String get selectedCompany => selectedCompanyFilter;
  String get currentCompany => selectedCompanyFilter;

  void setSelectedCompanyFilter(String company) {
    selectedCompanyFilter = company;
    _notify();
  }

  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback l) => _listeners.add(l);
  void removeListener(VoidCallback l) => _listeners.remove(l);
  void _notify() {
    for (final l in _listeners) {
      l();
    }
  }

  List<Quotation> get filteredQuotations {
    if (selectedCompanyFilter == 'all') return quotations;
    return quotations.where((q) => q.company == selectedCompanyFilter).toList();
  }

  List<SaleHistory> get filteredSalesHistory {
    if (selectedCompanyFilter == 'all') return salesHistory;
    return salesHistory.where((s) => s.company == selectedCompanyFilter).toList();
  }

  List<Expense> get filteredExpenses {
    if (selectedCompanyFilter == 'all') return expenses;
    return expenses.where((e) => e.company == selectedCompanyFilter).toList();
  }

  List<BankAccount> get filteredBanks {
    if (selectedCompanyFilter == 'all') return banks;
    return banks.where((b) => b.company == selectedCompanyFilter).toList();
  }

  Future<void> clearCheque(String saleId, String paymentId) async {
    final index = salesHistory.indexWhere((s) => s.id == saleId);
    if (index == -1) return;
    final sale = salesHistory[index];

    final updatedPayments = sale.payments.map((p) {
      if (p.id == paymentId) {
        return PaymentReceipt(
          id: p.id,
          amount: p.amount,
          date: p.date,
          method: p.method,
          chequeNumber: p.chequeNumber,
          bankName: p.bankName,
          transactionId: p.transactionId,
          chequeDate: DateTime.now().subtract(const Duration(minutes: 1)),
          logoPath: p.logoPath,
          bankId: p.bankId,
          supplierId: p.supplierId,
          supplierName: p.supplierName,
          supplierPaymentAmount: p.supplierPaymentAmount,
        );
      }
      return p;
    }).toList();

    final updatedSale = SaleHistory(
      id: sale.id,
      invoiceNumber: sale.invoiceNumber,
      customerName: sale.customerName,
      customerPhone: sale.customerPhone,
      customerAddress: sale.customerAddress,
      items: sale.items,
      totalAmount: sale.totalAmount,
      payments: updatedPayments,
      dateOfPurchase: sale.dateOfPurchase,
      quotationId: sale.quotationId,
      notes: sale.notes,
      company: sale.company,
    );

    await updateSale(updatedSale);
  }

  final List<StreamSubscription> _subs = [];

  // ============ COMPUTED BALANCES BY COMPANY ============

  double getCashBalance(String company) {
    double b = settings.getOpeningCash(company);
    for (final s in salesHistory) {
      if (s.company == company) {
        for (final p in s.payments) {
          if (p.method == PaymentMethod.cash) {
            b += p.netToBusiness;
          }
        }
      }
    }
    for (final e in expenses) {
      if (e.company == company && e.paidFrom == 'cash') {
        b -= e.amount;
      }
    }
    for (final s in salaryRecords) {
      if (s.company == company && s.method == PaymentMethod.cash) {
        b -= s.amount;
      }
    }
    for (final p in purchases) {
      if (p.company == company && p.paymentMethod == 'cash') {
        b -= p.totalAmount;
      }
    }
    for (final r in purchaseReturns) {
      if (r.company == company && r.paymentMethod == 'cash') {
        b += r.totalAmount;
      }
    }
    return b;
  }

  double get cashBalance {
    if (selectedCompanyFilter == 'electric') {
      return getCashBalance(AppCompanies.electric);
    } else if (selectedCompanyFilter == 'energy') {
      return getCashBalance(AppCompanies.energy);
    } else {
      return getCashBalance(AppCompanies.energy) +
          getCashBalance(AppCompanies.electric);
    }
  }

  double getBankBalance(String bankId) {
    final normalizedId = normalizeBankId(bankId);
    final bank = banks.where((b) => b.id == normalizedId).firstOrNull;
    double b = bank?.openingBalance ?? 0.0;

    for (final s in salesHistory) {
      for (final p in s.payments) {
        final pBankId = p.bankId.isNotEmpty ? p.bankId : 'default_bank';
        if (pBankId == normalizedId) {
          if (p.method == PaymentMethod.online) {
            b += p.netToBusiness;
          }
          if (p.method == PaymentMethod.cheque &&
              (p.chequeDate == null || !p.chequeDate!.isAfter(DateTime.now()))) {
            b += p.netToBusiness;
          }
        }
      }
    }

    for (final e in expenses) {
      final eBankId = normalizeBankId(e.paidFrom);
      if (eBankId == normalizedId) {
        b -= e.amount;
      }
    }

    for (final s in salaryRecords) {
      final sBankId = s.bankId.isNotEmpty ? s.bankId : 'default_bank';
      if (sBankId == normalizedId && s.method == PaymentMethod.online) {
        b -= s.amount;
      }
    }

    for (final p in purchases) {
      if (p.bankId == null || p.bankId!.isEmpty) continue;
      final pBankId = normalizeBankId(p.bankId!);
      if (pBankId != normalizedId) continue;

      if (p.paymentMethod == 'bank') {
        b -= p.totalAmount;
      } else if (p.paymentMethod == 'cheque') {
        if (p.chequeDate == null || !p.chequeDate!.isAfter(DateTime.now())) {
          b -= p.totalAmount;
        }
      }
    }

    for (final r in purchaseReturns) {
      if (r.paymentMethod == 'bank' || r.paymentMethod == 'cheque') {
        if (r.bankId == null || r.bankId!.isEmpty) continue;
        final rBankId = normalizeBankId(r.bankId!);
        if (rBankId == normalizedId) {
          b += r.totalAmount;
        }
      }
    }

    return b;
  }

  String getBankName(String bankId) {
    final normalizedId = normalizeBankId(bankId);
    if (normalizedId == 'cash') return 'Cash';
    final bank = banks.where((b) => b.id == normalizedId).firstOrNull;
    return bank?.name ?? 'Unknown Bank';
  }

  String normalizeBankId(String paidFrom) {
    if (paidFrom == 'cash') return 'cash';
    if (paidFrom == 'bank') return 'default_bank';
    if (paidFrom.isEmpty) return 'default_bank';
    return paidFrom;
  }

  double get bankBalance {
    final targetBanks = filteredBanks;
    if (targetBanks.isEmpty) return 0.0;
    return targetBanks.fold(0.0, (sum, bank) => sum + getBankBalance(bank.id));
  }

  double get totalExpenses =>
      filteredExpenses.fold(0.0, (s, e) => s + e.amount);

  double get pendingCheques {
    double t = 0.0;
    for (final sale in filteredSalesHistory) {
      for (final p in sale.payments) {
        if (p.method == PaymentMethod.cheque &&
            p.chequeDate != null &&
            p.chequeDate!.isAfter(DateTime.now())) {
          t += p.netToBusiness;
        }
      }
    }
    return t;
  }

  int get pendingChequeCount {
    int count = 0;
    for (final sale in filteredSalesHistory) {
      for (final p in sale.payments) {
        if (p.method == PaymentMethod.cheque &&
            p.chequeDate != null &&
            p.chequeDate!.isAfter(DateTime.now())) {
          count++;
        }
      }
    }
    return count;
  }

  int get totalStock => products.fold(0, (s, p) => s + p.quantity);

  double get totalInvoiceAmount =>
      filteredSalesHistory.fold(0.0, (s, x) => s + x.totalAmount);

  // ============ INITIALIZE ============

  Future<void> initialize() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();

    _subs.add(_db.collection('products').snapshots().listen((snap) {
      products = snap.docs.map(_productFromDoc).toList();
      _notify();
    }));
    _subs.add(_db
        .collection('quotations')
        .orderBy('createdDate', descending: true)
        .snapshots()
        .listen((snap) {
      quotations = snap.docs.map(_quotationFromDoc).toList();
      _notify();
    }));
    _subs.add(_db
        .collection('sales')
        .orderBy('dateOfPurchase', descending: true)
        .snapshots()
        .listen((snap) {
      salesHistory = snap.docs.map(_saleFromDoc).toList();
      _notify();
    }));
    _subs.add(_db
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snap) {
      expenses = snap.docs.map(_expenseFromDoc).toList();
      _notify();
    }));
    _subs.add(_db.collection('employees').snapshots().listen((snap) {
      employees = snap.docs.map(_employeeFromDoc).toList();
      _notify();
    }));
    _subs.add(_db
        .collection('salaryRecords')
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .listen((snap) {
      salaryRecords = snap.docs.map(_salaryRecordFromDoc).toList();
      _notify();
    }));
    _subs.add(_db.collection('templates').snapshots().listen((snap) {
      quotationTemplates = snap.docs.map(_templateFromDoc).toList();
      _notify();
    }));
    _subs.add(_db
        .collection('settings')
        .doc('company')
        .snapshots()
        .listen((snap) {
      if (snap.exists) settings = _settingsFromDoc(snap);
      _notify();
    }));
    _subs.add(_db.collection('banks').snapshots().listen((snap) {
      banks = snap.docs.map(_bankFromDoc).toList();
      _notify();
    }));
    _subs.add(_db.collection('vendors').snapshots().listen((snap) {
      vendors = snap.docs.map(_vendorFromDoc).toList();
      vendors.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _notify();
    }));
    _subs.add(_db
        .collection('purchases')
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .listen((snap) {
      purchases = snap.docs.map(_purchaseFromDoc).toList();
      _notify();
    }));
    _subs.add(_db
        .collection('purchase_returns')
        .orderBy('returnDate', descending: true)
        .snapshots()
        .listen((snap) {
      purchaseReturns = snap.docs.map(_purchaseReturnFromDoc).toList();
      _notify();
    }));

    // Users listener (ADDED)
    _subs.add(_db.collection('users').snapshots().listen((snap) {
      users = snap.docs.map(_userFromDoc).toList();
      if (currentUser != null) {
        final updated = users.where((u) => u.id == currentUser!.id).toList();
        if (updated.isNotEmpty) {
          currentUser = updated.first;
        }
      }
      _notify();
    }));

    await _initialFetch();
  }

  Future<void> _initialFetch() async {
    try {
      final r = await Future.wait([
        _db.collection('products').get(),
        _db
            .collection('quotations')
            .orderBy('createdDate', descending: true)
            .get(),
        _db
            .collection('sales')
            .orderBy('dateOfPurchase', descending: true)
            .get(),
        _db.collection('expenses').orderBy('date', descending: true).get(),
        _db.collection('employees').get(),
        _db
            .collection('salaryRecords')
            .orderBy('paymentDate', descending: true)
            .get(),
        _db.collection('templates').get(),
        _db.collection('banks').get(),
        _db.collection('vendors').get(),
        _db
            .collection('purchases')
            .orderBy('purchaseDate', descending: true)
            .get(),
        _db
            .collection('purchase_returns')
            .orderBy('returnDate', descending: true)
            .get(),
        _db.collection('users').get(),
      ]);
      products = r[0].docs.map(_productFromDoc).toList();
      quotations = r[1].docs.map(_quotationFromDoc).toList();
      salesHistory = r[2].docs.map(_saleFromDoc).toList();
      expenses = r[3].docs.map(_expenseFromDoc).toList();
      employees = r[4].docs.map(_employeeFromDoc).toList();
      salaryRecords = r[5].docs.map(_salaryRecordFromDoc).toList();
      quotationTemplates = r[6].docs.map(_templateFromDoc).toList();
      banks = r[7].docs.map(_bankFromDoc).toList();
      vendors = r[8].docs.map(_vendorFromDoc).toList();
      vendors.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      purchases = r[9].docs.map(_purchaseFromDoc).toList();
      purchaseReturns = r[10].docs.map(_purchaseReturnFromDoc).toList();
      users = r[11].docs.map(_userFromDoc).toList();
      final sd = await _db.collection('settings').doc('company').get();
      if (sd.exists) settings = _settingsFromDoc(sd);
    } catch (e) {
      debugPrint('Initial fetch failed (offline?): $e');
    }
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _listeners.clear();
  }

  Future<void> seedInitialDataIfEmpty() async {
    try {
      final ps = await _db.collection('products').get();
      if (ps.docs.isEmpty) {
        await _db.collection('products').doc('P001').set(_productToMap(Product(
            id: 'P001',
            name: 'Solar Panel 400W',
            category: 'Solar',
            price: 15000,
            quantity: 25)));
        await _db.collection('products').doc('P002').set(_productToMap(Product(
            id: 'P002',
            name: 'Inverter 5KW',
            category: 'Inverters',
            price: 85000,
            quantity: 10)));
      }
      final ss = await _db.collection('settings').doc('company').get();
      if (!ss.exists) {
        await _db
            .collection('settings')
            .doc('company')
            .set(_settingsToMap(CompanySettings()));
      }
      final ic = await _db.collection('counters').doc('invoiceCounter').get();
      if (!ic.exists) {
        await _db
            .collection('counters')
            .doc('invoiceCounter')
            .set({'lastNumber': 1000});
      }
      final qc = await _db.collection('counters').doc('quotationCounter').get();
      if (!qc.exists) {
        await _db
            .collection('counters')
            .doc('quotationCounter')
            .set({'lastNumber': 100});
      }
      final pc = await _db.collection('counters').doc('purchaseCounter').get();
      if (!pc.exists) {
        await _db
            .collection('counters')
            .doc('purchaseCounter')
            .set({'lastNumber': 0});
      }

      final banksSnap = await _db.collection('banks').get();
      if (banksSnap.docs.isEmpty) {
        final sd = await _db.collection('settings').doc('company').get();
        final openingBank = sd.exists
            ? ((sd.data()?['openingBankBalance'] as num?)?.toDouble() ??
                500000.0)
            : 500000.0;
        await _db.collection('banks').doc('default_bank').set({
          'id': 'default_bank',
          'name': 'Default Bank',
          'accountNumber': '',
          'accountTitle': '',
          'openingBalance': openingBank,
          'company': AppCompanies.energy,
        });
      }

      // Seed admin user if no users exist (ADDED)
      final usersSnap = await _db.collection('users').get();
      if (usersSnap.docs.isEmpty) {
        await _db.collection('users').doc('admin').set({
          'id': 'admin',
          'name': 'Admin',
          'role': 'admin',
          'allowedScreens': [],
        });
      }
    } catch (e) {
      debugPrint('Seed skipped (offline?): $e');
    }
  }

  PaymentMethod _parsePaymentMethod(dynamic val) {
    if (val == null) return PaymentMethod.cash;
    final s = val.toString().toLowerCase();
    if (s.contains('cash')) return PaymentMethod.cash;
    if (s.contains('cheque') || s.contains('check')) return PaymentMethod.cheque;
    if (s.contains('online') || s.contains('bank')) return PaymentMethod.online;
    return PaymentMethod.cash;
  }

  BankAccount _bankFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return BankAccount(
      id: d['id']?.toString() ?? doc.id,
      name: d['name']?.toString() ?? '',
      accountNumber: d['accountNumber']?.toString() ?? '',
      accountTitle: d['accountTitle']?.toString() ?? '',
      openingBalance: (d['openingBalance'] as num?)?.toDouble() ?? 0.0,
      company: d['company']?.toString() ?? AppCompanies.energy,
    );
  }

  Map<String, dynamic> _bankToMap(BankAccount b) => {
        'id': b.id,
        'name': b.name,
        'accountNumber': b.accountNumber,
        'accountTitle': b.accountTitle,
        'openingBalance': b.openingBalance,
        'company': b.company,
      };

  Product _productFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return Product(
      id: d['id']?.toString() ?? doc.id,
      name: d['name']?.toString() ?? '',
      category: d['category']?.toString() ?? '',
      price: (d['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (d['quantity'] as num?)?.toInt() ?? 0,
      unit: d['unit']?.toString() ?? 'pcs',
      description: d['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> _productToMap(Product p) => {
        'id': p.id,
        'name': p.name,
        'category': p.category,
        'price': p.price,
        'quantity': p.quantity,
        'unit': p.unit,
        'description': p.description
      };

  Quotation _quotationFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return Quotation(
      id: d['id']?.toString() ?? doc.id,
      customerName: d['customerName']?.toString() ?? '',
      customerPhone: d['customerPhone']?.toString() ?? '',
      customerEmail: d['customerEmail']?.toString() ?? '',
      customerAddress: d['customerAddress']?.toString() ?? '',
      items: (d['items'] as List<dynamic>? ?? []).map((i) {
        final itemMap = i as Map<String, dynamic>;
        return QuotationItem(
          productId: itemMap['productId']?.toString() ?? '',
          productName: itemMap['productName']?.toString() ?? '',
          unitPrice: (itemMap['unitPrice'] as num?)?.toDouble() ?? 0.0,
          quantity: (itemMap['quantity'] as num?)?.toInt() ?? 0,
          discount: (itemMap['discount'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList(),
      createdDate: (d['createdDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: QuotationStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'draft'),
        orElse: () => QuotationStatus.draft,
      ),
      notes: d['notes']?.toString() ?? '',
      company: d['company']?.toString() ?? AppCompanies.energy,
    );
  }

  Map<String, dynamic> _quotationToMap(Quotation q) => {
        'id': q.id,
        'customerName': q.customerName,
        'customerPhone': q.customerPhone,
        'customerEmail': q.customerEmail,
        'customerAddress': q.customerAddress,
        'items': q.items
            .map((i) => {
                  'productId': i.productId,
                  'productName': i.productName,
                  'unitPrice': i.unitPrice,
                  'quantity': i.quantity,
                  'discount': i.discount
                })
            .toList(),
        'createdDate': Timestamp.fromDate(q.createdDate),
        'status': q.status.name,
        'notes': q.notes,
        'company': q.company,
      };

  SaleHistory _saleFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return SaleHistory(
      id: d['id']?.toString() ?? doc.id,
      invoiceNumber: d['invoiceNumber']?.toString() ?? '',
      customerName: d['customerName']?.toString() ?? '',
      customerPhone: d['customerPhone']?.toString() ?? '',
      customerAddress: d['customerAddress']?.toString() ?? '',
      items: (d['items'] as List<dynamic>? ?? []).map((i) {
        final itemMap = i as Map<String, dynamic>;
        return QuotationItem(
          productId: itemMap['productId']?.toString() ?? '',
          productName: itemMap['productName']?.toString() ?? '',
          unitPrice: (itemMap['unitPrice'] as num?)?.toDouble() ?? 0.0,
          quantity: (itemMap['quantity'] as num?)?.toInt() ?? 0,
          discount: (itemMap['discount'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList(),
      totalAmount: (d['totalAmount'] as num?)?.toDouble() ?? 0.0,
      payments: (d['payments'] as List<dynamic>? ?? []).map((p) {
        final pMap = p as Map<String, dynamic>;
        return PaymentReceipt(
          id: pMap['id']?.toString() ?? '',
          amount: (pMap['amount'] as num?)?.toDouble() ?? 0.0,
          date: (pMap['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          method: _parsePaymentMethod(pMap['method']),
          chequeNumber: pMap['chequeNumber']?.toString() ?? '',
          bankName: pMap['bankName']?.toString() ?? '',
          transactionId: pMap['transactionId']?.toString() ?? '',
          chequeDate: pMap['chequeDate'] != null
              ? (pMap['chequeDate'] as Timestamp).toDate()
              : null,
          logoPath: pMap['logoPath']?.toString() ?? '',
          bankId: pMap['bankId']?.toString() ?? 'default_bank',
          supplierId: pMap['supplierId']?.toString() ?? '',
          supplierName: pMap['supplierName']?.toString() ?? '',
          supplierPaymentAmount:
              (pMap['supplierPaymentAmount'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList(),
      dateOfPurchase:
          (d['dateOfPurchase'] as Timestamp?)?.toDate() ?? DateTime.now(),
      quotationId: d['quotationId']?.toString() ?? '',
      notes: d['notes']?.toString() ?? '',
      company: d['company']?.toString() ?? AppCompanies.energy,
    );
  }

  Map<String, dynamic> _saleToMap(SaleHistory s) => {
        'id': s.id,
        'invoiceNumber': s.invoiceNumber,
        'customerName': s.customerName,
        'customerPhone': s.customerPhone,
        'customerAddress': s.customerAddress,
        'items': s.items
            .map((i) => {
                  'productId': i.productId,
                  'productName': i.productName,
                  'unitPrice': i.unitPrice,
                  'quantity': i.quantity,
                  'discount': i.discount
                })
            .toList(),
        'totalAmount': s.totalAmount,
        'payments': s.payments
            .map((p) => {
                  'id': p.id,
                  'amount': p.amount,
                  'date': Timestamp.fromDate(p.date),
                  'method': p.method.name,
                  'chequeNumber': p.chequeNumber,
                  'bankName': p.bankName,
                  'transactionId': p.transactionId,
                  'chequeDate': p.chequeDate != null
                      ? Timestamp.fromDate(p.chequeDate!)
                      : null,
                  'logoPath': p.logoPath,
                  'bankId': p.bankId,
                  'supplierId': p.supplierId,
                  'supplierName': p.supplierName,
                  'supplierPaymentAmount': p.supplierPaymentAmount,
                })
            .toList(),
        'dateOfPurchase': Timestamp.fromDate(s.dateOfPurchase),
        'quotationId': s.quotationId,
        'notes': s.notes,
        'company': s.company,
      };

  Expense _expenseFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return Expense(
      id: d['id']?.toString() ?? doc.id,
      description: d['description']?.toString() ?? '',
      amount: (d['amount'] as num?)?.toDouble() ?? 0.0,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: d['category']?.toString() ?? 'General',
      paidFrom: d['paidFrom']?.toString() ?? 'cash',
      company: d['company']?.toString() ?? AppCompanies.energy,
    );
  }

  Map<String, dynamic> _expenseToMap(Expense e) => {
        'id': e.id,
        'description': e.description,
        'amount': e.amount,
        'date': Timestamp.fromDate(e.date),
        'category': e.category,
        'paidFrom': e.paidFrom,
        'company': e.company,
      };

  Employee _employeeFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return Employee(
      id: d['id']?.toString() ?? doc.id,
      name: d['name']?.toString() ?? '',
      phone: d['phone']?.toString() ?? '',
      role: d['role']?.toString() ?? '',
      baseSalary: (d['baseSalary'] as num?)?.toDouble() ?? 0.0,
      joinDate: (d['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _employeeToMap(Employee e) => {
        'id': e.id,
        'name': e.name,
        'phone': e.phone,
        'role': e.role,
        'baseSalary': e.baseSalary,
        'joinDate': Timestamp.fromDate(e.joinDate)
      };

  SalaryRecord _salaryRecordFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return SalaryRecord(
      id: d['id']?.toString() ?? doc.id,
      employeeId: d['employeeId']?.toString() ?? '',
      employeeName: d['employeeName']?.toString() ?? '',
      amount: (d['amount'] as num?)?.toDouble() ?? 0.0,
      salaryMonth: d['salaryMonth']?.toString() ?? '',
      paymentDate:
          (d['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      method: _parsePaymentMethod(d['method']),
      notes: d['notes']?.toString() ?? '',
      bankId: d['bankId']?.toString() ?? 'default_bank',
      company: d['company']?.toString() ?? AppCompanies.energy,
    );
  }

  Map<String, dynamic> _salaryRecordToMap(SalaryRecord s) => {
        'id': s.id,
        'employeeId': s.employeeId,
        'employeeName': s.employeeName,
        'amount': s.amount,
        'salaryMonth': s.salaryMonth,
        'paymentDate': Timestamp.fromDate(s.paymentDate),
        'method': s.method.name,
        'notes': s.notes,
        'bankId': s.bankId,
        'company': s.company,
      };

  QuotationTemplate _templateFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return QuotationTemplate(
      id: d['id']?.toString() ?? doc.id,
      name: d['name']?.toString() ?? '',
      items: (d['items'] as List<dynamic>? ?? []).map((i) {
        final itemMap = i as Map<String, dynamic>;
        return QuotationItem(
          productId: itemMap['productId']?.toString() ?? '',
          productName: itemMap['productName']?.toString() ?? '',
          unitPrice: (itemMap['unitPrice'] as num?)?.toDouble() ?? 0.0,
          quantity: (itemMap['quantity'] as num?)?.toInt() ?? 0,
          discount: (itemMap['discount'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList(),
      notes: d['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> _templateToMap(QuotationTemplate t) => {
        'id': t.id,
        'name': t.name,
        'items': t.items
            .map((i) => {
                  'productId': i.productId,
                  'productName': i.productName,
                  'unitPrice': i.unitPrice,
                  'quantity': i.quantity,
                  'discount': i.discount
                })
            .toList(),
        'notes': t.notes
      };

  Vendor _vendorFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return Vendor(
      id: d['id']?.toString() ?? doc.id,
      name: d['name']?.toString() ?? '',
      phone: d['phone']?.toString() ?? '',
      email: d['email']?.toString() ?? '',
      address: d['address']?.toString() ?? '',
      company: d['company']?.toString() ?? '',
      notes: d['notes']?.toString() ?? '',
      createdDate:
          (d['createdDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _vendorToMap(Vendor v) => {
        'id': v.id,
        'name': v.name,
        'phone': v.phone,
        'email': v.email,
        'address': v.address,
        'company': v.company,
        'notes': v.notes,
        'createdDate': Timestamp.fromDate(v.createdDate),
      };

  Purchase _purchaseFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return Purchase.fromMap(d);
  }

  Map<String, dynamic> _purchaseToMap(Purchase p) => p.toMap();

  PurchaseReturn _purchaseReturnFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return PurchaseReturn.fromMap(d);
  }

  CompanySettings _settingsFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final num? cashE = d['openingCashEnergy'] as num?;
    final num? cashOld = d['openingCashBalance'] as num?;
    final num? cashEl = d['openingCashElectric'] as num?;
    final num? bankOld = d['openingBankBalance'] as num?;

    return CompanySettings(
      addressLine1: d['addressLine1']?.toString() ?? '',
      addressLine2: d['addressLine2']?.toString() ?? '',
      addressLine3: d['addressLine3']?.toString() ?? '',
      phone: d['phone']?.toString() ?? '',
      openingCashEnergy: (cashE ?? cashOld ?? 46500.0).toDouble(),
      openingCashElectric: (cashEl ?? 0.0).toDouble(),
      openingBankBalance: (bankOld ?? 500000.0).toDouble(),
      logoPathEnergy: d['logoPathEnergy']?.toString() ??
          d['logoPath']?.toString() ??
          'assets/images/logo.jpeg',
      logoPathElectric: d['logoPathElectric']?.toString() ?? '',
    );
  }

  Map<String, dynamic> _settingsToMap(CompanySettings s) => {
        'addressLine1': s.addressLine1,
        'addressLine2': s.addressLine2,
        'addressLine3': s.addressLine3,
        'phone': s.phone,
        'openingCashEnergy': s.openingCashEnergy,
        'openingCashElectric': s.openingCashElectric,
        'openingBankBalance': s.openingBankBalance,
        'logoPathEnergy': s.logoPathEnergy,
        'logoPathElectric': s.logoPathElectric,
      };

  // ============ CRUD ============
  Future<void> addProduct(Product p) async =>
      await _db.collection('products').doc(p.id).set(_productToMap(p));
  Future<void> updateProduct(Product p) async =>
      await _db.collection('products').doc(p.id).set(_productToMap(p));
  Future<void> deleteProduct(String id) async =>
      await _db.collection('products').doc(id).delete();

  Future<void> addQuotation(Quotation q) async =>
      await _db.collection('quotations').doc(q.id).set(_quotationToMap(q));
  Future<void> updateQuotation(Quotation q) async =>
      await _db.collection('quotations').doc(q.id).set(_quotationToMap(q));
  Future<void> deleteQuotation(String id) async =>
      await _db.collection('quotations').doc(id).delete();

  Future<void> addSale(SaleHistory s) async =>
      await _db.collection('sales').doc(s.id).set(_saleToMap(s));
  Future<void> updateSale(SaleHistory s) async =>
      await _db.collection('sales').doc(s.id).set(_saleToMap(s));
  Future<void> deleteSale(String id) async =>
      await _db.collection('sales').doc(id).delete();

  Future<void> addExpense(Expense e) async =>
      await _db.collection('expenses').doc(e.id).set(_expenseToMap(e));
  Future<void> deleteExpense(String id) async =>
      await _db.collection('expenses').doc(id).delete();

  Future<void> addEmployee(Employee e) async =>
      await _db.collection('employees').doc(e.id).set(_employeeToMap(e));
  Future<void> updateEmployee(Employee e) async =>
      await _db.collection('employees').doc(e.id).set(_employeeToMap(e));
  Future<void> deleteEmployee(String id) async =>
      await _db.collection('employees').doc(id).delete();

  Future<void> addSalaryRecord(SalaryRecord s) async => await _db
      .collection('salaryRecords')
      .doc(s.id)
      .set(_salaryRecordToMap(s));
  Future<void> deleteSalaryRecord(String id) async =>
      await _db.collection('salaryRecords').doc(id).delete();

  Future<void> addTemplate(QuotationTemplate t) async =>
      await _db.collection('templates').doc(t.id).set(_templateToMap(t));
  Future<void> updateTemplate(QuotationTemplate t) async =>
      await _db.collection('templates').doc(t.id).set(_templateToMap(t));
  Future<void> deleteTemplate(String id) async =>
      await _db.collection('templates').doc(id).delete();

  Future<void> updateSettings(CompanySettings s) async => await _db
      .collection('settings')
      .doc('company')
      .set(_settingsToMap(s));

  Future<void> addBank(BankAccount b) async =>
      await _db.collection('banks').doc(b.id).set(_bankToMap(b));
  Future<void> updateBank(BankAccount b) async =>
      await _db.collection('banks').doc(b.id).set(_bankToMap(b));
  Future<void> deleteBank(String id) async =>
      await _db.collection('banks').doc(id).delete();

  Future<void> addVendor(Vendor v) async =>
      await _db.collection('vendors').doc(v.id).set(_vendorToMap(v));
  Future<void> updateVendor(Vendor v) async =>
      await _db.collection('vendors').doc(v.id).set(_vendorToMap(v));
  Future<void> deleteVendor(String id) async =>
      await _db.collection('vendors').doc(id).delete();

  // ============ PURCHASE CRUD ============

  Future<String> generatePurchaseNumber() async {
    final ref = _db.collection('counters').doc('purchaseCounter');
    final num = await _db.runTransaction<int>((tx) async {
      final snap = await tx.get(ref);
      final cur = snap.exists ? (snap.data()?['lastNumber'] as int? ?? 0) : 0;
      tx.set(ref, {'lastNumber': cur + 1});
      return cur + 1;
    });
    final now = DateTime.now();
    final prefix = 'PUR-${now.year}${now.month.toString().padLeft(2, '0')}';
    return '$prefix-${num.toString().padLeft(4, '0')}';
  }

  Future<void> addPurchase(Purchase p) async {
    final batch = _db.batch();

    batch.set(_db.collection('purchases').doc(p.id), _purchaseToMap(p));

    for (final item in p.items) {
      if (item.productId.isNotEmpty) {
        final existing = products.where((x) => x.id == item.productId).toList();
        if (existing.isNotEmpty) {
          final newQty = existing.first.quantity + item.quantity;
          batch.update(_db.collection('products').doc(item.productId),
              {'quantity': newQty});
        }
      }
    }

    await batch.commit();
  }

  Future<void> deletePurchase(String id) async =>
      await _db.collection('purchases').doc(id).delete();

  Future<void> processPurchaseReturn({
    required String purchaseId,
    required Map<int, int> returnQuantities,
    String paymentMethod = 'cash',
    String? bankId,
    String notes = '',
  }) async {
    final pIndex = purchases.indexWhere((p) => p.id == purchaseId);
    if (pIndex == -1) return;

    final purchase = purchases[pIndex];
    final batch = _db.batch();

    final List<PurchaseReturnItem> returnItems = [];
    final List<PurchaseItem> updatedPurchaseItems = List.from(purchase.items);
    double returnTotalAmount = 0.0;

    returnQuantities.forEach((itemIndex, qtyToReturn) {
      if (itemIndex >= 0 &&
          itemIndex < purchase.items.length &&
          qtyToReturn > 0) {
        final item = purchase.items[itemIndex];
        final maxReturnable = item.quantity - item.returnedQuantity;
        final actualReturnQty = min(qtyToReturn, maxReturnable);

        if (actualReturnQty > 0) {
          final newReturnedQty = item.returnedQuantity + actualReturnQty;
          updatedPurchaseItems[itemIndex] =
              item.copyWith(returnedQuantity: newReturnedQty);

          if (item.productId.isNotEmpty) {
            final prodIndex =
                products.indexWhere((pr) => pr.id == item.productId);
            if (prodIndex != -1) {
              final currentProd = products[prodIndex];
              final newQty = max(0, currentProd.quantity - actualReturnQty);
              batch.update(_db.collection('products').doc(item.productId),
                  {'quantity': newQty});
            }
          }

          final itemReturnTotal = actualReturnQty * item.unitPrice;
          returnTotalAmount += itemReturnTotal;

          returnItems.add(PurchaseReturnItem(
            productId: item.productId,
            productName: item.productName,
            quantity: actualReturnQty,
            unitPrice: item.unitPrice,
          ));
        }
      }
    });

    if (returnItems.isEmpty) return;

    final updatedPurchase = Purchase(
      id: purchase.id,
      vendorId: purchase.vendorId,
      vendorName: purchase.vendorName,
      items: updatedPurchaseItems,
      purchaseDate: purchase.purchaseDate,
      paymentMethod: purchase.paymentMethod,
      bankId: purchase.bankId,
      notes: purchase.notes,
      totalAmount: purchase.totalAmount,
      chequeNumber: purchase.chequeNumber,
      chequeDate: purchase.chequeDate,
      chequeBankName: purchase.chequeBankName,
      company: purchase.company,
    );
    batch.set(_db.collection('purchases').doc(purchase.id),
        _purchaseToMap(updatedPurchase));

    final returnId = _db.collection('purchase_returns').doc().id;
    final purchaseReturn = PurchaseReturn(
      id: returnId,
      purchaseId: purchase.id,
      vendorId: purchase.vendorId,
      vendorName: purchase.vendorName,
      items: returnItems,
      returnDate: DateTime.now(),
      totalAmount: returnTotalAmount,
      paymentMethod: paymentMethod,
      bankId: bankId ?? (paymentMethod == 'bank' ? purchase.bankId : null),
      company: purchase.company,
      notes: notes,
    );
    batch.set(_db.collection('purchase_returns').doc(returnId),
        purchaseReturn.toMap());

    await batch.commit();
  }

  Future<void> returnPurchase(
    String purchaseId, {
    String paymentMethod = 'cash',
    String? bankId,
  }) async {
    final pIndex = purchases.indexWhere((p) => p.id == purchaseId);
    if (pIndex == -1) return;
    final purchase = purchases[pIndex];

    final Map<int, int> returnAllMap = {};
    for (int i = 0; i < purchase.items.length; i++) {
      final rem =
          purchase.items[i].quantity - purchase.items[i].returnedQuantity;
      if (rem > 0) {
        returnAllMap[i] = rem;
      }
    }
    if (returnAllMap.isNotEmpty) {
      await processPurchaseReturn(
        purchaseId: purchaseId,
        returnQuantities: returnAllMap,
        paymentMethod: paymentMethod,
        bankId: bankId,
        notes: 'Full Return',
      );
    }
  }

  Future<void> addPurchaseItemToInventory({
    required String purchaseId,
    required int itemIndex,
    required Product newProduct,
  }) async {
    final purchase = purchases.firstWhere((p) => p.id == purchaseId);
    final batch = _db.batch();

    batch.set(_db.collection('products').doc(newProduct.id),
        _productToMap(newProduct));

    final updatedItems = List<PurchaseItem>.from(purchase.items);
    updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
      productId: newProduct.id,
      addedToInventory: true,
    );

    final updatedPurchase = Purchase(
      id: purchase.id,
      vendorId: purchase.vendorId,
      vendorName: purchase.vendorName,
      items: updatedItems,
      purchaseDate: purchase.purchaseDate,
      paymentMethod: purchase.paymentMethod,
      bankId: purchase.bankId,
      notes: purchase.notes,
      totalAmount: purchase.totalAmount,
      chequeNumber: purchase.chequeNumber,
      chequeDate: purchase.chequeDate,
      chequeBankName: purchase.chequeBankName,
      company: purchase.company,
    );

    batch.set(_db.collection('purchases').doc(purchase.id),
        _purchaseToMap(updatedPurchase));

    await batch.commit();
  }

  // ============ COUNTERS ============
  Future<String> generateInvoiceNumber() async {
    final ref = _db.collection('counters').doc('invoiceCounter');
    final num = await _db.runTransaction<int>((tx) async {
      final snap = await tx.get(ref);
      final cur =
          snap.exists ? (snap.data()?['lastNumber'] as int? ?? 1000) : 1000;
      tx.set(ref, {'lastNumber': cur + 1});
      return cur + 1;
    });
    return 'INV-$num';
  }

  Future<String> generateQuotationNumber() async {
    final ref = _db.collection('counters').doc('quotationCounter');
    final num = await _db.runTransaction<int>((tx) async {
      final snap = await tx.get(ref);
      final cur =
          snap.exists ? (snap.data()?['lastNumber'] as int? ?? 100) : 100;
      tx.set(ref, {'lastNumber': cur + 1});
      return cur + 1;
    });
    return 'QT-$num';
  }

  // ============ COMPLEX BUSINESS OPERATIONS ============

  Future<void> convertQuotationToInvoice({
    required Quotation quotation,
    required List<PaymentReceipt> payments,
    required String invoiceNumber,
    required String saleId,
    required String notes,
  }) async {
    final sale = SaleHistory(
      id: saleId,
      invoiceNumber: invoiceNumber,
      customerName: quotation.customerName,
      customerPhone: quotation.customerPhone,
      customerAddress: quotation.customerAddress,
      items: List.from(quotation.items),
      totalAmount: quotation.grandTotal,
      payments: payments,
      dateOfPurchase: DateTime.now(),
      quotationId: quotation.id,
      notes: notes,
      company: quotation.company,
    );

    final batch = _db.batch();

    batch.set(_db.collection('sales').doc(saleId), _saleToMap(sale));

    quotation.status = QuotationStatus.invoiced;
    batch.set(_db.collection('quotations').doc(quotation.id),
        _quotationToMap(quotation));

    final stockChanges = <String, int>{};
    for (final item in quotation.items) {
      stockChanges[item.productId] =
          (stockChanges[item.productId] ?? 0) + item.quantity;
    }
    for (final entry in stockChanges.entries) {
      final product = products.where((p) => p.id == entry.key).toList();
      if (product.isNotEmpty) {
        final newQty = max(0, product.first.quantity - entry.value);
        batch.update(_db.collection('products').doc(entry.key),
            {'quantity': newQty});
      }
    }
    await batch.commit();
  }

  Future<void> editConvertedQuotation({
    required Quotation oldQuotation,
    required Quotation newQuotation,
  }) async {
    final linkedSale =
        salesHistory.where((s) => s.quotationId == oldQuotation.id).toList();
    if (linkedSale.isEmpty) {
      await updateQuotation(newQuotation);
      return;
    }
    final oldInv = linkedSale.first;
    final batch = _db.batch();

    final stockDelta = <String, int>{};
    for (final oldItem in oldQuotation.items) {
      stockDelta[oldItem.productId] =
          (stockDelta[oldItem.productId] ?? 0) + oldItem.quantity;
    }
    for (final newItem in newQuotation.items) {
      stockDelta[newItem.productId] =
          (stockDelta[newItem.productId] ?? 0) - newItem.quantity;
    }
    for (final entry in stockDelta.entries) {
      final product = products.where((p) => p.id == entry.key).toList();
      if (product.isNotEmpty) {
        final newQty = max(0, product.first.quantity + entry.value);
        batch.update(_db.collection('products').doc(entry.key),
            {'quantity': newQty});
      }
    }

    final totalPaid = oldInv.payments.fold(0.0, (s, p) => s + p.amount);
    newQuotation.status = totalPaid >= newQuotation.grandTotal
        ? QuotationStatus.invoiced
        : QuotationStatus.partiallyPaid;
    batch.set(_db.collection('quotations').doc(newQuotation.id),
        _quotationToMap(newQuotation));

    final updatedInv = SaleHistory(
      id: oldInv.id,
      invoiceNumber: oldInv.invoiceNumber,
      customerName: newQuotation.customerName,
      customerPhone: newQuotation.customerPhone,
      customerAddress: newQuotation.customerAddress,
      items: List.from(newQuotation.items),
      totalAmount: newQuotation.grandTotal,
      payments: oldInv.payments,
      dateOfPurchase: oldInv.dateOfPurchase,
      quotationId: newQuotation.id,
      notes: newQuotation.notes,
      company: newQuotation.company,
    );
    batch.set(_db.collection('sales').doc(oldInv.id), _saleToMap(updatedInv));

    await batch.commit();
  }

  Future<void> addInstallmentPayment({
    required SaleHistory sale,
    required PaymentReceipt payment,
  }) async {
    final newPayments = [...sale.payments, payment];
    final updatedSale = SaleHistory(
      id: sale.id,
      invoiceNumber: sale.invoiceNumber,
      customerName: sale.customerName,
      customerPhone: sale.customerPhone,
      customerAddress: sale.customerAddress,
      items: sale.items,
      totalAmount: sale.totalAmount,
      payments: newPayments,
      dateOfPurchase: sale.dateOfPurchase,
      quotationId: sale.quotationId,
      notes: sale.notes,
      company: sale.company,
    );

    final batch = _db.batch();
    batch.set(_db.collection('sales').doc(sale.id), _saleToMap(updatedSale));

    if (sale.quotationId.isNotEmpty) {
      final totalPaid = newPayments.fold(0.0, (s, p) => s + p.amount);
      final isFullyPaid = totalPaid >= sale.totalAmount;
      batch.update(_db.collection('quotations').doc(sale.quotationId), {
        'status': isFullyPaid ? 'invoiced' : 'partiallyPaid',
      });
    }

    await batch.commit();
  }
}
