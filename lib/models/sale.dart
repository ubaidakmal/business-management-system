class SaleItem {
  const SaleItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.id,
    this.saleId,
    this.productName,
    this.productSku,
    this.productUnit,
    this.createdAt,
  });

  final String? id;
  final String? saleId;
  final String productId;
  final String? productName;
  final String? productSku;
  final String? productUnit;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final DateTime? createdAt;

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    final product = json['products'];
    String? productName;
    String? productSku;
    String? productUnit;
    if (product is Map<String, dynamic>) {
      productName = product['name'] as String?;
      productSku = product['sku'] as String?;
      productUnit = product['unit'] as String?;
    }

    return SaleItem(
      id: json['id'] as String?,
      saleId: json['sale_id'] as String?,
      productId: json['product_id'] as String,
      productName: productName,
      productSku: productSku,
      productUnit: productUnit,
      quantity: _toDouble(json['quantity']),
      unitPrice: _toDouble(json['unit_price']),
      lineTotal: _toDouble(json['line_total']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toRpcJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }
}

class Sale {
  const Sale({
    required this.id,
    required this.companyId,
    required this.saleDate,
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
  final DateTime saleDate;
  final String? invoiceNumber;
  final String? referenceNumber;
  final String? notes;
  final double subtotal;
  final double discount;
  final double otherCharges;
  final double totalAmount;
  final String status;
  final int itemCount;
  final List<SaleItem> items;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDraft => status == 'draft';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get canEdit => isDraft;
  bool get canCancel => !isCancelled;

  factory Sale.fromJson(Map<String, dynamic> json) {
    final company = json['companies'];
    String? companyName;
    if (company is Map<String, dynamic>) {
      companyName = company['name'] as String?;
    }

    final rawItems = json['sale_items'];
    final items = <SaleItem>[];
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
            items.add(SaleItem.fromJson(row));
          }
        }
      }
      if (items.isNotEmpty) itemCount = items.length;
    }

    return Sale(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      companyName: companyName,
      saleDate: _parseDate(json['sale_date']) ?? DateTime.now(),
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

abstract final class SaleMath {
  static double roundMoney(num value) =>
      double.parse(value.toDouble().toStringAsFixed(2));

  static double lineTotal({required num quantity, required num unitPrice}) {
    return roundMoney(quantity * unitPrice);
  }

  static double subtotal(Iterable<SaleItem> items) {
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
