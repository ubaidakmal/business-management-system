import '../core/utils/formatters.dart';
import '../models/report.dart';
import '../models/stock_movement.dart';
import '../services/settings_service.dart';
import '../widgets/reports/report_widgets.dart';
import 'report_export_data.dart';

abstract final class ReportExportBuilders {
  static String get _businessName => SettingsService.cachedBusinessName;

  static String dateRangeFilter(DateTime? from, DateTime? to) {
    if (from == null && to == null) return 'Date: All';
    return 'Date: ${Formatters.date(from)} → ${Formatters.date(to)}';
  }

  static String companyFilter(String? companyId, String? companyName) {
    if (companyId == null || companyId.isEmpty) return 'Company: All';
    return 'Company: ${companyName ?? companyId}';
  }

  static ReportExportData sales({
    required SalesReportData data,
    required List<String> filters,
  }) {
    return ReportExportData(
      businessName: _businessName,
      title: 'Sales Report',
      fileStem: 'sales_report',
      filters: filters,
      summary: [
        ReportExportMetric(
          label: 'Total Sales',
          value: Formatters.money(data.summary.salesTotal),
        ),
        ReportExportMetric(
          label: 'Number of Sales',
          value: '${data.summary.salesCount}',
        ),
        ReportExportMetric(
          label: 'Total COGS',
          value: Formatters.money(data.summary.totalCogs),
        ),
        ReportExportMetric(
          label: 'Total Profit',
          value: Formatters.money(data.summary.totalProfit),
        ),
      ],
      columns: const [
        'Invoice',
        'Company',
        'Date',
        'Items',
        'Revenue',
        'COGS',
        'Profit',
        'Status',
      ],
      rows: [
        for (final row in data.rows)
          [
            row.invoiceNumber?.isNotEmpty == true ? row.invoiceNumber! : '—',
            row.companyName ?? '—',
            Formatters.date(row.saleDate),
            '${row.itemsCount}',
            Formatters.money(row.revenue),
            Formatters.money(row.totalCogs),
            Formatters.money(row.totalProfit),
            row.status,
          ],
      ],
    );
  }

  static ReportExportData purchases({
    required PurchasesReportData data,
    required List<String> filters,
  }) {
    return ReportExportData(
      businessName: _businessName,
      title: 'Purchase Report',
      fileStem: 'purchases_report',
      filters: filters,
      summary: [
        ReportExportMetric(
          label: 'Purchase Total',
          value: Formatters.money(data.summary.purchasesTotal),
        ),
        ReportExportMetric(
          label: 'Number of Purchases',
          value: '${data.summary.purchasesCount}',
        ),
      ],
      columns: const ['Invoice', 'Company', 'Date', 'Items', 'Total'],
      rows: [
        for (final row in data.rows)
          [
            row.invoiceNumber?.isNotEmpty == true ? row.invoiceNumber! : '—',
            row.companyName ?? '—',
            Formatters.date(row.purchaseDate),
            '${row.itemsCount}',
            Formatters.money(row.totalAmount),
          ],
      ],
    );
  }

  static ReportExportData profit({
    required ProfitReportData data,
    required List<String> filters,
  }) {
    return ReportExportData(
      businessName: _businessName,
      title: 'Profit Report',
      fileStem: 'profit_report',
      filters: filters,
      summary: [
        ReportExportMetric(
          label: 'Revenue',
          value: Formatters.money(data.summary.revenue),
        ),
        ReportExportMetric(
          label: 'COGS',
          value: Formatters.money(data.summary.totalCogs),
        ),
        ReportExportMetric(
          label: 'Gross Profit',
          value: Formatters.money(data.summary.grossProfit),
        ),
        ReportExportMetric(
          label: 'Number of Sales',
          value: '${data.summary.salesCount}',
        ),
      ],
      columns: const [
        'Invoice',
        'Company',
        'Date',
        'Revenue',
        'COGS',
        'Profit',
      ],
      rows: [
        for (final row in data.rows)
          [
            row.invoiceNumber?.isNotEmpty == true ? row.invoiceNumber! : '—',
            row.companyName ?? '—',
            Formatters.date(row.saleDate),
            Formatters.money(row.revenue),
            Formatters.money(row.totalCogs),
            Formatters.money(row.grossProfit),
          ],
      ],
    );
  }

