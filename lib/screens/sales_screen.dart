import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatters.dart';
import '../core/utils/responsive.dart';
import '../models/company.dart';
import '../models/sale.dart';
import '../services/company_service.dart';
import '../state/app_status.dart';
import '../state/sales_controller.dart';
import '../state/locale_controller.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_fields.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_states.dart';
import '../widgets/app_surfaces.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _controller = SalesController();
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

  Future<void> _openForm({String? saleId}) async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.saleForm,
      arguments: saleId,
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

  Future<void> _cancel(Sale sale) async {
    final l10n = context.l10n;
    final ok = await AppDialog.confirm(
      context,
      title: l10n.cancelSale,
      message:
          'Are you sure you want to cancel this sale? The record will be kept.',
      confirmLabel: l10n.cancelSale,
    );
    if (!ok) return;
    final success = await _controller.cancel(sale);
    if (!mounted) return;
    if (success) {
      AppSnackbar.show(context, 'Sale cancelled.');
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
      title: l10n.salesTitle,
      route: AppRoutes.sales,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: l10n.salesTitle,
            subtitle:
                'Record sales to customers/companies. Stock updates come later.',
            action: AppButton(
              label: l10n.addSale,
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
        title: l10n.noSalesYet,
        message: 'Create your first sale to get started.',
        actionLabel: l10n.addSale,
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
        final sale = _controller.items[index];
        return AppCard(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.saleDetail,
            arguments: sale.id,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sale.companyName ?? context.l10n.emDash,
                      style: AppTextStyles.headingSmall,
                    ),
                  ),
                  AppBadge(label: sale.status, type: _statusType(sale.status)),
                ],
              ),
              const SizedBox(height: 6),
              Text(Formatters.date(sale.saleDate)),
              Text(
                sale.invoiceNumber?.isNotEmpty == true
                    ? 'Invoice ${sale.invoiceNumber}'
                    : 'No invoice',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                sale.isCompleted
                    ? 'Total ${Formatters.money(sale.totalAmount)} · Profit ${Formatters.money(sale.totalProfit)} · ${sale.itemCount} items'
                    : 'Total ${Formatters.money(sale.totalAmount)} · ${sale.itemCount} items',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (sale.canEdit)
                    AppOutlinedButton(
                      label: context.l10n.edit,
                      expanded: false,
                      onPressed: () => _openForm(saleId: sale.id),
                    ),
                  if (sale.canCancel)
                    AppOutlinedButton(
                      label: context.l10n.cancel,
                      expanded: false,
                      onPressed: () => _cancel(sale),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _desktopRow(Sale sale) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.saleDetail,
        arguments: sale.id,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(Formatters.date(sale.saleDate))),
            Expanded(
              flex: 2,
              child: Text(
                sale.companyName ?? context.l10n.emDash,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                sale.invoiceNumber?.isNotEmpty == true
                    ? sale.invoiceNumber!
                    : context.l10n.emDash,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(child: Text('${sale.itemCount}')),
            Expanded(child: Text(Formatters.money(sale.totalAmount))),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppBadge(
                  label: sale.status,
                  type: _statusType(sale.status),
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  if (sale.canEdit)
                    IconButton(
                      tooltip: context.l10n.edit,
                      onPressed: () => _openForm(saleId: sale.id),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                  if (sale.canCancel)
                    IconButton(
                      tooltip: context.l10n.cancel,
                      onPressed: () => _cancel(sale),
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
                      AppRoutes.saleDetail,
                      arguments: sale.id,
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
