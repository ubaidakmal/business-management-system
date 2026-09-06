import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/app_error.dart';
import '../core/utils/formatters.dart';
import '../models/sale.dart';
import '../services/sale_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_states.dart';
import '../widgets/app_surfaces.dart';

class SaleDetailScreen extends StatefulWidget {
  const SaleDetailScreen({super.key, required this.saleId});

  final String saleId;

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  final _service = SaleService();
  Sale? _sale;
  bool _loading = true;
  bool _busy = false;
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
      final sale = await _service.getById(widget.saleId);
      if (!mounted) return;
      setState(() => _sale = sale);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = AppError.messageOf(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    final sale = _sale;
    if (sale == null || !sale.canCancel) return;

    final confirmed = await AppDialog.confirm(
      context,
      title: 'Cancel sale?',
      message:
          'Are you sure you want to cancel this sale? The record will be kept.',
      confirmLabel: 'Cancel sale',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await _service.cancel(sale.id);
      if (!mounted) return;
      AppSnackbar.show(context, 'Sale cancelled.');
      await _load();
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.show(context, AppError.messageOf(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.saleForm,
      arguments: widget.saleId,
    );
    if (result == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final sale = _sale;

    return AppScaffold(
      title: 'Sale Details',
      route: AppRoutes.sales,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorState(message: _error!, onRetry: _load)
              : sale == null
                  ? const AppEmptyState(
                      title: 'Sale not found',
                      message: 'This sale may have been removed.',
                    )
                  : ListView(
                      children: [
                        AppSectionHeader(
                          title: sale.invoiceNumber?.isNotEmpty == true
                              ? 'Invoice ${sale.invoiceNumber}'
                              : 'Sale',
                          subtitle:
                              'Historical sale. Completed sales include FIFO COGS and profit.',
                          action: Wrap(
                            spacing: AppSizes.sm,
                            children: [
                              if (sale.canEdit)
                                AppOutlinedButton(
                                  label: 'Edit',
                                  expanded: false,
                                  onPressed: _busy ? null : _edit,
                                ),
                              if (sale.canCancel)
                                AppOutlinedButton(
                                  label: 'Cancel',
                                  expanded: false,
                                  onPressed: _busy ? null : _cancel,
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
                                  Text(
                                    'Sale information',
                                    style: AppTextStyles.headingSmall,
                                  ),
                                  const Spacer(),
                                  AppBadge(
                                    label: sale.status,
                                    type: switch (sale.status) {
                                      'completed' => AppBadgeType.success,
                                      'draft' => AppBadgeType.info,
                                      'cancelled' => AppBadgeType.neutral,
                                      _ => AppBadgeType.neutral,
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.md),
                              AppDetailRow(
                                label: 'Company',
                                value: sale.companyName ?? '—',
                              ),
                              AppDetailRow(
                                label: 'Date',
                                value: Formatters.date(sale.saleDate),
                              ),
                              AppDetailRow(
                                label: 'Invoice',
                                value: sale.invoiceNumber?.isNotEmpty == true
                                    ? sale.invoiceNumber!
                                    : '—',
                              ),
                              AppDetailRow(
                                label: 'Reference',
                                value:
                                    sale.referenceNumber?.isNotEmpty == true
                                        ? sale.referenceNumber!
                                        : '—',
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
                                'Sale items',
                                style: AppTextStyles.headingSmall,
                              ),
                              const SizedBox(height: AppSizes.md),
                              if (sale.items.isEmpty)
                                Text(
                                  'No items on this sale.',
                                  style: AppTextStyles.bodySmall,
                                )
                              else
                                for (final item in sale.items)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSizes.md,
                                    ),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radius,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                          AppSizes.md,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName ?? 'Product',
                                              style: AppTextStyles.bodyMedium,
                                            ),
                                            Text(
                                              [
                                                if (item.productSku
                                                        ?.isNotEmpty ==
                                                    true)
                                                  'SKU ${item.productSku}',
                                                if (item.productUnit
                                                        ?.isNotEmpty ==
                                                    true)
                                                  item.productUnit!,
                                              ].join(' · '),
                                              style: AppTextStyles.bodySmall,
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 16,
                                              runSpacing: 4,
                                              children: [
                                                Text(
                                                  'Qty ${Formatters.quantity(item.quantity)}',
                                                ),
                                                Text(
                                                  'Price ${Formatters.money(item.unitPrice)}',
                                                ),
                                                Text(
                                                  'Revenue ${Formatters.money(item.revenue)}',
                                                ),
                                                if (sale.showsCosting) ...[
                                                  Text(
                                                    'COGS ${Formatters.money(item.cogs)}',
                                                  ),
                                                  Text(
                                                    'Profit ${Formatters.money(item.lineProfit)}',
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
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
                              Text('Summary', style: AppTextStyles.headingSmall),
                              const SizedBox(height: AppSizes.md),
                              AppDetailRow(
                                label: 'Subtotal',
                                value: Formatters.money(sale.subtotal),
                              ),
                              AppDetailRow(
                                label: 'Discount',
                                value: Formatters.money(sale.discount),
                              ),
                              AppDetailRow(
                                label: 'Other charges',
                                value: Formatters.money(sale.otherCharges),
                              ),
                              AppDetailRow(
                                label: 'Total',
                                value: Formatters.money(sale.totalAmount),
                              ),
                              if (sale.showsCosting) ...[
                                AppDetailRow(
                                  label: 'Total COGS (FIFO)',
                                  value: Formatters.money(sale.totalCogs),
                                ),
                                AppDetailRow(
                                  label: 'Total profit',
                                  value: Formatters.money(sale.totalProfit),
                                ),
                              ],
                              if (sale.notes?.isNotEmpty == true) ...[
                                const SizedBox(height: AppSizes.md),
                                Text('Notes', style: AppTextStyles.label),
                                const SizedBox(height: 4),
                                Text(
                                  sale.notes!,
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                              if (sale.createdAt != null) ...[
                                const SizedBox(height: AppSizes.md),
                                AppDetailRow(
                                  label: 'Created',
                                  value: Formatters.dateTime(
                                    sale.createdAt!,
                                  ),
                                ),
                              ],
                              if (sale.updatedAt != null)
                                AppDetailRow(
                                  label: 'Updated',
                                  value: Formatters.dateTime(
                                    sale.updatedAt!,
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
