import 'quotation.dart'; // for AppCompanies

class BankAccount {
  final String id;
  String name;
  String accountNumber;
  String accountTitle;
  double openingBalance;
  /// 'energy' or 'electric'
  String company;

  BankAccount({
    required this.id,
    required this.name,
    this.accountNumber = '',
    this.accountTitle = '',
    this.openingBalance = 0.0,
    this.company = AppCompanies.energy,
  });
}