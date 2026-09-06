class DashboardSummary {
  const DashboardSummary({
    required this.salesTotal,
    required this.purchasesTotal,
    required this.revenue,
    required this.totalCogs,
    required this.totalProfit,
    required this.salesCount,
    required this.purchasesCount,
  });

  final double salesTotal;
  final double purchasesTotal;
  final double revenue;
  final double totalCogs;
  final double totalProfit;
  final int salesCount;
  final int purchasesCount;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      salesTotal: _toDouble(json['sales_total']),
      purchasesTotal: _toDouble(json['purchases_total']),
      revenue: _toDouble(json['revenue']),
      totalCogs: _toDouble(json['total_cogs']),
      totalProfit: _toDouble(json['total_profit']),
      salesCount: _toInt(json['sales_count']),
      purchasesCount: _toInt(json['purchases_count']),
    );
  }

  static const empty = DashboardSummary(
    salesTotal: 0,
    purchasesTotal: 0,
    revenue: 0,
    totalCogs: 0,
    totalProfit: 0,
    salesCount: 0,
    purchasesCount: 0,
  );
}

class DashboardRecentSale {
  const DashboardRecentSale({
    required this.id,
    required this.totalAmount,
    required this.totalProfit,
    required this.saleDate,
    this.invoiceNumber,
    this.companyName,
  });

  final String id;
  final String? invoiceNumber;
  final String? companyName;
  final double totalAmount;
  final double totalProfit;
  final DateTime saleDate;

  factory DashboardRecentSale.fromJson(Map<String, dynamic> json) {
    return DashboardRecentSale(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String?,
      companyName: json['company_name'] as String?,
      totalAmount: _toDouble(json['total_amount']),
      totalProfit: _toDouble(json['total_profit']),
      saleDate: _parseDate(json['sale_date']) ?? DateTime.now(),
    );
  }
}

class DashboardRecentPurchase {
  const DashboardRecentPurchase({
    required this.id,
    required this.totalAmount,
    required this.purchaseDate,
    this.invoiceNumber,
    this.companyName,
  });

  final String id;
  final String? invoiceNumber;
  final String? companyName;
  final double totalAmount;
  final DateTime purchaseDate;

  factory DashboardRecentPurchase.fromJson(Map<String, dynamic> json) {
    return DashboardRecentPurchase(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String?,
      companyName: json['company_name'] as String?,
      totalAmount: _toDouble(json['total_amount']),
      purchaseDate: _parseDate(json['purchase_date']) ?? DateTime.now(),
    );
  }
}

class DashboardInventory {
  const DashboardInventory({
    required this.totalProducts,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  final int totalProducts;
  final int lowStockCount;
  final int outOfStockCount;

  factory DashboardInventory.fromJson(Map<String, dynamic> json) {
    return DashboardInventory(
      totalProducts: _toInt(json['total_products']),
      lowStockCount: _toInt(json['low_stock_count']),
      outOfStockCount: _toInt(json['out_of_stock_count']),
    );
  }

  static const empty = DashboardInventory(
    totalProducts: 0,
    lowStockCount: 0,
    outOfStockCount: 0,
  );
}

class DashboardLowStockItem {
  const DashboardLowStockItem({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.reorderLevel,
    this.sku,
    this.companyName,
  });

  final String productId;
  final String productName;
  final String? sku;
  final String? companyName;
  final double currentStock;
  final double reorderLevel;

  factory DashboardLowStockItem.fromJson(Map<String, dynamic> json) {
    return DashboardLowStockItem(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? '',
      sku: json['sku'] as String?,
      companyName: json['company_name'] as String?,
      currentStock: _toDouble(json['current_stock']),
      reorderLevel: _toDouble(json['reorder_level']),
    );
  }
}

class DashboardTrendPoint {
  const DashboardTrendPoint({
    required this.day,
    required this.salesTotal,
    required this.profitTotal,
    required this.salesCount,
  });

  final DateTime day;
  final double salesTotal;
  final double profitTotal;
  final int salesCount;

  factory DashboardTrendPoint.fromJson(Map<String, dynamic> json) {
    return DashboardTrendPoint(
      day: _parseDate(json['day']) ?? DateTime.now(),
      salesTotal: _toDouble(json['sales_total']),
      profitTotal: _toDouble(json['profit_total']),
      salesCount: _toInt(json['sales_count']),
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.dateFrom,
    required this.dateTo,
    required this.summary,
    required this.recentSales,
    required this.recentPurchases,
    required this.inventory,
    required this.lowStock,
    required this.trend,
  });

  final DateTime dateFrom;
  final DateTime dateTo;
  final DashboardSummary summary;
  final List<DashboardRecentSale> recentSales;
  final List<DashboardRecentPurchase> recentPurchases;
  final DashboardInventory inventory;
  final List<DashboardLowStockItem> lowStock;
  final List<DashboardTrendPoint> trend;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final summaryJson = _asMap(json['summary']);
    final inventoryJson = _asMap(json['inventory']);

    return DashboardData(
      dateFrom: _parseDate(json['date_from']) ?? DateTime.now(),
      dateTo: _parseDate(json['date_to']) ?? DateTime.now(),
      summary: summaryJson != null
          ? DashboardSummary.fromJson(summaryJson)
          : DashboardSummary.empty,
      recentSales: _mapList(json['recent_sales'], DashboardRecentSale.fromJson),
      recentPurchases: _mapList(
        json['recent_purchases'],
        DashboardRecentPurchase.fromJson,
      ),
      inventory: inventoryJson != null
          ? DashboardInventory.fromJson(inventoryJson)
          : DashboardInventory.empty,
      lowStock: _mapList(json['low_stock'], DashboardLowStockItem.fromJson),
      trend: _mapList(json['trend'], DashboardTrendPoint.fromJson),
    );
  }
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<T> _mapList<T>(Object? raw, T Function(Map<String, dynamic> json) mapper) {
  if (raw is! List) return const [];
  return [
    for (final row in raw)
      if (_asMap(row) case final map?) mapper(map),
  ];
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _parseDate(Object? value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
