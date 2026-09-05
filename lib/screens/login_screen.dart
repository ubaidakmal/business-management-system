import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/validators/validators.dart';
import '../state/auth_controller.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_fields.dart';
import '../widgets/auth_form_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthScope.read(context).clearError();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = AuthScope.read(context);
    final ok = await auth.signIn(email: _email.text, password: _password.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
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
            Text(AppStrings.appName, style: AppTextStyles.headingLarge),
            const SizedBox(height: 8),
            Text(AppStrings.tagline, style: AppTextStyles.bodySmall),
            const SizedBox(height: 28),
            Text(AppStrings.loginTitle, style: AppTextStyles.headingSmall),
            const SizedBox(height: 4),
            Text(AppStrings.loginSubtitle, style: AppTextStyles.bodySmall),
            const SizedBox(height: 20),
            AppTextField(
              label: AppStrings.emailLabel,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.mail_outline,
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: AppStrings.passwordLabel,
              controller: _password,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: auth.isLoading
                    ? null
                    : () => Navigator.pushNamed(
                        context,
                        AppRoutes.forgotPassword,
                      ),
                child: const Text(AppStrings.forgotPassword),
              ),
            ),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                auth.errorMessage!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 12),
            AppButton(
              label: AppStrings.signIn,
              isLoading: auth.isLoading,
              onPressed: auth.isLoading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