  static ReportExportData stock({
    required List<StockBalance> items,
    required List<String> filters,
  }) {
    final lowCount = items
        .where((i) => i.isLowStock && i.currentStock > 0)
        .length;
    final outCount = items.where((i) => i.currentStock <= 0).length;
    return ReportExportData(
      businessName: _businessName,
      title: 'Stock Report',
      fileStem: 'stock_report',
      filters: filters,
      summary: [
        ReportExportMetric(label: 'Products shown', value: '${items.length}'),
        ReportExportMetric(label: 'Low stock', value: '$lowCount'),
        ReportExportMetric(label: 'Out of stock', value: '$outCount'),
      ],
      columns: const [
        'Product',
        'SKU',
        'Company',
        'Category',
        'Current Stock',
        'Reorder Level',
        'Status',
      ],
      rows: [
        for (final row in items)
          [
            row.productName,
            row.sku?.isNotEmpty == true ? row.sku! : '—',
            row.companyName ?? '—',
            row.category?.isNotEmpty == true ? row.category! : '—',
            Formatters.quantity(row.currentStock),
            Formatters.quantity(row.reorderLevel),
            stockStatusLabel(
              currentStock: row.currentStock,
              isLowStock: row.isLowStock,
            ),
          ],
      ],
    );
  }

  static ReportExportData products({
    required ProductReportData data,
    required List<String> filters,
  }) {
    return ReportExportData(
      businessName: _businessName,
      title: 'Product Report',
      fileStem: 'product_report',
      filters: filters,
      summary: [
        ReportExportMetric(
          label: 'Products',
          value: '${data.summary.productCount}',
        ),
        ReportExportMetric(
          label: 'Qty Sold',
          value: Formatters.quantity(data.summary.quantitySold),
        ),
        ReportExportMetric(
          label: 'Revenue',
          value: Formatters.money(data.summary.revenue),
        ),
        ReportExportMetric(
          label: 'COGS',
          value: Formatters.money(data.summary.totalCogs),
        ),
        ReportExportMetric(
          label: 'Profit',
          value: Formatters.money(data.summary.totalProfit),
        ),
      ],
      columns: const [
        'Product',
        'SKU',
        'Company',
        'Qty Sold',
        'Revenue',
        'COGS',
        'Profit',
      ],
      rows: [
        for (final row in data.rows)
          [
            row.productName,
            row.sku?.isNotEmpty == true ? row.sku! : '—',
            row.companyName ?? '—',
            Formatters.quantity(row.quantitySold),
            Formatters.money(row.revenue),
            Formatters.money(row.totalCogs),
            Formatters.money(row.totalProfit),
          ],
      ],
    );
  }

  static ReportExportData companies({
    required CompanyReportData data,
    required List<String> filters,
  }) {
    return ReportExportData(
      businessName: _businessName,
      title: 'Company Report',
      fileStem: 'company_report',
      filters: filters,
      summary: [
        ReportExportMetric(
          label: 'Companies',
          value: '${data.summary.companyCount}',
        ),
        ReportExportMetric(
          label: 'Sales Total',
          value: Formatters.money(data.summary.salesTotal),
        ),
        ReportExportMetric(
          label: 'Purchases Total',
          value: Formatters.money(data.summary.purchasesTotal),
        ),
        ReportExportMetric(
          label: 'Profit Total',
          value: Formatters.money(data.summary.profitTotal),
        ),
      ],
      columns: const [
        'Company',
        'Code',
        'Sales',
        'Purchases',
        'Profit',
        'Products',
      ],
      rows: [
        for (final row in data.rows)
          [
            row.companyName,
            row.code?.isNotEmpty == true ? row.code! : '—',
            Formatters.money(row.salesTotal),
            Formatters.money(row.purchasesTotal),
            Formatters.money(row.profitTotal),
            '${row.productCount}',
          ],
      ],
    );
  }
}
