import '../core/utils/formatters.dart';
import '../l10n/app_localizations.dart';
import '../models/report.dart';
import '../models/stock_movement.dart';
import '../services/settings_service.dart';
import '../widgets/reports/report_widgets.dart';
import 'report_export_data.dart';

abstract final class ReportExportBuilders {
  static String get _businessName => SettingsService.cachedBusinessName;

  static String dateRangeFilter(
    AppLocalizations l10n,
    DateTime? from,
    DateTime? to,
  ) {
    if (from == null && to == null) return l10n.dateAll;
    return l10n.dateRange(Formatters.date(from), Formatters.date(to));
  }

  static String companyFilter(
    AppLocalizations l10n,
    String? companyId,
    String? companyName,
  ) {
    if (companyId == null || companyId.isEmpty) return l10n.companyAll;
    return l10n.companyFilter(companyName ?? companyId);
  }

  static ReportExportData sales({
    required AppLocalizations l10n,
    required SalesReportData data,
    required List<String> filters,
  }) {
    return ReportExportData(
      businessName: _businessName,
      title: l10n.salesReport,
      fileStem: 'sales_report',
      filters: filters,
      summary: [
        ReportExportMetric(
          label: l10n.totalSales,
          value: Formatters.money(data.summary.salesTotal),
        ),
        ReportExportMetric(
          label: l10n.numberOfSales,
          value: '${data.summary.salesCount}',
        ),
        ReportExportMetric(
          label: l10n.totalCogs,
          value: Formatters.money(data.summary.totalCogs),
        ),
        ReportExportMetric(
          label: l10n.totalProfit,
          value: Formatters.money(data.summary.totalProfit),
        ),
      ],
      columns: [
        l10n.invoice,
        l10n.company,
        l10n.date,
        l10n.items,
        l10n.revenue,
        l10n.cogs,
        l10n.profit,
        l10n.status,
      ],
      rows: [
        for (final row in data.rows)
          [
            row.invoiceNumber?.isNotEmpty == true
                ? row.invoiceNumber!
                : l10n.emDash,
            row.companyName ?? l10n.emDash,
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
    required AppLocalizations l10n,
    required PurchasesReportData data,
    required List<String> filters,
  }) {
    return ReportExportData(
      businessName: _businessName,
      title: l10n.purchaseReport,
      fileStem: 'purchases_report',
      filters: filters,
      summary: [
        ReportExportMetric(
          label: l10n.purchasesTotal,
          value: Formatters.money(data.summary.purchasesTotal),
        ),
        ReportExportMetric(
          label: l10n.numberOfPurchases,
          value: '${data.summary.purchasesCount}',
        ),
      ],
      columns: [
        l10n.invoice,
        l10n.company,
        l10n.date,
        l10n.items,
        l10n.total,
      ],
      rows: [
        for (final row in data.rows)
          [
            row.invoiceNumber?.isNotEmpty == true
                ? row.invoiceNumber!
                : l10n.emDash,
            row.companyName ?? l10n.emDash,
            Formatters.date(row.purchaseDate),
            '${row.itemsCount}',
            Formatters.money(row.totalAmount),
          ],
      ],
    );
  }

  static ReportExportData profit({
    required AppLocalizations l10n,
    required ProfitReportData data,
    required List<String> filters,
  }) {
    return ReportExportData(
      businessName: _businessName,
      title: l10n.profitReport,
      fileStem: 'profit_report',
      filters: filters,
      summary: [
        ReportExportMetric(
          label: l10n.revenue,
          value: Formatters.money(data.summary.revenue),
        ),
        ReportExportMetric(
          label: l10n.cogs,
          value: Formatters.money(data.summary.totalCogs),
        ),
        ReportExportMetric(
          label: l10n.grossProfit,
          value: Formatters.money(data.summary.grossProfit),
        ),
        ReportExportMetric(
          label: l10n.numberOfSales,
          value: '${data.summary.salesCount}',
        ),
      ],
      columns: [
        l10n.invoice,
        l10n.company,
        l10n.date,
        l10n.revenue,
        l10n.cogs,
        l10n.profit,
      ],
      rows: [
        for (final row in data.rows)
          [
            row.invoiceNumber?.isNotEmpty == true
                ? row.invoiceNumber!
                : l10n.emDash,
            row.companyName ?? l10n.emDash,
            Formatters.date(row.saleDate),
            Formatters.money(row.revenue),
            Formatters.money(row.totalCogs),
            Formatters.money(row.grossProfit),
          ],
      ],
    );
  }

  static ReportExportData stock({
    required AppLocalizations l10n,
    required List<StockBalance> items,
    required List<String> filters,
  }) {
    final lowCount = items
        .where((i) => i.isLowStock && i.currentStock > 0)
        .length;
    final outCount = items.where((i) => i.currentStock <= 0).length;
    return ReportExportData(
      businessName: _businessName,
      title: l10n.stockReport,
      fileStem: 'stock_report',
      filters: filters,
      summary: [
        ReportExportMetric(
          label: l10n.productsShown,
          value: '${items.length}',
        ),
        ReportExportMetric(label: l10n.lowStock, value: '$lowCount'),
        ReportExportMetric(label: l10n.outOfStock, value: '$outCount'),
      ],
      columns: [
        l10n.product,
        l10n.sku,
        l10n.company,
        l10n.category,
        l10n.currentStock,
        l10n.reorderLevel,
        l10n.status,
      ],
      rows: [
        for (final row in items)
          [
            row.productName,
            row.sku?.isNotEmpty == true ? row.sku! : l10n.emDash,
            row.companyName ?? l10n.emDash,
            row.category?.isNotEmpty == true ? row.category! : l10n.emDash,
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
    required AppLocalizations l10n,
    required ProductReportData data,
    required List<String> filters,
  }) {
    return ReportExportData(
      businessName: _businessName,
      title: l10n.productReport,
      fileStem: 'product_report',
      filters: filters,
      summary: [
        ReportExportMetric(
          label: l10n.productsCount,
          value: '${data.summary.productCount}',
        ),
        ReportExportMetric(
          label: l10n.qtySold,
          value: Formatters.quantity(data.summary.quantitySold),
        ),
        ReportExportMetric(
          label: l10n.revenue,
          value: Formatters.money(data.summary.revenue),
        ),
        ReportExportMetric(
          label: l10n.cogs,
          value: Formatters.money(data.summary.totalCogs),
        ),
        ReportExportMetric(
          label: l10n.profit,
          value: Formatters.money(data.summary.totalProfit),
        ),
      ],
      columns: [
        l10n.product,
        l10n.sku,
        l10n.company,
        l10n.qtySold,
        l10n.revenue,
        l10n.cogs,
        l10n.profit,
      ],
      rows: [
        for (final row in data.rows)
          [
            row.productName,
            row.sku?.isNotEmpty == true ? row.sku! : l10n.emDash,
            row.companyName ?? l10n.emDash,
            Formatters.quantity(row.quantitySold),
            Formatters.money(row.revenue),
            Formatters.money(row.totalCogs),
            Formatters.money(row.totalProfit),
          ],
      ],
    );
  }

  static ReportExportData companies({
    required AppLocalizations l10n,
    required CompanyReportData data,
    required List<String> filters,
  }) {
    return ReportExportData(
      businessName: _businessName,
      title: l10n.companyReport,
      fileStem: 'company_report',
      filters: filters,
      summary: [
        ReportExportMetric(
          label: l10n.companiesTitle,
          value: '${data.summary.companyCount}',
        ),
        ReportExportMetric(
          label: l10n.salesTotal,
          value: Formatters.money(data.summary.salesTotal),
        ),
        ReportExportMetric(
          label: l10n.purchasesTotal,
          value: Formatters.money(data.summary.purchasesTotal),
        ),
        ReportExportMetric(
          label: l10n.profitTotal,
          value: Formatters.money(data.summary.profitTotal),
        ),
      ],
      columns: [
        l10n.company,
        l10n.code,
        l10n.navSales,
        l10n.navPurchases,
        l10n.profit,
        l10n.productsCount,
      ],
      rows: [
        for (final row in data.rows)
          [
            row.companyName,
            row.code?.isNotEmpty == true ? row.code! : l10n.emDash,
            Formatters.money(row.salesTotal),
            Formatters.money(row.purchasesTotal),
            Formatters.money(row.profitTotal),
            '${row.productCount}',
          ],
      ],
    );
  }
}
