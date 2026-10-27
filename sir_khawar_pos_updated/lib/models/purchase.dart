import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final bool addedToInventory;

  PurchaseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.addedToInventory = false,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'addedToInventory': addedToInventory,
      };

  factory PurchaseItem.fromMap(Map<String, dynamic> m) => PurchaseItem(
        productId: m['productId']?.toString() ?? '',
        productName: m['productName']?.toString() ?? '',
        quantity: (m['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0.0,
        addedToInventory: m['addedToInventory'] == true,
      );

  PurchaseItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    bool? addedToInventory,
  }) =>
      PurchaseItem(
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        addedToInventory: addedToInventory ?? this.addedToInventory,
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
  });

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
        bankId: m['bankId']?.toString(),
        notes: m['notes']?.toString() ?? '',
        totalAmount: (m['totalAmount'] as num?)?.toDouble() ?? 0.0,
        chequeNumber: m['chequeNumber']?.toString() ?? '',
        chequeDate: m['chequeDate'] != null
            ? (m['chequeDate'] as Timestamp).toDate()
            : null,
        chequeBankName: m['chequeBankName']?.toString() ?? '',
      );
}