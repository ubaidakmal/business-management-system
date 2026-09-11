# 011 — Phase 9 Reports

Date: 2026-09-10

## User command

Implement Phase 9 only: Reports module on Phases 1–8. No PDF/Excel/print, expenses, taxes, or financial statements.

## Database

Migration: `supabase/migrations/20260910063757_reports.sql`

RPCs (authenticated, security definer, require `auth.uid()`):

| RPC | Purpose |
| --- | --- |
| `get_sales_report` | Sales rows + summary; cancelled excluded; status completed/draft |
| `get_purchases_report` | Completed purchases only |
| `get_profit_report` | Stored revenue/COGS/profit; optional product filter via `sale_items` |
| `get_product_report` | Product-wise qty/revenue/COGS/profit from completed sale lines |
| `get_company_report` | Company-wise sales, purchases, profit, product count |

Stock reports use existing `product_stock_balances` + `stock_movements` (no new stock formula).

COGS/profit always from Phase 7 stored columns — not recalculated in Flutter.

### Apply

```bash
supabase db push --dry-run
supabase db push --yes
```

If CLI returns 403 for project `pkvvjicqbvbieltrgdov`, re-login with an account that owns the BMS org or set `SUPABASE_DB_PASSWORD`.

## App files created

- `lib/models/report.dart`
- `lib/services/report_service.dart`
- `lib/state/report_controllers.dart`
- `lib/widgets/reports/report_widgets.dart`
- `lib/screens/reports/reports_screen.dart` (hub)
- `lib/screens/reports/sales_report_screen.dart`
- `lib/screens/reports/purchases_report_screen.dart`
- `lib/screens/reports/profit_report_screen.dart`
- `lib/screens/reports/stock_report_screen.dart`
- `lib/screens/reports/product_report_screen.dart`
- `lib/screens/reports/company_report_screen.dart`

## Files modified

- `lib/core/routes/app_router.dart` — reports hub + sub-routes under AuthGate
- `test/models_test.dart`
- `documentation/PROJECT.md`
- `README.md` (brief)
- `documentation/TESTING.md` (Phase 9 steps)

## Features

- Reports landing with 6 report types
- Date / company / search / status filters where specified
- Desktop tables + mobile cards
- Row taps to existing detail screens
- Stock movement history sheet

## Tests

- `flutter analyze`
- `flutter test`

## Remaining manual checks

- Push migrations, then open each report with live data
- Confirm cancelled sales/purchases excluded
- Confirm profit/COGS match sale detail
- Confirm stock matches Stock module
- Mobile + desktop layout
