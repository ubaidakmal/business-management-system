# Business Management System

Living project document. Update this file whenever a phase or meaningful change is completed.

## Product

Internal ERP-style app for companies, products, purchases, sales, stock, transactions, profit, and reports.

Current phase: **Phase 5 — Sales Management.** Stock/reports remain placeholders.

## Stack

- Flutter / Dart (SDK `^3.10.1`)
- Supabase Auth + PostgreSQL + RLS
- Navigator 1.0 routes (`onGenerateRoute`)
- `ChangeNotifier` controllers (`AuthController`, `CompaniesController`, `ProductsController`, `PurchasesController`, `SalesController`)

## Architecture

```
Screen
  → Controller (ChangeNotifier) when list state is shared on the screen
  → Service
  → Supabase
```

Form screens call services directly with local loading/error state.

## Auth (Phase 2)

- Session restore, login, logout, forgot/reset password
- Profiles + roles (`admin` / `user`)
- Test admin: `admin@bms.app` / `Password123!`

## Companies & Products (Phase 3)

### Tables

- `companies`: name, code, contact, address, notes, `is_active`, timestamps, `created_by`
- `products`: `company_id`, name, sku, barcode, category, unit, description,
  `purchase_price numeric(14,2)`, `sale_price numeric(14,2)`,
  `opening_stock numeric(14,3)`, `is_active`, timestamps, `created_by`

### Design decisions

- Prefer **deactivate** over hard delete; hard delete is admin-only
- Product `company_id` uses `ON DELETE RESTRICT` so companies with products cannot be wiped accidentally
- Opening stock is a simple starting quantity only — no stock ledger yet
- Money uses `numeric`, not float

### Screens

- Companies list / form / detail
- Products list / form / detail
- Search + filters on lists
- Desktop responsive rows, mobile cards

## Purchases (Phase 4)

### Tables

- `purchases`: `company_id`, date, invoice/reference, notes, subtotal/discount/other_charges/total,
  status (`draft` | `completed` | `cancelled`), `created_by`, timestamps
- `purchase_items`: `purchase_id`, `product_id`, quantity, historical `unit_cost`, `line_total`

### Design decisions

- Create/update drafts via transactional RPCs so headers never orphan without items
- Server recalculates line totals and purchase totals
- Duplicate product on one purchase is blocked at DB and merged in the UI
- Editing allowed for drafts only; completed historical amounts are not freely edited
- Cancel keeps the record (no stock movement yet)
- Does **not** change `products.purchase_price` or `opening_stock`

### Screens

- Purchases list / form / detail
- Search by invoice, reference, company name
- Filters: company, status, date range
- Desktop rows + mobile cards; form uses stacked item cards on all sizes

## Sales (Phase 5)

### Tables

- `sales`: `company_id`, date, invoice/reference, notes, subtotal/discount/other_charges/total,
  status (`draft` | `completed` | `cancelled`), `created_by`, timestamps
- `sale_items`: `sale_id`, `product_id`, quantity, historical `unit_price`, `line_total`

### Design decisions

- Same transactional RPC pattern as purchases (`create_sale_with_items`, draft update, cancel)
- Historical selling price stored on items; current `products.sale_price` is only a default
- No stock deduction, COGS, or profit in this phase
- Draft editable; completed not freely editable; cancel preserves the record

### Screens

- Sales list / form / detail
- Search by invoice, reference, company name
- Filters: company, status, date range
- Desktop rows + mobile cards

## Routing

Public: `/`, `/login`, `/forgot-password`, `/reset-password`

Protected:

- `/dashboard`
- `/companies`, `/companies/form`, `/companies/detail`
- `/products`, `/products/form`, `/products/detail`
- `/purchases`, `/purchases/form`, `/purchases/detail`
- `/sales`, `/sales/form`, `/sales/detail`
- `/settings`
- placeholders: stock, reports

## Conventions

- Prefer one clear file over three tiny files
- Use `AppColors` / `AppTextStyles` / existing widgets
- Never put a service-role key in Flutter
- After every user command: update this file and add `documentation/commands/NNN_short_name.md`

## How to run

```bash
flutter pub get
flutter run
```

## Changelog

### 2026-09-05 — Phase 5 Sales Management

- Added sales / sale_items tables, RLS, and transactional RPCs
- Flutter list/form/detail with search, filters, draft edit, cancel
- No stock or profit logic

### 2026-09-05 — Phase 4 Purchase Management

- Added purchases / purchase_items tables, RLS, and transactional RPCs
- Flutter list/form/detail with search, filters, draft edit, cancel
- Follow-up migration fixed RPC item-alias ambiguity on create/update

### 2026-09-04 — Phase 3 Companies & Products

- Added companies/products tables, RLS, and Flutter CRUD UI
- Opening stock stored as foundation data only

### 2026-09-04 — Phase 2 Authentication

- Profiles, login/logout/session, password reset, AuthGate

### 2026-09-04 — Supabase keys in AppConfig

- Public URL + publishable key for Android Studio Play

### Phase 1 — Foundation

- Theme, routes, widgets, docs pattern
