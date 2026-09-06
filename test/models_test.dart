import 'package:flutter_test/flutter_test.dart';

import 'package:business_management_app/core/utils/formatters.dart';
import 'package:business_management_app/models/company.dart';
import 'package:business_management_app/models/dashboard.dart';
import 'package:business_management_app/models/product.dart';
import 'package:business_management_app/models/purchase.dart';
import 'package:business_management_app/models/sale.dart';
import 'package:business_management_app/models/stock_movement.dart';

void main() {
  test('Company.fromJson maps fields', () {
    final company = Company.fromJson({
      'id': 'c1',
      'name': 'Acme',
      'code': 'ACM',
      'email': 'a@acme.com',
      'city': 'Karachi',
      'country': 'Pakistan',
      'is_active': true,
    });

    expect(company.name, 'Acme');
    expect(company.locationLabel, 'Karachi, Pakistan');
    expect(company.contactLabel, 'a@acme.com');
  });

  test('Product.fromJson maps joined company name and decimals', () {
    final product = Product.fromJson({
      'id': 'p1',
      'company_id': 'c1',
      'name': 'Rice',
      'purchase_price': '12.50',
      'sale_price': 15,
      'opening_stock': 3,
      'is_active': true,
      'companies': {'name': 'Acme'},
    });

    expect(product.companyName, 'Acme');
    expect(product.purchasePrice, 12.5);
    expect(Formatters.money(product.salePrice), '15.00');
  });

  test('PurchaseMath calculates line, subtotal, and grand total', () {
    final items = [
      PurchaseItem(
        productId: 'p1',
        quantity: 10,
        unitCost: 50,
        lineTotal: PurchaseMath.lineTotal(quantity: 10, unitCost: 50),
      ),
      PurchaseItem(
        productId: 'p2',
        quantity: 5,
        unitCost: 20,
        lineTotal: PurchaseMath.lineTotal(quantity: 5, unitCost: 20),
      ),
    ];

    expect(items[0].lineTotal, 500);
    expect(items[1].lineTotal, 100);
    expect(PurchaseMath.subtotal(items), 600);
    expect(
      PurchaseMath.grandTotal(subtotal: 600, discount: 50, otherCharges: 10),
      560,
    );
  });

  test('Purchase.fromJson maps company, items, and count', () {
    final purchase = Purchase.fromJson({
      'id': 'pu1',
      'company_id': 'c1',
      'purchase_date': '2026-09-04',
      'invoice_number': 'INV-1',
      'subtotal': '600.00',
      'discount': 50,
      'other_charges': 10,
      'total_amount': 560,
      'status': 'draft',
      'companies': {'name': 'Acme'},
      'purchase_items': [
        {
          'id': 'i1',
          'purchase_id': 'pu1',
          'product_id': 'p1',
          'quantity': 10,
          'unit_cost': 50,
          'line_total': 500,
          'products': {'name': 'Rice', 'sku': 'R1', 'unit': 'kg'},
        },
      ],
    });

    expect(purchase.companyName, 'Acme');
    expect(purchase.canEdit, isTrue);
    expect(purchase.itemCount, 1);
    expect(purchase.items.first.productName, 'Rice');
    expect(purchase.items.first.productSku, 'R1');
  });

  test('SaleMath calculates line, subtotal, and grand total', () {
    final items = [
      SaleItem(
        productId: 'p1',
        quantity: 10,
        unitPrice: 80,
        lineTotal: SaleMath.lineTotal(quantity: 10, unitPrice: 80),
      ),
      SaleItem(
        productId: 'p2',
        quantity: 5,
        unitPrice: 40,
        lineTotal: SaleMath.lineTotal(quantity: 5, unitPrice: 40),
      ),
    ];

    expect(items[0].lineTotal, 800);
    expect(items[1].lineTotal, 200);
    expect(SaleMath.subtotal(items), 1000);
    expect(
      SaleMath.grandTotal(subtotal: 1000, discount: 100, otherCharges: 20),
      920,
    );
  });

  test('Sale.fromJson maps company, items, and count', () {
    final sale = Sale.fromJson({
      'id': 's1',
      'company_id': 'c1',
      'sale_date': '2026-09-05',
      'invoice_number': 'S-INV-1',
      'subtotal': '1000.00',
      'discount': 100,
      'other_charges': 20,
      'total_amount': 920,
      'total_cogs': 175,
      'total_profit': 125,
      'status': 'completed',
      'companies': {'name': 'Acme'},
      'sale_items': [
        {
          'id': 'i1',
          'sale_id': 's1',
          'product_id': 'p1',
          'quantity': 15,
          'unit_price': 20,
          'line_total': 300,
          'cogs': 175,
          'line_profit': 125,
          'products': {'name': 'Rice', 'sku': 'R1', 'unit': 'kg'},
        },
      ],
    });

    expect(sale.companyName, 'Acme');
    expect(sale.showsCosting, isTrue);
    expect(sale.totalCogs, 175);
    expect(sale.totalProfit, 125);
    expect(sale.items.first.cogs, 175);
    expect(sale.items.first.lineProfit, 125);
    expect(sale.items.first.revenue, 300);
  });

  test('StockBalance.fromJson maps current stock and low-stock flag', () {
    final balance = StockBalance.fromJson({
      'product_id': 'p1',
      'company_id': 'c1',
      'company_name': 'Acme',
      'product_name': 'Rice',
      'sku': 'R1',
      'opening_stock': '20',
      'reorder_level': 25,
      'movement_qty': 5,
      'current_stock': 25,
      'is_low_stock': true,
      'is_active': true,
    });

    expect(balance.currentStock, 25);
    expect(balance.isLowStock, isTrue);
    expect(balance.companyName, 'Acme');
  });

  test('StockMovement.typeLabel maps known types', () {
    final movement = StockMovement.fromJson({
      'id': 'm1',
      'product_id': 'p1',
      'movement_type': 'sale',
      'quantity': '-3',
      'created_at': '2026-09-05T10:00:00Z',
    });

    expect(movement.quantity, -3);
    expect(movement.typeLabel, 'Sale');
  });

  test('DashboardData.fromJson maps summary, activity, inventory, trend', () {
    final data = DashboardData.fromJson({
      'date_from': '2026-09-01',
      'date_to': '2026-09-05',
      'summary': {
        'sales_total': '100.00',
        'purchases_total': 50,
        'revenue': 100,
        'total_cogs': '40.5',
        'total_profit': 59.5,
        'sales_count': 2,
        'purchases_count': 1,
      },
      'recent_sales': [
        {
          'id': 's1',
          'invoice_number': 'S-1',
          'company_name': 'Acme',
          'total_amount': 100,
          'total_profit': 59.5,
          'sale_date': '2026-09-05',
        },
      ],
      'recent_purchases': [
        {
          'id': 'p1',
          'invoice_number': 'P-1',
          'company_name': 'Acme',
          'total_amount': 50,
          'purchase_date': '2026-09-02',
        },
      ],
      'inventory': {
        'total_products': 3,
        'low_stock_count': 1,
        'out_of_stock_count': 0,
      },
      'low_stock': [
        {
          'product_id': 'pr1',
          'product_name': 'Rice',
          'sku': 'R1',
          'current_stock': 2,
          'reorder_level': 5,
          'company_name': 'Acme',
        },
      ],
      'trend': [
        {
          'day': '2026-09-05',
          'sales_total': 100,
          'profit_total': 59.5,
          'sales_count': 1,
        },
      ],
    });

    expect(data.summary.salesTotal, 100);
    expect(data.summary.purchasesTotal, 50);
    expect(data.summary.revenue, 100);
    expect(data.summary.totalCogs, 40.5);
    expect(data.summary.totalProfit, 59.5);
    expect(data.summary.salesCount, 2);
    expect(data.summary.purchasesCount, 1);
    expect(data.recentSales.single.invoiceNumber, 'S-1');
    expect(data.recentPurchases.single.totalAmount, 50);
    expect(data.inventory.lowStockCount, 1);
    expect(data.lowStock.single.reorderLevel, 5);
    expect(data.trend.single.salesTotal, 100);
  });
}
