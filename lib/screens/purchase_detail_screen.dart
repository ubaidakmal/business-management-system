import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/app_error.dart';
import '../core/utils/formatters.dart';
import '../models/purchase.dart';
import '../services/purchase_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_states.dart';
import '../widgets/app_surfaces.dart';

class PurchaseDetailScreen extends StatefulWidget {
  const PurchaseDetailScreen({super.key, required this.purchaseId});

  final String purchaseId;

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  final _service = PurchaseService();
  Purchase? _purchase;
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
      final purchase = await _service.getById(widget.purchaseId);
      if (!mounted) return;
      setState(() => _purchase = purchase);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = AppError.messageOf(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    final purchase = _purchase;
    if (purchase == null || !purchase.canCancel) return;

    final confirmed = await AppDialog.confirm(
      context,
      title: 'Cancel purchase?',
      message:
          'Are you sure you want to cancel this purchase? The record will be kept.',
      confirmLabel: 'Cancel purchase',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await _service.cancel(purchase.id);
      if (!mounted) return;
      AppSnackbar.show(context, 'Purchase cancelled.');
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
      AppRoutes.purchaseForm,
      arguments: widget.purchaseId,
    );
    if (result == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final purchase = _purchase;

    return AppScaffold(
      title: 'Purchase Details',
      route: AppRoutes.purchases,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorState(message: _error!, onRetry: _load)
              : purchase == null
                  ? const AppEmptyState(
                      title: 'Purchase not found',
                      message: 'This purchase may have been removed.',
                    )
                  : ListView(
                      children: [
                        AppSectionHeader(
                          title: purchase.invoiceNumber?.isNotEmpty == true
                              ? 'Invoice ${purchase.invoiceNumber}'
                              : 'Purchase',
                          subtitle:
                              'Historical purchase transaction. Stock is not updated in this phase.',
                          action: Wrap(
                            spacing: AppSizes.sm,
                            children: [
                              if (purchase.canEdit)
                                AppOutlinedButton(
                                  label: 'Edit',
                                  expanded: false,
                                  onPressed: _busy ? null : _edit,
                                ),
                              if (purchase.canCancel)
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
                                    'Purchase information',
                                    style: AppTextStyles.headingSmall,
                                  ),
                                  const Spacer(),
                                  AppBadge(
                                    label: purchase.status,
                                    type: switch (purchase.status) {
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
                                value: purchase.companyName ?? '—',
                              ),
                              AppDetailRow(
                                label: 'Date',
                                value: Formatters.date(purchase.purchaseDate),
                              ),
                              AppDetailRow(
                                label: 'Invoice',
                                value: purchase.invoiceNumber?.isNotEmpty == true
                                    ? purchase.invoiceNumber!
                                    : '—',
                              ),
                              AppDetailRow(
                                label: 'Reference',
                                value:
                                    purchase.referenceNumber?.isNotEmpty == true
                                        ? purchase.referenceNumber!
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
                                'Purchase items',
                                style: AppTextStyles.headingSmall,
                              ),
                              const SizedBox(height: AppSizes.md),
                              if (purchase.items.isEmpty)
                                Text(
                                  'No items on this purchase.',
                                  style: AppTextStyles.bodySmall,
                                )
                              else
                                for (final item in purchase.items)
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
                                                  'Cost ${Formatters.money(item.unitCost)}',
                                                ),
                                                Text(
                                                  'Line ${Formatters.money(item.lineTotal)}',
                                                ),
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
                                value: Formatters.money(purchase.subtotal),
                              ),
                              AppDetailRow(
                                label: 'Discount',
                                value: Formatters.money(purchase.discount),
                              ),
                              AppDetailRow(
                                label: 'Other charges',
                                value: Formatters.money(purchase.otherCharges),
                              ),
                              AppDetailRow(
                                label: 'Total',
                                value: Formatters.money(purchase.totalAmount),
                              ),
                              if (purchase.notes?.isNotEmpty == true) ...[
                                const SizedBox(height: AppSizes.md),
                                Text('Notes', style: AppTextStyles.label),
                                const SizedBox(height: 4),
                                Text(
                                  purchase.notes!,
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                              if (purchase.createdAt != null) ...[
                                const SizedBox(height: AppSizes.md),
                                AppDetailRow(
                                  label: 'Created',
                                  value: Formatters.dateTime(
                                    purchase.createdAt!,
                                  ),
                                ),
                              ],
                              if (purchase.updatedAt != null)
                                AppDetailRow(
                                  label: 'Updated',
                                  value: Formatters.dateTime(
                                    purchase.updatedAt!,
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
