import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatters.dart';
import '../core/utils/responsive.dart';
import '../models/company.dart';
import '../models/product.dart';
import '../services/company_service.dart';
import '../state/app_status.dart';
import '../state/auth_controller.dart';
import '../state/products_controller.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_fields.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_states.dart';
import '../widgets/app_surfaces.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _controller = ProductsController();
  final _companies = CompanyService();
  final _search = TextEditingController();
  Timer? _debounce;
  List<Company> _companyOptions = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
    _load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      _companyOptions = await _companies.list(isActive: true);
    } catch (_) {
      _companyOptions = const [];
    }
    await _controller.load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_refresh);
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _controller.search(value);
    });
  }

  Future<void> _openForm({String? productId}) async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.productForm,
      arguments: productId,
    );
    if (changed == true) await _controller.load();
  }

  Future<void> _confirmDeactivate(Product product) async {
    final activate = !product.isActive;
    final ok = await AppDialog.confirm(
      context,
      title: activate ? 'Activate product' : 'Deactivate product',
      message: activate
          ? 'Activate ${product.name}?'
          : 'Deactivate ${product.name}? Prefer this over deletion.',
      confirmLabel: activate ? 'Activate' : 'Deactivate',
    );
    if (!ok) return;
    final success = await _controller.setActive(product, activate);
    if (!mounted) return;
    if (success) {
      AppSnackbar.show(
        context,
        activate ? 'Product activated.' : 'Product deactivated.',
      );
    } else if (_controller.errorMessage != null) {
      AppSnackbar.show(context, _controller.errorMessage!, isError: true);
    }
  }

  Future<void> _confirmDelete(Product product) async {
    final ok = await AppDialog.confirm(
      context,
      title: 'Delete product',
      message:
          'Permanently delete ${product.name}? Prefer deactivation if it may be used later.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    final success = await _controller.delete(product);
    if (!mounted) return;
    if (success) {
      AppSnackbar.show(context, 'Product deleted.');
    } else if (_controller.errorMessage != null) {
      AppSnackbar.show(context, _controller.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);
    final isAdmin = AuthScope.of(context).user?.isAdmin == true;

    return AppScaffold(
      title: 'Products',
      route: AppRoutes.products,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: 'Products',
            subtitle: 'Catalog items linked to companies.',
            action: AppButton(
              label: 'Add Product',
              expanded: false,
              icon: Icons.add,
              onPressed: () => _openForm(),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Wrap(
            spacing: AppSizes.md,
            runSpacing: AppSizes.md,
            children: [
              SizedBox(
                width: desktop ? 280 : double.infinity,
                child: AppSearchField(
                  controller: _search,
                  hint: 'Search name, SKU, barcode',
                  onChanged: _onSearch,
                ),
              ),
              SizedBox(
                width: desktop ? 220 : double.infinity,
                child: AppDropdown<String?>(
                  label: 'Company',
                  value: _controller.companyId,
                  hint: 'All companies',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    for (final company in _companyOptions)
                      DropdownMenuItem(
                        value: company.id,
                        child: Text(
                          company.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _controller.setCompanyFilter,
                ),
              ),
              SizedBox(
                width: desktop ? 180 : double.infinity,
                child: AppDropdown<String?>(
                  label: 'Category',
                  value: _controller.category,
                  hint: 'All categories',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    for (final category in _controller.categories)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: _controller.setCategoryFilter,
                ),
              ),
              SizedBox(
                width: desktop ? 160 : double.infinity,
                child: AppDropdown<bool?>(
                  label: 'Status',
                  value: _controller.activeFilter,
                  hint: 'All',
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: true, child: Text('Active')),
                    DropdownMenuItem(value: false, child: Text('Inactive')),
                  ],
                  onChanged: _controller.setActiveFilter,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Expanded(
            child: _buildBody(desktop: desktop, isAdmin: isAdmin),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({required bool desktop, required bool isAdmin}) {
    if (_controller.isLoading || _controller.status.isInitial) {
      return const AppLoading();
    }
    if (_controller.status.hasError) {
      return AppErrorState(
        message: _controller.errorMessage,
        onRetry: _controller.load,
      );
    }
    if (_controller.status.isEmpty) {
      return AppEmptyState(
        title: 'No products yet',
        message: 'Add your first product to get started.',
        actionLabel: 'Add Product',
        onAction: () => _openForm(),
      );
    }

    if (desktop) {
      return AppCard(
        child: Column(
          children: [
            _headerRow(),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: _controller.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = _controller.items[index];
                  return _productRow(product, isAdmin: isAdmin);
                },
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _controller.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, index) {
        final product = _controller.items[index];
        return AppCard(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.productDetail,
            arguments: product.id,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: AppTextStyles.headingSmall,
                    ),
                  ),
                  AppBadge(
                    label: product.isActive ? 'Active' : 'Inactive',
                    type: product.isActive
                        ? AppBadgeType.success
                        : AppBadgeType.neutral,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(product.companyName ?? '—', style: AppTextStyles.bodySmall),
              Text(
                [
                  if (product.sku?.isNotEmpty == true) 'SKU ${product.sku}',
                  if (product.category?.isNotEmpty == true) product.category!,
                  if (product.unit?.isNotEmpty == true) product.unit!,
                ].join(' · '),
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Buy ${Formatters.money(product.purchasePrice)} · Sell ${Formatters.money(product.salePrice)}',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  AppOutlinedButton(
                    label: 'Edit',
                    expanded: false,
                    onPressed: () => _openForm(productId: product.id),
                  ),
                  AppOutlinedButton(
                    label: product.isActive ? 'Deactivate' : 'Activate',
                    expanded: false,
                    onPressed: () => _confirmDeactivate(product),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('Product', style: AppTextStyles.label)),
          Expanded(flex: 2, child: Text('Company', style: AppTextStyles.label)),
          Expanded(child: Text('SKU', style: AppTextStyles.label)),
          Expanded(child: Text('Buy', style: AppTextStyles.label)),
          Expanded(child: Text('Sell', style: AppTextStyles.label)),
          Expanded(child: Text('Status', style: AppTextStyles.label)),
          SizedBox(
            width: 120,
            child: Text('Actions', style: AppTextStyles.label),
          ),
        ],
      ),
    );
  }

  Widget _productRow(Product product, {required bool isAdmin}) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.productDetail,
        arguments: product.id,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                product.companyName ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall,
              ),
            ),
            Expanded(
              child: Text(
                product.sku?.isNotEmpty == true ? product.sku! : '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(child: Text(Formatters.money(product.purchasePrice))),
            Expanded(child: Text(Formatters.money(product.salePrice))),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppBadge(
                  label: product.isActive ? 'Active' : 'Inactive',
                  type: product.isActive
                      ? AppBadgeType.success
                      : AppBadgeType.neutral,
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => _openForm(productId: product.id),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                  IconButton(
                    tooltip: product.isActive ? 'Deactivate' : 'Activate',
                    onPressed: () => _confirmDeactivate(product),
                    icon: Icon(
                      product.isActive ? Icons.toggle_on : Icons.toggle_off,
                      color: product.isActive
                          ? AppColors.success
                          : AppColors.disabled,
                    ),
                  ),
                  if (isAdmin)
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(product),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
