import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/validators/validators.dart';
import '../../models/app_settings.dart';
import '../../state/app_status.dart';
import '../../state/settings_controller.dart';
import '../../widgets/admin_gate.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_fields.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_surfaces.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  final _controller = SettingsController();
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _logoUrl = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();

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
    _fill(_controller.settings);
  }

  void _fill(AppSettings settings) {
    _businessName.text = settings.businessName;
    _logoUrl.text = settings.logoUrl ?? '';
    _email.text = settings.contactEmail ?? '';
    _phone.text = settings.phone ?? '';
    _address.text = settings.address ?? '';
    _city.text = settings.city ?? '';
    _country.text = settings.country ?? '';
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    _businessName.dispose();
    _logoUrl.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final next = _controller.settings.copyWith(
      businessName: _businessName.text,
      logoUrl: _logoUrl.text,
      contactEmail: _email.text,
      phone: _phone.text,
      address: _address.text,
      city: _city.text,
      country: _country.text,
    );
    final ok = await _controller.saveBusiness(next);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.show(context, _controller.saveMessage ?? 'Saved.');
    } else if (_controller.errorMessage != null) {
      AppSnackbar.show(context, _controller.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminGate(
      child: AppScaffold(
        title: 'Business profile',
        route: AppRoutes.settings,
        body: _controller.isLoading
            ? const AppLoading()
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    AppSectionHeader(
                      title: 'Business profile',
                      subtitle: 'Used on report exports and printouts',
                      action: IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.settings,
                        ),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    if (_controller.errorMessage != null &&
                        _controller.status.hasError) ...[
                      const SizedBox(height: AppSizes.md),
                      Text(
                        _controller.errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSizes.lg),
                    AppCard(
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _businessName,
                            label: 'Business name',
                            validator: (value) => Validators.requiredField(
                              value,
                              'Business name',
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(
                            controller: _logoUrl,
                            label: 'Logo URL (optional)',
                            hint: 'https://…',
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(
                            controller: _email,
                            label: 'Contact email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(
                            controller: _phone,
                            label: 'Phone',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(
                            controller: _address,
                            label: 'Address',
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(controller: _city, label: 'City'),
                          const SizedBox(height: AppSizes.md),
                          AppTextField(controller: _country, label: 'Country'),
                          const SizedBox(height: AppSizes.lg),
                          AppButton(
                            label: 'Save business profile',
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
