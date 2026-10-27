import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseItem {
  final String productId; // may be empty if not in inventory
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
        productId: m['productId'] ?? '',
        productName: m['productName'] ?? '',
        quantity: (m['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0.0,
        addedToInventory: m['addedToInventory'] ?? false,
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
  final String paymentMethod; // 'cash' / 'bank'
  final String? bankId;
  final String notes;
  final double totalAmount;

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
      };

  factory Purchase.fromMap(Map<String, dynamic> m) => Purchase(
        id: m['id'] ?? '',
        vendorId: m['vendorId'] ?? '',
        vendorName: m['vendorName'] ?? '',
        items: (m['items'] as List<dynamic>? ?? [])
            .map((e) => PurchaseItem.fromMap(e as Map<String, dynamic>))
            .toList(),
        purchaseDate: (m['purchaseDate'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        paymentMethod: m['paymentMethod'] ?? 'cash',
        bankId: m['bankId'],
        notes: m['notes'] ?? '',
        totalAmount: (m['totalAmount'] as num?)?.toDouble() ?? 0.0,
      );
}