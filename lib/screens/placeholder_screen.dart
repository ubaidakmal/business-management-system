import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_states.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.route,
  });

  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      route: route,
      body: AppEmptyState(title: title, message: AppStrings.phasePlaceholder),
    );
  }
}
