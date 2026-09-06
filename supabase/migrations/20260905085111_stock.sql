-- Phase 6: Inventory / stock movements. No FIFO, COGS, or profit.

-- ---------------------------------------------------------------------------
-- Products: reorder level + lock opening_stock after movements exist
-- ---------------------------------------------------------------------------

alter table public.products
  add column if not exists reorder_level numeric(14, 3) not null default 0;

alter table public.products
  drop constraint if exists products_reorder_level_non_negative;

alter table public.products
  add constraint products_reorder_level_non_negative check (reorder_level >= 0);

-- ---------------------------------------------------------------------------
-- stock_movements
-- ---------------------------------------------------------------------------

create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete restrict,
  movement_type text not null
    check (movement_type in (
      'purchase',
      'sale',
      'purchase_reversal',
      'sale_reversal',
      'adjustment_in',
      'adjustment_out'
    )),
  quantity numeric(14, 3) not null,
  unit_cost numeric(14, 2),
  reference_type text,
  reference_id uuid,
  reference_item_id uuid,
  reason text,
  notes text,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  constraint stock_movements_quantity_nonzero check (quantity <> 0),
  constraint stock_movements_unit_cost_non_negative
    check (unit_cost is null or unit_cost >= 0),
  constraint stock_movements_signed_quantity check (
    (movement_type in ('purchase', 'sale_reversal', 'adjustment_in') and quantity > 0)
    or (movement_type in ('sale', 'purchase_reversal', 'adjustment_out') and quantity < 0)
  )
);

create index if not exists stock_movements_product_id_idx
  on public.stock_movements (product_id);
create index if not exists stock_movements_created_at_idx
  on public.stock_movements (created_at desc);
create index if not exists stock_movements_reference_idx
  on public.stock_movements (reference_type, reference_id);

-- One movement per item + type (prevents duplicate apply)
create unique index if not exists stock_movements_ref_item_type_uidx
  on public.stock_movements (reference_type, reference_item_id, movement_type)
  where reference_item_id is not null;

create or replace function public.prevent_opening_stock_change_with_movements()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.opening_stock is distinct from old.opening_stock
     and exists (
       select 1 from public.stock_movements sm where sm.product_id = old.id
     ) then
    raise exception 'Opening stock cannot be changed after stock movements exist.';
  end if;
  return new;
end;
$$;

drop trigger if exists products_prevent_opening_stock_change on public.products;
create trigger products_prevent_opening_stock_change
  before update on public.products
  for each row
  execute function public.prevent_opening_stock_change_with_movements();

-- ---------------------------------------------------------------------------
-- Balance view
-- ---------------------------------------------------------------------------

create or replace view public.product_stock_balances
with (security_invoker = true)
as
select
  p.id as product_id,
  p.company_id,
  c.name as company_name,
  p.name as product_name,
  p.sku,
  p.category,
  p.unit,
  p.is_active,
  p.opening_stock,
  p.reorder_level,
  coalesce(m.movement_qty, 0) as movement_qty,
  (p.opening_stock + coalesce(m.movement_qty, 0)) as current_stock,
  case
    when (p.opening_stock + coalesce(m.movement_qty, 0)) <= p.reorder_level
    then true
    else false
  end as is_low_stock
from public.products p
left join public.companies c on c.id = p.company_id
left join (
  select product_id, sum(quantity) as movement_qty
  from public.stock_movements
  group by product_id
) m on m.product_id = p.id;

grant select on public.product_stock_balances to authenticated;

-- ---------------------------------------------------------------------------
-- RLS: clients may read; writes only via security definer functions
-- ---------------------------------------------------------------------------

alter table public.stock_movements enable row level security;

create policy "stock_movements_select_authenticated"
  on public.stock_movements for select to authenticated
  using (true);

revoke insert, update, delete on table public.stock_movements from authenticated;
revoke insert, update, delete on table public.stock_movements from anon;
grant select on table public.stock_movements to authenticated;

-- ---------------------------------------------------------------------------
-- Stock helpers
-- ---------------------------------------------------------------------------

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

