import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/responsive.dart';
import '../models/company.dart';
import '../state/app_status.dart';
import '../state/auth_controller.dart';
import '../state/companies_controller.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_fields.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_states.dart';
import '../widgets/app_surfaces.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final _controller = CompaniesController();
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
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

  Future<void> _openForm({String? companyId}) async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.companyForm,
      arguments: companyId,
    );
    if (changed == true) await _controller.load();
  }

  Future<void> _confirmDeactivate(Company company) async {
    final activate = !company.isActive;
    final ok = await AppDialog.confirm(
      context,
      title: activate ? 'Activate company' : 'Deactivate company',
      message: activate
          ? 'Activate ${company.name}?'
          : 'Deactivate ${company.name}? It will stay in the system for future records.',
      confirmLabel: activate ? 'Activate' : 'Deactivate',
    );
    if (!ok) return;
    final success = await _controller.setActive(company, activate);
    if (!mounted) return;
    if (success) {
      AppSnackbar.show(
        context,
        activate ? 'Company activated.' : 'Company deactivated.',
      );
    } else if (_controller.errorMessage != null) {
      AppSnackbar.show(context, _controller.errorMessage!, isError: true);
    }
  }

  Future<void> _confirmDelete(Company company) async {
    final ok = await AppDialog.confirm(
      context,
      title: 'Delete company',
      message:
          'Permanently delete ${company.name}? Prefer deactivation if this company may be used later.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    final success = await _controller.delete(company);
    if (!mounted) return;
    if (success) {
      AppSnackbar.show(context, 'Company deleted.');
    } else if (_controller.errorMessage != null) {
      AppSnackbar.show(context, _controller.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);
    final isAdmin = AuthScope.of(context).user?.isAdmin == true;

    return AppScaffold(
      title: 'Companies',
      route: AppRoutes.companies,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: 'Companies',
            subtitle: 'Manage business partners and suppliers.',
            action: AppButton(
              label: 'Add Company',
              expanded: false,
              icon: Icons.add,
              onPressed: () => _openForm(),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Wrap(
            spacing: AppSizes.md,
            runSpacing: AppSizes.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: desktop ? 320 : double.infinity,
                child: AppSearchField(
                  controller: _search,
                  hint: 'Search name or code',
                  onChanged: _onSearch,
                ),
              ),
              SizedBox(
                width: desktop ? 180 : double.infinity,
                child: AppDropdown<bool?>(
                  label: 'Status',
                  value: _controller.activeFilter,
                  hint: 'All statuses',
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
    if (_controller.status.isLoading || _controller.status.isInitial) {
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
        title: 'No companies yet',
        message: 'Add your first company to get started.',
        actionLabel: 'Add Company',
        onAction: () => _openForm(),
      );
    }

    if (desktop) {
      return AppCard(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('Company', style: AppTextStyles.label),
                  ),
                  Expanded(child: Text('Code', style: AppTextStyles.label)),
                  Expanded(
                    flex: 2,
                    child: Text('Contact', style: AppTextStyles.label),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Location', style: AppTextStyles.label),
                  ),
                  Expanded(child: Text('Status', style: AppTextStyles.label)),
                  SizedBox(
                    width: 120,
                    child: Text('Actions', style: AppTextStyles.label),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: _controller.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final company = _controller.items[index];
                  return _companyRow(company, isAdmin: isAdmin);
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
        final company = _controller.items[index];
        return AppCard(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.companyDetail,
            arguments: company.id,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      company.name,
                      style: AppTextStyles.headingSmall,
                    ),
                  ),
                  AppBadge(
                    label: company.isActive ? 'Active' : 'Inactive',
                    type: company.isActive
                        ? AppBadgeType.success
                        : AppBadgeType.neutral,
                  ),
                ],
              ),
              if (company.code?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(company.code!, style: AppTextStyles.bodySmall),
              ],
              const SizedBox(height: 8),
              Text(company.contactLabel, style: AppTextStyles.bodyMedium),
              Text(company.locationLabel, style: AppTextStyles.bodySmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  AppOutlinedButton(
                    label: 'Edit',
                    expanded: false,
                    onPressed: () => _openForm(companyId: company.id),
                  ),
                  AppOutlinedButton(
                    label: company.isActive ? 'Deactivate' : 'Activate',
                    expanded: false,
                    onPressed: () => _confirmDeactivate(company),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _companyRow(Company company, {required bool isAdmin}) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.companyDetail,
        arguments: company.id,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                company.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            Expanded(
              child: Text(
                company.code?.isNotEmpty == true ? company.code! : '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                company.contactLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                company.locationLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall,
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppBadge(
                  label: company.isActive ? 'Active' : 'Inactive',
                  type: company.isActive
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
                    onPressed: () => _openForm(companyId: company.id),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                  IconButton(
                    tooltip: company.isActive ? 'Deactivate' : 'Activate',
                    onPressed: () => _confirmDeactivate(company),
                    icon: Icon(
                      company.isActive ? Icons.toggle_on : Icons.toggle_off,
                      color: company.isActive
                          ? AppColors.success
                          : AppColors.disabled,
                    ),
                  ),
                  if (isAdmin)
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(company),
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
