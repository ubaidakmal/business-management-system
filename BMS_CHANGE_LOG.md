# Business Management System — Change Log / Handoff

## Project

Business Management System (BMS), an ERP/business management application built with Flutter + Supabase/PostgreSQL.

The project is developed heavily through Cursor.

## User Preferences

Communication:
- Explain in Roman Urdu.
- Cursor commands/prompts must be in English.
- Keep explanations practical and concise.

Development:
- Simple, clean, readable, maintainable code.
- Professional architecture, simple implementation.
- Avoid unnecessary abstractions, interfaces, factories, managers, wrappers, helpers, layers, and packages.
- Every file/class/folder must have a clear purpose.
- Reuse existing components.

UI/UX:
- Professional and polished.
- Must work on Web, Android, iOS, macOS, Windows, Linux.
- Responsive for mobile, tablet, small desktop, normal desktop, large desktop, orientations and browser sizes.
- No overflow, clipped buttons, text overlap, broken layouts, or unnecessary horizontal scrolling.
- Desktop must not look like a stretched mobile app.
- Prefer LayoutBuilder, Flexible, Expanded, Wrap, SingleChildScrollView and constraints.
- Centralize colors/theme/typography; avoid hardcoded colors.

Database:
- PostgreSQL/Supabase is the source of truth for business and financial logic.
- Do not expose service-role keys in Flutter.
- Use RLS and security-definer functions where appropriate.
- Create new migrations; never edit already-applied migrations.
- Safely use:
  supabase db push --dry-run
  supabase db push --yes
- Use database smoke tests where relevant.
- Never silently delete or modify business data.

## Architecture

Typical structure:

lib/
  core/constants
  core/theme
  core/routes
  core/utils
  core/validators
  models
  services
  repositories
  state
  widgets/common
  screens
  config
  main.dart

Not every feature must use every layer.

Preferred flow:

Screen → State/Controller → Service/Repository when useful → Supabase/PostgreSQL

Existing reusable widgets include AppButton, AppOutlinedButton, AppTextField, AppDropdown, AppSearchField, AppCard, AppDialog, AppLoading, AppEmptyState, AppErrorState, AppSectionHeader, AppStatCard, AppDataTable foundations, AppBadge/StatusBadge, AppIconButton, AppDetailRow and shared field widgets.

## Phase Status

1. Foundation — COMPLETE
2. Authentication & User Management — COMPLETE
3. Companies & Products — COMPLETE
4. Purchase Management — COMPLETE
5. Sales Management — COMPLETE
6. Inventory / Stock Management — COMPLETE
7. FIFO / COGS / Profit Engine — COMPLETE
8. Dashboard — IMPLEMENTED LOCALLY; REMOTE RPC DEPLOYMENT PENDING
9. Reports — NEXT
10. PDF / Excel / Printing
11. Settings & Administration
12. Live Market Integration
13. Security, Testing & Final Polish

---

# Phase 1 — Foundation

COMPLETE.

Established:
- Simple project structure
- Theme/colors
- Typography
- Constants
- Routes/navigation
- Supabase initialization
- State foundation
- Models/services/repositories pattern
- Utilities/validators
- Reusable widgets
- Responsive foundation

No business features were implemented here.

---

# Phase 2 — Authentication & User Management

COMPLETE.

Important files/features:
- auth_service.dart
- auth_controller.dart
- forgot/reset password screens
- dashboard
- settings
- auth_gate.dart
- auth_form_shell.dart

Database:
- profiles table: id, email, name, role, timestamps
- RLS
- current_user_role()
- automatic profile creation on signup
- non-admins cannot change roles

Features:
- Login/logout
- Session restore
- Forgot/reset password
- Profile name editing
- Admin/user roles
- Protected routes/AuthGate

Tests:
- flutter analyze clean
- widget tests passed
- macOS build launched
- Supabase init/login smoke tests passed
- bad password rejected

Do not expose old test credentials.

---

# Phase 3 — Companies & Products

COMPLETE.

Migration:
- 20260904180935_companies_products.sql

Implemented:
- Company model/service/controller/screens
- Product model/service/controller/screens
- Company list/form/detail
- Product list/form/detail
- Formatters

Products include company relationship, name/code/SKU/barcode/category/prices/opening stock/status.

Indexes:
- name
- code
- sku
- barcode
- company_id

Unique constraints for code/SKU/barcode where applicable.

RLS:
- Authenticated SELECT/INSERT/UPDATE
- Admin-only DELETE
- Prefer deactivation over deletion

Opening stock was introduced here and later became the Phase 6 stock baseline.

Tests passed including API smoke tests and duplicate SKU protection.

---

# Phase 4 — Purchase Management

COMPLETE.

