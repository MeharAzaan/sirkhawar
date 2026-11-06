import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sir_khawar_pos_updated/models/quotation.dart';

class PurchaseItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final bool addedToInventory;
  final int returnedQuantity;

  PurchaseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.addedToInventory = false,
    this.returnedQuantity = 0,
  });

  double get total => quantity * unitPrice;
  int get remainingQuantity => max(0, quantity - returnedQuantity);
  double get returnedTotal => returnedQuantity * unitPrice;
  double get remainingTotal => remainingQuantity * unitPrice;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'addedToInventory': addedToInventory,
        'returnedQuantity': returnedQuantity,
      };

  factory PurchaseItem.fromMap(Map<String, dynamic> m) => PurchaseItem(
        productId: m['productId']?.toString() ?? '',
        productName: m['productName']?.toString() ?? '',
        quantity: (m['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0.0,
        addedToInventory: m['addedToInventory'] == true,
        returnedQuantity: (m['returnedQuantity'] as num?)?.toInt() ?? 0,
      );

  PurchaseItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    bool? addedToInventory,
    int? returnedQuantity,
  }) =>
      PurchaseItem(
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        addedToInventory: addedToInventory ?? this.addedToInventory,
        returnedQuantity: returnedQuantity ?? this.returnedQuantity,
      );
}

class Purchase {
  final String id;
  final String vendorId;
  final String vendorName;
  final List<PurchaseItem> items;
  final DateTime purchaseDate;
  /// 'cash' | 'bank' | 'cheque'
  final String paymentMethod;
  final String? bankId;
  final String notes;
  final double totalAmount;
  // Cheque fields (used when paymentMethod == 'cheque')
  final String chequeNumber;
  final DateTime? chequeDate;
  final String chequeBankName;
  /// Company this purchase is paid under (energy / electric). Legacy → energy.
  final String company;

  Purchase({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.items,
    required this.purchaseDate,
    this.paymentMethod = 'cash',
    this.bankId,
    this.notes = '',
    required this.totalAmount,
    this.chequeNumber = '',
    this.chequeDate,
    this.chequeBankName = '',
    this.company = AppCompanies.energy,
  });

  int get totalReturnedQuantity =>
      items.fold(0, (sum1, i) => sum1 + i.returnedQuantity);

  int get totalOriginalQuantity =>
      items.fold(0, (sum1, i) => sum1 + i.quantity);

  double get totalReturnedAmount =>
      items.fold(0.0, (sum1, i) => sum1 + i.returnedTotal);

  bool get isFullyReturned =>
      items.isNotEmpty && items.every((i) => i.returnedQuantity >= i.quantity);

  bool get isPartiallyReturned =>
      totalReturnedQuantity > 0 && !isFullyReturned;

  Map<String, dynamic> toMap() => {
        'id': id,
        'vendorId': vendorId,
        'vendorName': vendorName,
        'items': items.map((i) => i.toMap()).toList(),
        'purchaseDate': Timestamp.fromDate(purchaseDate),
        'paymentMethod': paymentMethod,
        'bankId': bankId,
        'notes': notes,
        'totalAmount': totalAmount,
        'chequeNumber': chequeNumber,
        'chequeDate':
            chequeDate != null ? Timestamp.fromDate(chequeDate!) : null,
        'chequeBankName': chequeBankName,
        'company': company,
      };

  factory Purchase.fromMap(Map<String, dynamic> m) => Purchase(
        id: m['id']?.toString() ?? '',
        vendorId: m['vendorId']?.toString() ?? '',
        vendorName: m['vendorName']?.toString() ?? '',
        items: (m['items'] as List<dynamic>? ?? [])
            .map((e) => PurchaseItem.fromMap(e as Map<String, dynamic>))
            .toList(),
        purchaseDate:
            (m['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        paymentMethod: m['paymentMethod']?.toString() ?? 'cash',
        bankId: m['bankId']?.toString() ?? m['bankAccountId']?.toString(),
        notes: m['notes']?.toString() ?? '',
        totalAmount: (m['totalAmount'] as num?)?.toDouble() ?? 0.0,
        chequeNumber: m['chequeNumber']?.toString() ?? '',
        chequeDate: m['chequeDate'] != null
            ? (m['chequeDate'] as Timestamp).toDate()
            : null,
        chequeBankName: m['chequeBankName']?.toString() ?? '',
        company: m['company']?.toString() ?? AppCompanies.energy,
      );
}

class PurchaseReturn {
  final String id;
  final String purchaseId;
  final String vendorId;
  final String vendorName;
  final List<PurchaseReturnItem> items;
  final DateTime returnDate;
  final double totalAmount;
  final String paymentMethod;
  final String? bankId;
  final String company;
  final String notes;

  PurchaseReturn({
    required this.id,
    required this.purchaseId,
    required this.vendorId,
    required this.vendorName,
    required this.items,
    required this.returnDate,
    required this.totalAmount,
    required this.paymentMethod,
    this.bankId,
    required this.company,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'purchaseId': purchaseId,
        'vendorId': vendorId,
        'vendorName': vendorName,
        'items': items.map((i) => i.toMap()).toList(),
        'returnDate': Timestamp.fromDate(returnDate),
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'bankId': bankId,
        'company': company,
        'notes': notes,
      };

  factory PurchaseReturn.fromMap(Map<String, dynamic> m) => PurchaseReturn(
        id: m['id']?.toString() ?? '',
        purchaseId: m['purchaseId']?.toString() ?? '',
        vendorId: m['vendorId']?.toString() ?? '',
        vendorName: m['vendorName']?.toString() ?? '',
        items: (m['items'] as List<dynamic>? ?? [])
            .map((e) => PurchaseReturnItem.fromMap(e as Map<String, dynamic>))
            .toList(),
        returnDate:
            (m['returnDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        totalAmount: (m['totalAmount'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: m['paymentMethod']?.toString() ?? 'cash',
        bankId: m['bankId']?.toString() ?? m['bankAccountId']?.toString(),
        company: m['company']?.toString() ?? AppCompanies.energy,
        notes: m['notes']?.toString() ?? '',
      );
}

class PurchaseReturnItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  PurchaseReturnItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory PurchaseReturnItem.fromMap(Map<String, dynamic> m) =>
      PurchaseReturnItem(
        productId: m['productId']?.toString() ?? '',
        productName: m['productName']?.toString() ?? '',
        quantity: (m['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0.0,
      );
}