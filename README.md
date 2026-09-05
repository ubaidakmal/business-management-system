# Business Management System

Flutter + Supabase ERP app.

Living notes: [documentation/PROJECT.md](documentation/PROJECT.md)

## Run

```bash
flutter pub get
flutter run
```

Android Studio: press Play. Supabase keys are in `lib/config/app_config.dart`.

## Phase 2 test login

- Email: `admin@bms.app`
- Password: `Password123!`

## Phase 3–5

After login, use the sidebar for **Companies**, **Products**, **Purchases**, and **Sales**.

Stock and reports remain placeholders.

Add password-reset redirect URLs in the Supabase Auth dashboard:

- `io.supabase.bms://login-callback/`
- your web origin + `/#/reset-password`

Never put a service-role key in the Flutter app.