Created:
- lib/models/purchase.dart
- lib/services/purchase_service.dart
- lib/state/purchases_controller.dart
- lib/screens/purchases_screen.dart
- lib/screens/purchase_form_screen.dart
- lib/screens/purchase_detail_screen.dart
- supabase/migrations/20260904200655_purchases.sql
- supabase/migrations/20260904201438_fix_purchase_rpc_item_alias.sql
- documentation/commands/006_phase4_purchases.md

Database:
- purchases
- purchase_items

RPCs:
- create_purchase_with_items
- update_draft_purchase_with_items
- cancel_purchase
- _validate_and_build_purchase_items

Features:
- Create/edit drafts
- Multi-item purchases
- Historical unit cost
- Automatic totals
- Detail
- Cancel
- Search/filter by invoice/reference/company/status/date

At this stage purchases did NOT update stock.

Tests passed.

---

# Phase 5 — Sales Management

COMPLETE.

Created:
- lib/models/sale.dart
- lib/services/sale_service.dart
- lib/state/sales_controller.dart
- lib/screens/sales_screen.dart
- lib/screens/sale_form_screen.dart
- lib/screens/sale_detail_screen.dart
- supabase/migrations/20260905063059_sales.sql
- documentation/commands/007_phase5_sales.md

Database:
- sales
- sale_items

RPCs:
- create_sale_with_items
- update_draft_sale_with_items
- cancel_sale
- _validate_and_build_sale_items

Features:
- Create/edit drafts
- Complete/cancel sale
- Multi-item sales
- Historical unit price
- Automatic totals
- Duplicate product handling
- Search/filter by invoice/reference/company/status/date

Phase 5 initially did NOT update stock.

Smoke test included:
subtotal 1000, discount 100, charges 20, total 920.
Duplicate product rejected.
Cancellation worked.
products.sale_price remained unchanged.

---

# Phase 6 — Inventory / Stock Management

COMPLETE.

Created:
- lib/models/stock_movement.dart
- lib/services/stock_service.dart
- lib/state/stock_controller.dart
- lib/screens/stock_screen.dart
- lib/screens/stock_detail_screen.dart
- lib/screens/stock_adjustment_screen.dart
- supabase/migrations/20260905085111_stock.sql
- documentation/commands/008_phase6_stock.md

Modified product, product form/detail, router, dashboard, shared fields, error handling, tests and docs.

Database:
- products.reorder_level
- stock_movements
- indexes and unique reference/item/type protection
- product_stock_balances view
- opening-stock lock trigger
- purchase/sale status triggers and helpers
- create_stock_adjustment RPC

Core formula:

Current Stock =
products.opening_stock + SUM(stock_movements.quantity)

Signed movements:
- Purchase: +qty
- Sale: -qty
- Purchase reversal: -qty
- Sale reversal: +qty
- Adjustment in: +qty
- Adjustment out: -qty

Rules:
- Draft purchase/sale = no movement
- Completed purchase = +qty
- Completed sale = -qty
- Insufficient stock sale = rejected
- Completed transaction cancellation = reversal
- Adjustments = admin only
- Stock cannot become negative
- Duplicate applications blocked
- Direct client writes to stock_movements blocked

Backfill:
- 2 completed purchases
- stock became 40 = 20 opening + 20 purchases
- cancelled sale skipped

Tests passed:
- opening stock
- draft no effect
- purchase +7
- sale -3
- oversell rejection
- cancellation restoration/reversal
- adjustment
- over-adjust rejection
- direct INSERT denied
- opening stock locked
- idempotency

Manual check: stock list/detail/adjustment mobile and desktop; non-admins should not see Adjust.

---

# Phase 7 — FIFO / COGS / Profit Engine

COMPLETE.

Created:
- supabase/migrations/20260906002539_fifo_cogs_profit.sql
- supabase/migrations/20260906002818_opening_layer_sync.sql
- documentation/commands/009_phase7_profit.md

Modified:
- lib/models/sale.dart
- lib/models/product.dart
- sale detail/list
- product form/detail
- tests/docs

Database:
- products.opening_unit_cost
- inventory_cost_layers
- sale_cost_allocations
- sale_items.cogs
- sale_items.line_profit
- sales.total_cogs
- sales.total_profit

FIFO:
- Layers from opening stock, purchases and qualifying adjustments
- Sales consume oldest layers first
- Stock ledger itself remains unchanged

Stock formula remains:

opening_stock + SUM(stock_movements.quantity)

Financial formulas:

Revenue = sale line revenue
COGS = FIFO allocations
Profit = Revenue - COGS

Values are stored on sale items and sale header.

Cancellation:
- Cancel sale restores stock and FIFO layer quantities and clears/reverses COGS/profit.
- Cancel purchase is blocked if its layer has already been consumed by a sale.

Smoke test:
10 × $10 + 10 × $15
Sale 15 × $20
Revenue = $300
COGS = $175
Profit = $125

