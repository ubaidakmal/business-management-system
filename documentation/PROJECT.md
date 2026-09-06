# Business Management System

Living project document. Update this file whenever a phase or meaningful change is completed.

## Product

Internal ERP-style app for companies, products, purchases, sales, stock, costing, profit, and reports.

Current phase: **Phase 7 — Transaction & Profit Engine (FIFO).** Reports/PDF remain later.

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

## Routing

Protected: dashboard, companies, products, purchases, sales, stock, settings.  
Placeholder: reports.

## Conventions

- Prefer simple files; reuse widgets/theme
- Never put a service-role key in Flutter
- After each user command: update this file + `documentation/commands/NNN_*.md`

## How to run

```bash
flutter pub get
flutter run
```

Test admin: `admin@bms.app` / `Password123!`

## Changelog

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
