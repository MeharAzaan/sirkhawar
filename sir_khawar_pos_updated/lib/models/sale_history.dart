import 'quotation.dart';

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
final String bankId; // 👈 which of YOUR banks received this payment

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
});
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
final String company; // 👈 NEW: 'energy' or 'electric'

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
this.company = AppCompanies.energy, // 👈 defaults to energy for old records
});

double get paidAmount => payments.fold(0, (sum, p) => sum + p.amount);
double get remainingAmount => totalAmount - paidAmount;
bool get isFullyPaid => remainingAmount <= 0;
}