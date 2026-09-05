import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/app_error.dart';
import '../core/utils/responsive.dart';
import '../core/validators/validators.dart';
import '../models/company.dart';
import '../models/product.dart';
import '../services/company_service.dart';
import '../services/product_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_fields.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_surfaces.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _companyService = CompanyService();

  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _barcode = TextEditingController();
  final _category = TextEditingController();
  final _unit = TextEditingController();
  final _description = TextEditingController();
  final _purchasePrice = TextEditingController(text: '0');
  final _salePrice = TextEditingController(text: '0');
  final _openingStock = TextEditingController(text: '0');

  List<Company> _companies = const [];
  String? _companyId;
  bool _isActive = true;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _companies = await _companyService.list(isActive: true);
      if (_isEditing) {
        final product = await _productService.getById(widget.productId!);
        _companyId = product.companyId;
        _name.text = product.name;
        _sku.text = product.sku ?? '';
        _barcode.text = product.barcode ?? '';
        _category.text = product.category ?? '';
        _unit.text = product.unit ?? '';
        _description.text = product.description ?? '';
        _purchasePrice.text = product.purchasePrice.toStringAsFixed(2);
        _salePrice.text = product.salePrice.toStringAsFixed(2);
        _openingStock.text = product.openingStock.toString();
        _isActive = product.isActive;

        // Keep selected company visible even if inactive.
        if (!_companies.any((c) => c.id == product.companyId)) {
          try {
            final company = await _companyService.getById(product.companyId);
            _companies = [..._companies, company];
          } catch (_) {}
        }
      } else if (_companies.length == 1) {
        _companyId = _companies.first.id;
      }
    } catch (error) {
      _error = AppError.messageOf(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _barcode.dispose();
    _category.dispose();
    _unit.dispose();
    _description.dispose();
    _purchasePrice.dispose();
    _salePrice.dispose();
    _openingStock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final product = Product(
      id: widget.productId ?? '',
      companyId: _companyId!,
      name: _name.text,
      sku: _sku.text,
      barcode: _barcode.text,
      category: _category.text,
      unit: _unit.text,
      description: _description.text,
      purchasePrice: double.parse(_purchasePrice.text.trim()),
      salePrice: double.parse(_salePrice.text.trim()),
      openingStock: double.parse(_openingStock.text.trim()),
      isActive: _isActive,
    );

    try {
      if (_isEditing) {
        await _productService.update(product);
      } else {
        await _productService.create(product);
      }
      if (!mounted) return;
      AppSnackbar.show(
        context,
        _isEditing ? 'Product updated.' : 'Product created.',
      );
      Navigator.pop(context, true);
    } catch (error) {
      setState(() => _error = AppError.messageOf(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);

    return AppScaffold(
      title: _isEditing ? 'Edit Product' : 'Add Product',
      route: '/products',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                children: [
                  AppSectionHeader(
                    title: _isEditing ? 'Edit product' : 'New product',
                    subtitle:
                        'Opening stock is the starting quantity only. Inventory movements come later.',
                  ),
                  const SizedBox(height: AppSizes.lg),
                  AppCard(
                    child: Column(
                      children: [
                        AppDropdown<String>(
                          label: 'Company',
                          value: _companyId,
                          hint: 'Select company',
                          items: [
                            for (final company in _companies)
                              DropdownMenuItem(
                                value: company.id,
                                child: Text(
                                  company.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _companyId = value),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Company is required.'
                              : null,
                        ),
                        if (_companies.isEmpty) ...[
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            'Create an active company before adding products.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSizes.md),
                        AppTextField(
                          label: 'Product name',
                          controller: _name,
                          validator: (value) =>
                              Validators.requiredField(value, 'Product name') ??
                              Validators.maxLength(value, 160, 'Product name'),
                        ),
                        const SizedBox(height: AppSizes.md),
                        _twoCol(
                          desktop: desktop,
                          left: AppTextField(
                            label: 'SKU',
                            controller: _sku,
                            validator: (value) =>
                                Validators.maxLength(value, 60, 'SKU'),
                          ),
                          right: AppTextField(
                            label: 'Barcode',
                            controller: _barcode,
                            validator: (value) =>
                                Validators.maxLength(value, 60, 'Barcode'),
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        _twoCol(
                          desktop: desktop,
                          left: AppTextField(
                            label: 'Category',
                            controller: _category,
                            validator: (value) =>
                                Validators.maxLength(value, 80, 'Category'),
                          ),
                          right: AppTextField(
                            label: 'Unit',
                            controller: _unit,
                            hint: 'pcs, kg, box…',
                            validator: (value) =>
                                Validators.maxLength(value, 30, 'Unit'),
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        _twoCol(
                          desktop: desktop,
                          left: AppTextField(
                            label: 'Purchase price',
                            controller: _purchasePrice,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) => Validators.nonNegativeNumber(
                              value,
                              'Purchase price',
                            ),
                          ),
                          right: AppTextField(
                            label: 'Sale price',
                            controller: _salePrice,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) => Validators.nonNegativeNumber(
                              value,
                              'Sale price',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        AppTextField(
                          label: 'Opening stock',
                          controller: _openingStock,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) => Validators.nonNegativeNumber(
                            value,
                            'Opening stock',
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        AppTextField(
                          label: 'Description',
                          controller: _description,
                          maxLines: 3,
                          validator: (value) =>
                              Validators.maxLength(value, 500, 'Description'),
                        ),
                        const SizedBox(height: AppSizes.md),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Active'),
                          value: _isActive,
                          activeThumbColor: AppColors.success,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppSizes.sm),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _error!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSizes.lg),
                        Row(
                          children: [
                            AppOutlinedButton(
                              label: 'Cancel',
                              expanded: false,
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.pop(context),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: AppButton(
                                label: _isEditing
                                    ? 'Save changes'
                                    : 'Create product',
                                isLoading: _saving,
                                onPressed: _saving || _companies.isEmpty
                                    ? null
                                    : _save,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _twoCol({
    required bool desktop,
    required Widget left,
    required Widget right,
  }) {
    if (!desktop) {
      return Column(
        children: [
          left,
          const SizedBox(height: AppSizes.md),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSizes.md),
        Expanded(child: right),
      ],
    );
  }
}
