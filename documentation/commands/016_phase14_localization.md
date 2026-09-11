# 016 — Phase 14 Localization / Multi-language

Date: 2026-09-11

## User command

Implement Phase 14 only: Localization with English + Traditional Chinese (Taiwan), local language preference storage. No business-logic or Supabase business-table changes.

## Supported languages

| Code | Label |
|------|--------|
| `en` (default) | English |
| `zh_TW` | 繁體中文 |

Fallback ARB `app_zh.arb` exists for Flutter gen-l10n base-locale rules; UI selection uses `zh_TW`.

## Local storage approach

- **Not** stored in Supabase
- `SharedPreferences` key: `app_locale_code`
- `LocaleService` read/write
- `LocaleController` loads on startup, applies `MaterialApp.locale`, persists on change

Startup:

1. Load saved code (or default `en`)
2. Bind `AppStrings` resolver
3. Run app inside `LocaleScope`

## Architecture

```
Settings → LanguageSelector
  → LocaleController.setLanguageCode
  → SharedPreferences
  → MaterialApp rebuild with new locale
  → context.l10n / AppLocalizations
```

Exports: `ReportExportBuilders.*(l10n: …)` use selected-language labels only.

## Files created

- `l10n.yaml`
- `lib/l10n/app_en.arb`, `app_zh_TW.arb`, `app_zh.arb` (+ generated `app_localizations*.dart`)
- `lib/services/locale_service.dart`
- `lib/state/locale_controller.dart`
- `lib/widgets/language_selector.dart`
- `test/locale_test.dart`
- `documentation/commands/016_phase14_localization.md`

## Files modified (high level)

- `pubspec.yaml` (`generate: true`, `flutter_localizations`, `intl`, `shared_preferences`)
- `lib/main.dart`, `lib/app.dart`
- `lib/core/constants/app_strings.dart` (localized getters)
- `lib/core/routes/app_router.dart` (nav labels via l10n)
- Settings, dashboard, lists, market, reports, export builders/actions, auth widgets, form/detail titles
- `documentation/PROJECT.md`, `TESTING.md`, `README.md`

## Packages added

- `flutter_localizations` (SDK)
- `intl` (via Flutter)
- `shared_preferences`

## Tests performed

```bash
flutter analyze   # clean
flutter test      # all passed (incl. locale persistence + zh_TW 總利潤)
```

## Remaining translation checks

- Some form field labels / secondary dialog copy may still be English — extend ARBs incrementally
- PDF Helvetica lacks CJK glyphs (Excel OK); add a CJK PDF font if needed later
- Status values from DB (`completed`, etc.) are not translated (stored enums)
- Validator / server error messages remain English unless mapped separately
