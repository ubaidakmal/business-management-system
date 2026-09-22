# Business Management System — Easy Guide

A simple explanation of what this app does and how each part works.

You do **not** need to know coding to understand this file.

---

## What is this app?

This is an internal **business management** app.

It helps a company:

1. Keep records of **companies** and **products**
2. Record **purchases** (buying stock)
3. Record **sales** (selling products)
4. Track **stock / inventory**
5. See **profit** (after cost of goods)
6. View a **dashboard** and **reports**
7. Check **live currency exchange rates**
8. Manage **settings**, **users**, and **language**

Think of it as a simple ERP for daily business work.

---

## How to open the app

1. Start the app
2. Sign in with your email and password
3. After login you see the main menu (sidebar on desktop, drawer/menu on mobile)

**Test admin login (for development):**

- Email: `admin@bms.app`
- Password: `Password123!`

---

## Main menu (what each screen is for)

| Menu item | Simple meaning |
|-----------|----------------|
| **Dashboard** | Home overview of sales, purchases, profit, stock |
| **Companies** | Customers / suppliers / business partners |
| **Products** | Items you buy and sell |
| **Purchases** | Buying products into stock |
| **Sales** | Selling products to customers |
| **Stock** | How much inventory you have |
| **Market** | Live currency exchange rates |
| **Reports** | Detailed summaries + export PDF/Excel |
| **Settings** | Your account, language, business setup, admin |

---

## 1. Login & account

### Sign in
- Enter email + password
- Wrong password shows an error
- Correct login opens the Dashboard

### Forgot password
- Use **Forgot password?** on the login screen
- Enter email to request a reset link
- (Email delivery depends on Supabase Auth setup)

### Sign out
- Open **Settings** → **Sign out**
- Or use the logout icon in the top bar

### Important security rules
- If an admin **disables** your account, you cannot use the app
- Hiding buttons in the UI is not the only security — the database also blocks unauthorized actions

---

## 2. Dashboard (home screen)

The dashboard answers:

> “How is the business doing right now?”

You can see:

- **Total sales**
- **Total purchases**
- **Revenue**
- **COGS** (cost of goods sold)
- **Profit**
- Number of sales / purchases
- **Sales & profit trend** chart
- **Inventory** summary (including low stock)
- **Recent sales** and **recent purchases**
- Quick buttons (Add Sale, Add Purchase, etc.)

### Filters
- Today / This week / This month / Custom date range
- Optional company filter

Only **completed** transactions count here. Cancelled ones are ignored.

---

## 3. Companies

Companies are the businesses you deal with (buy from or sell to).

### What you can do
- Add a company (name, code, contact, address, notes)
- Edit a company
- View company details
- Search / filter the list
- Deactivate a company if needed

Admin users can hard-delete master data when allowed by permissions.

---

## 4. Products

Products are the items in your inventory.

### Typical fields
- Name
- Company (which company the product belongs to)
- SKU / barcode / category / unit
- Selling price
- Opening stock (starting quantity)
- Opening unit cost (starting cost for profit calculation)
- Reorder level (warn when stock is low)

### Important
- After stock movements exist, **opening stock cannot be changed**
- Opening unit cost creates the first cost layer used for profit (FIFO)

---

## 5. Purchases (buying)

A purchase increases stock when it is **completed**.

### Statuses
- **Draft** — saved, but stock does **not** change yet
- **Completed** — stock increases; cost layers are created
- **Cancelled** — completed purchase reversed (only if that stock was not already sold)

### Typical flow
1. Create purchase → choose company + products + quantities + unit costs
2. Save as **draft** (optional)
3. **Complete** purchase → stock goes up
4. If needed, **cancel** completed purchase (if inventory still available)

Also supports invoice number, discount, other charges, notes.

---

## 6. Sales (selling)

A sale decreases stock when it is **completed**, and calculates profit.

### Statuses
- **Draft** — no stock change
- **Completed** — stock decreases; COGS + profit calculated
- **Cancelled** — stock restored; cost layers restored

### Typical flow
1. Create sale → company + products + qty + selling price
2. Save draft (optional)
3. **Complete** sale
4. App checks stock — **overselling is blocked**
5. Detail screen shows revenue, COGS, and profit

### How profit is calculated (simple explanation)

When you sell, the system uses **FIFO** (First In, First Out):

> Oldest stock cost is used first.

Example:

1. You bought 10 units at cost 100
2. Later bought 10 units at cost 120
3. You sell 12 units

Cost used:

- 10 × 100
- 2 × 120

Then:

- Revenue = qty × selling price  
- COGS = cost of the layers used  
- Profit = Revenue − COGS  

