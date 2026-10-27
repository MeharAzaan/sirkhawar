import 'package:flutter/material.dart';
import 'package:sir_khawar_pos_updated/data/app_data.dart';
import 'package:sir_khawar_pos_updated/constants/app_colors.dart';

import '../models/quotation.dart';
import '../models/quotation_template.dart';
import 'create_template_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final AppData data = AppData();

  @override
  void initState() {
    super.initState();
    data.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _deleteTemplate(QuotationTemplate t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Delete "${t.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expenseRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await data.deleteTemplate(t.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check your internet connection'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    }
  }

  /// Convert template → new draft quotation in Firestore (with company choice)
  Future<void> _convertToQuotation(QuotationTemplate t) async {
    String selectedCompany = AppCompanies.energy;

    final company = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Convert to Quotation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create a new quotation from template "${t.name}"?\n\n'
                    'Items and notes will be copied. You can add customer details afterward.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Company *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(AppCompanies.label(AppCompanies.energy)),
                    value: AppCompanies.energy,
                    groupValue: selectedCompany,
                    activeColor: AppColors.sidebarActive,
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() => selectedCompany = v);
                    },
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(AppCompanies.label(AppCompanies.electric)),
                    value: AppCompanies.electric,
                    groupValue: selectedCompany,
                    activeColor: AppColors.sidebarActive,
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() => selectedCompany = v);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sidebarActive,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, selectedCompany),
                  child: const Text('Convert'),
                ),
              ],
            );
          },
        );
      },
    );

    if (company == null) return;

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      final qtId = await data.generateQuotationNumber();

      final quotation = Quotation(
        id: qtId,
        customerName: '',
        customerPhone: '',
        customerEmail: '',
        customerAddress: '',
        items: t.items
            .map(
              (i) => QuotationItem(
                productId: i.productId,
                productName: i.productName,
                unitPrice: i.unitPrice,
                quantity: i.quantity,
                discount: i.discount,
              ),
            )
            .toList(),
        createdDate: DateTime.now(),
        status: QuotationStatus.draft,
        notes: t.notes,
        company: company,
      );

      await data.addQuotation(quotation);

      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quotation $qtId created from "${t.name}" '
              '(${AppCompanies.label(company)})',
            ),
            backgroundColor: AppColors.cashGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check your internet connection'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = data.quotationTemplates;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quotation Templates'),
        backgroundColor: AppColors.headerBg,
        foregroundColor: AppColors.cardBg,
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('New Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sidebarActive,
              foregroundColor: AppColors.cardBg,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CreateTemplateScreen()),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: templates.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined,
                      size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('No templates yet',
                      style: TextStyle(
                          fontSize: 18, color: AppColors.textSecondary)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.6,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final t = templates[index];
                final totalValue = t.items.fold(
                    0.0,
                    (sum, item) =>
                        sum +
                        (item.unitPrice * item.quantity) -
                        item.discount);
                return Card(
                  color: AppColors.cardBg,
                  elevation: 2,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateTemplateScreen(template: t),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(t.name,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CreateTemplateScreen(
                                                template: t),
                                      ),
                                    );
                                  } else if (value == 'convert') {
                                    _convertToQuotation(t);
                                  } else if (value == 'delete') {
                                    _deleteTemplate(t);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit')
                                    ]),
                                  ),
                                  const PopupMenuItem(
                                    value: 'convert',
                                    child: Row(children: [
                                      Icon(Icons.request_quote,
                                          size: 18,
                                          color: AppColors.bankBlue),
                                      SizedBox(width: 8),
                                      Text('Convert to Quotation',
                                          style: TextStyle(
                                              color: AppColors.bankBlue))
                                    ]),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(children: [
                                      Icon(Icons.delete,
                                          size: 18,
                                          color: AppColors.expenseRed),
                                      SizedBox(width: 8),
                                      Text('Delete',
                                          style: TextStyle(
                                              color:
                                                  AppColors.expenseRed))
                                    ]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (t.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(t.notes,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                          const Spacer(),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  '${t.items.length} item${t.items.length != 1 ? "s" : ""}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                              Text(
                                  'Rs. ${totalValue.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.bankBlue)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}