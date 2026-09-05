# 006 — Phase 4 purchase management

Date: 2026-09-05

## User command

Implement Phase 4 only: Purchase Management on the existing Phase 1–3 foundation. Use the linked Supabase CLI. Do not start sales, inventory, FIFO, average costing, profit, reports, PDF/Excel, or market API.

## Database

Migration: `supabase/migrations/20260904200655_purchases.sql`

Follow-up fix: `supabase/migrations/20260904201438_fix_purchase_rpc_item_alias.sql`
(resolves PL/pgSQL `item` alias ambiguity in create/update RPCs)

Tables:

- `purchases` (`company_id → companies.id`, money as `numeric`, status draft/completed/cancelled)
- `purchase_items` (`purchase_id`, `product_id`, historical `unit_cost` / `quantity` / `line_total`, unique product per purchase)

RLS: authenticated select/insert/update; admin delete drafts only; cancel preferred over delete.

RPCs:

- `create_purchase_with_items`
- `update_draft_purchase_with_items`
- `cancel_purchase`
- helper `_validate_and_build_purchase_items`

CLI:

- `supabase migration new purchases`
- `supabase db push --dry-run`
- `supabase db push --yes`

## App

- Purchase list with search (invoice/reference/company), company/status/date filters
- Create/edit draft form with multi-item lines, auto totals, duplicate product merge
- Detail screen; cancel keeps the record
- Completed purchases are not freely editable
- No stock / product price updates on purchase

## Packages added

None.