create or replace function public.apply_purchase_stock(p_purchase_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
  v_user_id uuid := auth.uid();
  item record;
begin
  select status into v_status
  from public.purchases
  where id = p_purchase_id
  for update;

  if v_status is null then
    raise exception 'Purchase not found.';
  end if;
  if v_status <> 'completed' then
    return;
  end if;

  for item in
    select id, product_id, quantity, unit_cost
    from public.purchase_items
    where purchase_id = p_purchase_id
    order by product_id
  loop
    perform public.product_current_stock(item.product_id);

    insert into public.stock_movements (
      product_id,
      movement_type,
      quantity,
      unit_cost,
      reference_type,
      reference_id,
      reference_item_id,
      reason,
      created_by
    )
    values (
      item.product_id,
      'purchase',
      item.quantity,
      item.unit_cost,
      'purchase',
      p_purchase_id,
      item.id,
      'Purchase completed',
      v_user_id
    )
    on conflict (reference_type, reference_item_id, movement_type)
      where (reference_item_id is not null)
    do nothing;
  end loop;
end;
$$;

create or replace function public.reverse_purchase_stock(p_purchase_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  item record;
  v_balance numeric;
begin
  for item in
    select
      pi.id as item_id,
      pi.product_id,
      pi.quantity,
      pi.unit_cost,
      sm.id as movement_id
    from public.purchase_items pi
    join public.stock_movements sm
      on sm.reference_type = 'purchase'
     and sm.reference_item_id = pi.id
     and sm.movement_type = 'purchase'
    where pi.purchase_id = p_purchase_id
    order by pi.product_id
  loop
    if exists (
      select 1
      from public.stock_movements sm
      where sm.reference_type = 'purchase'
        and sm.reference_item_id = item.item_id
        and sm.movement_type = 'purchase_reversal'
    ) then
      continue;
    end if;

    v_balance := public.product_current_stock(item.product_id);
    if v_balance - item.quantity < 0 then
      raise exception
        'Cannot reverse purchase: insufficient stock for one or more products.';
    end if;

    insert into public.stock_movements (
      product_id,
      movement_type,
      quantity,
      unit_cost,
      reference_type,
      reference_id,
      reference_item_id,
      reason,
      created_by
    )
    values (
      item.product_id,
      'purchase_reversal',
      -item.quantity,
      item.unit_cost,
      'purchase',
      p_purchase_id,
      item.item_id,
      'Purchase cancelled',
      v_user_id
    );
  end loop;
end;
$$;

create or replace function public.apply_sale_stock(p_sale_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
  v_user_id uuid := auth.uid();
  item record;
  v_balance numeric;
  v_product_name text;
begin
  select status into v_status
  from public.sales
  where id = p_sale_id
  for update;

  if v_status is null then
    raise exception 'Sale not found.';
  end if;
  if v_status <> 'completed' then
    return;
  end if;

  for item in
    select si.id, si.product_id, si.quantity, p.name as product_name
    from public.sale_items si
    join public.products p on p.id = si.product_id
    where si.sale_id = p_sale_id
    order by si.product_id
  loop
    v_balance := public.product_current_stock(item.product_id);
    if v_balance < item.quantity then
      raise exception
        'Insufficient stock for "%". Available: %, required: %.',
        item.product_name,
        v_balance,
        item.quantity;
    end if;

    insert into public.stock_movements (
      product_id,
      movement_type,
      quantity,
      unit_cost,
      reference_type,
      reference_id,
      reference_item_id,
      reason,
      created_by
    )
    values (
      item.product_id,
      'sale',
      -item.quantity,
      null,
      'sale',
      p_sale_id,
      item.id,
      'Sale completed',
      v_user_id
    )
    on conflict (reference_type, reference_item_id, movement_type)
      where (reference_item_id is not null)
    do nothing;
  end loop;
end;
$$;

create or replace function public.reverse_sale_stock(p_sale_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  item record;
begin
  for item in
    select
      si.id as item_id,
      si.product_id,
      si.quantity
    from public.sale_items si
    join public.stock_movements sm
      on sm.reference_type = 'sale'
     and sm.reference_item_id = si.id
     and sm.movement_type = 'sale'
    where si.sale_id = p_sale_id
    order by si.product_id
  loop
    if exists (
      select 1
      from public.stock_movements sm
      where sm.reference_type = 'sale'
        and sm.reference_item_id = item.item_id
        and sm.movement_type = 'sale_reversal'
    ) then
      continue;
    end if;

    perform public.product_current_stock(item.product_id);

    insert into public.stock_movements (
      product_id,
      movement_type,
      quantity,
      unit_cost,
      reference_type,
      reference_id,
      reference_item_id,
      reason,
      created_by
    )
    values (
      item.product_id,
      'sale_reversal',
      item.quantity,
      null,
      'sale',
      p_sale_id,
      item.item_id,
      'Sale cancelled',
      v_user_id
    );
  end loop;
end;
$$;

-- Safety net when status is changed after items exist
create or replace function public.purchases_stock_status_trigger()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE'
     and new.status = 'completed'
     and old.status is distinct from 'completed' then
    perform public.apply_purchase_stock(new.id);
  elsif tg_op = 'UPDATE'
     and new.status = 'cancelled'
     and old.status = 'completed' then
    perform public.reverse_purchase_stock(new.id);
  end if;
  return new;
end;
$$;

create or replace function public.sales_stock_status_trigger()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE'
     and new.status = 'completed'
     and old.status is distinct from 'completed' then
    perform public.apply_sale_stock(new.id);
  elsif tg_op = 'UPDATE'
     and new.status = 'cancelled'
     and old.status = 'completed' then
    perform public.reverse_sale_stock(new.id);
  end if;
  return new;
end;
$$;

drop trigger if exists purchases_stock_on_status on public.purchases;
create trigger purchases_stock_on_status
  after update of status on public.purchases
  for each row
  execute function public.purchases_stock_status_trigger();

drop trigger if exists sales_stock_on_status on public.sales;
create trigger sales_stock_on_status
  after update of status on public.sales
  for each row
  execute function public.sales_stock_status_trigger();

-- ---------------------------------------------------------------------------
-- Rewrite purchase/sale RPCs: finalize items before status=completed
-- ---------------------------------------------------------------------------

create or replace function public.create_purchase_with_items(
  p_company_id uuid,
  p_purchase_date date,
  p_invoice_number text default null,
  p_reference_number text default null,
  p_notes text default null,
  p_discount numeric default 0,
  p_other_charges numeric default 0,
  p_status text default 'draft',
  p_items jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_purchase_id uuid;
  v_subtotal numeric(14, 2) := 0;
  v_discount numeric(14, 2) := coalesce(p_discount, 0);
  v_other_charges numeric(14, 2) := coalesce(p_other_charges, 0);
  v_total numeric(14, 2);
  v_status text := coalesce(nullif(trim(p_status), ''), 'draft');
  built_item record;
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;
  if p_company_id is null then
    raise exception 'Company is required.';
  end if;
  if not exists (select 1 from public.companies c where c.id = p_company_id) then
    raise exception 'Company not found.';
  end if;
  if p_purchase_date is null then
    raise exception 'Purchase date is required.';
  end if;
  if v_status not in ('draft', 'completed') then
    raise exception 'New purchases must be draft or completed.';
  end if;
  if v_discount < 0 then
    raise exception 'Discount cannot be negative.';
  end if;
  if v_other_charges < 0 then
    raise exception 'Other charges cannot be negative.';
  end if;

  for built_item in
    select * from public._validate_and_build_purchase_items(p_items)
  loop
    v_subtotal := v_subtotal + built_item.line_total;
  end loop;

  v_total := round(v_subtotal - v_discount + v_other_charges, 2);
  if v_total < 0 then
    raise exception 'Total amount cannot be negative.';
  end if;

  -- Always insert as draft first so items exist before completion/stock.
  insert into public.purchases (
    company_id,
    purchase_date,
    invoice_number,
    reference_number,
    notes,
    subtotal,
    discount,
    other_charges,
    total_amount,
    status,
    created_by
  )
  values (
    p_company_id,
    p_purchase_date,
    nullif(trim(p_invoice_number), ''),
    nullif(trim(p_reference_number), ''),
    nullif(trim(p_notes), ''),
    v_subtotal,
    v_discount,
    v_other_charges,
    v_total,
    'draft',
    v_user_id
  )
  returning id into v_purchase_id;

  insert into public.purchase_items (
    purchase_id,
    product_id,
    quantity,
    unit_cost,
    line_total
  )
  select
    v_purchase_id,
    built.product_id,
    built.quantity,
    built.unit_cost,
    built.line_total
  from public._validate_and_build_purchase_items(p_items) as built;

  if v_status = 'completed' then
    update public.purchases
    set status = 'completed'
    where id = v_purchase_id;
  end if;

  return v_purchase_id;
end;
$$;

create or replace function public.update_draft_purchase_with_items(
  p_purchase_id uuid,
  p_company_id uuid,
  p_purchase_date date,
  p_invoice_number text default null,
  p_reference_number text default null,
  p_notes text default null,
  p_discount numeric default 0,
  p_other_charges numeric default 0,
  p_status text default 'draft',
  p_items jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_current_status text;
  v_subtotal numeric(14, 2) := 0;
  v_discount numeric(14, 2) := coalesce(p_discount, 0);
  v_other_charges numeric(14, 2) := coalesce(p_other_charges, 0);
  v_total numeric(14, 2);
  v_status text := coalesce(nullif(trim(p_status), ''), 'draft');
  built_item record;
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;

  select status into v_current_status
  from public.purchases
  where id = p_purchase_id
  for update;

  if v_current_status is null then
    raise exception 'Purchase not found.';
  end if;
  if v_current_status <> 'draft' then
    raise exception 'Only draft purchases can be edited.';
  end if;
  if p_company_id is null then
    raise exception 'Company is required.';
  end if;
  if not exists (select 1 from public.companies c where c.id = p_company_id) then
    raise exception 'Company not found.';
  end if;
  if p_purchase_date is null then
    raise exception 'Purchase date is required.';
  end if;
  if v_status not in ('draft', 'completed') then
    raise exception 'Draft purchases can only be saved as draft or completed.';
  end if;
  if v_discount < 0 then
    raise exception 'Discount cannot be negative.';
  end if;
  if v_other_charges < 0 then
    raise exception 'Other charges cannot be negative.';
  end if;

  for built_item in
    select * from public._validate_and_build_purchase_items(p_items)
  loop
    v_subtotal := v_subtotal + built_item.line_total;
  end loop;

  v_total := round(v_subtotal - v_discount + v_other_charges, 2);
  if v_total < 0 then
    raise exception 'Total amount cannot be negative.';
  end if;

  -- Keep status draft while replacing items, then complete.
  update public.purchases
  set
    company_id = p_company_id,
    purchase_date = p_purchase_date,
    invoice_number = nullif(trim(p_invoice_number), ''),
    reference_number = nullif(trim(p_reference_number), ''),
    notes = nullif(trim(p_notes), ''),
    subtotal = v_subtotal,
    discount = v_discount,
    other_charges = v_other_charges,
    total_amount = v_total,
    status = 'draft'
  where id = p_purchase_id;

  delete from public.purchase_items where purchase_id = p_purchase_id;

  insert into public.purchase_items (
    purchase_id,
    product_id,
    quantity,
    unit_cost,
    line_total
  )
  select
    p_purchase_id,
    built.product_id,
    built.quantity,
    built.unit_cost,
    built.line_total
  from public._validate_and_build_purchase_items(p_items) as built;

  if v_status = 'completed' then
    update public.purchases
    set status = 'completed'
    where id = p_purchase_id;
  end if;

  return p_purchase_id;
end;
$$;

create or replace function public.cancel_purchase(p_purchase_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_status text;
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;

  select status into v_status
  from public.purchases
  where id = p_purchase_id
  for update;

  if v_status is null then
    raise exception 'Purchase not found.';
  end if;
  if v_status = 'cancelled' then
    raise exception 'Purchase is already cancelled.';
  end if;

  update public.purchases
  set status = 'cancelled'
  where id = p_purchase_id;

  return p_purchase_id;
end;
$$;

create or replace function public.create_sale_with_items(
  p_company_id uuid,
  p_sale_date date,
  p_invoice_number text default null,
  p_reference_number text default null,
  p_notes text default null,
  p_discount numeric default 0,
  p_other_charges numeric default 0,
  p_status text default 'draft',
  p_items jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_sale_id uuid;
  v_subtotal numeric(14, 2) := 0;
  v_discount numeric(14, 2) := coalesce(p_discount, 0);
  v_other_charges numeric(14, 2) := coalesce(p_other_charges, 0);
  v_total numeric(14, 2);
  v_status text := coalesce(nullif(trim(p_status), ''), 'draft');
  built_item record;
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;
  if p_company_id is null then
    raise exception 'Company is required.';
  end if;
  if not exists (select 1 from public.companies c where c.id = p_company_id) then
    raise exception 'Company not found.';
  end if;
  if p_sale_date is null then
    raise exception 'Sale date is required.';
  end if;
  if v_status not in ('draft', 'completed') then
    raise exception 'New sales must be draft or completed.';
  end if;
  if v_discount < 0 then
    raise exception 'Discount cannot be negative.';
  end if;
  if v_other_charges < 0 then
    raise exception 'Other charges cannot be negative.';
  end if;

  for built_item in
    select * from public._validate_and_build_sale_items(p_items)
  loop
    v_subtotal := v_subtotal + built_item.line_total;
  end loop;

  v_total := round(v_subtotal - v_discount + v_other_charges, 2);
  if v_total < 0 then
    raise exception 'Total amount cannot be negative.';
  end if;

  insert into public.sales (
    company_id,
    sale_date,
    invoice_number,
    reference_number,
    notes,
    subtotal,
    discount,
    other_charges,
    total_amount,
    status,
    created_by
  )
  values (
    p_company_id,
    p_sale_date,
    nullif(trim(p_invoice_number), ''),
    nullif(trim(p_reference_number), ''),
    nullif(trim(p_notes), ''),
    v_subtotal,
    v_discount,
    v_other_charges,
    v_total,
    'draft',
    v_user_id
  )
  returning id into v_sale_id;

  insert into public.sale_items (
    sale_id,
    product_id,
    quantity,
    unit_price,
    line_total
  )
  select
    v_sale_id,
    built.product_id,
    built.quantity,
    built.unit_price,
    built.line_total
  from public._validate_and_build_sale_items(p_items) as built;

  if v_status = 'completed' then
    update public.sales
    set status = 'completed'
    where id = v_sale_id;
  end if;

  return v_sale_id;
end;
$$;

create or replace function public.update_draft_sale_with_items(
  p_sale_id uuid,
  p_company_id uuid,
  p_sale_date date,
  p_invoice_number text default null,
  p_reference_number text default null,
  p_notes text default null,
  p_discount numeric default 0,
  p_other_charges numeric default 0,
  p_status text default 'draft',
  p_items jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_current_status text;
  v_subtotal numeric(14, 2) := 0;
  v_discount numeric(14, 2) := coalesce(p_discount, 0);
  v_other_charges numeric(14, 2) := coalesce(p_other_charges, 0);
  v_total numeric(14, 2);
  v_status text := coalesce(nullif(trim(p_status), ''), 'draft');
  built_item record;
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;

  select status into v_current_status
  from public.sales
  where id = p_sale_id
  for update;

  if v_current_status is null then
    raise exception 'Sale not found.';
  end if;
  if v_current_status <> 'draft' then
    raise exception 'Only draft sales can be edited.';
  end if;
  if p_company_id is null then
    raise exception 'Company is required.';
  end if;
  if not exists (select 1 from public.companies c where c.id = p_company_id) then
    raise exception 'Company not found.';
  end if;
  if p_sale_date is null then
    raise exception 'Sale date is required.';
  end if;
  if v_status not in ('draft', 'completed') then
    raise exception 'Draft sales can only be saved as draft or completed.';
  end if;
  if v_discount < 0 then
    raise exception 'Discount cannot be negative.';
  end if;
  if v_other_charges < 0 then
    raise exception 'Other charges cannot be negative.';
  end if;

  for built_item in
    select * from public._validate_and_build_sale_items(p_items)
  loop
    v_subtotal := v_subtotal + built_item.line_total;
  end loop;

  v_total := round(v_subtotal - v_discount + v_other_charges, 2);
  if v_total < 0 then
    raise exception 'Total amount cannot be negative.';
  end if;

  update public.sales
  set
    company_id = p_company_id,
    sale_date = p_sale_date,
    invoice_number = nullif(trim(p_invoice_number), ''),
    reference_number = nullif(trim(p_reference_number), ''),
    notes = nullif(trim(p_notes), ''),
    subtotal = v_subtotal,
    discount = v_discount,
    other_charges = v_other_charges,
    total_amount = v_total,
    status = 'draft'
  where id = p_sale_id;

  delete from public.sale_items where sale_id = p_sale_id;

  insert into public.sale_items (
    sale_id,
    product_id,
    quantity,
    unit_price,
    line_total
  )
  select
    p_sale_id,
    built.product_id,
    built.quantity,
    built.unit_price,
    built.line_total
  from public._validate_and_build_sale_items(p_items) as built;

  if v_status = 'completed' then
    update public.sales
    set status = 'completed'
    where id = p_sale_id;
  end if;

  return p_sale_id;
end;
$$;

create or replace function public.cancel_sale(p_sale_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_status text;
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;

  select status into v_status
  from public.sales
  where id = p_sale_id
  for update;

  if v_status is null then
    raise exception 'Sale not found.';
  end if;
  if v_status = 'cancelled' then
    raise exception 'Sale is already cancelled.';
  end if;

  update public.sales
  set status = 'cancelled'
  where id = p_sale_id;

  return p_sale_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Admin stock adjustment
-- ---------------------------------------------------------------------------

create or replace function public.create_stock_adjustment(
  p_product_id uuid,
  p_direction text,
  p_quantity numeric,
  p_unit_cost numeric default null,
  p_reason text default null,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_qty numeric(14, 3);
  v_type text;
  v_balance numeric;
  v_id uuid;
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;
  if coalesce(public.current_user_role(), '') <> 'admin' then
    raise exception 'Only admins can adjust stock.';
  end if;
  if p_product_id is null then
    raise exception 'Product is required.';
  end if;
  if not exists (select 1 from public.products p where p.id = p_product_id) then
    raise exception 'Product not found.';
  end if;
  if p_quantity is null or p_quantity <= 0 then
    raise exception 'Quantity must be greater than zero.';
  end if;
  if p_unit_cost is not null and p_unit_cost < 0 then
    raise exception 'Unit cost cannot be negative.';
  end if;

  if lower(trim(p_direction)) in ('in', 'stock_in', 'adjustment_in') then
    v_type := 'adjustment_in';
    v_qty := p_quantity;
  elsif lower(trim(p_direction)) in ('out', 'stock_out', 'adjustment_out') then
    v_type := 'adjustment_out';
    v_qty := -p_quantity;
  else
    raise exception 'Direction must be stock in or stock out.';
  end if;

  v_balance := public.product_current_stock(p_product_id);
  if v_type = 'adjustment_out' and v_balance - p_quantity < 0 then
    raise exception
      'Insufficient stock for adjustment. Available: %, requested: %.',
      v_balance,
      p_quantity;
  end if;

  insert into public.stock_movements (
    product_id,
    movement_type,
    quantity,
    unit_cost,
    reference_type,
    reason,
    notes,
    created_by
  )
  values (
    p_product_id,
    v_type,
    v_qty,
    case when v_type = 'adjustment_in' then p_unit_cost else null end,
    'adjustment',
    nullif(trim(p_reason), ''),
    nullif(trim(p_notes), ''),
    v_user_id
  )
  returning id into v_id;

  update public.stock_movements
  set reference_id = v_id
  where id = v_id;

  return v_id;
end;
$$;

revoke all on function public.product_current_stock(uuid) from public;
revoke all on function public.apply_purchase_stock(uuid) from public;
revoke all on function public.reverse_purchase_stock(uuid) from public;
revoke all on function public.apply_sale_stock(uuid) from public;
revoke all on function public.reverse_sale_stock(uuid) from public;
revoke all on function public.create_stock_adjustment(uuid, text, numeric, numeric, text, text) from public;

grant execute on function public.product_current_stock(uuid) to authenticated;
grant execute on function public.create_stock_adjustment(uuid, text, numeric, numeric, text, text) to authenticated;
grant execute on function public.create_purchase_with_items(uuid, date, text, text, text, numeric, numeric, text, jsonb) to authenticated;
grant execute on function public.update_draft_purchase_with_items(uuid, uuid, date, text, text, text, numeric, numeric, text, jsonb) to authenticated;
grant execute on function public.cancel_purchase(uuid) to authenticated;
grant execute on function public.create_sale_with_items(uuid, date, text, text, text, numeric, numeric, text, jsonb) to authenticated;
grant execute on function public.update_draft_sale_with_items(uuid, uuid, date, text, text, text, numeric, numeric, text, jsonb) to authenticated;
grant execute on function public.cancel_sale(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Backfill completed purchases/sales (idempotent). Cancelled skipped (net 0).
-- ---------------------------------------------------------------------------

do $$
declare
  r record;
  v_neg record;
begin
  for r in
    select id from public.purchases where status = 'completed'
  loop
    perform public.apply_purchase_stock(r.id);
  end loop;

  for r in
    select id from public.sales where status = 'completed'
  loop
    perform public.apply_sale_stock(r.id);
  end loop;

  select
    p.id,
    p.name,
    (p.opening_stock + coalesce(sum(sm.quantity), 0)) as current_stock
  into v_neg
  from public.products p
  left join public.stock_movements sm on sm.product_id = p.id
  group by p.id, p.name, p.opening_stock
  having (p.opening_stock + coalesce(sum(sm.quantity), 0)) < 0
  limit 1;

  if v_neg.id is not null then
    raise exception
      'Backfill would create negative stock for product "%" (id %, balance %). Aborting.',
      v_neg.name,
      v_neg.id,
      v_neg.current_stock;
  end if;
end;
$$;
