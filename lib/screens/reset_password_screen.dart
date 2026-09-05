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
import '../widgets/auth_form_shell.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = AuthScope.read(context);
    final ok = await auth.updatePassword(_password.text);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.show(context, AppStrings.passwordUpdated);
      Navigator.pushNamedAndRemoveUntil(
        context,
        auth.isAuthenticated ? AppRoutes.dashboard : AppRoutes.login,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return AuthFormShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.newPasswordTitle,
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.newPasswordSubtitle,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: AppStrings.passwordLabel,
              controller: _password,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.lock_outline,
              validator: Validators.password,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: AppStrings.confirmPasswordLabel,
              controller: _confirm,
              obscureText: _hideConfirm,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline,
              validator: (value) =>
                  Validators.confirmPassword(value, _password.text),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                icon: Icon(
                  _hideConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.errorMessage!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 20),
            AppButton(
              label: AppStrings.updatePassword,
              isLoading: auth.isLoading,
              onPressed: auth.isLoading ? null : _submit,
            ),
            const SizedBox(height: 10),
            AppOutlinedButton(
              label: AppStrings.backToLogin,
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (_) => false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
