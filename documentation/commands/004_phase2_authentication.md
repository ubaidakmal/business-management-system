# 004 — Phase 2 authentication and user management

Date: 2026-09-04

## User command

Implement Phase 2: Supabase authentication, login/logout, session restore, forgot/reset password, profile + admin/user roles, protected routes, and responsive auth UI. Use the linked Supabase CLI for migrations. Stop after Phase 2.

## Database

Migrations pushed:

1. `20260904174559_profiles_auth.sql`
   - `profiles` table
   - RLS select/update policies
   - `current_user_role()` helper
   - trigger to create profile on `auth.users` insert
   - trigger to block non-admin role changes
2. `20260904175115_profiles_role_update_fix.sql`
   - allow SQL/service updates when `auth.uid()` is null

CLI commands:

- `supabase migration new profiles_auth`
- `supabase db push --dry-run`
- `supabase db push`
- `supabase migration new profiles_role_update_fix`
- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked ...`

## App changes

- `AuthService` + `AuthController` + `AuthScope`
- Login, forgot password, reset password, dashboard welcome, settings profile/logout
- `AuthGate` for protected routes
- Removed Phase 1 “Continue without signing in”
- Deep-link scheme `io.supabase.bms` for password-reset callbacks

## Packages added

None.

## Test admin

- `admin@bms.app` / `Password123!` (role `admin`)

## Manual follow-up

Add redirect URLs in the Supabase Auth dashboard:

- `io.supabase.bms://login-callback/`
- web origin `/#/reset-password` when testing on Chrome