Also verified:
- insufficient stock rejected
- sale cancel restores layers
- purchase cancel blocked after consumption
- direct layer INSERT denied
- backfill layers matched stock = 45

---

# Phase 8 — Dashboard

STATUS:
Flutter implementation complete.
Migration is ready locally.
Remote Supabase RPC is NOT deployed yet.

Created:
- supabase/migrations/20260906101728_dashboard.sql
- lib/models/dashboard.dart
- lib/services/dashboard_service.dart
- lib/state/dashboard_controller.dart
- lib/widgets/dashboard_trend_chart.dart
- documentation/commands/010_phase8_dashboard.md

Modified:
- lib/screens/dashboard_screen.dart
- test/models_test.dart
- documentation/PROJECT.md
- README.md

Database RPC:

get_dashboard_data(p_date_from, p_date_to, p_company_id?)

Returns:
- summary
- recent sales
- recent purchases
- inventory
- low-stock products
- daily sales/profit trend

Dashboard sections:
- KPIs
- date presets/custom range
- company filter
- quick actions
- sales/profit trend
- inventory summary
- low-stock list
- recent sales/purchases
- tap-through to detail screens

KPIs:
- Total Sales
- Total Purchases
- Total Revenue
- Total COGS
- Total Profit
- Number of Sales
- Number of Purchases

Cancelled transactions are excluded.

Inventory uses product_stock_balances.
Low stock uses reorder_level.

Trend chart uses Flutter CustomPaint; no chart package.

Tests:
- flutter analyze clean
- flutter test passed

Live RPC smoke test failed only because the RPC does not exist on remote yet.

CURRENT BLOCKER:
Supabase CLI account lost access to the organization/project.

Project/org references previously reported:
- org: ufscnairxkzwdwmkajyq
- project: pkvvjicqbvbieltrgdov

Do not assume these are accessible until CLI login/access is restored.

When access is restored:
1. Login with an account that has access.
2. Run:
   supabase db push
3. Run the dashboard RPC smoke test.
4. Verify KPI totals, cancelled exclusion, date/company filters, low stock, navigation and responsive layout.

---

# CURRENT DATA FLOW

Companies
  ↓
Products
  ↓
Purchases
  ↓
Stock Movements
  ↓
Current Stock

Purchases
  ↓
FIFO Cost Layers
  ↓
Sales
  ↓
FIFO Consumption
  ↓
COGS + Profit
  ↓
Dashboard

Core source-of-truth rules:

Current Stock =
opening_stock + SUM(stock_movements.quantity)

COGS =
FIFO cost allocations

Profit =
Revenue - COGS

PostgreSQL/Supabase is the source of truth for these calculations.

---

# NEXT TASK — PHASE 9 REPORTS

Phase 9 has NOT started.

Planned:
- Sales reports
- Purchase reports
- Profit/COGS reports
- Stock reports
- Product-wise reports
- Company-wise reports
- Date-range filtering
- Summary and detailed views
- Search
- Filtering
- Sorting

Important:
Use existing PostgreSQL data.
Do not recalculate stock, FIFO, COGS or profit inside Flutter.

Do NOT implement PDF/Excel export in Phase 9.
That belongs to Phase 10.

The next likely user request is:
"Write the Phase 9 Cursor command."

The Phase 9 command should be concise like Phases 6–8, in English, and should preserve all established architecture and simplicity rules.

---

# FUTURE PHASES

## Phase 10 — PDF / Excel / Printing
- PDF reports
- Excel exports
- Printing
- Sales/purchase/profit/stock exports
- Preserve report filters in exports

## Phase 11 — Settings & Administration
- System settings
- User management
- Roles/permissions
- Business/company settings
- Administrative controls

## Phase 12 — Live Market Integration
- External market API
- Live market data
- Supabase Edge Functions for secrets
- Never expose API secrets in Flutter

## Phase 13 — Security, Testing & Final Polish
- RLS/security review
- Edge cases
- Concurrency testing
- Responsive UI audit
- Performance
- Cross-platform verification
- Final cleanup

---

# FUTURE CURSOR COMMAND RULES

Every command should:
1. Inspect the existing implementation first.
2. Reuse the existing architecture.
3. Reuse existing widgets/theme/components.
4. Create new migrations rather than editing applied migrations.
5. Keep business/financial logic in PostgreSQL.
6. Keep Flutter focused on UI/state/presentation.
7. Avoid unnecessary packages.
8. Avoid over-engineering.
9. Preserve previous phase behavior.
10. Run flutter analyze and flutter test.
11. Safely use Supabase CLI.
12. Run database smoke tests when relevant.
13. Update documentation/commands, PROJECT.md and README.md.
14. End with a concise summary of files, database changes, features, tests and remaining manual checks.
