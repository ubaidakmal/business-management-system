import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/app_user.dart';
import '../../state/app_status.dart';
import '../../state/users_controller.dart';
import '../../widgets/admin_gate.dart';
import '../../widgets/app_fields.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/reports/report_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _controller = UsersController();
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
    _controller.load();
  }

  void _refresh() {
    if (mounted) setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);

    return AdminGate(
      child: AppScaffold(
        title: 'Users',
        route: AppRoutes.settings,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: 'User management',
              subtitle: 'Admins only. Passwords stay in Supabase Auth.',
              action: IconButton(
                tooltip: 'Back',
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.admin),
                icon: const Icon(Icons.arrow_back),
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
                    hint: 'Search name or email',
                    onChanged: _onSearch,
                  ),
                ),
                SizedBox(
                  width: desktop ? 160 : double.infinity,
                  child: AppDropdown<String?>(
                    label: 'Role',
                    value: _controller.roleFilter,
                    hint: 'All roles',
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'user', child: Text('User')),
                    ],
                    onChanged: _controller.setRoleFilter,
                  ),
                ),
                SizedBox(
                  width: desktop ? 160 : double.infinity,
                  child: AppDropdown<bool?>(
                    label: 'Status',
                    value: _controller.activeFilter,
                    hint: 'All',
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: true, child: Text('Active')),
                      DropdownMenuItem(value: false, child: Text('Disabled')),
                    ],
                    onChanged: _controller.setActiveFilter,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            Expanded(child: _buildBody(desktop: desktop)),
          ],
        ),
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
      return const AppEmptyState(
        title: 'No users found',
        message: 'Try a different search or filter.',
      );
    }

    final rows = _controller.items;
    if (desktop) {
      return AppCard(
        child: Column(
          children: [
            const ReportTableHeader(
              columns: [
                ('Name', 2),
                ('Email', 2),
                ('Role', 1),
                ('Status', 1),
                ('Created', 1),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _desktopRow(rows[index]),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, index) {
        final user = rows[index];
        return AppCard(
          onTap: () => _openUser(user.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user.name?.isNotEmpty == true ? user.name! : '—',
                      style: AppTextStyles.headingSmall,
                    ),
                  ),
                  AppBadge(
                    label: user.isActive ? 'active' : 'disabled',
                    type: user.isActive
                        ? AppBadgeType.success
                        : AppBadgeType.neutral,
                  ),
                ],
              ),
              Text(user.email, style: AppTextStyles.bodySmall),
              Text('Role: ${user.role}'),
            ],
          ),
        );
      },
    );
  }

  Widget _desktopRow(AppUser user) {
    return InkWell(
      onTap: () => _openUser(user.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                user.name?.isNotEmpty == true ? user.name! : '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppBadge(
                  label: user.role,
                  type: user.isAdmin ? AppBadgeType.info : AppBadgeType.neutral,
                ),
              ),
            ),
            Expanded(
              child: Text(
                user.isActive ? 'Active' : 'Disabled',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: user.isActive
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(child: Text(Formatters.date(user.createdAt))),
          ],
        ),
      ),
    );
  }

  Future<void> _openUser(String id) async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.adminUserDetail,
      arguments: id,
    );
    if (changed == true) await _controller.load();
  }
}
