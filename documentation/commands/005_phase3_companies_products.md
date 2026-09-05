# 005 — Phase 3 companies and products

Date: 2026-09-04

## User command

Implement Phase 3 only: Company Management and Product Management on the existing Phase 1/2 foundation. Use the linked Supabase CLI. Do not start purchases, sales, inventory, profit, reports, or market API.

## Database

Migration: `supabase/migrations/20260904180935_companies_products.sql`

Tables:

- `companies`
- `products` with `company_id → companies.id`

CLI:

- `supabase migration new companies_products`
- `supabase db push --dry-run`
- `supabase db push --yes`

## App

- Company list/form/detail with search, status filter, activate/deactivate, admin delete
- Product list/form/detail with search, company/category/status filters
- Opening stock stored as a simple foundation field only
- Desktop row layout + mobile cards
- Routes wired under AuthGate

## Packages added

None.
