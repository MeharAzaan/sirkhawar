import 'package:cloud_firestore/cloud_firestore.dart';

class Vendor {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String company; // vendor's company name (not our company)
  final String notes;
  final DateTime createdDate;

  Vendor({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.company = '',
    this.notes = '',
    required this.createdDate,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'company': company,
        'notes': notes,
        'createdDate': Timestamp.fromDate(createdDate),
      };

  factory Vendor.fromMap(Map<String, dynamic> m) => Vendor(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        phone: m['phone'] ?? '',
        email: m['email'] ?? '',
        address: m['address'] ?? '',
        company: m['company'] ?? '',
        notes: m['notes'] ?? '',
        createdDate: (m['createdDate'] as Timestamp?)?.toDate() ??
            DateTime.now(),
      );
}