# 010 — Phase 8 Dashboard

Date: 2026-09-06

## User command

Implement Phase 8 only: Dashboard with real Supabase aggregates, date/company filters, recent activity, inventory summary, simple trend chart, and quick actions. Do not build reports, PDF/Excel, expenses, or new COGS/profit logic.

## Database

Migration: `supabase/migrations/20260906101728_dashboard.sql`

### RPC

`get_dashboard_data(p_date_from date, p_date_to date, p_company_id uuid default null) → jsonb`

Returns:

| Key | Source |
| --- | --- |
| `summary` | Completed `sales` / `purchases` in range (totals, COGS, profit, counts) |
| `recent_sales` | Up to 8 completed sales (invoice, company, total, profit, date) |
| `recent_purchases` | Up to 8 completed purchases |
| `inventory` | Counts from `product_stock_balances` (active products) |
| `low_stock` | Up to 8 rows where `is_low_stock` (uses `reorder_level`) |
| `trend` | Daily sales total + profit via `generate_series` |

Rules:

- Financial stats use **completed** transactions only (cancelled excluded)
- Revenue / COGS / profit come from stored sale columns (Phase 7) — not recalculated in Flutter
- Inventory uses existing `product_stock_balances` view — no second stock formula
- Callable by `authenticated`; requires signed-in `auth.uid()`

### Apply note

If CLI org access fails (`403` on login-role / api-keys), set `SUPABASE_DB_PASSWORD` or re-login with an account that owns project `pkvvjicqbvbieltrgdov`, then:

```bash
supabase db push
```

## App

- `DashboardService` → RPC
- `DashboardController` → presets (today / week / month / custom) + company filter + refresh
- `DashboardScreen` → KPI cards, quick actions, trend chart (`CustomPaint`, no chart package), inventory, recent lists → existing detail routes
- Model: `lib/models/dashboard.dart`

## Packages added

None.

## Verification

- `flutter analyze`
- `flutter test` (includes `DashboardData.fromJson`)
- Manual: after migration push, confirm KPI totals vs completed docs and date/company filters
