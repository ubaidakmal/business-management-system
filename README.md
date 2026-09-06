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

## Phase 3–7

After login: **Companies**, **Products**, **Purchases**, **Sales**, and **Stock**.

- Stock = opening stock + movements
- Completed sales use **FIFO** for COGS and profit (shown on sale details)

Reports / PDF export come later.

Add password-reset redirect URLs in the Supabase Auth dashboard:

- `io.supabase.bms://login-callback/`
- your web origin + `/#/reset-password`

Never put a service-role key in the Flutter app.
