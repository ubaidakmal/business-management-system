import 'package:flutter/material.dart';

import '../state/locale_controller.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/app_error.dart';
import '../core/utils/formatters.dart';
import '../models/stock_movement.dart';
import '../services/stock_service.dart';
import '../state/auth_controller.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_states.dart';
import '../widgets/app_surfaces.dart';

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final _service = StockService();
  StockBalance? _balance;
  List<StockMovement> _movements = const [];
  bool _loading = true;
  String? _error;

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
      final balance = await _service.getBalance(widget.productId);
      final movements = await _service.listMovements(widget.productId);
      if (!mounted) return;
      setState(() {
        _balance = balance;
        _movements = movements;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = AppError.messageOf(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _adjust() async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.stockAdjustment,
      arguments: widget.productId,
    );
    if (changed == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final balance = _balance;
    final isAdmin = AuthScope.of(context).user?.isAdmin == true;

    return AppScaffold(
      title: context.l10n.stockDetails,
      route: AppRoutes.stock,
      body: _loading
          ? const AppLoading()
          : _error != null
          ? AppErrorState(message: _error!, onRetry: _load)
          : balance == null
          ? const AppEmptyState(
              title: 'Not found',
              message: 'This product stock record was not found.',
            )
          : ListView(
              children: [
                AppSectionHeader(
                  title: balance.productName,
                  subtitle: balance.companyName,
                  action: isAdmin
                      ? AppOutlinedButton(
                          label: 'Adjust',
                          expanded: false,
                          onPressed: _adjust,
                        )
                      : null,
                ),
                const SizedBox(height: AppSizes.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Stock summary',
                            style: AppTextStyles.headingSmall,
                          ),
                          const Spacer(),
                          if (balance.isLowStock)
                            const AppBadge(
                              label: 'Low stock',
                              type: AppBadgeType.warning,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                      AppDetailRow(
                        label: 'SKU',
                        value: balance.sku?.isNotEmpty == true
                            ? balance.sku!
                            : '—',
                      ),
                      AppDetailRow(
                        label: 'Unit',
                        value: balance.unit?.isNotEmpty == true
                            ? balance.unit!
                            : '—',
                      ),
                      AppDetailRow(
                        label: 'Opening stock',
                        value: Formatters.quantity(balance.openingStock),
                      ),
                      AppDetailRow(
                        label: 'Movements',
                        value: Formatters.quantity(balance.movementQty),
                      ),
                      AppDetailRow(
                        label: 'Current stock',
                        value: Formatters.quantity(balance.currentStock),
                      ),
                      AppDetailRow(
                        label: 'Reorder level',
                        value: Formatters.quantity(balance.reorderLevel),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Movement history',
                        style: AppTextStyles.headingSmall,
                      ),
                      const SizedBox(height: AppSizes.md),
                      if (_movements.isEmpty)
                        Text(
                          'No movements yet.',
                          style: AppTextStyles.bodySmall,
                        )
                      else
                        for (final movement in _movements)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSizes.md),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radius,
                                ),
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
                                            movement.typeLabel,
                                            style: AppTextStyles.bodyMedium,
                                          ),
                                        ),
                                        Text(
                                          Formatters.quantity(
                                            movement.quantity,
                                          ),
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color: movement.quantity < 0
                                                    ? AppColors.error
                                                    : AppColors.success,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.dateTime(movement.createdAt),
                                      style: AppTextStyles.bodySmall,
                                    ),
                                    if (movement.referenceType != null)
                                      Text(
                                        'Ref ${movement.referenceType}'
                                        '${movement.referenceId == null ? '' : ' · ${movement.referenceId!.substring(0, 8)}'}',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    if (movement.reason?.isNotEmpty == true)
                                      Text(
                                        movement.reason!,
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    if (movement.notes?.isNotEmpty == true)
                                      Text(
                                        movement.notes!,
                                        style: AppTextStyles.bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
