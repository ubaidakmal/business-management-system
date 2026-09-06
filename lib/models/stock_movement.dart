class StockBalance {
  const StockBalance({
    required this.productId,
    required this.companyId,
    required this.productName,
    required this.openingStock,
    required this.reorderLevel,
    required this.movementQty,
    required this.currentStock,
    required this.isLowStock,
    required this.isActive,
    this.companyName,
    this.sku,
    this.category,
    this.unit,
  });

  final String productId;
  final String companyId;
  final String? companyName;
  final String productName;
  final String? sku;
  final String? category;
  final String? unit;
  final bool isActive;
  final double openingStock;
  final double reorderLevel;
  final double movementQty;
  final double currentStock;
  final bool isLowStock;

  factory StockBalance.fromJson(Map<String, dynamic> json) {
    return StockBalance(
      productId: json['product_id'] as String,
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String?,
      productName: json['product_name'] as String? ?? '',
      sku: json['sku'] as String?,
      category: json['category'] as String?,
      unit: json['unit'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      openingStock: _toDouble(json['opening_stock']),
      reorderLevel: _toDouble(json['reorder_level']),
      movementQty: _toDouble(json['movement_qty']),
      currentStock: _toDouble(json['current_stock']),
      isLowStock: json['is_low_stock'] as bool? ?? false,
    );
  }
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.movementType,
    required this.quantity,
    this.unitCost,
    this.referenceType,
    this.referenceId,
    this.referenceItemId,
    this.reason,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String productId;
  final String movementType;
  final double quantity;
  final double? unitCost;
  final String? referenceType;
  final String? referenceId;
  final String? referenceItemId;
  final String? reason;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;

  String get typeLabel => switch (movementType) {
    'purchase' => 'Purchase',
    'sale' => 'Sale',
    'purchase_reversal' => 'Purchase reversal',
    'sale_reversal' => 'Sale reversal',
    'adjustment_in' => 'Adjustment in',
    'adjustment_out' => 'Adjustment out',
    _ => movementType,
  };

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      movementType: json['movement_type'] as String? ?? '',
      quantity: _toDouble(json['quantity']),
      unitCost: json['unit_cost'] == null ? null : _toDouble(json['unit_cost']),
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      referenceItemId: json['reference_item_id'] as String?,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
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
