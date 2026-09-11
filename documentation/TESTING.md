# Manual testing guide

Step-by-step checks for Phases 1–12. Keep it short: do the steps in order when possible (later phases need companies/products/stock).

---

## Login credentials

| Field    | Value           |
| -------- | --------------- |
| Email    | `admin@bms.app` |
| Password | `Password123!`  |
| Role     | `admin`         |

Run the app first:

```bash
flutter pub get
flutter run
```

---

## Phase 1 — Foundation

1. App launches without crash (splash → login or dashboard if already signed in).
2. Theme looks consistent (colors/text from app theme, not random hardcoded styles).
3. On a wide window: sidebar/nav shows module list.
4. On a narrow window: bottom/compact nav works; no clipped titles.
5. Open **Reports** → reports hub with six report types (not a placeholder).

---

## Phase 2 — Authentication

1. Open app signed out → **Login** screen.
2. Wrong password → clear error; stay on login.
3. Login with credentials above → land on **Dashboard**.
4. Open **Settings** → see your email/role; **Sign out** works → back to login.
5. **Forgot password** screen opens (email form). Full email delivery depends on Supabase Auth config.
6. After sign-out, open `/dashboard` (or tap a protected route) → redirected to login.

---

## Phase 3 — Companies & Products

### Companies

1. **Companies** → **Add** → save name (and optional code/contact).
2. Company appears in list; search/filter finds it.
3. Open detail → fields match; **Edit** → change name → save → detail updates.
4. Deactivate (if available) → inactive handling matches UI (hidden or marked).

### Products

1. **Products** → **Add** → pick company, name, prices, opening stock, reorder level, opening unit cost.
2. Product shows in list with company name.
3. Open detail → values correct; **Edit** → save → updates stick.
4. Filter by company → only that company’s products.

---

## Phase 4 — Purchases

1. **Purchases** → **Add Purchase** → company + date + line items (product, qty, unit cost).
2. Save as **draft** → stock must **not** change yet.
3. Open draft → **Complete** → status `completed`; totals look right.
4. Cancel a **completed** purchase (only if its stock wasn’t sold yet) → status `cancelled`; stock reverses.
5. Cancelled purchase still visible in list when filter allows; amounts not treated as “active” stock.

---

## Phase 5 — Sales

1. **Sales** → **Add Sale** → company + products + qty + unit price.
2. Save **draft** → stock must **not** change.
3. **Complete** → status `completed`; invoice/total correct.
4. Open detail → lines and grand total match form.
5. **Cancel** completed sale → status `cancelled`; record kept.

---

## Phase 6 — Inventory / Stock

1. **Stock** → list shows current stock per product.
2. Note stock before a **completed purchase** → after complete, stock **increases** by qty.
3. Note stock before a **completed sale** → after complete, stock **decreases** by qty.
4. Draft purchase/sale → stock unchanged.
5. Cancel completed sale → stock restored.
6. Product with stock ≤ reorder level → marked low stock.
7. Stock detail → movements history (purchase/sale/adjustment) makes sense.
8. **Adjustment** (if used) → in increases stock; out decreases (and fails if not enough stock).

**Formula to sanity-check:**  
`current_stock = opening_stock + sum(movements)`

---

## Phase 7 — FIFO, COGS & Profit

Use a product with known cost (opening unit cost and/or purchase costs).

1. Complete a **purchase** at cost A, then another at cost B (A older).
2. Complete a **sale** that sells from the oldest layer first.
3. Sale detail shows:
   - Revenue (qty × price)
   - **COGS** (from FIFO, not typed in Flutter)
   - **Profit** = revenue − COGS
4. Sell more than available stock → complete fails.
5. Cancel completed **sale** → COGS/profit cleared/zeroed; layers restored; stock back.
6. Cancel completed **purchase** after its qty was sold → should **fail**; if not sold → cancel OK.
7. After stock movements exist, **opening unit cost** should be locked on the product.

---

## Phase 8 — Dashboard

**Prerequisite:** migration `get_dashboard_data` applied (`supabase db push`).

1. Open **Dashboard** → loading then KPIs (not empty placeholders only).
2. Filters:
   - **Today / This week / This month / Custom** → numbers change with range.
   - **Company** filter → limits sales/purchases/inventory for that company.
3. KPIs (completed only):
   - Total Sales / Revenue
   - Total Purchases
   - Total COGS / Total Profit (match a known completed sale)
   - Number of Sales / Purchases
4. Create a **cancelled** sale/purchase in range → those amounts **not** in KPIs.
5. **Recent sales** → tap row → sale detail.
6. **Recent purchases** → tap row → purchase detail.
7. **Inventory** → product / low-stock / out-of-stock counts; low-stock list uses reorder level; tap → stock detail.
8. Trend chart shows for the selected range (sales/profit bars).
9. Quick actions: Add Sale / Purchase / Product, View Stock, Companies, Reports.
10. Pull to refresh; break network briefly → error + retry.
11. Resize window: desktop multi-column; mobile stacked; no overflow.

---

## Phase 9 — Reports

**Prerequisite:** migration `20260910063757_reports.sql` applied.

1. **Reports** hub → open each: Sales, Purchases, Profit, Stock, Product, Company.
2. Sales: date/company/status/search; totals; cancelled excluded; tap row → sale detail.
3. Purchases: completed only; totals; tap → purchase detail.
4. Profit: revenue/COGS/gross profit match a known completed sale; product filter optional.
5. Stock: balances match Stock module; low/out filters; History shows movements.
6. Product: qty sold / revenue / COGS / profit from completed lines.
7. Company: sales, purchases, profit, product count per company.
8. Desktop tables + mobile cards; no overflow.
9. **Export PDF / Export Excel / Print** — file matches current filters and on-screen totals.

---

## Phase 11 — Settings & Administration

**Prerequisite:** migration `20260910070436_settings_admin.sql` applied.

1. Login still works; session restore and logout still work.
2. **Settings** → update own display name.
3. As **admin**:
   - Business profile → save name → export a report → header shows new name.
   - Preferences → save currency/date/number formats.
   - Administration → overview counts look sensible.
   - Users → edit name/role/active; cannot disable/demote the last admin.
4. As **non-admin**:
   - No Administration / Business profile links (or blocked by AdminGate).
   - `/admin` redirects away.
5. Disable a non-admin user → that user cannot stay signed in.
6. Roles & permissions screen lists capabilities for the current role.

---

## Phase 12 — Live Market

**Prerequisite:** migration `20260911095540_market_data.sql` + Edge Function `fetch-market-rates` deployed.

1. Open **Market** → rates load (or tap Refresh).
2. Source + last updated shown; no API keys in app source.
3. Select a pair → history + trend update after multiple refreshes.
4. Admin → Settings → Market settings → disable → Market shows disabled / blocked.
5. Re-enable → Refresh works again.
6. Mobile cards + desktop split layout without overflow.

---

## Quick smoke path (all phases in ~10 minutes)

1. Login with credentials above.
2. Add company → add product (opening stock + cost + reorder).
3. Complete purchase → check Stock up.
4. Complete sale → check Stock down; sale shows COGS/profit.
5. Dashboard (this month) → sales/purchases/profit/counts look right.
6. **Reports → Sales / Profit** → same totals; cancelled excluded after step 7.
7. Cancel the sale → stock/profit reverse; dashboard + sales report refresh exclude it.
8. Sign out → login again.

---

## Automated checks (optional)

```bash
flutter analyze
flutter test
```
