# 008 — Phase 6 inventory / stock management

Date: 2026-09-05

## User command

Implement Phase 6 only: Inventory / Stock Management on Phases 1–5. Integrate with purchase/sale completion and cancellation. Do not start FIFO, average costing, COGS, profit, reports, or advanced valuation.

## Database

Migration: `supabase/migrations/20260905085111_stock.sql`

- `products.reorder_level` (default 0)
- `stock_movements` (signed quantity; purchase/sale/reversal/adjustment types)
- View `product_stock_balances`:
  `current_stock = opening_stock + SUM(movements.quantity)`
- Opening stock locked after any movement exists
- RLS: authenticated SELECT only; writes via security definer RPCs/triggers
- RPC `create_stock_adjustment` (admin-only)
- Purchase/sale RPCs finalize items as draft then set completed so stock triggers see items
- Status triggers apply/reverse stock idempotently
- Backfill: completed purchases/sales only (cancelled skipped; net historically zero)

CLI:

- `supabase migration new stock`
- `supabase db push --dry-run`
- `supabase db push --yes`

## App

- Stock list / detail / admin adjustment screens
- Search + company/category/status/low-stock filters
- Product form shows reorder level; locks opening stock when movements exist

## Packages added

None.
