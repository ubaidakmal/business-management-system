# Business Management System

Flutter + Supabase ERP app.

Living notes: [documentation/PROJECT.md](documentation/PROJECT.md)  
Manual test steps (all phases): [documentation/TESTING.md](documentation/TESTING.md)

## Run

```bash
flutter pub get
flutter run
```

Android Studio: press Play. Supabase keys are in `lib/config/app_config.dart`.

## Phase 2 test login

- Email: `admin@bms.app`
- Password: `Password123!`

## Phase 3–14

After login: **Dashboard**, **Companies**, **Products**, **Purchases**, **Sales**, **Stock**, **Market**, **Reports**, and **Settings**.

- Phase 14: Settings → Language (English / 繁體中文), stored on device only
- Phase 13 hardened DB security (RPC-only purchase/sale writes; disabled-user gates)
- Market: live FX rates via Edge Function (secrets server-side only)
- Reports + PDF/Excel/Print exports
- Settings/admin for business profile and users
- Stock = opening stock + movements; sales use FIFO COGS/profit

Advanced accounting / full market platforms come later.

Add password-reset redirect URLs in the Supabase Auth dashboard:

- `io.supabase.bms://login-callback/`
- your web origin + `/#/reset-password`

Never put a service-role key in the Flutter app.
