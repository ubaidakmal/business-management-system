import 'package:flutter/material.dart';

import '../core/constants/app_sizes.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/responsive.dart';
import '../core/validators/validators.dart';
import '../models/permission.dart';
import '../services/settings_service.dart';
import '../state/auth_controller.dart';
import '../state/locale_controller.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_fields.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/language_selector.dart';

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
    if (ok) AppSnackbar.show(context, context.l10n.profileUpdated);
  }

  Future<void> _signOut() async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.signOut,
      message: l10n.signOutConfirm(SettingsService.cachedBusinessName),
      confirmLabel: l10n.signOut,
    );
    if (!confirmed || !mounted) return;

    await AuthScope.read(context).signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = AuthScope.of(context);
    final user = auth.user;
    final permissions = AppPermissions(user?.role ?? 'user');
    final desktop = AppResponsive.isDesktop(context);

    final links = <Widget>[
      if (permissions.manageSettings) ...[
        _SettingsLink(
          icon: Icons.storefront_outlined,
          title: l10n.businessProfile,
          subtitle: l10n.businessProfileSubtitle,
          onTap: () => Navigator.pushNamed(context, AppRoutes.settingsBusiness),
        ),
        _SettingsLink(
          icon: Icons.tune_outlined,
          title: l10n.preferences,
          subtitle: l10n.preferencesSubtitle,
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.settingsPreferences),
        ),
        _SettingsLink(
          icon: Icons.show_chart_outlined,
          title: l10n.marketSettings,
          subtitle: l10n.marketSettingsSubtitle,
          onTap: () => Navigator.pushNamed(context, AppRoutes.settingsMarket),
        ),
      ],
      _SettingsLink(
        icon: Icons.security_outlined,
        title: l10n.rolesPermissions,
        subtitle: l10n.rolesPermissionsSubtitle,
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.settingsPermissions),
      ),
      if (permissions.viewAdmin)
        _SettingsLink(
          icon: Icons.admin_panel_settings_outlined,
          title: l10n.administration,
          subtitle: l10n.administrationSubtitle,
          onTap: () => Navigator.pushNamed(context, AppRoutes.admin),
        ),
    ];

    final workspace = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LanguageSelector(),
        const SizedBox(height: AppSizes.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.workspace, style: AppTextStyles.headingSmall),
              const SizedBox(height: AppSizes.md),
              ...links,
            ],
          ),
        ),
      ],
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
                    l10n.profileTitle,
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
            Text(l10n.emailLabel, style: AppTextStyles.label),
            const SizedBox(height: 6),
            Text(user?.email ?? l10n.emDash, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSizes.md),
            AppTextField(
              controller: _name,
              label: l10n.nameLabel,
              validator: (value) => Validators.requiredField(value, 'Name'),
            ),
            const SizedBox(height: AppSizes.lg),
            AppButton(
              label: l10n.saveProfile,
              isLoading: auth.isLoading,
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );

    return AppScaffold(
      title: l10n.settingsTitle,
      route: AppRoutes.settings,
      body: ListView(
        children: [
          AppSectionHeader(
            title: l10n.settingsTitle,
            subtitle: l10n.settingsSubtitle,
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
                Text(l10n.security, style: AppTextStyles.headingSmall),
                const SizedBox(height: AppSizes.md),
                AppOutlinedButton(
                  label: l10n.forgotPasswordTitle,
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.resetPassword),
                ),
                const SizedBox(height: AppSizes.md),
                AppButton(label: l10n.signOut, onPressed: _signOut),
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
