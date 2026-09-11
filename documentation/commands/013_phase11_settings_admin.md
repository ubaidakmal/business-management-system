# 013 — Phase 11 Settings & Administration

Date: 2026-09-10

## User command

Implement Phase 11 only: Settings & Administration on Phases 1–10. Do not redesign AuthService / AuthController / AuthGate / login flow.

## Database

Migration: `supabase/migrations/20260910070436_settings_admin.sql`

### Changes

| Object | Purpose |
| --- | --- |
| `profiles.is_active` | Soft-disable users |
| `profiles_update_own_or_admin` | Admins can update any profile; users still own-only for themselves |
| `handle_profile_update` | Blocks non-admin role/active/email changes; protects last active admin |
| `app_settings` | Singleton business profile + preferences |
| `get_admin_overview()` | Admin-only counts RPC |
| `current_user_can(text)` | Simple role→capability helper (RLS remains authoritative) |

### Apply

```bash
supabase db push --dry-run
supabase db push --yes
```

## Files created

- `lib/models/app_settings.dart`
- `lib/models/permission.dart`
- `lib/services/settings_service.dart`
- `lib/services/user_management_service.dart`
- `lib/state/settings_controller.dart`
- `lib/state/users_controller.dart`
- `lib/widgets/admin_gate.dart`
- `lib/screens/settings/business_settings_screen.dart`
- `lib/screens/settings/preferences_settings_screen.dart`
- `lib/screens/settings/permissions_settings_screen.dart`
- `lib/screens/admin/admin_overview_screen.dart`
- `lib/screens/admin/admin_users_screen.dart`
- `lib/screens/admin/admin_user_detail_screen.dart`
- `test/settings_admin_test.dart`
- `documentation/commands/013_phase11_settings_admin.md`

## Files modified

- `lib/models/app_user.dart` — `isActive`, timestamps
- `lib/state/auth_controller.dart` — disabled-user sign-out; load/clear settings cache
- `lib/screens/settings_screen.dart` — settings hub
- `lib/core/routes/app_router.dart` — settings/admin routes
- `lib/export/report_export_builders.dart` — business name from `SettingsService`
- `documentation/PROJECT.md`, `README.md`, `documentation/TESTING.md`

## Packages added

None.

## Features

1. Business profile + preferences (admin)
2. User list / detail: name, role, active flag (admin)
3. Roles & permissions foundation (`AppPermissions` + SQL helper)
4. Admin overview dashboard
5. Exports use stored business name when settings are loaded

## Security decisions

- Auth stack unchanged
- Admin UI gated by `AdminGate` + `AppPermissions`
- RLS/RPC enforce admin updates and overview
- Disabled profiles cannot stay signed in
- Last active admin cannot be demoted/disabled

## Tests

- `flutter analyze`
- `flutter test`

## Remaining manual checks

- Push migration
- Admin: save business name → export PDF shows it
- Admin: list/edit users; non-admin blocked from `/admin`
- Disable a non-admin user → cannot sign in
- Existing login/session/logout still work
