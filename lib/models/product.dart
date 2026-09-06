class Product {
  const Product({
    required this.id,
    required this.companyId,
    required this.name,
    this.companyName,
    this.sku,
    this.barcode,
    this.category,
    this.unit,
    this.description,
    this.purchasePrice = 0,
    this.salePrice = 0,
    this.openingStock = 0,
    this.openingUnitCost = 0,
    this.reorderLevel = 0,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String companyId;
  final String? companyName;
  final String name;
  final String? sku;
  final String? barcode;
  final String? category;
  final String? unit;
  final String? description;
  final double purchasePrice;
  final double salePrice;
  final double openingStock;
  final double openingUnitCost;
  final double reorderLevel;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Product.fromJson(Map<String, dynamic> json) {
    final company = json['companies'];
    String? companyName;
    if (company is Map<String, dynamic>) {
      companyName = company['name'] as String?;
    }

    return Product(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      companyName: companyName,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      category: json['category'] as String?,
      unit: json['unit'] as String?,
      description: json['description'] as String?,
      purchasePrice: _toDouble(json['purchase_price']),
      salePrice: _toDouble(json['sale_price']),
      openingStock: _toDouble(json['opening_stock']),
      openingUnitCost: _toDouble(json['opening_unit_cost']),
      reorderLevel: _toDouble(json['reorder_level']),
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    return {
      if (includeId) 'id': id,
      'company_id': companyId,
      'name': name.trim(),
      'sku': _emptyToNull(sku),
      'barcode': _emptyToNull(barcode),
      'category': _emptyToNull(category),
      'unit': _emptyToNull(unit),
      'description': _emptyToNull(description),
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'opening_stock': openingStock,
      'opening_unit_cost': openingUnitCost,
      'reorder_level': reorderLevel,
      'is_active': isActive,
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime? _parseDate(Object? value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

String? _emptyToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
