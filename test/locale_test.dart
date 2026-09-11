import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:business_management_app/services/locale_service.dart';
import 'package:business_management_app/state/locale_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LocaleService persists language code locally', () async {
    SharedPreferences.setMockInitialValues({});
    final service = LocaleService();
    expect(await service.loadCode(), isNull);

    await service.saveCode('zh_TW');
    expect(await service.loadCode(), 'zh_TW');
  });

  test('LocaleController defaults to English and switches to zh_TW', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = LocaleController();
    await controller.load();
    expect(controller.languageCode, 'en');
    expect(controller.l10n.navDashboard, 'Dashboard');

    await controller.setLanguageCode('zh_TW');
    expect(controller.languageCode, 'zh_TW');
    expect(controller.l10n.navDashboard, '儀表板');
    expect(controller.l10n.totalProfit, '總利潤');

    final reloaded = LocaleController();
    await reloaded.load();
    expect(reloaded.languageCode, 'zh_TW');
  });
}
