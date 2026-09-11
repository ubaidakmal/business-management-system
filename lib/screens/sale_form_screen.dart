import 'package:flutter/material.dart';

import '../state/locale_controller.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/app_error.dart';
import '../core/utils/formatters.dart';
import '../core/utils/responsive.dart';
import '../core/validators/validators.dart';
import '../models/company.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/company_service.dart';
import '../services/product_service.dart';
import '../services/sale_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_fields.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/app_states.dart';

class _DraftItem {
  _DraftItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  final Product product;
  double quantity;
  double unitPrice;

  double get lineTotal =>
      SaleMath.lineTotal(quantity: quantity, unitPrice: unitPrice);
}

class SaleFormScreen extends StatefulWidget {
  const SaleFormScreen({super.key, this.saleId});

  final String? saleId;

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _saleService = SaleService();
  final _companyService = CompanyService();
  final _productService = ProductService();

  final _invoice = TextEditingController();
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  final _discount = TextEditingController(text: '0');
  final _otherCharges = TextEditingController(text: '0');

  List<Company> _companies = const [];
  List<Product> _products = const [];
  final List<_DraftItem> _items = [];

  String? _companyId;
  DateTime _saleDate = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.saleId != null;

  double get _subtotal => SaleMath.subtotal(
    _items.map(
      (item) => SaleItem(
        productId: item.product.id,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        lineTotal: item.lineTotal,
      ),
    ),
  );

  double get _discountValue => double.tryParse(_discount.text.trim()) ?? 0;
  double get _otherChargesValue =>
      double.tryParse(_otherCharges.text.trim()) ?? 0;

  double get _grandTotal => SaleMath.grandTotal(
    subtotal: _subtotal,
    discount: _discountValue,
    otherCharges: _otherChargesValue,
  );

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
        final sale = await _saleService.getById(widget.saleId!);
        if (!sale.canEdit) {
          throw const AppException('Only draft sales can be edited.');
        }
        _companyId = sale.companyId;
        _saleDate = sale.saleDate;
        _invoice.text = sale.invoiceNumber ?? '';
        _reference.text = sale.referenceNumber ?? '';
        _notes.text = sale.notes ?? '';
        _discount.text = sale.discount.toStringAsFixed(2);
        _otherCharges.text = sale.otherCharges.toStringAsFixed(2);

        if (!_companies.any((c) => c.id == sale.companyId)) {
          try {
            _companies = [
              ..._companies,
              await _companyService.getById(sale.companyId),
            ];
          } catch (_) {}
        }

