-- Phase 13: Security hardening (no business-logic changes).
-- - RPC-only writes for purchases/sales (+ items)
-- - Active-user gate for RLS + client RPCs
-- - Harden market_data grants + product_current_stock auth

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create or replace function public.is_active_user()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select p.is_active from public.profiles p where p.id = auth.uid()),
    false
  );
$$;

revoke all on function public.is_active_user() from public;
grant execute on function public.is_active_user() to authenticated;

create or replace function public.require_active_user()
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_active boolean;
begin
  if v_uid is null then
    raise exception 'You must be signed in.';
  end if;

  select p.is_active into v_active
  from public.profiles p
  where p.id = v_uid;

  if coalesce(v_active, false) is not true then
    raise exception 'Account is disabled.';
  end if;

  return v_uid;
end;
$$;

revoke all on function public.require_active_user() from public;
grant execute on function public.require_active_user() to authenticated;

-- ---------------------------------------------------------------------------
-- Purchases / sales: revoke client writes (RPCs remain SECURITY DEFINER)
-- ---------------------------------------------------------------------------

revoke insert, update, delete on table public.purchases from authenticated, anon;
revoke insert, update, delete on table public.purchase_items from authenticated, anon;
revoke insert, update, delete on table public.sales from authenticated, anon;
revoke insert, update, delete on table public.sale_items from authenticated, anon;

grant select on table public.purchases to authenticated;
grant select on table public.purchase_items to authenticated;
grant select on table public.sales to authenticated;
grant select on table public.sale_items to authenticated;

drop policy if exists "purchases_insert_authenticated" on public.purchases;
drop policy if exists "purchases_update_authenticated" on public.purchases;
drop policy if exists "purchases_delete_draft_admin" on public.purchases;
drop policy if exists "purchase_items_insert_authenticated" on public.purchase_items;
drop policy if exists "purchase_items_update_authenticated" on public.purchase_items;
drop policy if exists "purchase_items_delete_authenticated" on public.purchase_items;

drop policy if exists "sales_insert_authenticated" on public.sales;
drop policy if exists "sales_update_authenticated" on public.sales;
drop policy if exists "sales_delete_draft_admin" on public.sales;
drop policy if exists "sale_items_insert_authenticated" on public.sale_items;
drop policy if exists "sale_items_update_authenticated" on public.sale_items;
drop policy if exists "sale_items_delete_authenticated" on public.sale_items;

-- ---------------------------------------------------------------------------
-- market_data: match stock/FIFO grant pattern
-- ---------------------------------------------------------------------------

revoke all on table public.market_data from anon;
revoke insert, update, delete on table public.market_data from authenticated, anon;
grant select on table public.market_data to authenticated;

-- ---------------------------------------------------------------------------
-- Restrictive RLS: disabled users cannot read/write via PostgREST
-- ---------------------------------------------------------------------------

-- profiles: allow reading own row so Flutter can detect is_active=false and sign out.
drop policy if exists "active_user_only" on public.profiles;
create policy "active_user_only" on public.profiles
  as restrictive
  for all
  to authenticated
  using (public.is_active_user() or id = auth.uid())
  with check (public.is_active_user() or id = auth.uid());

drop policy if exists "active_user_only" on public.companies;
create policy "active_user_only" on public.companies
  as restrictive
  for all
  to authenticated
  using (public.is_active_user())
  with check (public.is_active_user());

drop policy if exists "active_user_only" on public.products;
create policy "active_user_only" on public.products
  as restrictive
  for all
  to authenticated
  using (public.is_active_user())
  with check (public.is_active_user());

drop policy if exists "active_user_only" on public.purchases;
create policy "active_user_only" on public.purchases
  as restrictive
  for all
  to authenticated
  using (public.is_active_user())
  with check (public.is_active_user());

drop policy if exists "active_user_only" on public.purchase_items;
create policy "active_user_only" on public.purchase_items
  as restrictive
  for all
  to authenticated
  using (public.is_active_user())
  with check (public.is_active_user());

drop policy if exists "active_user_only" on public.sales;
create policy "active_user_only" on public.sales
  as restrictive
  for all
  to authenticated
  using (public.is_active_user())
  with check (public.is_active_user());

drop policy if exists "active_user_only" on public.sale_items;
create policy "active_user_only" on public.sale_items
  as restrictive
  for all
  to authenticated
  using (public.is_active_user())
  with check (public.is_active_user());

drop policy if exists "active_user_only" on public.stock_movements;
create policy "active_user_only" on public.stock_movements
  as restrictive
  for all
  to authenticated
  using (public.is_active_user())
  with check (public.is_active_user());

drop policy if exists "active_user_only" on public.inventory_cost_layers;
create policy "active_user_only" on public.inventory_cost_layers
  as restrictive
  for all
  to authenticated
  using (public.is_active_user())
  with check (public.is_active_user());

drop policy if exists "active_user_only" on public.sale_cost_allocations;
create policy "active_user_only" on public.sale_cost_allocations
  as restrictive
  for all
  to authenticated
  using (public.is_active_user())
  with check (public.is_active_user());

drop policy if exists "active_user_only" on public.app_settings;
create policy "active_user_only" on public.app_settings
  as restrictive
  for all
  to authenticated
  using (public.is_active_user())
  with check (public.is_active_user());

drop policy if exists "active_user_only" on public.market_data;
create policy "active_user_only" on public.market_data
  as restrictive
  for all
  to authenticated
  using (public.is_active_user())
  with check (public.is_active_user());

-- ---------------------------------------------------------------------------
-- Patch client RPCs: auth.uid() → require_active_user()
-- ---------------------------------------------------------------------------

do $migrate$
declare
  r record;
  def text;
  new_def text;
begin
  for r in
    select p.oid, p.proname
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'create_purchase_with_items',
        'update_draft_purchase_with_items',
        'cancel_purchase',
        'create_sale_with_items',
        'update_draft_sale_with_items',
        'cancel_sale',
        'create_stock_adjustment',
        'get_dashboard_data',
        'get_sales_report',
        'get_purchases_report',
        'get_profit_report',
        'get_product_report',
        'get_company_report',
        'get_admin_overview'
      )
  loop
    def := pg_get_functiondef(r.oid);
    new_def := replace(
      def,
      'v_user_id uuid := auth.uid();',
      'v_user_id uuid := public.require_active_user();'
    );
    if new_def is distinct from def then
      execute new_def;
    end if;
  end loop;
end;
$migrate$;

-- product_current_stock: require signed-in active user (takes FOR UPDATE locks)
create or replace function public.product_current_stock(p_product_id uuid)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v_opening numeric(14, 3);
  v_movements numeric(14, 3);
begin
  perform public.require_active_user();

  select opening_stock
  into v_opening
  from public.products
  where id = p_product_id
  for update;

  if v_opening is null then
    raise exception 'Product not found.';
  end if;

  select coalesce(sum(quantity), 0)
  into v_movements
  from public.stock_movements
  where product_id = p_product_id;

  return v_opening + v_movements;
end;
$$;

revoke all on function public.product_current_stock(uuid) from public;
grant execute on function public.product_current_stock(uuid) to authenticated;

-- Helpful indexes for common list/report filters (safe, no logic change)
create index if not exists purchases_status_date_idx
  on public.purchases (status, purchase_date desc);
create index if not exists sales_status_date_idx
  on public.sales (status, sale_date desc);
create index if not exists products_company_active_idx
  on public.products (company_id, is_active);