These values are stored by the database (not recalculated loosely in the UI).

---

## 7. Stock (inventory)

### Current stock formula

```text
Current stock = Opening stock + all stock movements
```

Movements come from:

- Completed purchases (stock in)
- Completed sales (stock out)
- Purchase/sale cancellations (reverse)
- Admin stock adjustments

### What you can see
- Current quantity per product
- Low-stock warnings (based on reorder level)
- Movement history for a product

### Stock adjustment (admin only)
- Manually increase or decrease stock
- Useful for damage, count correction, found stock, etc.
- Stock out cannot go below zero

---

## 8. Market (live exchange rates)

Shows live currency rates (for example USD → PKR, EUR, GBP, AED).

### What you can do
- View current rates
- See last updated time and data source
- Refresh manually
- View simple history / trend for a selected pair

### Important security point
- API keys are **not** stored in the Flutter app
- The app calls a secure server function (Supabase Edge Function), which talks to the external market API

Admin can enable/disable market data and set base/quote currencies in Settings.

---

## 9. Reports

Reports give deeper analysis than the dashboard.

### Report types
1. **Sales report** — invoices, revenue, COGS, profit  
2. **Purchases report** — completed purchases  
3. **Profit report** — revenue / COGS / gross profit  
4. **Stock report** — balances, low stock, movements  
5. **Product report** — qty sold and profit by product  
6. **Company report** — sales, purchases, profit by company  

### Filters
- Date range
- Company
- Status / search (where available)

Cancelled transactions are excluded from financial totals.

---

## 10. Export (PDF / Excel / Print)

On each report screen you can:

- **Export PDF**
- **Export Excel**
- **Print / Share**

Exports use the **same filters** you currently see on screen.

- Labels (like “Total Profit”) follow your selected language  
- Company/product names stay as entered in the database  

---

## 11. Settings

### For every user
- View profile (email, role)
- Edit display name
- Change password / reset password
- View roles & permissions
- Change **Language**

### Language
- English
- 繁體中文 (Traditional Chinese)

Language is saved **on this device only** (not in the cloud).  
Change it anytime — no logout needed. It stays after app restart.

### For admins
- Business profile (name used on exports)
- Preferences (currency / date / number formats)
- Market settings
- Administration (users overview)

---

## 12. Administration (admins only)

Admins can:

- See system overview (user/company/product counts)
- Manage users (name, role, active/disabled)
- Disable a user so they cannot sign in / use data

Roles in simple terms:

- **Admin** — full control (users, settings, stock adjustments, deletes)
- **User** — day-to-day work (companies, products, purchases, sales, reports, market view)

---

## How the big pieces connect (story)

1. Create a **Company**
2. Add **Products** for that company (with opening stock + cost)
3. Make a **Purchase** and complete it → stock increases
4. Make a **Sale** and complete it → stock decreases, profit appears
5. Check **Stock** to confirm balances
6. Open **Dashboard** / **Reports** to review performance
7. Export a report if needed
8. Use **Market** if you need exchange rates
9. Use **Settings** for language and business profile

---

## Draft vs Completed (very important)

| Type | Draft | Completed | Cancelled |
|------|-------|-----------|-----------|
| Purchase | No stock change | Stock up | Stock reverse (if allowed) |
| Sale | No stock change | Stock down + profit | Stock + cost restored |

Always remember:

> Only **completed** documents affect stock and financial totals.

---

## Mobile vs desktop

- **Mobile:** cards, stacked layout, drawer menu  
- **Desktop:** sidebar navigation, wider tables/dashboard  

Same features on both — layout adapts.

---

## What this app does *not* do (yet)

- Full accounting (balance sheet, tax modules, etc.)
- Full trading / market trading platform
- Multi-company tenant isolation for separate businesses in one cloud project (current design is shared internal use)

Those can come in later phases if needed.

---

## Quick FAQ

**Q: Why didn’t stock change after I saved a purchase?**  
A: It is probably still a **draft**. Complete it.

**Q: Why can’t I complete a sale?**  
A: Not enough stock, or validation failed (check quantity / product).

**Q: Why can’t I cancel a purchase?**  
A: Some of that purchased stock was already sold.

**Q: Where is profit calculated?**  
A: In the database using FIFO cost layers when a sale is completed.

**Q: Where is language saved?**  
A: On your device only (local storage).

**Q: Are market API keys in the phone/app?**  
A: No. They stay on the server.

---

## Related docs

- Technical project notes: [PROJECT.md](PROJECT.md)
- Step-by-step manual tests: [TESTING.md](TESTING.md)
- Phase command logs: [commands/](commands/)

---

*Last updated for Phase 14 (Localization).*
