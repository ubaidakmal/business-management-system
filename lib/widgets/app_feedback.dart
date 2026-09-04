import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'app_buttons.dart';

abstract final class AppDialog {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppTextStyles.headingSmall),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          AppOutlinedButton(
            label: cancelLabel,
            expanded: false,
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton(
            label: confirmLabel,
            expanded: false,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

abstract final class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }
}
