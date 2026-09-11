import 'package:flutter/material.dart';

import '../state/locale_controller.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/app_error.dart';
import '../core/utils/responsive.dart';
import '../core/validators/validators.dart';
import '../models/company.dart';
import '../services/company_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_fields.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/app_states.dart';

class CompanyFormScreen extends StatefulWidget {
  const CompanyFormScreen({super.key, this.companyId});

  final String? companyId;

  @override
  State<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends State<CompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CompanyService();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _notes = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  bool _isActive = true;
  String? _error;

  bool get _isEditing => widget.companyId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final company = await _service.getById(widget.companyId!);
      _name.text = company.name;
      _code.text = company.code ?? '';
      _email.text = company.email ?? '';
      _phone.text = company.phone ?? '';
      _address.text = company.address ?? '';
      _city.text = company.city ?? '';
      _country.text = company.country ?? '';
      _notes.text = company.notes ?? '';
      _isActive = company.isActive;
    } catch (error) {
      _error = AppError.messageOf(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _country.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final company = Company(
      id: widget.companyId ?? '',
      name: _name.text,
      code: _code.text,
      email: _email.text,
      phone: _phone.text,
      address: _address.text,
      city: _city.text,
      country: _country.text,
      notes: _notes.text,
      isActive: _isActive,
    );

    try {
      if (_isEditing) {
        await _service.update(company);
      } else {
        await _service.create(company);
      }
      if (!mounted) return;
      AppSnackbar.show(
        context,
        _isEditing ? 'Company updated.' : 'Company created.',
      );
      Navigator.pop(context, true);
    } catch (error) {
      setState(() => _error = AppError.messageOf(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);

    return AppScaffold(
      title: _isEditing ? context.l10n.editCompany : context.l10n.addCompany,
      route: '/companies',
      body: _loading
          ? const AppLoading()
          : Form(
              key: _formKey,
              child: ListView(
                children: [
                  AppSectionHeader(
                    title: _isEditing ? 'Edit company' : 'New company',
                    subtitle: 'Enter company details below.',
                  ),
                  const SizedBox(height: AppSizes.lg),
                  AppCard(
                    child: Column(
                      children: [
                        _twoCol(
                          desktop: desktop,
                          left: AppTextField(
                            label: 'Company name',
                            controller: _name,
                            validator: (value) =>
                                Validators.requiredField(
                                  value,
                                  'Company name',
                                ) ??
                                Validators.maxLength(
                                  value,
                                  120,
                                  'Company name',
                                ),
                          ),
                          right: AppTextField(
                            label: 'Company code',
                            controller: _code,
                            validator: (value) =>
                                Validators.maxLength(value, 40, 'Company code'),
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        _twoCol(
                          desktop: desktop,
                          left: AppTextField(
                            label: 'Email',
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.optionalEmail,
                          ),
                          right: AppTextField(
                            label: 'Phone',
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            validator: Validators.optionalPhone,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        AppTextField(
                          label: 'Address',
                          controller: _address,
                          maxLines: 2,
                          validator: (value) =>
                              Validators.maxLength(value, 250, 'Address'),
                        ),
                        const SizedBox(height: AppSizes.md),
                        _twoCol(
                          desktop: desktop,
                          left: AppTextField(
                            label: 'City',
                            controller: _city,
                            validator: (value) =>
                                Validators.maxLength(value, 80, 'City'),
                          ),
                          right: AppTextField(
                            label: 'Country',
                            controller: _country,
                            validator: (value) =>
                                Validators.maxLength(value, 80, 'Country'),
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        AppTextField(
                          label: 'Notes',
                          controller: _notes,
                          maxLines: 3,
                          validator: (value) =>
                              Validators.maxLength(value, 500, 'Notes'),
                        ),
                        const SizedBox(height: AppSizes.md),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Active'),
                          value: _isActive,
                          activeThumbColor: AppColors.success,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppSizes.sm),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _error!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSizes.lg),
                        Row(
                          children: [
                            AppOutlinedButton(
                              label: 'Cancel',
                              expanded: false,
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.pop(context),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: AppButton(
                                label: _isEditing
                                    ? 'Save changes'
                                    : 'Create company',
                                isLoading: _saving,
                                onPressed: _saving ? null : _save,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _twoCol({
    required bool desktop,
    required Widget left,
    required Widget right,
  }) {
    if (!desktop) {
      return Column(
        children: [
          left,
          const SizedBox(height: AppSizes.md),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSizes.md),
        Expanded(child: right),
      ],
    );
  }
}
