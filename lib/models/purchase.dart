class PurchaseItem {
  const PurchaseItem({
    required this.productId,
    required this.quantity,
    required this.unitCost,
    required this.lineTotal,
    this.id,
    this.purchaseId,
    this.productName,
    this.productSku,
    this.productUnit,
    this.createdAt,
  });

  final String? id;
  final String? purchaseId;
  final String productId;
  final String? productName;
  final String? productSku;
  final String? productUnit;
  final double quantity;
  final double unitCost;
  final double lineTotal;
  final DateTime? createdAt;

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    final product = json['products'];
    String? productName;
    String? productSku;
    String? productUnit;
    if (product is Map<String, dynamic>) {
      productName = product['name'] as String?;
      productSku = product['sku'] as String?;
      productUnit = product['unit'] as String?;
    }

    return PurchaseItem(
      id: json['id'] as String?,
      purchaseId: json['purchase_id'] as String?,
      productId: json['product_id'] as String,
      productName: productName,
      productSku: productSku,
      productUnit: productUnit,
      quantity: _toDouble(json['quantity']),
      unitCost: _toDouble(json['unit_cost']),
      lineTotal: _toDouble(json['line_total']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toRpcJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'unit_cost': unitCost,
    };
  }

  PurchaseItem copyWith({
    String? id,
    String? purchaseId,
    String? productId,
    String? productName,
    String? productSku,
    String? productUnit,
    double? quantity,
    double? unitCost,
    double? lineTotal,
    DateTime? createdAt,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      productUnit: productUnit ?? this.productUnit,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      lineTotal: lineTotal ?? this.lineTotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Purchase {
  const Purchase({
    required this.id,
    required this.companyId,
    required this.purchaseDate,
    required this.subtotal,
    required this.discount,
    required this.otherCharges,
    required this.totalAmount,
    required this.status,
    this.companyName,
    this.invoiceNumber,
    this.referenceNumber,
    this.notes,
    this.itemCount = 0,
    this.items = const [],
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String companyId;
  final String? companyName;
  final DateTime purchaseDate;
  final String? invoiceNumber;
  final String? referenceNumber;
  final String? notes;
  final double subtotal;
  final double discount;
  final double otherCharges;
  final double totalAmount;
  final String status;
  final int itemCount;
  final List<PurchaseItem> items;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDraft => status == 'draft';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get canEdit => isDraft;
  bool get canCancel => !isCancelled;

  factory Purchase.fromJson(Map<String, dynamic> json) {
    final company = json['companies'];
    String? companyName;
    if (company is Map<String, dynamic>) {
      companyName = company['name'] as String?;
    }

    final rawItems = json['purchase_items'];
    final items = <PurchaseItem>[];
    var itemCount = 0;

    if (rawItems is List) {
      for (final row in rawItems) {
        if (row is Map<String, dynamic>) {
          if (row.containsKey('count')) {
            final count = row['count'];
            if (count is int) {
              itemCount = count;
            } else if (count is num) {
              itemCount = count.toInt();
            }
          } else {
            items.add(PurchaseItem.fromJson(row));
          }
        }
      }
      if (items.isNotEmpty) itemCount = items.length;
    }

    return Purchase(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      companyName: companyName,
      purchaseDate: _parseDate(json['purchase_date']) ?? DateTime.now(),
      invoiceNumber: json['invoice_number'] as String?,
      referenceNumber: json['reference_number'] as String?,
      notes: json['notes'] as String?,
      subtotal: _toDouble(json['subtotal']),
      discount: _toDouble(json['discount']),
      otherCharges: _toDouble(json['other_charges']),
      totalAmount: _toDouble(json['total_amount']),
      status: json['status'] as String? ?? 'draft',
      itemCount: itemCount,
      items: items,
      createdBy: json['created_by'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}

abstract final class PurchaseMath {
  static double roundMoney(num value) =>
      double.parse(value.toDouble().toStringAsFixed(2));

  static double lineTotal({required num quantity, required num unitCost}) {
    return roundMoney(quantity * unitCost);
  }

  static double subtotal(Iterable<PurchaseItem> items) {
    var total = 0.0;
    for (final item in items) {
      total += item.lineTotal;
    }
    return roundMoney(total);
  }

  static double grandTotal({
    required num subtotal,
    required num discount,
    required num otherCharges,
  }) {
    return roundMoney(subtotal - discount + otherCharges);
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
