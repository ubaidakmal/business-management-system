# 014 — Phase 12 Live Market Integration

Date: 2026-09-11

## User command

Implement Phase 12 only: Live Market Integration on Phases 1–11. Never put external API secrets in Flutter. Use Edge Functions.

## Architecture

```
Flutter MarketScreen
  → MarketService.functions.invoke('fetch-market-rates')
    → Supabase Edge Function
      → External FX API (open.er-api.com by default)
      → Insert into market_data (service role)
  → Flutter reads market_data via RLS
```

## Security

- No API keys in Flutter / `AppConfig`
- Optional secrets (Edge Function env only):
  - `MARKET_API_PROVIDER` = `open_er_api` (default) | `frankfurter` | `exchangerate_api`
  - `MARKET_API_KEY` = required only for `exchangerate_api`
- JWT required (`verify_jwt: true`)
- Clients can SELECT `market_data` only when `app_settings.market_enabled`
- Clients cannot INSERT/UPDATE/DELETE market rows

### Set secrets (when using a paid provider)

```bash
supabase secrets set MARKET_API_PROVIDER=exchangerate_api
supabase secrets set MARKET_API_KEY=your_key_here
```

Default `open_er_api` provider needs no key and supports PKR/AED.

## Database

Migration: `supabase/migrations/20260911095540_market_data.sql` (applied remotely)

- `market_data` table + indexes + RLS
- `app_settings.market_enabled`, `market_base_currency`, `market_quote_currencies`
- `current_user_can` extended with `view_market` / `manage_market_settings`

## Edge Functions

- `supabase/functions/fetch-market-rates/` (deployed)

Deploy:

```bash
supabase functions deploy fetch-market-rates
supabase db push
```

## Files created

- Migration + Edge Function
- `lib/models/market_data.dart`
- `lib/services/market_service.dart`
- `lib/state/market_controller.dart`
- `lib/screens/market/market_screen.dart`
- `lib/screens/settings/market_settings_screen.dart`
- `lib/widgets/market/market_trend_chart.dart`
- `test/market_test.dart`
- `documentation/commands/014_phase12_market_integration.md`

## Files modified

- `lib/models/app_settings.dart`, `permission.dart`
- `lib/screens/settings_screen.dart`
- `lib/core/routes/app_router.dart`
- `documentation/PROJECT.md`, `README.md`, `documentation/TESTING.md`

## Packages added

None.

## Features

- Market nav screen: current FX rates, source, last updated, refresh
- History list + simple trend chart for selected pair
- Admin market settings (enable/base/quotes)
- Manual refresh only (no aggressive polling)

## Tests

- `flutter analyze` — clean
- `flutter test` — all passed
- Edge Function smoke test (admin JWT): USD→PKR/EUR/GBP/AED via `open_er_api`

## Remaining manual checks

- Refresh rates in the running Flutter app
- Confirm no secrets in Flutter source
- Disable market in settings → reads/refresh blocked
- Mobile + desktop layout
