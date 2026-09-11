import 'package:flutter/material.dart';

import '../state/locale_controller.dart';

import '../core/constants/app_sizes.dart';
import '../core/routes/app_router.dart';
import '../core/utils/app_error.dart';
import '../core/utils/formatters.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_states.dart';
import '../widgets/app_surfaces.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _service = ProductService();
  Product? _product;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _product = await _service.getById(widget.productId);
    } catch (error) {
      _error = AppError.messageOf(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.productForm,
      arguments: widget.productId,
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;

    return AppScaffold(
      title: context.l10n.productDetails,
      route: AppRoutes.products,
      body: _loading
          ? const AppLoading()
          : _error != null
          ? AppErrorState(message: _error, onRetry: _load)
          : product == null
          ? AppEmptyState(title: context.l10n.productNotFound)
          : ListView(
              children: [
                AppSectionHeader(
                  title: product.name,
                  subtitle: product.sku,
                  action: AppBadge(
                    label: product.isActive ? 'Active' : 'Inactive',
                    type: product.isActive
                        ? AppBadgeType.success
                        : AppBadgeType.neutral,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppDetailRow(
                        label: 'Company',
                        value: product.companyName ?? '',
                      ),
                      AppDetailRow(
                        label: 'Barcode',
                        value: product.barcode ?? '',
                      ),
                      AppDetailRow(
                        label: 'Category',
                        value: product.category ?? '',
                      ),
                      AppDetailRow(label: 'Unit', value: product.unit ?? ''),
                      AppDetailRow(
                        label: 'Purchase price',
                        value: Formatters.money(product.purchasePrice),
                      ),
                      AppDetailRow(
                        label: 'Sale price',
                        value: Formatters.money(product.salePrice),
                      ),
                      AppDetailRow(
                        label: 'Opening stock',
                        value: Formatters.quantity(product.openingStock),
                      ),
                      AppDetailRow(
                        label: 'Opening unit cost',
                        value: Formatters.money(product.openingUnitCost),
                      ),
                      AppDetailRow(
                        label: 'Reorder level',
                        value: Formatters.quantity(product.reorderLevel),
                      ),
                      AppDetailRow(
                        label: 'Description',
                        value: product.description ?? '',
                      ),
                      AppDetailRow(
                        label: 'Created',
                        value: Formatters.dateTime(product.createdAt),
                      ),
                      AppDetailRow(
                        label: 'Updated',
                        value: Formatters.dateTime(product.updatedAt),
                      ),
                      const SizedBox(height: AppSizes.md),
                      AppButton(
                        label: 'Edit product',
                        expanded: false,
                        onPressed: _edit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
