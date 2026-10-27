import 'quotation.dart'; // for AppCompanies

class Expense {
  String id;
  String description;
  double amount;
  DateTime date;
  String category;
  String paidFrom; // 'cash' or bank id
  /// 'energy' or 'electric'
  String company;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.category = 'General',
    this.paidFrom = 'cash',
    this.company = AppCompanies.energy,
  });
}