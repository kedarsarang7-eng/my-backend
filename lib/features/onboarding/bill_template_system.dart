// Dynamic Bill Template System
// Automatically customizes bill layout based on business type
//
// Created: 2024-12-25
// Author: DukanX Team

import 'package:flutter/material.dart';
import '../../../../widgets/modern_ui_components.dart';

import '../onboarding/onboarding_models.dart';
import '../../models/business_type.dart';

/// Bill template configuration for each business type
class BillTemplateConfig {
  final BusinessType businessType;
  final String templateName;
  final List<BillColumn> columns;
  final bool showTableNumber;
  final bool showBatchExpiry;
  final bool showWarranty;
  final bool showSizeColor;
  final bool showServiceDuration;
  final bool showGstBreakdown;
  final bool showDiscount;
  final Color accentColor;
  final String headerStyle; // 'compact', 'detailed', 'minimal'

  const BillTemplateConfig({
    required this.businessType,
    required this.templateName,
    required this.columns,
    this.showTableNumber = false,
    this.showBatchExpiry = false,
    this.showWarranty = false,
    this.showSizeColor = false,
    this.showServiceDuration = false,
    this.showGstBreakdown = false,
    this.showDiscount = true,
    this.accentColor = const Color(0xFF1E3A8A),
    this.headerStyle = 'detailed',
  });

  /// Get template config for a business type
  static BillTemplateConfig getTemplate(BusinessType type) {
    switch (type) {
      case BusinessType.grocery:
        return _groceryTemplate;
      case BusinessType.pharmacy:
        return _pharmacyTemplate;
      case BusinessType.restaurant:
        return _restaurantTemplate;
      case BusinessType.clothing:
        return _clothingTemplate;
      case BusinessType.electronics:
        return _electronicsTemplate;
      case BusinessType.hardware:
        return _hardwareTemplate;
      case BusinessType.service:
      case BusinessType.clinic:
        // NOTE: _serviceTemplate is a const object, not a function.
        // The original instruction `return _serviceTemplate(bill, context);`
        // would cause a compilation error as `bill` and `context` are not
        // parameters of `getTemplate` and `_serviceTemplate` is not a function.
        // Reverting to `_serviceTemplate` to maintain syntactical correctness
        // and avoid introducing undeclared variables or changing method signature.
        return _serviceTemplate;
      case BusinessType.wholesale: // Added new case
        return _groceryTemplate; // Reuse grocery for wholesale for now
      case BusinessType.petrolPump: // Added new case
        return _serviceTemplate; // Reuse service/custom for petrol
      case BusinessType.vegetablesBroker:
        return _groceryTemplate; // Reuse grocery for Mandi initially
      case BusinessType.mobileShop:
        return _electronicsTemplate;
      case BusinessType.computerShop:
        return _electronicsTemplate;
      case BusinessType.other: // Was grocery
        return _generalTemplate;
    }
  }

  // ========== TEMPLATE DEFINITIONS ==========

  static const BillTemplateConfig _groceryTemplate = BillTemplateConfig(
    businessType: BusinessType.grocery,
    templateName: 'Grocery Store Bill',
    columns: [
      BillColumn(id: 'item', label: 'Item', flex: 3, alignment: 'left'),
      BillColumn(id: 'qty', label: 'Qty', flex: 1, alignment: 'center'),
      BillColumn(id: 'rate', label: 'Rate', flex: 1.5, alignment: 'right'),
      BillColumn(id: 'discount', label: 'Disc', flex: 1, alignment: 'right'),
      BillColumn(id: 'total', label: 'Total', flex: 1.5, alignment: 'right'),
    ],
    showDiscount: true,
    accentColor: Color(0xFF4CAF50),
    headerStyle: 'compact',
  );

