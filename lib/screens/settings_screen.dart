import 'package:flutter/material.dart';

import '../core/constants/app_sizes.dart';
import '../core/constants/app_strings.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/responsive.dart';
import '../core/validators/validators.dart';
import '../models/permission.dart';
import '../services/settings_service.dart';
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
      message: 'Sign out of ${SettingsService.cachedBusinessName}?',
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
    final permissions = AppPermissions(user?.role ?? 'user');
    final desktop = AppResponsive.isDesktop(context);

    final links = <Widget>[
      if (permissions.manageSettings) ...[
        _SettingsLink(
          icon: Icons.storefront_outlined,
          title: 'Business profile',
          subtitle: 'Name, contact, and address used in reports',
          onTap: () => Navigator.pushNamed(context, AppRoutes.settingsBusiness),
        ),
        _SettingsLink(
          icon: Icons.tune_outlined,
          title: 'Preferences',
          subtitle: 'Currency and display formats',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.settingsPreferences),
        ),
        _SettingsLink(
          icon: Icons.show_chart_outlined,
          title: 'Market settings',
          subtitle: 'Enable rates and configure currencies',
          onTap: () => Navigator.pushNamed(context, AppRoutes.settingsMarket),
        ),
      ],
      _SettingsLink(
        icon: Icons.security_outlined,
        title: 'Roles & permissions',
        subtitle: 'What your role can do in the app',
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.settingsPermissions),
      ),
      if (permissions.viewAdmin)
        _SettingsLink(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Administration',
          subtitle: 'Users and system overview',
          onTap: () => Navigator.pushNamed(context, AppRoutes.admin),
        ),
    ];

    final workspace = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Workspace', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSizes.md),
          ...links,
        ],
      ),
    );

    final profile = AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.profileTitle,
                    style: AppTextStyles.headingSmall,
                  ),
                ),
                AppBadge(
                  label: user?.role ?? 'user',
                  type: user?.isAdmin == true
                      ? AppBadgeType.info
                      : AppBadgeType.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Text(AppStrings.emailLabel, style: AppTextStyles.label),
            const SizedBox(height: 6),
            Text(user?.email ?? '—', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSizes.md),
            AppTextField(
              controller: _name,
              label: AppStrings.nameLabel,
              validator: (value) => Validators.requiredField(value, 'Name'),
            ),
            const SizedBox(height: AppSizes.lg),
            AppButton(
              label: AppStrings.saveProfile,
              isLoading: auth.isLoading,
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );

    return AppScaffold(
      title: 'Settings',
      route: AppRoutes.settings,
      body: ListView(
        children: [
          const AppSectionHeader(
            title: 'Settings',
            subtitle: 'Account, business profile, and administration',
          ),
          const SizedBox(height: AppSizes.lg),
          if (desktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: profile),
                const SizedBox(width: AppSizes.lg),
                Expanded(child: workspace),
              ],
            )
          else ...[
            profile,
            const SizedBox(height: AppSizes.lg),
            workspace,
          ],
          const SizedBox(height: AppSizes.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Security', style: AppTextStyles.headingSmall),
                const SizedBox(height: AppSizes.md),
                AppOutlinedButton(
                  label: AppStrings.forgotPasswordTitle,
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.resetPassword),
                ),
                const SizedBox(height: AppSizes.md),
                AppButton(label: AppStrings.signOut, onPressed: _signOut),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
