import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_router.dart';
import '../../core/validators/validators.dart';
import '../../state/app_status.dart';
import '../../state/settings_controller.dart';
import '../../widgets/admin_gate.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_fields.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_surfaces.dart';

class PreferencesSettingsScreen extends StatefulWidget {
  const PreferencesSettingsScreen({super.key});

  @override
  State<PreferencesSettingsScreen> createState() =>
      _PreferencesSettingsScreenState();
}

class _PreferencesSettingsScreenState extends State<PreferencesSettingsScreen> {
  final _controller = SettingsController();
  final _formKey = GlobalKey<FormState>();
  final _currency = TextEditingController();
  final _dateFormat = TextEditingController();
  final _numberFormat = TextEditingController();

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
    await _controller.load();
    final s = _controller.settings;
    _currency.text = s.defaultCurrency;
    _dateFormat.text = s.dateFormat;
    _numberFormat.text = s.numberFormat;
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    _currency.dispose();
    _dateFormat.dispose();
    _numberFormat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final next = _controller.settings.copyWith(
      defaultCurrency: _currency.text,
      dateFormat: _dateFormat.text,
      numberFormat: _numberFormat.text,
    );
    final ok = await _controller.savePreferences(next);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.show(context, 'Preferences saved.');
    } else if (_controller.errorMessage != null) {
      AppSnackbar.show(context, _controller.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminGate(
      child: AppScaffold(
        title: 'Preferences',
        route: AppRoutes.settings,
        body: _controller.isLoading
            ? const AppLoading()
            : _controller.status.hasError
            ? AppErrorState(
                message: _controller.errorMessage,
                onRetry: _bootstrap,
              )
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    AppSectionHeader(
                      title: 'Preferences',
                      subtitle: 'Default formats for the workspace',
                      action: IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.settings,
                        ),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    AppCard(
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _currency,
                            label: 'Default currency',
                            hint: 'PKR',
                            validator: (value) =>
                                Validators.requiredField(value, 'Currency'),
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(
                            controller: _dateFormat,
                            label: 'Date format',
                            hint: 'yyyy-MM-dd',
                            validator: (value) =>
                                Validators.requiredField(value, 'Date format'),
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(
                            controller: _numberFormat,
                            label: 'Number format',
                            hint: '1,234.56',
                            validator: (value) => Validators.requiredField(
                              value,
                              'Number format',
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                          AppButton(
                            label: 'Save preferences',
                            isLoading: _controller.isSaving,
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
