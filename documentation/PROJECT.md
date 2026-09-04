# Business Management System

Living project document. Update this file whenever a phase or meaningful change is completed.

## Product

Internal ERP-style app for companies, products, purchases, sales, stock, transactions, profit, and reports.

Current phase: **Phase 1 — Project foundation only.** Business modules are not implemented.

## Stack

- Flutter / Dart (SDK `^3.10.1`)
- Supabase + PostgreSQL (client foundation only)
- Navigator 1.0 routes (`onGenerateRoute`)
- `ChangeNotifier` when a screen later needs shared state (`AppStatus` enum is ready now)

## Architecture

Keep this simple on purpose.

```
Screen
  → ChangeNotifier (only when state is real)
    → Service (Supabase / APIs)
      → Database
```

Add a repository later only if a service is doing too much mapping or is reused by several screens.

Do not add extra layers, base classes, or wrappers unless they solve a real problem.

## Folder map

```
lib/
  main.dart                 App bootstrap + Supabase init
  app.dart                  MaterialApp
  config/app_config.dart    public Supabase URL + anon key
  core/constants/           colors, sizes, strings
  core/theme/               theme + typography
  core/routes/              route names + router
  core/utils/               logger, errors, responsive
  core/validators/          shared form validators
  models/                   Dart models (AppUser is the pattern)
  services/                 Supabase client
  state/                    AppStatus
  widgets/                  reusable UI
  screens/                  splash, login placeholder, module placeholders

documentation/
  PROJECT.md                this file
  commands/                 one markdown file per user command
```

There is no `repositories/` folder yet. Do not create empty folders for future theory.

## Theme

- Colors: `lib/core/constants/app_colors.dart` (`AppColors`)
- Type: `lib/core/theme/app_text_styles.dart` (`AppTextStyles`)
- Theme: `lib/core/theme/app_theme.dart` (`AppTheme.light`)
- Visual direction: deep navy primary, light surfaces, gray neutrals, green/red/amber/blue for status

Never hardcode colors in screens. Use `AppColors` / `AppTextStyles`.

## State

`AppStatus`: `initial`, `loading`, `success`, `error`, `empty`.

When a later phase needs screen state, use a small `ChangeNotifier` on that screen. Do not introduce Provider/Riverpod/Bloc unless sharing state across many screens becomes painful.

## Supabase

- Public URL + anon/publishable key live in `lib/config/app_config.dart`
- Android Studio Play and `flutter run` both read those values. No `--dart-define` needed
- Never put a service-role key in Flutter
- Init lives in `SupabaseService.initialize()`
- Project URL and anon/publishable key are set in `AppConfig` for local Play/run
- Never put a service-role key in Flutter

## Routing

Implemented placeholders:

- `/` splash
- `/login`
- `/dashboard`
- `/companies`
- `/products`
- `/purchases`
- `/sales`
- `/stock`
- `/reports`
- `/settings`

Login has a temporary **Continue without signing in** action so the shell can be reached before auth exists. Remove it when auth is real.

## Conventions

- Prefer one clear file over three tiny files
- Do not copy Digi Dukaan’s cache/offline/platform-owner complexity
- Do not implement business modules until their phase
- After every user command: update this file and add `documentation/commands/NNN_short_name.md`

## How to run

```bash
flutter pub get
flutter run
```

Android Studio: press Play. Keys are already in `lib/config/app_config.dart`.

## Changelog

### 2026-09-04 — Supabase project keys in AppConfig

- Added the project URL and publishable key to `lib/config/app_config.dart`

### 2026-09-03 — Android Studio Play / config keys

- Supabase URL and anon key now live in `lib/config/app_config.dart`
- Removed the `--dart-define` run requirement so Play works with no extra args

### Phase 1 — Foundation (2026-09-03)

- Replaced the default counter app with a simple ERP foundation
- Centralized colors, typography, theme, routes, validators, errors, and responsive helpers
- Added reusable widgets and module placeholder screens
- Prepared Supabase client init without embedding secrets
- Added this living document and a per-command documentation folder
