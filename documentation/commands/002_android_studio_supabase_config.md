# 002 — Supabase config for Android Studio Play

Date: 2026-09-03

## User command

Run the app with the Android Studio Play button. Do not require:

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

The user will put Supabase credentials in the config file.

## What changed

- `lib/config/app_config.dart` now holds the public URL and anon/publishable key
- `flutter run` and Android Studio Play both use those values with no extra arguments
- Docs, README, and the Cursor rule were updated to match

## How to use

1. Paste the project URL and anon/publishable key into `lib/config/app_config.dart`
2. Press Play in Android Studio

Never put a service-role key in this file.
