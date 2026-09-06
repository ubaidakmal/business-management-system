-- Phase 7: FIFO cost layers, COGS, and profit. Stock ledger unchanged.

-- ---------------------------------------------------------------------------
-- Opening unit cost for FIFO baseline
-- ---------------------------------------------------------------------------

alter table public.products
  add column if not exists opening_unit_cost numeric(14, 2) not null default 0;

alter table public.products
  drop constraint if exists products_opening_unit_cost_non_negative;

alter table public.products
  add constraint products_opening_unit_cost_non_negative
  check (opening_unit_cost >= 0);

-- Seed from purchase_price where still default zero and opening stock exists
update public.products
set opening_unit_cost = purchase_price
where opening_unit_cost = 0
  and opening_stock > 0
  and purchase_price >= 0;

create or replace function public.prevent_opening_stock_change_with_movements()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (
       new.opening_stock is distinct from old.opening_stock
       or new.opening_unit_cost is distinct from old.opening_unit_cost
     )
     and exists (
       select 1 from public.stock_movements sm where sm.product_id = old.id
     ) then
    raise exception
      'Opening stock/cost cannot be changed after stock movements exist.';
  end if;
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Sale financial columns (DB is source of truth)
-- ---------------------------------------------------------------------------

alter table public.sale_items
  add column if not exists cogs numeric(14, 2) not null default 0;

alter table public.sale_items
  add column if not exists line_profit numeric(14, 2) not null default 0;

alter table public.sales
  add column if not exists total_cogs numeric(14, 2) not null default 0;

alter table public.sales
  add column if not exists total_profit numeric(14, 2) not null default 0;

-- ---------------------------------------------------------------------------
-- FIFO layers + sale allocations
-- ---------------------------------------------------------------------------

create table if not exists public.inventory_cost_layers (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete restrict,
  source_type text not null
    check (source_type in ('opening', 'purchase', 'adjustment')),
  source_id uuid,
  source_item_id uuid,
  original_quantity numeric(14, 3) not null,
  remaining_quantity numeric(14, 3) not null,
  unit_cost numeric(14, 2) not null,
  created_at timestamptz not null default now(),
  constraint inventory_cost_layers_original_positive check (original_quantity > 0),
  constraint inventory_cost_layers_remaining_range
    check (remaining_quantity >= 0 and remaining_quantity <= original_quantity),
  constraint inventory_cost_layers_unit_cost_non_negative check (unit_cost >= 0)
);

create index if not exists inventory_cost_layers_product_fifo_idx
  on public.inventory_cost_layers (product_id, created_at, id)
  where remaining_quantity > 0;

create unique index if not exists inventory_cost_layers_opening_uidx
  on public.inventory_cost_layers (product_id)
  where source_type = 'opening';

create unique index if not exists inventory_cost_layers_source_item_uidx
  on public.inventory_cost_layers (source_type, source_item_id)
  where source_item_id is not null;

create table if not exists public.sale_cost_allocations (
  id uuid primary key default gen_random_uuid(),
  sale_item_id uuid not null references public.sale_items (id) on delete cascade,
  cost_layer_id uuid not null references public.inventory_cost_layers (id) on delete restrict,
  quantity numeric(14, 3) not null,
  unit_cost numeric(14, 2) not null,
  total_cost numeric(14, 2) not null,
  created_at timestamptz not null default now(),
  constraint sale_cost_allocations_quantity_positive check (quantity > 0),
  constraint sale_cost_allocations_unit_cost_non_negative check (unit_cost >= 0),
  constraint sale_cost_allocations_total_non_negative check (total_cost >= 0),
  constraint sale_cost_allocations_unique unique (sale_item_id, cost_layer_id)
);

create index if not exists sale_cost_allocations_sale_item_idx
  on public.sale_cost_allocations (sale_item_id);
create index if not exists sale_cost_allocations_layer_idx
  on public.sale_cost_allocations (cost_layer_id);

alter table public.inventory_cost_layers enable row level security;
alter table public.sale_cost_allocations enable row level security;

create policy "inventory_cost_layers_select_authenticated"
  on public.inventory_cost_layers for select to authenticated
  using (true);

create policy "sale_cost_allocations_select_authenticated"
  on public.sale_cost_allocations for select to authenticated
  using (true);

revoke insert, update, delete on table public.inventory_cost_layers from authenticated, anon;
revoke insert, update, delete on table public.sale_cost_allocations from authenticated, anon;
grant select on table public.inventory_cost_layers to authenticated;
grant select on table public.sale_cost_allocations to authenticated;

