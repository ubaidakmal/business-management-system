# 015 — Phase 13 Security, Testing & Final Polish

Date: 2026-09-11

## User command

Implement Phase 13 only: Security, Testing & Final Polish on Phases 1–12. No major new features. Preserve stock / FIFO / profit sources of truth in PostgreSQL.

## Security review

### Findings (before fixes)

| Severity | Finding |
|----------|---------|
| Critical | `purchases` / `sales` / line-item tables allowed authenticated INSERT/UPDATE/DELETE via PostgREST, bypassing validated RPCs and risking stock/FIFO corruption |
| High | Disabled users (`profiles.is_active=false`) retained JWT access to tables/RPCs |
| Medium | `market_data` anon write revoke incomplete vs stock/FIFO pattern |
| Medium | `product_current_stock` (DEFINER, `FOR UPDATE`) had no auth gate |
| OK | RLS enabled on all core tables; stock/FIFO tables already SELECT-only for clients; admin overview / stock adjust admin-gated; no secrets in Flutter |

### Fixes applied (new migration only)

Migration: `supabase/migrations/20260911110000_phase13_security_hardening.sql` (applied remotely)

- Revoked client INSERT/UPDATE/DELETE on `purchases`, `purchase_items`, `sales`, `sale_items` (RPC-only writes)
- Dropped permissive write policies on those tables
- Added `is_active_user()` + `require_active_user()` helpers
- Restrictive RLS `active_user_only` on business tables (profiles still readable by owner so Flutter can detect disable + sign out)
- Patched client RPCs to call `require_active_user()`
- Hardened `product_current_stock` with `require_active_user()`
- Hardened `market_data` grants (revoke anon / client writes)
- Added list/report helper indexes (`purchases_status_date_idx`, `sales_status_date_idx`, `products_company_active_idx`)

### Edge Function

`fetch-market-rates`:

- 10s external API timeout
- Empty rate set → HTTP 502 with clear error (no silent empty success)
- Secrets remain server-side only

Verified: direct `POST /rest/v1/sales` → `permission denied`; market refresh still returns rates.

## Flutter polish (no business-logic changes)

- Auth: do not invent active users on missing profile; sign out on profile verification failure; preserve disabled/verify messages on login
- `AppError` maps Edge Function `{ error }` payloads
- Market refresh reloads rates without wiping UI via full `load()` flash
- Stock adjustment wrapped in `AdminGate` + `AppLoading` / `AppErrorState`
- Form/detail screens use `AppLoading` instead of raw spinners
- Settings load errors use `AppErrorState` + retry
- Removed unused `cupertino_icons` dependency

## Business logic preserved

- Stock: `opening_stock + SUM(stock_movements.quantity)`
- FIFO: `inventory_cost_layers`
- Profit: stored COGS/profit columns from Phase 7 RPCs/triggers

## Packages

- Removed: `cupertino_icons` (unused)
- Added: none

## Tests

```bash
flutter analyze   # clean
flutter test      # all passed (incl. phase13_security_polish_test.dart)
```

## Remaining limitations / production considerations

- Single-tenant: all active staff share company/product data (by design)
- Cancel purchase/sale still allowed for any active authenticated user (not admin-only)
- Companies/products still writable by any active user (admin-only hard delete)
- Fine-grained `current_user_can` remains UI/helper oriented; DB enforces role + active + RPC/RLS
- Manual concurrency / large-dataset soak tests not automated
- Password reset email delivery depends on Supabase Auth email config
- PDF Helvetica Unicode warnings remain (known `pdf` package limitation)

## Remaining manual checks

- Login / logout / session restore / disabled user
- Purchase/sale draft → complete → cancel stock/FIFO integrity
- Reports/exports + Market refresh
- Mobile + desktop layout pass on major screens
