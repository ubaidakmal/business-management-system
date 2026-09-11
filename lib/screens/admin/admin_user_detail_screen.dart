import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/validators/validators.dart';
import '../../models/app_user.dart';
import '../../services/user_management_service.dart';
import '../../state/auth_controller.dart';
import '../../widgets/admin_gate.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_fields.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_surfaces.dart';

class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final _service = UserManagementService();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();

  AppUser? _user;
  String? _error;
  bool _loading = true;
  bool _saving = false;
  String _role = 'user';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _service.getById(widget.userId);
      _user = user;
      _name.text = user.name ?? '';
      _role = user.role;
      _isActive = user.isActive;
    } catch (error) {
      _error = error.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final current = AuthScope.read(context).user;
    if (current?.id == widget.userId && !_isActive) {
      AppSnackbar.show(
        context,
        'You cannot disable your own account.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.updateUser(
        id: widget.userId,
        name: _name.text,
        role: _role,
        isActive: _isActive,
      );
      if (!mounted) return;
      AppSnackbar.show(context, 'User updated.');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.show(context, error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminGate(
      child: AppScaffold(
        title: 'User details',
        route: AppRoutes.settings,
        body: _loading
            ? const AppLoading()
            : _error != null
            ? AppErrorState(message: _error, onRetry: _load)
            : _user == null
            ? const AppEmptyState(title: 'User not found')
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    AppSectionHeader(
                      title: _user!.email,
                      subtitle: 'Profile fields only — not Auth credentials',
                      action: IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Email', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          Text(_user!.email, style: AppTextStyles.bodyMedium),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(
                            controller: _name,
                            label: 'Display name',
                            validator: (value) =>
                                Validators.requiredField(value, 'Name'),
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppDropdown<String>(
                            label: 'Role',
                            value: _role,
                            items: const [
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text('Admin'),
                              ),
                              DropdownMenuItem(
                                value: 'user',
                                child: Text('User'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _role = value);
                            },
                          ),
                          const SizedBox(height: AppSizes.md),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Active'),
                            subtitle: const Text(
                              'Disabled users cannot sign in',
                            ),
                            value: _isActive,
                            onChanged: (value) =>
                                setState(() => _isActive = value),
                          ),
                          if (_user!.createdAt != null) ...[
                            const SizedBox(height: AppSizes.md),
                            Text(
                              'Created ${Formatters.dateTime(_user!.createdAt)}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                          const SizedBox(height: AppSizes.lg),
                          AppButton(
                            label: 'Save user',
                            isLoading: _saving,
                            onPressed: _save,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