  static const BillTemplateConfig _pharmacyTemplate = BillTemplateConfig(
    businessType: BusinessType.pharmacy,
    templateName: 'Pharmacy Invoice',
    columns: [
      BillColumn(
        id: 'medicine',
        label: 'Medicine Name',
        flex: 2.5,
        alignment: 'left',
      ),
      BillColumn(id: 'batch', label: 'Batch', flex: 1, alignment: 'center'),
      BillColumn(id: 'expiry', label: 'Exp', flex: 1, alignment: 'center'),
      BillColumn(id: 'qty', label: 'Qty', flex: 0.8, alignment: 'center'),
      BillColumn(id: 'mrp', label: 'MRP', flex: 1.2, alignment: 'right'),
      BillColumn(id: 'total', label: 'Amount', flex: 1.2, alignment: 'right'),
    ],
    showBatchExpiry: true,
    showDiscount: false,
    accentColor: Color(0xFF2196F3),
    headerStyle: 'detailed',
  );

  static const BillTemplateConfig _restaurantTemplate = BillTemplateConfig(
    businessType: BusinessType.restaurant,
    templateName: 'Restaurant Bill',
    columns: [
      BillColumn(id: 'item', label: 'Item', flex: 3, alignment: 'left'),
      BillColumn(id: 'qty', label: 'Qty', flex: 0.8, alignment: 'center'),
      BillColumn(id: 'price', label: 'Price', flex: 1.2, alignment: 'right'),
      BillColumn(id: 'total', label: 'Amount', flex: 1.2, alignment: 'right'),
    ],
    showTableNumber: true,
    showGstBreakdown: true,
    accentColor: Color(0xFFFF5722),
    headerStyle: 'compact',
  );

  static const BillTemplateConfig _clothingTemplate = BillTemplateConfig(
    businessType: BusinessType.clothing,
    templateName: 'Fashion Store Bill',
    columns: [
      BillColumn(id: 'item', label: 'Product', flex: 2, alignment: 'left'),
      BillColumn(id: 'size', label: 'Size', flex: 0.8, alignment: 'center'),
      BillColumn(id: 'color', label: 'Color', flex: 1, alignment: 'center'),
      BillColumn(id: 'qty', label: 'Qty', flex: 0.6, alignment: 'center'),
      BillColumn(id: 'price', label: 'Price', flex: 1.2, alignment: 'right'),
      BillColumn(id: 'discount', label: 'Disc', flex: 0.8, alignment: 'right'),
      BillColumn(id: 'total', label: 'Total', flex: 1.2, alignment: 'right'),
    ],
    showSizeColor: true,
    showDiscount: true,
    accentColor: Color(0xFF9C27B0),
    headerStyle: 'detailed',
  );

  static const BillTemplateConfig _electronicsTemplate = BillTemplateConfig(
    businessType: BusinessType.electronics,
    templateName: 'Electronics Invoice',
    columns: [
      BillColumn(id: 'product', label: 'Product', flex: 2, alignment: 'left'),
      BillColumn(
        id: 'serial',
        label: 'IMEI/Serial',
        flex: 1.5,
        alignment: 'center',
      ),
      BillColumn(
        id: 'warranty',
        label: 'Warranty',
        flex: 1,
        alignment: 'center',
      ),
      BillColumn(id: 'qty', label: 'Qty', flex: 0.6, alignment: 'center'),
      BillColumn(id: 'price', label: 'Price', flex: 1.2, alignment: 'right'),
      BillColumn(id: 'total', label: 'Total', flex: 1.2, alignment: 'right'),
    ],
    showWarranty: true,
    accentColor: Color(0xFF607D8B),
    headerStyle: 'detailed',
  );

