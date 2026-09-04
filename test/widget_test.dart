import 'package:flutter_test/flutter_test.dart';

import 'package:business_management_app/app.dart';
import 'package:business_management_app/core/constants/app_strings.dart';

void main() {
  testWidgets('app launches to splash then login', (tester) async {
    await tester.pumpWidget(const BusinessApp());
    expect(find.text(AppStrings.appName), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    expect(find.text(AppStrings.continueWithoutAuth), findsOneWidget);
  });
}
