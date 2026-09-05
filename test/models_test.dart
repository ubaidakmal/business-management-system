import 'package:flutter_test/flutter_test.dart';

import 'package:business_management_app/core/utils/formatters.dart';
import 'package:business_management_app/models/company.dart';
import 'package:business_management_app/models/product.dart';
import 'package:business_management_app/models/purchase.dart';
import 'package:business_management_app/models/sale.dart';

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
      'status': 'draft',
      'companies': {'name': 'Acme'},
      'sale_items': [
        {
          'id': 'i1',
          'sale_id': 's1',
          'product_id': 'p1',
          'quantity': 10,
          'unit_price': 80,
          'line_total': 800,
          'products': {'name': 'Rice', 'sku': 'R1', 'unit': 'kg'},
        },
      ],
    });

    expect(sale.companyName, 'Acme');
    expect(sale.canEdit, isTrue);
    expect(sale.itemCount, 1);
    expect(sale.items.first.productName, 'Rice');
    expect(sale.items.first.unitPrice, 80);
  });
}
