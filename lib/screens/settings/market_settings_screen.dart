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

class MarketSettingsScreen extends StatefulWidget {
  const MarketSettingsScreen({super.key});

  @override
  State<MarketSettingsScreen> createState() => _MarketSettingsScreenState();
}

class _MarketSettingsScreenState extends State<MarketSettingsScreen> {
  final _controller = SettingsController();
  final _formKey = GlobalKey<FormState>();
  final _base = TextEditingController();
  final _quotes = TextEditingController();
  var _enabled = true;

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
    _enabled = s.marketEnabled;
    _base.text = s.marketBaseCurrency;
    _quotes.text = s.marketQuoteCurrencies;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    _base.dispose();
    _quotes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final next = _controller.settings.copyWith(
      marketEnabled: _enabled,
      marketBaseCurrency: _base.text,
      marketQuoteCurrencies: _quotes.text,
    );
    final ok = await _controller.saveBusiness(next);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.show(context, 'Market settings saved.');
    } else if (_controller.errorMessage != null) {
      AppSnackbar.show(context, _controller.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminGate(
      child: AppScaffold(
        title: 'Market settings',
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
                      title: 'Market settings',
                      subtitle:
                          'API keys stay in Supabase secrets / Edge Functions — never in Flutter.',
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
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Enable market data'),
                            subtitle: const Text(
                              'When off, users cannot read or refresh rates',
                            ),
                            value: _enabled,
                            onChanged: (v) => setState(() => _enabled = v),
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(
                            controller: _base,
                            label: 'Base currency',
                            hint: 'USD',
                            validator: (value) => Validators.requiredField(
                              value,
                              'Base currency',
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(
                            controller: _quotes,
                            label: 'Quote currencies',
                            hint: 'PKR,EUR,GBP,AED',
                            validator: (value) => Validators.requiredField(
                              value,
                              'Quote currencies',
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                          AppButton(
                            label: 'Save market settings',
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
