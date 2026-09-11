import 'package:flutter/material.dart';

import '../core/constants/app_sizes.dart';
import '../core/theme/app_text_styles.dart';
import '../state/locale_controller.dart';
import 'app_feedback.dart';
import 'app_surfaces.dart';

/// Settings control for English / 繁體中文.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.language, style: AppTextStyles.headingSmall),
          const SizedBox(height: 4),
          Text(l10n.languageSubtitle, style: AppTextStyles.caption),
          const SizedBox(height: AppSizes.md),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'en',
                label: Text(l10n.languageEnglish),
              ),
              ButtonSegment(
                value: 'zh_TW',
                label: Text(l10n.languageTraditionalChinese),
              ),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (values) async {
              final value = values.firstOrNull;
              if (value == null) return;
              await LocaleScope.read(context).setLanguageCode(value);
              if (!context.mounted) return;
              AppSnackbar.show(context, context.l10n.languageSaved);
            },
          ),
        ],
      ),
    );
  }
}
