-- Sales management foundation. Stock and profit intentionally deferred.

create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete restrict,
  sale_date date not null default current_date,
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
  constraint sales_discount_non_negative check (discount >= 0),
  constraint sales_other_charges_non_negative check (other_charges >= 0),
  constraint sales_subtotal_non_negative check (subtotal >= 0),
  constraint sales_total_non_negative check (total_amount >= 0)
);

create index if not exists sales_company_id_idx on public.sales (company_id);
create index if not exists sales_status_idx on public.sales (status);
create index if not exists sales_sale_date_idx on public.sales (sale_date desc);
create index if not exists sales_invoice_number_idx
  on public.sales (lower(invoice_number))
  where invoice_number is not null and length(trim(invoice_number)) > 0;
create index if not exists sales_reference_number_idx
  on public.sales (lower(reference_number))
  where reference_number is not null and length(trim(reference_number)) > 0;

create table if not exists public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete restrict,
  quantity numeric(14, 3) not null,
  unit_price numeric(14, 2) not null,
  line_total numeric(14, 2) not null,
  created_at timestamptz not null default now(),
  constraint sale_items_quantity_positive check (quantity > 0),
  constraint sale_items_unit_price_non_negative check (unit_price >= 0),
  constraint sale_items_line_total_non_negative check (line_total >= 0),
  constraint sale_items_unique_product unique (sale_id, product_id)
);

create index if not exists sale_items_sale_id_idx on public.sale_items (sale_id);
create index if not exists sale_items_product_id_idx on public.sale_items (product_id);

drop trigger if exists sales_set_updated_at on public.sales;
create trigger sales_set_updated_at
  before update on public.sales
  for each row
  execute function public.set_updated_at();

alter table public.sales enable row level security;
alter table public.sale_items enable row level security;

create policy "sales_select_authenticated"
  on public.sales for select to authenticated
  using (true);

create policy "sales_insert_authenticated"
  on public.sales for insert to authenticated
  with check (auth.uid() is not null);

create policy "sales_update_authenticated"
  on public.sales for update to authenticated
  using (true)
  with check (true);

create policy "sales_delete_draft_admin"
  on public.sales for delete to authenticated
  using (
    status = 'draft'
    and public.current_user_role() = 'admin'
  );

create policy "sale_items_select_authenticated"
  on public.sale_items for select to authenticated
  using (true);

create policy "sale_items_insert_authenticated"
  on public.sale_items for insert to authenticated
  with check (auth.uid() is not null);

create policy "sale_items_update_authenticated"
  on public.sale_items for update to authenticated
  using (true)
  with check (true);

create policy "sale_items_delete_authenticated"
  on public.sale_items for delete to authenticated
  using (true);

grant select, insert, update, delete on table public.sales to authenticated;
grant select, insert, update, delete on table public.sale_items to authenticated;

create or replace function public._validate_and_build_sale_items(
  p_items jsonb
)
returns table (
  product_id uuid,
  quantity numeric,
  unit_price numeric,
  line_total numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  raw_item jsonb;
  v_product_id uuid;
  v_quantity numeric;
  v_unit_price numeric;
  v_line_total numeric;
  seen uuid[] := '{}';
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Add at least one sale item.';
  end if;

  for raw_item in select * from jsonb_array_elements(p_items)
  loop
    v_product_id := nullif(raw_item->>'product_id', '')::uuid;
    v_quantity := coalesce((raw_item->>'quantity')::numeric, 0);
    v_unit_price := coalesce((raw_item->>'unit_price')::numeric, 0);

    if v_product_id is null then
      raise exception 'Each item must include a product.';
    end if;
    if v_quantity <= 0 then
      raise exception 'Quantity must be greater than zero.';
    end if;
    if v_unit_price < 0 then
      raise exception 'Unit price cannot be negative.';
    end if;
    if not exists (select 1 from public.products p where p.id = v_product_id) then
      raise exception 'One or more products were not found.';
    end if;
    if v_product_id = any(seen) then
      raise exception 'Duplicate products are not allowed in one sale.';
    end if;

    seen := array_append(seen, v_product_id);
    v_line_total := round(v_quantity * v_unit_price, 2);

    product_id := v_product_id;
    quantity := v_quantity;
    unit_price := v_unit_price;
    line_total := v_line_total;
    return next;
  end loop;
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
    v_status,
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
    status = v_status
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

revoke all on function public._validate_and_build_sale_items(jsonb) from public;
revoke all on function public.create_sale_with_items(uuid, date, text, text, text, numeric, numeric, text, jsonb) from public;
revoke all on function public.update_draft_sale_with_items(uuid, uuid, date, text, text, text, numeric, numeric, text, jsonb) from public;
revoke all on function public.cancel_sale(uuid) from public;

grant execute on function public.create_sale_with_items(uuid, date, text, text, text, numeric, numeric, text, jsonb) to authenticated;
grant execute on function public.update_draft_sale_with_items(uuid, uuid, date, text, text, text, numeric, numeric, text, jsonb) to authenticated;
grant execute on function public.cancel_sale(uuid) to authenticated;
