import 'package:flutter/material.dart';

import '../state/locale_controller.dart';

import '../core/constants/app_sizes.dart';
import '../core/routes/app_router.dart';
import '../core/utils/app_error.dart';
import '../core/utils/formatters.dart';
import '../models/company.dart';
import '../services/company_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_states.dart';
import '../widgets/app_surfaces.dart';

class CompanyDetailScreen extends StatefulWidget {
  const CompanyDetailScreen({super.key, required this.companyId});

  final String companyId;

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  final _service = CompanyService();
  Company? _company;
  String? _error;
  bool _loading = true;

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
      _company = await _service.getById(widget.companyId);
    } catch (error) {
      _error = AppError.messageOf(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.companyForm,
      arguments: widget.companyId,
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final company = _company;

    return AppScaffold(
      title: context.l10n.companyDetails,
      route: AppRoutes.companies,
      body: _loading
          ? const AppLoading()
          : _error != null
          ? AppErrorState(message: _error, onRetry: _load)
          : company == null
          ? AppEmptyState(title: context.l10n.companyNotFound)
          : ListView(
              children: [
                AppSectionHeader(
                  title: company.name,
                  subtitle: company.code,
                  action: AppBadge(
                    label: company.isActive ? 'Active' : 'Inactive',
                    type: company.isActive
                        ? AppBadgeType.success
                        : AppBadgeType.neutral,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppDetailRow(label: 'Email', value: company.email ?? ''),
                      AppDetailRow(label: 'Phone', value: company.phone ?? ''),
                      AppDetailRow(
                        label: 'Address',
                        value: company.address ?? '',
                      ),
                      AppDetailRow(label: 'City', value: company.city ?? ''),
                      AppDetailRow(
                        label: 'Country',
                        value: company.country ?? '',
                      ),
                      AppDetailRow(label: 'Notes', value: company.notes ?? ''),
                      AppDetailRow(
                        label: 'Created',
                        value: Formatters.dateTime(company.createdAt),
                      ),
                      AppDetailRow(
                        label: 'Updated',
                        value: Formatters.dateTime(company.updatedAt),
                      ),
                      const SizedBox(height: AppSizes.md),
                      AppButton(
                        label: 'Edit company',
                        expanded: false,
                        onPressed: _edit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