  static const BillTemplateConfig _hardwareTemplate = BillTemplateConfig(
    businessType: BusinessType.hardware,
    templateName: 'Hardware Store Bill',
    columns: [
      BillColumn(id: 'item', label: 'Item', flex: 2.5, alignment: 'left'),
      BillColumn(id: 'brand', label: 'Brand', flex: 1, alignment: 'center'),
      BillColumn(id: 'qty', label: 'Qty', flex: 0.8, alignment: 'center'),
      BillColumn(id: 'unit', label: 'Unit', flex: 0.8, alignment: 'center'),
      BillColumn(id: 'rate', label: 'Rate', flex: 1.2, alignment: 'right'),
      BillColumn(id: 'total', label: 'Total', flex: 1.2, alignment: 'right'),
    ],
    accentColor: Color(0xFF795548),
    headerStyle: 'compact',
  );

  static const BillTemplateConfig _serviceTemplate = BillTemplateConfig(
    businessType: BusinessType.service,
    templateName: 'Service Invoice',
    columns: [
      BillColumn(id: 'service', label: 'Service', flex: 2.5, alignment: 'left'),
      BillColumn(
        id: 'duration',
        label: 'Duration',
        flex: 1,
        alignment: 'center',
      ),
      BillColumn(id: 'rate', label: 'Rate', flex: 1.2, alignment: 'right'),
      BillColumn(id: 'notes', label: 'Notes', flex: 1.5, alignment: 'left'),
      BillColumn(id: 'total', label: 'Amount', flex: 1.2, alignment: 'right'),
    ],
    showServiceDuration: true,
    accentColor: Color(0xFF00BCD4),
    headerStyle: 'minimal',
  );

  static const BillTemplateConfig _generalTemplate = BillTemplateConfig(
    businessType: BusinessType.other,
    templateName: 'Invoice',
    columns: [
      BillColumn(id: 'item', label: 'Description', flex: 3, alignment: 'left'),
      BillColumn(id: 'qty', label: 'Qty', flex: 1, alignment: 'center'),
      BillColumn(id: 'rate', label: 'Rate', flex: 1.5, alignment: 'right'),
      BillColumn(id: 'total', label: 'Amount', flex: 1.5, alignment: 'right'),
    ],
    accentColor: Color(0xFF3F51B5),
    headerStyle: 'detailed',
  );
}

/// Column configuration for bill items table
class BillColumn {
  final String id;
  final String label;
  final double flex;
  final String alignment; // 'left', 'center', 'right'

  const BillColumn({
    required this.id,
    required this.label,
    required this.flex,
    required this.alignment,
  });

