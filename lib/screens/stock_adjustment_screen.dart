import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/app_error.dart';
import '../core/utils/formatters.dart';
import '../core/utils/responsive.dart';
import '../core/validators/validators.dart';
import '../models/stock_movement.dart';
import '../services/stock_service.dart';
import '../state/auth_controller.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_fields.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_surfaces.dart';

class StockAdjustmentScreen extends StatefulWidget {
  const StockAdjustmentScreen({super.key, this.productId});

  final String? productId;

  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = StockService();
  final _quantity = TextEditingController();
  final _unitCost = TextEditingController();
  final _reason = TextEditingController();
  final _notes = TextEditingController();

  List<StockBalance> _products = const [];
  String? _productId;
  String _direction = 'in';
  bool _loading = true;
  bool _saving = false;
  String? _error;
  StockBalance? _selected;

  @override
  void initState() {
    super.initState();
    _productId = widget.productId;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (AuthScope.of(context).user?.isAdmin != true) {
        throw const AppException('Only admins can adjust stock.');
      }
      _products = await _service.listBalances(isActive: true);
      if (_productId != null) {
        _selected = _products.cast<StockBalance?>().firstWhere(
              (p) => p?.productId == _productId,
              orElse: () => null,
            );
        if (_selected == null) {
          _selected = await _service.getBalance(_productId!);
          _products = [..._products, _selected!];
        }
      }
    } catch (error) {
      _error = AppError.messageOf(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_productId == null) {
      setState(() => _error = 'Product is required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _service.createAdjustment(
        productId: _productId!,
        direction: _direction,
        quantity: double.parse(_quantity.text.trim()),
        unitCost: _direction == 'in' && _unitCost.text.trim().isNotEmpty
            ? double.parse(_unitCost.text.trim())
            : null,
        reason: _reason.text,
        notes: _notes.text,
      );
      if (!mounted) return;
      AppSnackbar.show(context, 'Stock adjusted.');
      Navigator.pop(context, true);
    } catch (error) {
      setState(() => _error = AppError.messageOf(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    _unitCost.dispose();
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);

    return AppScaffold(
      title: 'Stock Adjustment',
      route: AppRoutes.stock,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                children: [
                  const AppSectionHeader(
                    title: 'Adjust stock',
                    subtitle:
                        'Admin-only. Stock out cannot reduce balance below zero.',
                  ),
                  const SizedBox(height: AppSizes.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppDropdown<String>(
                          label: 'Product',
                          value: _productId,
                          hint: 'Select product',
                          items: [
                            for (final product in _products)
                              DropdownMenuItem(
                                value: product.productId,
                                child: Text(
                                  '${product.productName}'
                                  '${product.sku == null ? '' : ' (${product.sku})'}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _productId = value;
                              _selected = _products.cast<StockBalance?>().firstWhere(
                                    (p) => p?.productId == value,
                                    orElse: () => null,
                                  );
                            });
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Product is required.'
                              : null,
                        ),
                        if (_selected != null) ...[
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            'Current stock ${Formatters.quantity(_selected!.currentStock)}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                        const SizedBox(height: AppSizes.md),
                        AppDropdown<String>(
                          label: 'Direction',
                          value: _direction,
                          items: const [
                            DropdownMenuItem(
                              value: 'in',
                              child: Text('Stock in'),
                            ),
                            DropdownMenuItem(
                              value: 'out',
                              child: Text('Stock out'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _direction = value);
                          },
                        ),
                        const SizedBox(height: AppSizes.md),
                        _twoCol(
                          desktop: desktop,
                          left: AppTextField(
                            label: 'Quantity',
                            controller: _quantity,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: Validators.positiveNumber,
                          ),
                          right: AppTextField(
                            label: 'Unit cost (optional)',
                            controller: _unitCost,
                            enabled: _direction == 'in',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (_direction != 'in') return null;
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              return Validators.nonNegativeNumber(
                                value,
                                'Unit cost',
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        AppTextField(
                          label: 'Reason',
                          controller: _reason,
                          validator: (value) =>
                              Validators.maxLength(value, 120, 'Reason'),
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
                              onPressed:
                                  _saving ? null : () => Navigator.pop(context),
                            ),
                            AppButton(
                              label: 'Save adjustment',
                              expanded: false,
                              isLoading: _saving,
                              onPressed: _saving ? null : _save,
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
        children: [left, const SizedBox(height: AppSizes.md), right],
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
