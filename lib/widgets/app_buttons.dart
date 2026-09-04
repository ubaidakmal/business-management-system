import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final onTap = isLoading ? null : onPressed;
    final labelWidget = Text(label);
    final Widget button;
    if (isLoading) {
      button = FilledButton.icon(
        onPressed: onTap,
        icon: const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
        label: labelWidget,
      );
    } else if (icon != null) {
      button = FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: labelWidget,
      );
    } else {
      button = FilledButton(onPressed: onTap, child: labelWidget);
    }

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(onPressed: onPressed, child: Text(label));
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, color: AppColors.textPrimary),
      style: IconButton.styleFrom(
        minimumSize: const Size(40, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