        await _loadProducts(sale.companyId);
        for (final item in sale.items) {
          final product =
              _products.cast<Product?>().firstWhere(
                (p) => p?.id == item.productId,
                orElse: () => null,
              ) ??
              Product(
                id: item.productId,
                companyId: sale.companyId,
                name: item.productName ?? 'Product',
                sku: item.productSku,
                unit: item.productUnit,
                salePrice: item.unitPrice,
              );
          if (!_products.any((p) => p.id == product.id)) {
            _products = [..._products, product];
          }
          _items.add(
            _DraftItem(
              product: product,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
            ),
          );
        }
      } else if (_companies.length == 1) {
        _companyId = _companies.first.id;
        await _loadProducts(_companyId!);
      }
    } catch (error) {
      _error = AppError.messageOf(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadProducts(String companyId) async {
    _products = await _productService.list(
      companyId: companyId,
      isActive: true,
    );
  }

  Future<void> _onCompanyChanged(String? companyId) async {
    setState(() {
      _companyId = companyId;
      _items.clear();
      _products = const [];
    });
    if (companyId == null) return;
    try {
      await _loadProducts(companyId);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        setState(() => _error = AppError.messageOf(error));
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _saleDate = picked);
  }

  Future<void> _addItem() async {
    if (_companyId == null) {
      AppSnackbar.show(context, 'Select a company first.', isError: true);
      return;
    }
    if (_products.isEmpty) {
      AppSnackbar.show(
        context,
        'No active products for this company.',
        isError: true,
      );
      return;
    }

    Product? selected = _products.first;
    final qtyController = TextEditingController(text: '1');
    final costController = TextEditingController(
      text: selected.salePrice.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Add product'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppDropdown<Product>(
                        label: 'Product',
                        value: selected,
                        items: [
                          for (final product in _products)
                            DropdownMenuItem(
                              value: product,
                              child: Text(
                                '${product.name}${product.sku == null ? '' : ' (${product.sku})'}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setLocal(() {
                            selected = value;
                            costController.text = value.salePrice
                                .toStringAsFixed(2);
                          });
                        },
                      ),
                      const SizedBox(height: AppSizes.md),
                      AppTextField(
                        label: 'Quantity',
                        controller: qtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.positiveNumber,
                      ),
                      const SizedBox(height: AppSizes.md),
                      AppTextField(
                        label: 'Unit price',
                        controller: costController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) =>
                            Validators.nonNegativeNumber(value, 'Unit price'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || selected == null) return;

    final quantity = double.parse(qtyController.text.trim());
    final unitPrice = double.parse(costController.text.trim());
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == selected!.id,
    );
    var merged = false;

    setState(() {
      if (existingIndex >= 0) {
        final existing = _items[existingIndex];
        existing.quantity = SaleMath.roundMoney(existing.quantity + quantity);
        existing.unitPrice = unitPrice;
        merged = true;
      } else {
        _items.add(
          _DraftItem(
            product: selected!,
            quantity: quantity,
            unitPrice: unitPrice,
          ),
        );
      }
      _error = null;
    });

    if (merged && mounted) {
      AppSnackbar.show(
        context,
        'Product already on this sale. Quantity updated.',
      );
    }
  }

  Future<void> _editItem(_DraftItem item) async {
    final qtyController = TextEditingController(text: item.quantity.toString());
    final costController = TextEditingController(
      text: item.unitPrice.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item.product.name),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Quantity',
                  controller: qtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.positiveNumber,
                ),
                const SizedBox(height: AppSizes.md),
                AppTextField(
                  label: 'Unit price',
                  controller: costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      Validators.nonNegativeNumber(value, 'Unit price'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    setState(() {
      item.quantity = double.parse(qtyController.text.trim());
      item.unitPrice = double.parse(costController.text.trim());
    });
  }

  Future<void> _save({required String status}) async {
    FocusScope.of(context).unfocus();
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_companyId == null) {
      setState(() => _error = 'Company is required.');
      return;
    }
    if (_items.isEmpty) {
      setState(() => _error = 'Add at least one product.');
      return;
    }
    if (_grandTotal < 0) {
      setState(() => _error = 'Total amount cannot be negative.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final payloadItems = [
      for (final item in _items)
        SaleItem(
          productId: item.product.id,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          lineTotal: item.lineTotal,
        ),
    ];

    try {
      if (_isEditing) {
        await _saleService.updateDraft(
          saleId: widget.saleId!,
          companyId: _companyId!,
          saleDate: _saleDate,
          invoiceNumber: _invoice.text,
          referenceNumber: _reference.text,
          notes: _notes.text,
          discount: _discountValue,
          otherCharges: _otherChargesValue,
          status: status,
          items: payloadItems,
        );
      } else {
        await _saleService.create(
          companyId: _companyId!,
          saleDate: _saleDate,
          invoiceNumber: _invoice.text,
          referenceNumber: _reference.text,
          notes: _notes.text,
          discount: _discountValue,
          otherCharges: _otherChargesValue,
          status: status,
          items: payloadItems,
        );
      }
      if (!mounted) return;
      AppSnackbar.show(
        context,
        status == 'completed'
            ? 'Sale completed.'
            : (_isEditing ? 'Draft updated.' : 'Draft saved.'),
      );
      Navigator.pop(context, true);
    } catch (error) {
      setState(() => _error = AppError.messageOf(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _invoice.dispose();
    _reference.dispose();
    _notes.dispose();
    _discount.dispose();
    _otherCharges.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);

    return AppScaffold(
      title: _isEditing ? context.l10n.editSale : context.l10n.addSale,
      route: AppRoutes.sales,
      body: _loading
          ? const AppLoading()
          : Form(
              key: _formKey,
              child: ListView(
                children: [
                  AppSectionHeader(
                    title: _isEditing ? 'Edit draft sale' : 'New sale',
                    subtitle:
                        'Totals are calculated from line items. Stock is not updated yet.',
                  ),
                  const SizedBox(height: AppSizes.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Sale information',
                          style: AppTextStyles.headingSmall,
                        ),
                        const SizedBox(height: AppSizes.md),
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
                          onChanged: _saving
                              ? (_) {}
                              : (value) {
                                  _onCompanyChanged(value);
                                },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Company is required.'
                              : null,
                        ),
                        const SizedBox(height: AppSizes.md),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _pickDate,
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(Formatters.date(_saleDate)),
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        _twoCol(
                          desktop: desktop,
                          left: AppTextField(
                            label: 'Invoice number',
                            controller: _invoice,
                            validator: (value) => Validators.maxLength(
                              value,
                              60,
                              'Invoice number',
                            ),
                          ),
                          right: AppTextField(
                            label: 'Reference number',
                            controller: _reference,
                            validator: (value) => Validators.maxLength(
                              value,
                              60,
                              'Reference number',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Sale items',
                                style: AppTextStyles.headingSmall,
                              ),
                            ),
                            AppButton(
                              label: 'Add Product',
                              expanded: false,
                              icon: Icons.add,
                              onPressed: _saving ? null : _addItem,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.md),
                        if (_items.isEmpty)
                          Text(
                            'No products added yet.',
                            style: AppTextStyles.bodySmall,
                          )
                        else
                          ..._items.map(_itemCard),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Summary', style: AppTextStyles.headingSmall),
                        const SizedBox(height: AppSizes.md),
                        AppDetailRow(
                          label: 'Subtotal',
                          value: Formatters.money(_subtotal),
                        ),
                        _twoCol(
                          desktop: desktop,
                          left: AppTextField(
                            label: 'Discount',
                            controller: _discount,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (value) =>
                                Validators.nonNegativeNumber(value, 'Discount'),
                          ),
                          right: AppTextField(
                            label: 'Other charges',
                            controller: _otherCharges,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (value) => Validators.nonNegativeNumber(
                              value,
                              'Other charges',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          'Total ${Formatters.money(_grandTotal)}',
                          style: AppTextStyles.headingSmall,
                        ),
                        const SizedBox(height: AppSizes.md),
                        AppTextField(
                          label: 'Notes',
                          controller: _notes,
                          maxLines: 3,
                          validator: (value) =>
                              Validators.maxLength(value, 500, 'Notes'),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            _error!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSizes.lg),
                        Wrap(
                          spacing: AppSizes.md,
                          runSpacing: AppSizes.md,
                          children: [
                            AppOutlinedButton(
                              label: 'Cancel',
                              expanded: false,
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.pop(context),
                            ),
                            AppOutlinedButton(
                              label: 'Save draft',
                              expanded: false,
                              onPressed: _saving
                                  ? null
                                  : () => _save(status: 'draft'),
                            ),
                            AppButton(
                              label: 'Complete sale',
                              expanded: false,
                              isLoading: _saving,
                              onPressed: _saving
                                  ? null
                                  : () => _save(status: 'completed'),
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

  Widget _itemCard(_DraftItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.radius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.product.name,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: _saving ? null : () => _editItem(item),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: _saving
                        ? null
                        : () => setState(() => _items.remove(item)),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              Text(
                [
                  if (item.product.sku?.isNotEmpty == true)
                    'SKU ${item.product.sku}',
                  if (item.product.unit?.isNotEmpty == true) item.product.unit!,
                ].join(' · '),
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text('Qty ${Formatters.quantity(item.quantity)}'),
                  Text('Price ${Formatters.money(item.unitPrice)}'),
                  Text('Line ${Formatters.money(item.lineTotal)}'),
                ],
              ),
            ],
          ),
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
