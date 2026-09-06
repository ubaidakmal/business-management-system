# 009 — Phase 7 FIFO costing, COGS, and profit

Date: 2026-09-06

## User command

Implement Phase 7 only: Transaction & Profit Engine (FIFO + COGS + profit) on Phases 1–6. Keep the Phase 6 stock ledger intact. Do not build reports, PDF/Excel, taxes, expenses, or financial statements.

## Database

Migrations:

- `supabase/migrations/20260906002539_fifo_cogs_profit.sql`
- `supabase/migrations/20260906002818_opening_layer_sync.sql`

### Tables / columns

- `products.opening_unit_cost` — FIFO cost for opening stock
- `inventory_cost_layers` — FIFO batches (`opening` / `purchase` / `adjustment`)
- `sale_cost_allocations` — which layers a sale item consumed
- `sale_items.cogs`, `sale_items.line_profit`
- `sales.total_cogs`, `sales.total_profit`

### Behavior

- Stock formula unchanged: `opening_stock + SUM(stock_movements.quantity)`
- Completed purchase → stock movement + cost layer
- Completed sale → validate stock → FIFO consume → COGS/profit → stock movement
- Cancel completed sale → restore layers + clear COGS/profit + stock reversal
- Cancel completed purchase → allowed only if its layer was not sold
- Adjustment in → layer; adjustment out → FIFO consume
- Clients: SELECT only on costing tables; writes via security definer functions

### Backfill

Opening + unreversed purchases + adjustment-in layers; remaining quantity matched to current stock (45 for existing demo product).

## App

- Sale detail/list show revenue, COGS, profit for completed sales
- Product form/detail include opening unit cost (locked after movements)

## Packages added

None.
