import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatters.dart';
import '../core/utils/responsive.dart';
import '../models/company.dart';
import '../models/purchase.dart';
import '../services/company_service.dart';
import '../state/app_status.dart';
import '../state/purchases_controller.dart';
import '../state/locale_controller.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_fields.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_states.dart';
import '../widgets/app_surfaces.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final _controller = PurchasesController();
  final _companies = CompanyService();
  final _search = TextEditingController();
  Timer? _debounce;
  List<Company> _companyOptions = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
    _bootstrap();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
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

  Future<void> _openForm({String? purchaseId}) async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.purchaseForm,
      arguments: purchaseId,
    );
    if (changed == true) await _controller.load();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_controller.dateFrom ?? DateTime.now())
        : (_controller.dateTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    await _controller.setDateRange(
      from: isFrom ? picked : _controller.dateFrom,
      to: isFrom ? _controller.dateTo : picked,
    );
  }

  Future<void> _cancel(Purchase purchase) async {
    final l10n = context.l10n;
    final ok = await AppDialog.confirm(
      context,
      title: l10n.cancelPurchase,
      message:
          'Are you sure you want to cancel this purchase? The record will be kept.',
      confirmLabel: l10n.cancelPurchase,
    );
    if (!ok) return;
    final success = await _controller.cancel(purchase);
    if (!mounted) return;
    if (success) {
      AppSnackbar.show(context, 'Purchase cancelled.');
    } else if (_controller.errorMessage != null) {
      AppSnackbar.show(context, _controller.errorMessage!, isError: true);
    }
  }

  AppBadgeType _statusType(String status) {
    return switch (status) {
      'completed' => AppBadgeType.success,
      'draft' => AppBadgeType.info,
      'cancelled' => AppBadgeType.neutral,
      _ => AppBadgeType.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final desktop = AppResponsive.isDesktop(context);

    return AppScaffold(
      title: l10n.purchasesTitle,
      route: AppRoutes.purchases,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: l10n.purchasesTitle,
            subtitle:
                'Record purchases from companies. Stock updates come later.',
            action: AppButton(
              label: l10n.addPurchase,
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
                width: desktop ? 260 : double.infinity,
                child: AppSearchField(
                  controller: _search,
                  hint: 'Search invoice, reference, company',
                  onChanged: _onSearch,
                ),
              ),
              SizedBox(
                width: desktop ? 200 : double.infinity,
                child: AppDropdown<String?>(
                  label: l10n.company,
                  value: _controller.companyId,
                  hint: l10n.allCompanies,
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.all)),
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
                width: desktop ? 160 : double.infinity,
                child: AppDropdown<String?>(
                  label: l10n.status,
                  value: _controller.statusFilter,
                  hint: l10n.all,
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.all)),
                    DropdownMenuItem(value: 'draft', child: Text(l10n.draft)),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text(l10n.completed),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text(l10n.cancelled),
                    ),
                  ],
                  onChanged: _controller.setStatusFilter,
                ),
              ),
              SizedBox(
                width: desktop ? 150 : double.infinity,
                child: OutlinedButton(
                  onPressed: () => _pickDate(isFrom: true),
                  child: Text(
                    _controller.dateFrom == null
                        ? 'From date'
                        : Formatters.date(_controller.dateFrom),
                  ),
                ),
              ),
              SizedBox(
                width: desktop ? 150 : double.infinity,
                child: OutlinedButton(
                  onPressed: () => _pickDate(isFrom: false),
                  child: Text(
                    _controller.dateTo == null
                        ? 'To date'
                        : Formatters.date(_controller.dateTo),
                  ),
                ),
              ),
              if (_controller.dateFrom != null || _controller.dateTo != null)
                TextButton(
                  onPressed: () => _controller.setDateRange(),
                  child: Text('Clear dates'),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Expanded(child: _buildBody(desktop: desktop)),
        ],
      ),
    );
  }

  Widget _buildBody({required bool desktop}) {
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
      final l10n = context.l10n;
      return AppEmptyState(
        title: l10n.noPurchasesYet,
        message: 'Create your first purchase to get started.',
        actionLabel: l10n.addPurchase,
        onAction: () => _openForm(),
      );
    }

    if (desktop) {
      return AppCard(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Builder(
                builder: (context) {
                  final l10n = context.l10n;
                  return Row(
                    children: [
                      Expanded(child: Text(l10n.date, style: AppTextStyles.label)),
                      Expanded(
                        flex: 2,
                        child: Text(l10n.company, style: AppTextStyles.label),
                      ),
                      Expanded(child: Text(l10n.invoice, style: AppTextStyles.label)),
                      Expanded(child: Text(l10n.items, style: AppTextStyles.label)),
                      Expanded(child: Text(l10n.total, style: AppTextStyles.label)),
                      Expanded(child: Text(l10n.status, style: AppTextStyles.label)),
                      SizedBox(
                        width: 120,
                        child: Text(l10n.actions, style: AppTextStyles.label),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: _controller.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return _desktopRow(_controller.items[index]);
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
        final purchase = _controller.items[index];
        return AppCard(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.purchaseDetail,
            arguments: purchase.id,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      purchase.companyName ?? context.l10n.emDash,
                      style: AppTextStyles.headingSmall,
                    ),
                  ),
                  AppBadge(
                    label: purchase.status,
                    type: _statusType(purchase.status),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(Formatters.date(purchase.purchaseDate)),
              Text(
                purchase.invoiceNumber?.isNotEmpty == true
                    ? 'Invoice ${purchase.invoiceNumber}'
                    : 'No invoice',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Total ${Formatters.money(purchase.totalAmount)} · ${purchase.itemCount} items',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (purchase.canEdit)
                    AppOutlinedButton(
                      label: context.l10n.edit,
                      expanded: false,
                      onPressed: () => _openForm(purchaseId: purchase.id),
                    ),
                  if (purchase.canCancel)
                    AppOutlinedButton(
                      label: context.l10n.cancel,
                      expanded: false,
                      onPressed: () => _cancel(purchase),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _desktopRow(Purchase purchase) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.purchaseDetail,
        arguments: purchase.id,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(Formatters.date(purchase.purchaseDate))),
            Expanded(
              flex: 2,
              child: Text(
                purchase.companyName ?? context.l10n.emDash,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                purchase.invoiceNumber?.isNotEmpty == true
                    ? purchase.invoiceNumber!
                    : context.l10n.emDash,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(child: Text('${purchase.itemCount}')),
            Expanded(child: Text(Formatters.money(purchase.totalAmount))),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppBadge(
                  label: purchase.status,
                  type: _statusType(purchase.status),
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  if (purchase.canEdit)
                    IconButton(
                      tooltip: context.l10n.edit,
                      onPressed: () => _openForm(purchaseId: purchase.id),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                  if (purchase.canCancel)
                    IconButton(
                      tooltip: context.l10n.cancel,
                      onPressed: () => _cancel(purchase),
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 20,
                        color: AppColors.warning,
                      ),
                    ),
                  IconButton(
                    tooltip: 'View',
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.purchaseDetail,
                      arguments: purchase.id,
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 20),
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
