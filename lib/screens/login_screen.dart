import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/responsive.dart';
import '../core/validators/validators.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_fields.dart';

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
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    AppSnackbar.show(context, AppStrings.authComingSoon);
  }

  void _continueWithoutAuth() {
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final wide = AppResponsive.isDesktop(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.background],
            stops: [0, 0.42],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppResponsive.pagePadding(context)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 440 : 400),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppStrings.appName,
                            style: AppTextStyles.headingLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.tagline,
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 28),
                          Text(
                            AppStrings.loginTitle,
                            style: AppTextStyles.headingSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.loginSubtitle,
                            style: AppTextStyles.bodySmall,
                          ),
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
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          AppButton(
                            label: AppStrings.signIn,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 10),
                          AppOutlinedButton(
                            label: AppStrings.continueWithoutAuth,
                            onPressed: _continueWithoutAuth,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
