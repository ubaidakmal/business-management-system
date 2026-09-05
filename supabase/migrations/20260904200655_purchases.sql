-- Purchase management foundation. Stock effects intentionally deferred.

create table if not exists public.purchases (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete restrict,
  purchase_date date not null default current_date,
  invoice_number text,
  reference_number text,
  notes text,
  subtotal numeric(14, 2) not null default 0,
  discount numeric(14, 2) not null default 0,
  other_charges numeric(14, 2) not null default 0,
  total_amount numeric(14, 2) not null default 0,
  status text not null default 'draft'
    check (status in ('draft', 'completed', 'cancelled')),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint purchases_discount_non_negative check (discount >= 0),
  constraint purchases_other_charges_non_negative check (other_charges >= 0),
  constraint purchases_subtotal_non_negative check (subtotal >= 0),
  constraint purchases_total_non_negative check (total_amount >= 0)
);

create index if not exists purchases_company_id_idx on public.purchases (company_id);
create index if not exists purchases_status_idx on public.purchases (status);
create index if not exists purchases_purchase_date_idx on public.purchases (purchase_date desc);
create index if not exists purchases_invoice_number_idx
  on public.purchases (lower(invoice_number))
  where invoice_number is not null and length(trim(invoice_number)) > 0;
create index if not exists purchases_reference_number_idx
  on public.purchases (lower(reference_number))
  where reference_number is not null and length(trim(reference_number)) > 0;

create table if not exists public.purchase_items (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid not null references public.purchases (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete restrict,
  quantity numeric(14, 3) not null,
  unit_cost numeric(14, 2) not null,
  line_total numeric(14, 2) not null,
  created_at timestamptz not null default now(),
  constraint purchase_items_quantity_positive check (quantity > 0),
  constraint purchase_items_unit_cost_non_negative check (unit_cost >= 0),
  constraint purchase_items_line_total_non_negative check (line_total >= 0),
  constraint purchase_items_unique_product unique (purchase_id, product_id)
);

create index if not exists purchase_items_purchase_id_idx
  on public.purchase_items (purchase_id);
create index if not exists purchase_items_product_id_idx
  on public.purchase_items (product_id);

drop trigger if exists purchases_set_updated_at on public.purchases;
create trigger purchases_set_updated_at
  before update on public.purchases
  for each row
  execute function public.set_updated_at();

alter table public.purchases enable row level security;
alter table public.purchase_items enable row level security;

create policy "purchases_select_authenticated"
  on public.purchases for select to authenticated
  using (true);

create policy "purchases_insert_authenticated"
  on public.purchases for insert to authenticated
  with check (auth.uid() is not null);

create policy "purchases_update_authenticated"
  on public.purchases for update to authenticated
  using (true)
  with check (true);

create policy "purchases_delete_draft_admin"
  on public.purchases for delete to authenticated
  using (
    status = 'draft'
    and public.current_user_role() = 'admin'
  );

create policy "purchase_items_select_authenticated"
  on public.purchase_items for select to authenticated
  using (true);

create policy "purchase_items_insert_authenticated"
  on public.purchase_items for insert to authenticated
  with check (auth.uid() is not null);

create policy "purchase_items_update_authenticated"
  on public.purchase_items for update to authenticated
  using (true)
  with check (true);

create policy "purchase_items_delete_authenticated"
  on public.purchase_items for delete to authenticated
  using (true);

grant select, insert, update, delete on table public.purchases to authenticated;
grant select, insert, update, delete on table public.purchase_items to authenticated;

-- Shared helpers for purchase RPCs
create or replace function public._validate_and_build_purchase_items(
  p_items jsonb
)
returns table (
  product_id uuid,
  quantity numeric,
  unit_cost numeric,
  line_total numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  item jsonb;
  v_product_id uuid;
  v_quantity numeric;
  v_unit_cost numeric;
  v_line_total numeric;
  seen uuid[] := '{}';
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Add at least one purchase item.';
  end if;

  for item in select * from jsonb_array_elements(p_items)
  loop
    v_product_id := nullif(item->>'product_id', '')::uuid;
    v_quantity := coalesce((item->>'quantity')::numeric, 0);
    v_unit_cost := coalesce((item->>'unit_cost')::numeric, 0);

    if v_product_id is null then
      raise exception 'Each item must include a product.';
    end if;
    if v_quantity <= 0 then
      raise exception 'Quantity must be greater than zero.';
    end if;
    if v_unit_cost < 0 then
      raise exception 'Unit cost cannot be negative.';
    end if;
    if not exists (select 1 from public.products p where p.id = v_product_id) then
      raise exception 'One or more products were not found.';
    end if;
    if v_product_id = any(seen) then
      raise exception 'Duplicate products are not allowed in one purchase.';
    end if;

    seen := array_append(seen, v_product_id);
    v_line_total := round(v_quantity * v_unit_cost, 2);

    product_id := v_product_id;
    quantity := v_quantity;
    unit_cost := v_unit_cost;
    line_total := v_line_total;
    return next;
  end loop;
end;
$$;

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
    v_status,
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
    status = v_status
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

revoke all on function public._validate_and_build_purchase_items(jsonb) from public;
revoke all on function public.create_purchase_with_items(uuid, date, text, text, text, numeric, numeric, text, jsonb) from public;
revoke all on function public.update_draft_purchase_with_items(uuid, uuid, date, text, text, text, numeric, numeric, text, jsonb) from public;
revoke all on function public.cancel_purchase(uuid) from public;

grant execute on function public.create_purchase_with_items(uuid, date, text, text, text, numeric, numeric, text, jsonb) to authenticated;
grant execute on function public.update_draft_purchase_with_items(uuid, uuid, date, text, text, text, numeric, numeric, text, jsonb) to authenticated;
grant execute on function public.cancel_purchase(uuid) to authenticated;
