enum PaymentMethod { cash, cheque, online }

enum QuotationStatus { draft, sent, accepted, partiallyPaid, invoiced, cancelled }

/// Company keys used across the app
class AppCompanies {
  static const String energy = 'energy';
  static const String electric = 'electric';

  static const List<String> all = [energy, electric];

  static String label(String id) {
    switch (id) {
      case electric:
        return 'Alternative Electric Solutions Pvt. Ltd.';
      case energy:
      default:
        return 'Alternative Energy Solution';
    }
  }
}

class QuotationItem {
  String productId;
  String productName;
  double unitPrice;
  int quantity;
  double discount;

  QuotationItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.discount = 0,
  });

  double get total => (unitPrice * quantity) - discount;
}

class Quotation {
  String id;
  String customerName;
  String customerPhone;
  String customerEmail;
  String customerAddress;
  List<QuotationItem> items;
  DateTime createdDate;
  QuotationStatus status;
  String notes;
  /// 'energy' or 'electric' — defaults to energy for old records
  String company;

  Quotation({
    required this.id,
    required this.customerName,
    this.customerPhone = '',
    this.customerEmail = '',
    this.customerAddress = '',
    required this.items,
    required this.createdDate,
    this.status = QuotationStatus.draft,
    this.notes = '',
    this.company = AppCompanies.energy,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get tax => subtotal * 0.0;
  double get grandTotal => subtotal + tax;
}