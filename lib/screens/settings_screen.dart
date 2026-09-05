import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/validators/validators.dart';
import '../state/auth_controller.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_fields.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_surfaces.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  var _nameLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_nameLoaded) {
      _name.text = AuthScope.of(context).user?.name ?? '';
      _nameLoaded = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = AuthScope.read(context);
    final ok = await auth.updateName(_name.text);
    if (!mounted) return;
    if (ok) AppSnackbar.show(context, AppStrings.profileUpdated);
  }

  Future<void> _signOut() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: AppStrings.signOut,
      message: 'Sign out of ${AppStrings.appName}?',
      confirmLabel: AppStrings.signOut,
    );
    if (!confirmed || !mounted) return;

    await AuthScope.read(context).signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.user;

    return AppScaffold(
      title: 'Settings',
      route: AppRoutes.settings,
      body: ListView(
        children: [
          const AppSectionHeader(
            title: AppStrings.profileTitle,
            subtitle: 'Update your display name. Roles are managed by admins.',
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(user?.email ?? '', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${AppStrings.roleLabel}: ${user?.role ?? 'user'}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: AppStrings.nameLabel,
                    controller: _name,
                    prefixIcon: Icons.person_outline,
                    validator: (value) =>
                        Validators.requiredField(value, AppStrings.nameLabel),
                  ),
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      auth.errorMessage!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppButton(
                    label: AppStrings.saveProfile,
                    isLoading: auth.isLoading,
                    onPressed: auth.isLoading ? null : _saveProfile,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Security', style: AppTextStyles.headingSmall),
                const SizedBox(height: 12),
                AppOutlinedButton(
                  label: AppStrings.updatePassword,
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.resetPassword),
                ),
                const SizedBox(height: 10),
                AppButton(label: AppStrings.signOut, onPressed: _signOut),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
