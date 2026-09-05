# 007 — Phase 5 sales management

Date: 2026-09-05

## User command

Implement Phase 5 only: Sales Management on the existing Phase 1–4 foundation. Use the linked Supabase CLI. Do not start inventory, stock movements, FIFO, average costing, COGS, profit, reports, PDF/Excel, or market API.

## Database

Migration: `supabase/migrations/20260905063059_sales.sql`

Tables:

- `sales` (`company_id → companies.id`, money as `numeric`, status draft/completed/cancelled)
- `sale_items` (`sale_id`, `product_id`, historical `unit_price` / `quantity` / `line_total`, unique product per sale)

RLS: authenticated select/insert/update; admin delete drafts only; cancel preferred over delete.

RPCs:

- `create_sale_with_items`
- `update_draft_sale_with_items`
- `cancel_sale`
- helper `_validate_and_build_sale_items`

CLI:

- `supabase migration new sales`
- `supabase db push --dry-run`
- `supabase db push --yes`

## App

- Sales list with search (invoice/reference/company), company/status/date filters
- Create/edit draft form with multi-item lines, auto totals, duplicate product merge
- Detail screen; cancel keeps the record
- Completed sales are not freely editable
- No stock / product sale_price updates on sale
- No profit/COGS calculation

## Packages added

None.
