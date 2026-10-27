import 'package:sir_khawar_pos_updated/models/quotation.dart';

class Employee {
  final String id;
  String name;
  String phone;
  String role;
  double baseSalary;
  DateTime joinDate;

  Employee({
    required this.id,
    required this.name,
    this.phone = '',
    this.role = '',
    this.baseSalary = 0.0,
    required this.joinDate,
  });
}

class SalaryRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final double amount;
  final String salaryMonth;
  final DateTime paymentDate;
  final PaymentMethod method;
  final String notes;
  final String bankId;
  final String company; // 👈 NEW: 'energy' or 'electric'

  SalaryRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.salaryMonth,
    required this.paymentDate,
    required this.method,
    this.notes = '',
    this.bankId = 'default_bank',
    this.company = AppCompanies.energy, // 👈 defaults to energy for old records
  });
}