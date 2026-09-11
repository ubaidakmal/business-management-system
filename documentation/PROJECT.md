# Business Management System

Living project document. Update this file whenever a phase or meaningful change is completed.

## Product

Internal ERP-style app for companies, products, purchases, sales, stock, costing, profit, and reports.

Current phase: **Phase 14 — Localization (EN / 繁體中文).** Advanced accounting / market platforms remain later.

## Stack

- Flutter / Dart (SDK `^3.10.1`)
- Supabase Auth + PostgreSQL + RLS
- Navigator 1.0 routes (`onGenerateRoute`)
- `ChangeNotifier` controllers

## Architecture

```
Screen → Controller (lists) / local state (forms) → Service → Supabase/RPC
```

## Stock (Phase 6)

`current_stock = opening_stock + SUM(stock_movements.quantity)`

Draft docs do not move stock. Completed purchase/sale apply movements; cancel reverses.

## FIFO / COGS / Profit (Phase 7)

### Cost layers (`inventory_cost_layers`)

Sources: `opening`, `purchase`, `adjustment`.

Sales consume layers oldest-first (`created_at`, `id`).

### Formulas

- Line revenue = quantity × unit_price (`line_total`)
- Line COGS = sum of FIFO allocations
- Line profit = revenue − COGS
- Sale total profit = sum of line profits

Stored on `sale_items` / `sales` by the database (not Flutter).

### Cancellations

- Cancel completed sale: restore layer remaining, delete allocations, zero COGS/profit, reverse stock
- Cancel completed purchase: only if its layer is fully remaining (not sold)

### Opening cost

`products.opening_unit_cost` seeds the opening FIFO layer. Locked after stock movements exist.

## Dashboard (Phase 8)

Single RPC `get_dashboard_data(date_from, date_to, company_id?)` returns summary KPIs, recent sales/purchases, inventory counts + low-stock list, and a daily sales/profit trend.

- Filters: Today / This week / This month / Custom range; optional company
- Financial values from PostgreSQL completed transactions only (COGS/profit from Phase 7 columns)
- Stock summary from `product_stock_balances` (`reorder_level` / `is_low_stock`)

## Reports (Phase 9)

Hub at `/reports` with sales, purchases, profit, stock, product, and company reports.

- Aggregates via RPCs: `get_sales_report`, `get_purchases_report`, `get_profit_report`, `get_product_report`, `get_company_report`
- Stock report reads `product_stock_balances` + movement history (no second stock formula)
- Cancelled transactions excluded; COGS/profit from stored Phase 7 values

## Exports (Phase 10)

Each report screen can **Export PDF**, **Export Excel**, or **Print**.

- Uses the currently filtered in-memory report data (same filters as the UI)
- No new stock/COGS/profit calculations
- Packages: `pdf`, `printing`, `excel`, `file_saver`
- Business name on PDFs/Excel: from `app_settings` via `SettingsService` (fallback `AppStrings.appName`)

## Settings & Administration (Phase 11)

- `app_settings` singleton: business profile + currency/date/number preferences
- Settings hub: account profile, business/preferences (admin), roles view, admin entry
- Admin overview + user management (name/role/`is_active`)
- `AppPermissions` for UI; RLS/`current_user_can` for server rules
- Auth flow unchanged; disabled users are signed out

## Live Market (Phase 12)

```
Flutter → Edge Function `fetch-market-rates` → External FX API → market_data cache
```

- Secrets only in Edge Function env (`MARKET_API_PROVIDER`, optional `MARKET_API_KEY`)
- Default provider: `open_er_api` (no key, includes PKR/AED). Alternatives: `frankfurter`, `exchangerate_api` (+ secret)
- Flutter never holds external API keys
- Market screen: rates, history trend, manual refresh
- Admin market settings: enable + base/quote currencies

## Security & Polish (Phase 13)

- Purchases/sales (+ items) are **RPC-only** for writes (client INSERT/UPDATE/DELETE revoked)
- Disabled users blocked by restrictive RLS + `require_active_user()` in client RPCs
- Edge Function timeouts / empty-rate errors hardened
- UI polish: consistent `AppLoading` / `AppErrorState`; auth profile failure signs out
- Unused `cupertino_icons` removed

## Localization (Phase 14)

- Languages: English (default), Traditional Chinese Taiwan (`zh_TW` / 繁體中文)
- Preference stored **locally** via `SharedPreferences` (not Supabase)
- `LocaleService` + `LocaleController` + Settings → Language selector
- ARB files under `lib/l10n/`; access via `context.l10n` / `AppStrings` bridge
- Report PDF/Excel/Print column & metric **labels** follow the selected language (business data names stay as stored)
- Packages: `flutter_localizations`, `intl`, `shared_preferences`

## Routing

Protected: dashboard, companies, products, purchases, sales, stock, market, reports (+ sub-routes), settings (+ business/preferences/permissions/market), admin (+ users).

## Conventions

- Prefer simple files; reuse widgets/theme
- Never put a service-role key or external API secret in Flutter
- After each user command: update this file + `documentation/commands/NNN_*.md`

## How to run

```bash
flutter pub get
flutter run
```

Deploy market function (after linking):

```bash
supabase db push
supabase functions deploy fetch-market-rates
```

Test admin: `admin@bms.app` / `Password123!`

## Changelog

### 2026-09-11 — Phase 14 Localization

- English + 繁體中文 UI; local SharedPreferences language preference
- Settings → Language; immediate switch + persist across restarts
- Export labels localized; no business-logic or Supabase schema changes

### 2026-09-11 — Phase 13 Security, Testing & Final Polish

- Hardened RLS/grants: transactional writes RPC-only; active-user gates
- Edge Function timeout + empty-rate handling
- Auth/error/UI polish; removed unused `cupertino_icons`
- Added security polish tests; analyze/test clean

### 2026-09-11 — Phase 12 Live Market Integration

- `market_data` table + Edge Function `fetch-market-rates`
- Market screen + admin market settings
- FX rates cached securely; no secrets in Flutter

### 2026-09-10 — Phase 11 Settings & Administration

- `app_settings` + profile `is_active`
- Admin overview and user management
- Settings hub; exports use business name
- Auth stack preserved

### 2026-09-10 — Phase 10 Exports

- PDF / Excel / Print for all six report types
- Export actions respect active report filters
- Packages: pdf, printing, excel, file_saver

### 2026-09-10 — Phase 9 Reports

- Reports hub + six report screens (sales, purchases, profit, stock, product, company)
- DB report RPCs; stock from existing balances view
- Date/company filters; desktop tables / mobile cards

### 2026-09-06 — Phase 8 Dashboard

- Real dashboard via `get_dashboard_data` RPC
- KPI cards, recent activity, inventory summary, CustomPaint trend chart
- Date presets + company filter + refresh / error states

### 2026-09-06 — Phase 7 FIFO / COGS / Profit

- Cost layers + sale allocations; COGS/profit on sales
- Integrated with purchase/sale complete & cancel
- Sale UI shows revenue, COGS, profit

### 2026-09-05 — Phase 6 Stock

- stock_movements + balances; purchase/sale stock integration

### 2026-09-05 — Phase 5 Sales / Phase 4 Purchases

- Transaction headers + items via RPCs

### Earlier

- Phase 3 companies/products, Phase 2 auth, Phase 1 foundation