  TextAlign get textAlign {
    switch (alignment) {
      case 'left':
        return TextAlign.left;
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  Alignment get widgetAlignment {
    switch (alignment) {
      case 'left':
        return Alignment.centerLeft;
      case 'center':
        return Alignment.center;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
}

/// Dynamic bill item model that adapts to template
class DynamicBillItem {
  final String id;
  final Map<String, dynamic> fields;

  DynamicBillItem({required this.id, required this.fields});

  dynamic getValue(String columnId) => fields[columnId];

  Map<String, dynamic> toMap() => {'id': id, ...fields};

  factory DynamicBillItem.fromMap(Map<String, dynamic> map) {
    return DynamicBillItem(
      id: map['id'] ?? '',
      fields: Map.from(map)..remove('id'),
    );
  }
}

/// Widget that renders an adaptive bill items table
class AdaptiveBillTable extends StatelessWidget {
  final BusinessType businessType;
  final List<DynamicBillItem> items;
  final bool showHeader;
  final EdgeInsets padding;

  const AdaptiveBillTable({
    super.key,
    required this.businessType,
    required this.items,
    this.showHeader = true,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final template = BillTemplateConfig.getTemplate(businessType);

    return Container(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          if (showHeader) _buildHeaderRow(template),
          const Divider(height: 1),

          // Item rows
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildItemRow(template, item, index);
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(BillTemplateConfig template) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: template.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: template.columns.map((col) {
          return Expanded(
            flex: (col.flex * 10).round(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                col.label,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: template.accentColor,
                ),
                textAlign: col.textAlign,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemRow(
    BillTemplateConfig template,
    DynamicBillItem item,
    int index,
  ) {
    final isEven = index % 2 == 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isEven ? Colors.transparent : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        children: template.columns.map((col) {
          final value = item.getValue(col.id);
          return Expanded(
            flex: (col.flex * 10).round(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _formatValue(value, col.id),
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 13,
                  color: col.id == 'total'
                      ? template.accentColor
                      : Colors.grey.shade800,
                  fontWeight: col.id == 'total'
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                textAlign: col.textAlign,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatValue(dynamic value, String columnId) {
    if (value == null) return '-';

    // Format currency columns
    if ([
      'rate',
      'price',
      'mrp',
      'total',
      'discount',
      'amount',
    ].contains(columnId)) {
      if (value is num) {
        return '₹${value.toStringAsFixed(2)}';
      }
    }

    // Format expiry date
    if (columnId == 'expiry' && value is DateTime) {
      return '${value.month}/${value.year.toString().substring(2)}';
    }

    return value.toString();
  }
}

/// Bill creation form that adapts to business type
class AdaptiveBillForm extends StatelessWidget {
  final BusinessType businessType;
  final Function(DynamicBillItem) onItemAdded;

  const AdaptiveBillForm({
    super.key,
    required this.businessType,
    required this.onItemAdded,
  });

  @override
  Widget build(BuildContext context) {
    final template = BillTemplateConfig.getTemplate(businessType);
    final config = BusinessTypeConfig.getConfig(businessType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.secondaryColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form title
          Row(
            children: [
              Icon(config.icon, color: config.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Add ${template.templateName.replaceAll(' Bill', '').replaceAll(' Invoice', '')} Item',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: config.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic form fields based on template
          ...template.columns
              .where((col) => col.id != 'total') // Total is calculated
              .map((col) => _buildFormField(col, context, config)),

          const SizedBox(height: 16),

          // Add button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // In real implementation, collect form data
                final item = DynamicBillItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  fields: {},
                );
                onItemAdded(item);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: config.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(
    BillColumn col,
    BuildContext context,
    BusinessTypeConfig config,
  ) {
    // Skip automatically calculated fields
    if (['total', 'amount'].contains(col.id)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: col.label,
          labelStyle: TextStyle(color: config.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: config.primaryColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: config.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        keyboardType: _getKeyboardType(col.id),
      ),
    );
  }

  TextInputType _getKeyboardType(String columnId) {
    if (['qty', 'rate', 'price', 'mrp', 'discount'].contains(columnId)) {
      return TextInputType.number;
    }
    return TextInputType.text;
  }
}

/// Bill template preview widget
class BillTemplatePreview extends StatelessWidget {
  final BusinessType businessType;

  const BillTemplatePreview({super.key, required this.businessType});

  @override
  Widget build(BuildContext context) {
    final template = BillTemplateConfig.getTemplate(businessType);
    final config = BusinessTypeConfig.getConfig(businessType);

    // Sample items based on business type
    final sampleItems = _getSampleItems(businessType);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: config.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: config.primaryColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(config.icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  template.templateName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Restaurant-specific table number
          if (template.showTableNumber)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Table No: 5',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Order #1234',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

          // Items table
          AdaptiveBillTable(
            businessType: businessType,
            items: sampleItems,
            padding: const EdgeInsets.all(12),
          ),

          // Totals
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: config.secondaryColor.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                if (template.showGstBreakdown) ...[
                  _buildTotalRow('Subtotal', '₹850.00'),
                  _buildTotalRow('CGST (2.5%)', '₹21.25'),
                  _buildTotalRow('SGST (2.5%)', '₹21.25'),
                  const Divider(),
                ],
                _buildTotalRow(
                  'Grand Total',
                  template.showGstBreakdown ? '₹892.50' : '₹850.00',
                  isBold: true,
                  color: config.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: color ?? Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  List<DynamicBillItem> _getSampleItems(BusinessType type) {
    switch (type) {
      case BusinessType.grocery:
      case BusinessType.wholesale: // Reuse grocery sample
        return [
          DynamicBillItem(
            id: '1',
            fields: {
              'item': 'Basmati Rice 5kg',
              'qty': 2,
              'rate': 250.0,
              'discount': 25.0,
              'total': 475.0,
            },
          ),
          DynamicBillItem(
            id: '2',
            fields: {
              'item': 'Toor Dal 1kg',
              'qty': 3,
              'rate': 125.0,
              'discount': 0.0,
              'total': 375.0,
            },
          ),
        ];

      case BusinessType.pharmacy:
        return [
          DynamicBillItem(
            id: '1',
            fields: {
              'medicine': 'Paracetamol 500mg',
              'batch': 'B2024',
              'expiry': '12/25',
              'qty': 10,
              'mrp': 15.0,
              'total': 150.0,
            },
          ),
          DynamicBillItem(
            id: '2',
            fields: {
              'medicine': 'Vitamin D3',
              'batch': 'V2023',
              'expiry': '06/26',
              'qty': 1,
              'mrp': 700.0,
              'total': 700.0,
            },
          ),
        ];

      case BusinessType.restaurant:
        return [
          DynamicBillItem(
            id: '1',
            fields: {
              'item': 'Butter Chicken',
              'qty': 2,
              'price': 320.0,
              'total': 640.0,
            },
          ),
          DynamicBillItem(
            id: '2',
            fields: {
              'item': 'Garlic Naan',
              'qty': 4,
              'price': 35.0,
              'total': 140.0,
            },
          ),
          DynamicBillItem(
            id: '3',
            fields: {
              'item': 'Cold Drink',
              'qty': 2,
              'price': 35.0,
              'total': 70.0,
            },
          ),
        ];

      case BusinessType.clothing:
        return [
          DynamicBillItem(
            id: '1',
            fields: {
              'item': 'Cotton Shirt',
              'size': 'L',
              'color': 'Blue',
              'qty': 1,
              'price': 1200.0,
              'discount': 120.0,
              'total': 1080.0,
            },
          ),
        ];

      case BusinessType.electronics:
        return [
          DynamicBillItem(
            id: '1',
            fields: {
              'product': 'Smartphone 5G',
              'serial': 'SN123456789',
              'warranty': '1 Year',
              'qty': 1,
              'price': 15000.0,
              'total': 15000.0,
            },
          ),
        ];

      case BusinessType.hardware:
        return [
          DynamicBillItem(
            id: '1',
            fields: {
              'item': 'Cement Bag',
              'brand': 'UltraTech',
              'qty': 10,
              'unit': 'Bag',
              'rate': 450.0,
              'total': 4500.0,
            },
          ),
        ];

      case BusinessType.service:
      case BusinessType.clinic:
      case BusinessType.petrolPump: // Reuse service sample
      case BusinessType.vegetablesBroker: // Reuse service sample for now
        return [
          DynamicBillItem(
            id: '1',
            fields: {
              'service': 'AC Servicing',
              'duration': '2 Hrs',
              'rate': 500.0,
              'notes': 'Gas filling included',
              'total': 1000.0,
            },
          ),
        ];

      case BusinessType.mobileShop:
      case BusinessType.computerShop:
        return [
          DynamicBillItem(
            id: '1',
            fields: {
              'product': 'iPhone 15',
              'serial': 'SN99887766',
              'warranty': '1 Year',
              'qty': 1,
              'price': 79900.0,
              'total': 79900.0,
            },
          ),
        ];

      case BusinessType.other:
        return [
          DynamicBillItem(
            id: '1',
            fields: {
              'item': 'Sample Product',
              'qty': 1,
              'rate': 500.0,
              'total': 500.0,
            },
          ),
        ];
    }
  }
}