-- ---------------------------------------------------------------------------
-- FIFO helpers
-- ---------------------------------------------------------------------------

create or replace function public.create_opening_cost_layer(p_product_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_qty numeric(14, 3);
  v_cost numeric(14, 2);
begin
  select opening_stock, opening_unit_cost
  into v_qty, v_cost
  from public.products
  where id = p_product_id
  for update;

  if v_qty is null then
    raise exception 'Product not found.';
  end if;
  if v_qty <= 0 then
    return;
  end if;

  insert into public.inventory_cost_layers (
    product_id,
    source_type,
    source_id,
    source_item_id,
    original_quantity,
    remaining_quantity,
    unit_cost,
    created_at
  )
  values (
    p_product_id,
    'opening',
    p_product_id,
    null,
    v_qty,
    v_qty,
    coalesce(v_cost, 0),
    coalesce(
      (select min(created_at) from public.products where id = p_product_id),
      now()
    )
  )
  on conflict (product_id) where (source_type = 'opening')
  do nothing;
end;
$$;

create or replace function public.create_purchase_cost_layers(p_purchase_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
  item record;
  v_created timestamptz;
begin
  select status, created_at into v_status, v_created
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
    order by product_id, id
  loop
    insert into public.inventory_cost_layers (
      product_id,
      source_type,
      source_id,
      source_item_id,
      original_quantity,
      remaining_quantity,
      unit_cost,
      created_at
    )
    values (
      item.product_id,
      'purchase',
      p_purchase_id,
      item.id,
      item.quantity,
      item.quantity,
      item.unit_cost,
      coalesce(v_created, now())
    )
    on conflict (source_type, source_item_id) where (source_item_id is not null)
    do nothing;
  end loop;
end;
$$;

create or replace function public.reverse_purchase_cost_layers(p_purchase_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  layer record;
begin
  for layer in
    select icl.*
    from public.inventory_cost_layers icl
    join public.purchase_items pi on pi.id = icl.source_item_id
    where icl.source_type = 'purchase'
      and pi.purchase_id = p_purchase_id
    for update of icl
  loop
    if layer.remaining_quantity <> layer.original_quantity then
      raise exception
        'Cannot cancel purchase: stock from this purchase has already been sold (FIFO).';
    end if;
    if exists (
      select 1 from public.sale_cost_allocations a where a.cost_layer_id = layer.id
    ) then
      raise exception
        'Cannot cancel purchase: cost allocations still reference this purchase layer.';
    end if;

    delete from public.inventory_cost_layers where id = layer.id;
  end loop;
end;
$$;

create or replace function public.consume_fifo_for_quantity(
  p_product_id uuid,
  p_sale_item_id uuid,
  p_quantity numeric
)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v_needed numeric(14, 3) := p_quantity;
  v_cogs numeric(14, 2) := 0;
  layer record;
  v_take numeric(14, 3);
  v_line_cost numeric(14, 2);
begin
  if p_quantity is null or p_quantity <= 0 then
    raise exception 'Quantity must be greater than zero.';
  end if;

  -- Idempotent: already costed
  if exists (
    select 1 from public.sale_cost_allocations where sale_item_id = p_sale_item_id
  ) then
    select coalesce(sum(total_cost), 0)
    into v_cogs
    from public.sale_cost_allocations
    where sale_item_id = p_sale_item_id;
    return v_cogs;
  end if;

  for layer in
    select *
    from public.inventory_cost_layers
    where product_id = p_product_id
      and remaining_quantity > 0
    order by created_at, id
    for update
  loop
    exit when v_needed <= 0;
    v_take := least(layer.remaining_quantity, v_needed);
    v_line_cost := round(v_take * layer.unit_cost, 2);

    insert into public.sale_cost_allocations (
      sale_item_id,
      cost_layer_id,
      quantity,
      unit_cost,
      total_cost
    )
    values (
      p_sale_item_id,
      layer.id,
      v_take,
      layer.unit_cost,
      v_line_cost
    );

    update public.inventory_cost_layers
    set remaining_quantity = remaining_quantity - v_take
    where id = layer.id;

    v_cogs := v_cogs + v_line_cost;
    v_needed := v_needed - v_take;
  end loop;

  if v_needed > 0 then
    raise exception
      'Insufficient FIFO cost layers for product. Missing quantity: %.',
      v_needed;
  end if;

  return v_cogs;
end;
$$;

create or replace function public.apply_sale_cogs(p_sale_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
  item record;
  v_cogs numeric(14, 2);
  v_profit numeric(14, 2);
  v_total_cogs numeric(14, 2) := 0;
  v_total_profit numeric(14, 2) := 0;
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
    select id, product_id, quantity, line_total
    from public.sale_items
    where sale_id = p_sale_id
    order by product_id, id
  loop
    v_cogs := public.consume_fifo_for_quantity(item.product_id, item.id, item.quantity);
    v_profit := round(item.line_total - v_cogs, 2);

    update public.sale_items
    set cogs = v_cogs,
        line_profit = v_profit
    where id = item.id;

    v_total_cogs := v_total_cogs + v_cogs;
    v_total_profit := v_total_profit + v_profit;
  end loop;

  update public.sales
  set total_cogs = round(v_total_cogs, 2),
      total_profit = round(v_total_profit, 2)
  where id = p_sale_id;
end;
$$;

create or replace function public.reverse_sale_cogs(p_sale_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  alloc record;
begin
  for alloc in
    select a.id, a.cost_layer_id, a.quantity, a.sale_item_id
    from public.sale_cost_allocations a
    join public.sale_items si on si.id = a.sale_item_id
    where si.sale_id = p_sale_id
    for update of a
  loop
    update public.inventory_cost_layers
    set remaining_quantity = remaining_quantity + alloc.quantity
    where id = alloc.cost_layer_id;

    delete from public.sale_cost_allocations where id = alloc.id;
  end loop;

  update public.sale_items
  set cogs = 0,
      line_profit = 0
  where sale_id = p_sale_id;

  update public.sales
  set total_cogs = 0,
      total_profit = 0
  where id = p_sale_id;
end;
$$;

create or replace function public.consume_fifo_for_adjustment(
  p_product_id uuid,
  p_quantity numeric
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_needed numeric(14, 3) := p_quantity;
  layer record;
  v_take numeric(14, 3);
begin
  for layer in
    select *
    from public.inventory_cost_layers
    where product_id = p_product_id
      and remaining_quantity > 0
    order by created_at, id
    for update
  loop
    exit when v_needed <= 0;
    v_take := least(layer.remaining_quantity, v_needed);
    update public.inventory_cost_layers
    set remaining_quantity = remaining_quantity - v_take
    where id = layer.id;
    v_needed := v_needed - v_take;
  end loop;

  if v_needed > 0 then
    raise exception
      'Insufficient FIFO layers for stock-out adjustment. Missing: %.',
      v_needed;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Integrate costing into existing stock apply/reverse + adjustments
-- ---------------------------------------------------------------------------

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

  perform public.create_purchase_cost_layers(p_purchase_id);
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
  -- Reverse FIFO first (fails if layers already consumed)
  perform public.reverse_purchase_cost_layers(p_purchase_id);

  for item in
    select
      pi.id as item_id,
      pi.product_id,
      pi.quantity,
      pi.unit_cost
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
  end loop;

  -- FIFO COGS before stock movement (same transaction)
  perform public.apply_sale_cogs(p_sale_id);

  for item in
    select si.id, si.product_id, si.quantity
    from public.sale_items si
    where si.sale_id = p_sale_id
    order by si.product_id
  loop
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
  -- Restore FIFO before/with stock reversal
  perform public.reverse_sale_cogs(p_sale_id);

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
  v_cost numeric(14, 2);
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
    v_cost := coalesce(p_unit_cost, 0);
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

  if v_type = 'adjustment_out' then
    perform public.consume_fifo_for_adjustment(p_product_id, p_quantity);
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
    case when v_type = 'adjustment_in' then v_cost else null end,
    'adjustment',
    nullif(trim(p_reason), ''),
    nullif(trim(p_notes), ''),
    v_user_id
  )
  returning id into v_id;

  update public.stock_movements
  set reference_id = v_id
  where id = v_id;

  if v_type = 'adjustment_in' then
    insert into public.inventory_cost_layers (
      product_id,
      source_type,
      source_id,
      source_item_id,
      original_quantity,
      remaining_quantity,
      unit_cost
    )
    values (
      p_product_id,
      'adjustment',
      v_id,
      v_id,
      p_quantity,
      p_quantity,
      v_cost
    )
    on conflict (source_type, source_item_id) where (source_item_id is not null)
    do nothing;
  end if;

  return v_id;
end;
$$;

revoke all on function public.create_opening_cost_layer(uuid) from public;
revoke all on function public.create_purchase_cost_layers(uuid) from public;
revoke all on function public.reverse_purchase_cost_layers(uuid) from public;
revoke all on function public.consume_fifo_for_quantity(uuid, uuid, numeric) from public;
revoke all on function public.apply_sale_cogs(uuid) from public;
revoke all on function public.reverse_sale_cogs(uuid) from public;
revoke all on function public.consume_fifo_for_adjustment(uuid, numeric) from public;
revoke all on function public.apply_purchase_stock(uuid) from public;
revoke all on function public.reverse_purchase_stock(uuid) from public;
revoke all on function public.apply_sale_stock(uuid) from public;
revoke all on function public.reverse_sale_stock(uuid) from public;
revoke all on function public.create_stock_adjustment(uuid, text, numeric, numeric, text, text) from public;

grant execute on function public.create_stock_adjustment(uuid, text, numeric, numeric, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Backfill FIFO from existing stock history (no double counting)
-- ---------------------------------------------------------------------------

do $$
declare
  prod record;
  mov record;
  sale_row record;
  v_layer_sum numeric;
  v_stock numeric;
begin
  -- 1) Opening layers
  for prod in select id from public.products where opening_stock > 0
  loop
    perform public.create_opening_cost_layer(prod.id);
  end loop;

  -- 2) Unreversed purchase movements → layers
  for mov in
    select sm.*
    from public.stock_movements sm
    where sm.movement_type = 'purchase'
      and not exists (
        select 1
        from public.stock_movements rev
        where rev.reference_type = 'purchase'
          and rev.reference_item_id = sm.reference_item_id
          and rev.movement_type = 'purchase_reversal'
      )
    order by sm.created_at, sm.id
  loop
    insert into public.inventory_cost_layers (
      product_id,
      source_type,
      source_id,
      source_item_id,
      original_quantity,
      remaining_quantity,
      unit_cost,
      created_at
    )
    values (
      mov.product_id,
      'purchase',
      mov.reference_id,
      mov.reference_item_id,
      mov.quantity,
      mov.quantity,
      coalesce(mov.unit_cost, 0),
      mov.created_at
    )
    on conflict (source_type, source_item_id) where (source_item_id is not null)
    do nothing;
  end loop;

  -- 3) Adjustment-in layers
  for mov in
    select sm.*
    from public.stock_movements sm
    where sm.movement_type = 'adjustment_in'
    order by sm.created_at, sm.id
  loop
    insert into public.inventory_cost_layers (
      product_id,
      source_type,
      source_id,
      source_item_id,
      original_quantity,
      remaining_quantity,
      unit_cost,
      created_at
    )
    values (
      mov.product_id,
      'adjustment',
      mov.id,
      mov.id,
      mov.quantity,
      mov.quantity,
      coalesce(mov.unit_cost, 0),
      mov.created_at
    )
    on conflict (source_type, source_item_id) where (source_item_id is not null)
    do nothing;
  end loop;

  -- 4) Replay unreversed completed sales for COGS
  for sale_row in
    select s.id
    from public.sales s
    where s.status = 'completed'
      and exists (
        select 1
        from public.stock_movements sm
        where sm.reference_type = 'sale'
          and sm.reference_id = s.id
          and sm.movement_type = 'sale'
          and not exists (
            select 1
            from public.stock_movements rev
            where rev.reference_type = 'sale'
              and rev.reference_item_id = sm.reference_item_id
              and rev.movement_type = 'sale_reversal'
          )
      )
    order by s.created_at, s.id
  loop
    -- Mark completed temporarily handled by apply_sale_cogs which requires completed
    perform public.apply_sale_cogs(sale_row.id);
  end loop;

  -- Also consume FIFO for historical sale movements that were later reversed?
  -- Net zero — skip (no remaining COGS on cancelled sales).

  -- 5) Integrity: layer remaining must equal current stock
  for prod in
    select p.id, p.name, p.opening_stock
    from public.products p
  loop
    select coalesce(sum(remaining_quantity), 0)
    into v_layer_sum
    from public.inventory_cost_layers
    where product_id = prod.id;

    select public.product_current_stock(prod.id) into v_stock;

    -- product_current_stock locks; compare
    if v_layer_sum <> v_stock then
      raise exception
        'FIFO backfill mismatch for "%" (id %): layers remaining %, stock %. Aborting.',
        prod.name,
        prod.id,
        v_layer_sum,
        v_stock;
    end if;
  end loop;
end;
$$;
