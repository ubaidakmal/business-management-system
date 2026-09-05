import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:business_management_app/app.dart';
import 'package:business_management_app/core/constants/app_strings.dart';
import 'package:business_management_app/state/auth_controller.dart';

void main() {
  testWidgets('app launches to splash then login', (tester) async {
    final auth = AuthController.unauthenticated();

    await tester.pumpWidget(
      AuthScope(controller: auth, child: const BusinessApp()),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text(AppStrings.forgotPassword), findsOneWidget);
  });
}
