-- Fix ambiguous `item` alias vs PL/pgSQL record variable in purchase RPCs.

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

grant execute on function public.create_purchase_with_items(uuid, date, text, text, text, numeric, numeric, text, jsonb) to authenticated;
grant execute on function public.update_draft_purchase_with_items(uuid, uuid, date, text, text, text, numeric, numeric, text, jsonb) to authenticated;
