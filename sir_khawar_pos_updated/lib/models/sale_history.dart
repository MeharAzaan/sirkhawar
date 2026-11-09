import 'package:sir_khawar_pos_updated/models/quotation.dart';

class PaymentReceipt {
  final String id;
  final String logoPath;
  final double amount;
  final DateTime date;
  final PaymentMethod method;
  final String chequeNumber;
  final String bankName; // customer's cheque bank (existing, unchanged)
  final String transactionId;
  final DateTime? chequeDate;
  final String bankId; // which of YOUR banks received this payment

  /// Direct portion paid to a supplier from this customer payment.
  /// Invoice still credits [amount] in full; cash/bank only receive [netToBusiness].
  final String supplierId;
  final String supplierName;
  final double supplierPaymentAmount;
  final String supplierNote; // Note for the vendor ledger

  PaymentReceipt({
    required this.id,
    required this.amount,
    required this.date,
    required this.method,
    this.chequeNumber = '',
    this.bankName = '',
    this.transactionId = '',
    this.chequeDate,
    this.logoPath = '',
    this.bankId = 'default_bank',
    this.supplierId = '',
    this.supplierName = '',
    this.supplierPaymentAmount = 0.0,
    this.supplierNote = '',
  });

  /// Amount that actually lands in business cash/bank.
  double get netToBusiness {
    final net = amount - supplierPaymentAmount;
    return net < 0 ? 0.0 : net;
  }

  bool get hasSupplierDirectPayment =>
      supplierPaymentAmount > 0 && supplierName.trim().isNotEmpty;
}

class SaleHistory {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final List<QuotationItem> items;
  final double totalAmount;
  final List<PaymentReceipt> payments;
  final DateTime dateOfPurchase;
  final String quotationId;
  final String notes;
  final String company; // 'energy' or 'electric'

  SaleHistory({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.items,
    required this.totalAmount,
    required this.payments,
    required this.dateOfPurchase,
    this.quotationId = '',
    this.notes = '',
    this.company = AppCompanies.energy,
  });

  double get paidAmount => payments.fold(0, (sum, p) => sum + p.amount);
  double get remainingAmount => totalAmount - paidAmount;
  bool get isFullyPaid => remainingAmount <= 0;
}