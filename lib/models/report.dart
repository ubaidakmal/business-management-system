class SalesReportSummary {
  const SalesReportSummary({
    required this.salesTotal,
    required this.salesCount,
    required this.totalCogs,
    required this.totalProfit,
  });

  final double salesTotal;
  final int salesCount;
  final double totalCogs;
  final double totalProfit;

  factory SalesReportSummary.fromJson(Map<String, dynamic> json) {
    return SalesReportSummary(
      salesTotal: _toDouble(json['sales_total']),
      salesCount: _toInt(json['sales_count']),
      totalCogs: _toDouble(json['total_cogs']),
      totalProfit: _toDouble(json['total_profit']),
    );
  }

  static const empty = SalesReportSummary(
    salesTotal: 0,
    salesCount: 0,
    totalCogs: 0,
    totalProfit: 0,
  );
}

class SalesReportRow {
  const SalesReportRow({
    required this.id,
    required this.saleDate,
    required this.revenue,
    required this.totalCogs,
    required this.totalProfit,
    required this.itemsCount,
    this.invoiceNumber,
    this.referenceNumber,
    this.companyName,
    this.status = 'completed',
  });

  final String id;
  final String? invoiceNumber;
  final String? referenceNumber;
  final String? companyName;
  final DateTime saleDate;
  final String status;
  final double revenue;
  final double totalCogs;
  final double totalProfit;
  final int itemsCount;

  factory SalesReportRow.fromJson(Map<String, dynamic> json) {
    return SalesReportRow(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String?,
      referenceNumber: json['reference_number'] as String?,
      companyName: json['company_name'] as String?,
      saleDate: _parseDate(json['sale_date']) ?? DateTime.now(),
      status: json['status'] as String? ?? 'completed',
      revenue: _toDouble(json['revenue']),
      totalCogs: _toDouble(json['total_cogs']),
      totalProfit: _toDouble(json['total_profit']),
      itemsCount: _toInt(json['items_count']),
    );
  }
}

class SalesReportData {
  const SalesReportData({required this.summary, required this.rows});

  final SalesReportSummary summary;
  final List<SalesReportRow> rows;

  factory SalesReportData.fromJson(Map<String, dynamic> json) {
    final summary = _asMap(json['summary']);
    return SalesReportData(
      summary: summary != null
          ? SalesReportSummary.fromJson(summary)
          : SalesReportSummary.empty,
      rows: _mapList(json['rows'], SalesReportRow.fromJson),
    );
  }
}

class PurchasesReportSummary {
  const PurchasesReportSummary({
    required this.purchasesTotal,
    required this.purchasesCount,
  });

  final double purchasesTotal;
  final int purchasesCount;

  factory PurchasesReportSummary.fromJson(Map<String, dynamic> json) {
    return PurchasesReportSummary(
      purchasesTotal: _toDouble(json['purchases_total']),
      purchasesCount: _toInt(json['purchases_count']),
    );
  }

  static const empty = PurchasesReportSummary(
    purchasesTotal: 0,
    purchasesCount: 0,
  );
}

class PurchasesReportRow {
  const PurchasesReportRow({
    required this.id,
    required this.purchaseDate,
    required this.totalAmount,
    required this.itemsCount,
    this.invoiceNumber,
    this.referenceNumber,
    this.companyName,
  });

  final String id;
  final String? invoiceNumber;
  final String? referenceNumber;
  final String? companyName;
  final DateTime purchaseDate;
  final double totalAmount;
  final int itemsCount;

  factory PurchasesReportRow.fromJson(Map<String, dynamic> json) {
    return PurchasesReportRow(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String?,
      referenceNumber: json['reference_number'] as String?,
      companyName: json['company_name'] as String?,
      purchaseDate: _parseDate(json['purchase_date']) ?? DateTime.now(),
      totalAmount: _toDouble(json['total_amount']),
      itemsCount: _toInt(json['items_count']),
    );
  }
}

class PurchasesReportData {
  const PurchasesReportData({required this.summary, required this.rows});

  final PurchasesReportSummary summary;
  final List<PurchasesReportRow> rows;

  factory PurchasesReportData.fromJson(Map<String, dynamic> json) {
    final summary = _asMap(json['summary']);
    return PurchasesReportData(
      summary: summary != null
          ? PurchasesReportSummary.fromJson(summary)
          : PurchasesReportSummary.empty,
      rows: _mapList(json['rows'], PurchasesReportRow.fromJson),
    );
  }
}

class ProfitReportSummary {
  const ProfitReportSummary({
    required this.revenue,
    required this.totalCogs,
    required this.grossProfit,
    required this.salesCount,
  });

  final double revenue;
  final double totalCogs;
  final double grossProfit;
  final int salesCount;

  factory ProfitReportSummary.fromJson(Map<String, dynamic> json) {
    return ProfitReportSummary(
      revenue: _toDouble(json['revenue']),
      totalCogs: _toDouble(json['total_cogs']),
      grossProfit: _toDouble(json['gross_profit']),
      salesCount: _toInt(json['sales_count']),
    );
  }

  static const empty = ProfitReportSummary(
    revenue: 0,
    totalCogs: 0,
    grossProfit: 0,
    salesCount: 0,
  );
}

class ProfitReportRow {
  const ProfitReportRow({
    required this.id,
    required this.saleDate,
    required this.revenue,
    required this.totalCogs,
    required this.grossProfit,
    this.invoiceNumber,
    this.companyName,
  });

