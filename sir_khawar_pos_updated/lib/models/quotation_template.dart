import 'quotation.dart';

class QuotationTemplate {
  final String id;
  String name;
  List<QuotationItem> items;
  String notes;

  QuotationTemplate({
    required this.id,
    required this.name,
    required this.items,
    this.notes = '',
  });
}