  final String id;
  final String? invoiceNumber;
  final String? companyName;
  final DateTime saleDate;
  final double revenue;
  final double totalCogs;
  final double grossProfit;

  factory ProfitReportRow.fromJson(Map<String, dynamic> json) {
    return ProfitReportRow(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String?,
      companyName: json['company_name'] as String?,
      saleDate: _parseDate(json['sale_date']) ?? DateTime.now(),
      revenue: _toDouble(json['revenue']),
      totalCogs: _toDouble(json['total_cogs']),
      grossProfit: _toDouble(json['gross_profit']),
    );
  }
}

class ProfitReportData {
  const ProfitReportData({required this.summary, required this.rows});

  final ProfitReportSummary summary;
  final List<ProfitReportRow> rows;

  factory ProfitReportData.fromJson(Map<String, dynamic> json) {
    final summary = _asMap(json['summary']);
    return ProfitReportData(
      summary: summary != null
          ? ProfitReportSummary.fromJson(summary)
          : ProfitReportSummary.empty,
      rows: _mapList(json['rows'], ProfitReportRow.fromJson),
    );
  }
}

class ProductReportSummary {
  const ProductReportSummary({
    required this.quantitySold,
    required this.revenue,
    required this.totalCogs,
    required this.totalProfit,
    required this.productCount,
  });

  final double quantitySold;
  final double revenue;
  final double totalCogs;
  final double totalProfit;
  final int productCount;

  factory ProductReportSummary.fromJson(Map<String, dynamic> json) {
    return ProductReportSummary(
      quantitySold: _toDouble(json['quantity_sold']),
      revenue: _toDouble(json['revenue']),
      totalCogs: _toDouble(json['total_cogs']),
      totalProfit: _toDouble(json['total_profit']),
      productCount: _toInt(json['product_count']),
    );
  }

  static const empty = ProductReportSummary(
    quantitySold: 0,
    revenue: 0,
    totalCogs: 0,
    totalProfit: 0,
    productCount: 0,
  );
}

class ProductReportRow {
  const ProductReportRow({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
    required this.totalCogs,
    required this.totalProfit,
    this.sku,
    this.companyName,
  });

  final String productId;
  final String productName;
  final String? sku;
  final String? companyName;
  final double quantitySold;
  final double revenue;
  final double totalCogs;
  final double totalProfit;

  factory ProductReportRow.fromJson(Map<String, dynamic> json) {
    return ProductReportRow(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? '',
      sku: json['sku'] as String?,
      companyName: json['company_name'] as String?,
      quantitySold: _toDouble(json['quantity_sold']),
      revenue: _toDouble(json['revenue']),
      totalCogs: _toDouble(json['total_cogs']),
      totalProfit: _toDouble(json['total_profit']),
    );
  }
}

class ProductReportData {
  const ProductReportData({required this.summary, required this.rows});

  final ProductReportSummary summary;
  final List<ProductReportRow> rows;

  factory ProductReportData.fromJson(Map<String, dynamic> json) {
    final summary = _asMap(json['summary']);
    return ProductReportData(
      summary: summary != null
          ? ProductReportSummary.fromJson(summary)
          : ProductReportSummary.empty,
      rows: _mapList(json['rows'], ProductReportRow.fromJson),
    );
  }
}

class CompanyReportSummary {
  const CompanyReportSummary({
    required this.companyCount,
    required this.salesTotal,
    required this.purchasesTotal,
    required this.profitTotal,
  });

  final int companyCount;
  final double salesTotal;
  final double purchasesTotal;
  final double profitTotal;

  factory CompanyReportSummary.fromJson(Map<String, dynamic> json) {
    return CompanyReportSummary(
      companyCount: _toInt(json['company_count']),
      salesTotal: _toDouble(json['sales_total']),
      purchasesTotal: _toDouble(json['purchases_total']),
      profitTotal: _toDouble(json['profit_total']),
    );
  }

  static const empty = CompanyReportSummary(
    companyCount: 0,
    salesTotal: 0,
    purchasesTotal: 0,
    profitTotal: 0,
  );
}

class CompanyReportRow {
  const CompanyReportRow({
    required this.companyId,
    required this.companyName,
    required this.salesTotal,
    required this.purchasesTotal,
    required this.profitTotal,
    required this.productCount,
    this.code,
  });

  final String companyId;
  final String companyName;
  final String? code;
  final double salesTotal;
  final double purchasesTotal;
  final double profitTotal;
  final int productCount;

  factory CompanyReportRow.fromJson(Map<String, dynamic> json) {
    return CompanyReportRow(
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String? ?? '',
      code: json['code'] as String?,
      salesTotal: _toDouble(json['sales_total']),
      purchasesTotal: _toDouble(json['purchases_total']),
      profitTotal: _toDouble(json['profit_total']),
      productCount: _toInt(json['product_count']),
    );
  }
}

class CompanyReportData {
  const CompanyReportData({required this.summary, required this.rows});

  final CompanyReportSummary summary;
  final List<CompanyReportRow> rows;

  factory CompanyReportData.fromJson(Map<String, dynamic> json) {
    final summary = _asMap(json['summary']);
    return CompanyReportData(
      summary: summary != null
          ? CompanyReportSummary.fromJson(summary)
          : CompanyReportSummary.empty,
      rows: _mapList(json['rows'], CompanyReportRow.fromJson),
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
