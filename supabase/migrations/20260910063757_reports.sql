-- Phase 9: Reports aggregation RPCs (read-only; use stored COGS/profit/stock).

-- Sales report: rows + summary. Cancelled always excluded.
-- p_status: 'completed' (default), 'draft', or null for both non-cancelled.
create or replace function public.get_sales_report(
  p_date_from date default null,
  p_date_to date default null,
  p_company_id uuid default null,
  p_status text default 'completed',
  p_search text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_search text := nullif(trim(coalesce(p_search, '')), '');
  v_summary jsonb;
  v_rows jsonb;
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;
  if p_status is not null and p_status not in ('completed', 'draft') then
    raise exception 'Invalid status filter.';
  end if;
  if p_date_from is not null and p_date_to is not null and p_date_to < p_date_from then
    raise exception 'End date must be on or after start date.';
  end if;

  select jsonb_build_object(
    'sales_total', coalesce(sum(s.total_amount), 0),
    'sales_count', count(s.id)::int,
    'total_cogs', coalesce(sum(s.total_cogs), 0),
    'total_profit', coalesce(sum(s.total_profit), 0)
  )
  into v_summary
  from public.sales s
  where s.status <> 'cancelled'
    and (p_status is null or s.status = p_status)
    and (p_date_from is null or s.sale_date >= p_date_from)
    and (p_date_to is null or s.sale_date <= p_date_to)
    and (p_company_id is null or s.company_id = p_company_id)
    and (
      v_search is null
      or s.invoice_number ilike '%' || v_search || '%'
      or s.reference_number ilike '%' || v_search || '%'
      or exists (
        select 1 from public.companies c
        where c.id = s.company_id
          and c.name ilike '%' || v_search || '%'
      )
    );

  select coalesce(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
  into v_rows
  from (
    select
      s.id,
      s.invoice_number,
      s.reference_number,
      s.sale_date,
      s.status,
      s.total_amount as revenue,
      s.total_cogs,
      s.total_profit,
      c.name as company_name,
      (
        select count(*)::int from public.sale_items si where si.sale_id = s.id
      ) as items_count
    from public.sales s
    left join public.companies c on c.id = s.company_id
    where s.status <> 'cancelled'
      and (p_status is null or s.status = p_status)
      and (p_date_from is null or s.sale_date >= p_date_from)
      and (p_date_to is null or s.sale_date <= p_date_to)
      and (p_company_id is null or s.company_id = p_company_id)
      and (
        v_search is null
        or s.invoice_number ilike '%' || v_search || '%'
        or s.reference_number ilike '%' || v_search || '%'
        or c.name ilike '%' || v_search || '%'
      )
    order by s.sale_date desc, s.created_at desc
    limit 500
  ) t;

  return jsonb_build_object(
    'summary', coalesce(v_summary, jsonb_build_object(
      'sales_total', 0, 'sales_count', 0, 'total_cogs', 0, 'total_profit', 0
    )),
    'rows', v_rows
  );
end;
$$;

revoke all on function public.get_sales_report(date, date, uuid, text, text) from public;
grant execute on function public.get_sales_report(date, date, uuid, text, text) to authenticated;

-- Purchases report: completed only.
create or replace function public.get_purchases_report(
  p_date_from date default null,
  p_date_to date default null,
  p_company_id uuid default null,
  p_search text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_search text := nullif(trim(coalesce(p_search, '')), '');
  v_summary jsonb;
  v_rows jsonb;
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;
  if p_date_from is not null and p_date_to is not null and p_date_to < p_date_from then
    raise exception 'End date must be on or after start date.';
  end if;

  select jsonb_build_object(
    'purchases_total', coalesce(sum(p.total_amount), 0),
    'purchases_count', count(p.id)::int
  )
  into v_summary
  from public.purchases p
  where p.status = 'completed'
    and (p_date_from is null or p.purchase_date >= p_date_from)
    and (p_date_to is null or p.purchase_date <= p_date_to)
    and (p_company_id is null or p.company_id = p_company_id)
    and (
      v_search is null
      or p.invoice_number ilike '%' || v_search || '%'
      or p.reference_number ilike '%' || v_search || '%'
      or exists (
        select 1 from public.companies c
        where c.id = p.company_id
          and c.name ilike '%' || v_search || '%'
      )
    );

  select coalesce(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
  into v_rows
  from (
    select
      p.id,
      p.invoice_number,
      p.reference_number,
      p.purchase_date,
      p.total_amount,
      c.name as company_name,
      (
        select count(*)::int from public.purchase_items pi where pi.purchase_id = p.id
      ) as items_count
    from public.purchases p
    left join public.companies c on c.id = p.company_id
    where p.status = 'completed'
      and (p_date_from is null or p.purchase_date >= p_date_from)
      and (p_date_to is null or p.purchase_date <= p_date_to)
      and (p_company_id is null or p.company_id = p_company_id)
      and (
        v_search is null
        or p.invoice_number ilike '%' || v_search || '%'
        or p.reference_number ilike '%' || v_search || '%'
        or c.name ilike '%' || v_search || '%'
      )
    order by p.purchase_date desc, p.created_at desc
    limit 500
  ) t;

  return jsonb_build_object(
    'summary', coalesce(v_summary, jsonb_build_object(
      'purchases_total', 0, 'purchases_count', 0
    )),
    'rows', v_rows
  );
end;
$$;

revoke all on function public.get_purchases_report(date, date, uuid, text) from public;
grant execute on function public.get_purchases_report(date, date, uuid, text) to authenticated;

-- Profit report: completed sales; optional product filter uses stored line COGS/profit.
create or replace function public.get_profit_report(
  p_date_from date default null,
  p_date_to date default null,
  p_company_id uuid default null,
  p_product_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_summary jsonb;
  v_rows jsonb;
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;
  if p_date_from is not null and p_date_to is not null and p_date_to < p_date_from then
    raise exception 'End date must be on or after start date.';
  end if;

  if p_product_id is null then
    select jsonb_build_object(
      'revenue', coalesce(sum(s.total_amount), 0),
      'total_cogs', coalesce(sum(s.total_cogs), 0),
      'gross_profit', coalesce(sum(s.total_profit), 0),
      'sales_count', count(s.id)::int
    )
    into v_summary
    from public.sales s
    where s.status = 'completed'
      and (p_date_from is null or s.sale_date >= p_date_from)
      and (p_date_to is null or s.sale_date <= p_date_to)
      and (p_company_id is null or s.company_id = p_company_id);

    select coalesce(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
    into v_rows
    from (
      select
        s.id,
        s.invoice_number,
        s.sale_date,
        c.name as company_name,
        s.total_amount as revenue,
        s.total_cogs,
        s.total_profit as gross_profit
      from public.sales s
      left join public.companies c on c.id = s.company_id
      where s.status = 'completed'
        and (p_date_from is null or s.sale_date >= p_date_from)
        and (p_date_to is null or s.sale_date <= p_date_to)
        and (p_company_id is null or s.company_id = p_company_id)
      order by s.sale_date desc, s.created_at desc
      limit 500
    ) t;
  else
    select jsonb_build_object(
      'revenue', coalesce(sum(si.line_total), 0),
      'total_cogs', coalesce(sum(si.cogs), 0),
      'gross_profit', coalesce(sum(si.line_profit), 0),
      'sales_count', count(distinct s.id)::int
    )
    into v_summary
    from public.sale_items si
    join public.sales s on s.id = si.sale_id
    where s.status = 'completed'
      and si.product_id = p_product_id
      and (p_date_from is null or s.sale_date >= p_date_from)
      and (p_date_to is null or s.sale_date <= p_date_to)
      and (p_company_id is null or s.company_id = p_company_id);

    select coalesce(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
    into v_rows
    from (
      select
        s.id,
        s.invoice_number,
        s.sale_date,
        c.name as company_name,
        si.line_total as revenue,
        si.cogs as total_cogs,
        si.line_profit as gross_profit
      from public.sale_items si
      join public.sales s on s.id = si.sale_id
      left join public.companies c on c.id = s.company_id
      where s.status = 'completed'
        and si.product_id = p_product_id
        and (p_date_from is null or s.sale_date >= p_date_from)
        and (p_date_to is null or s.sale_date <= p_date_to)
        and (p_company_id is null or s.company_id = p_company_id)
      order by s.sale_date desc, s.created_at desc
      limit 500
    ) t;
  end if;

  return jsonb_build_object(
    'summary', coalesce(v_summary, jsonb_build_object(
      'revenue', 0, 'total_cogs', 0, 'gross_profit', 0, 'sales_count', 0
    )),
    'rows', coalesce(v_rows, '[]'::jsonb)
  );
end;
$$;

revoke all on function public.get_profit_report(date, date, uuid, uuid) from public;
grant execute on function public.get_profit_report(date, date, uuid, uuid) to authenticated;

-- Product performance from completed sale lines (stored COGS/profit).
create or replace function public.get_product_report(
  p_date_from date default null,
  p_date_to date default null,
  p_company_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_summary jsonb;
  v_rows jsonb;
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;
  if p_date_from is not null and p_date_to is not null and p_date_to < p_date_from then
    raise exception 'End date must be on or after start date.';
  end if;

  select jsonb_build_object(
    'quantity_sold', coalesce(sum(si.quantity), 0),
    'revenue', coalesce(sum(si.line_total), 0),
    'total_cogs', coalesce(sum(si.cogs), 0),
    'total_profit', coalesce(sum(si.line_profit), 0),
    'product_count', count(distinct si.product_id)::int
  )
  into v_summary
  from public.sale_items si
  join public.sales s on s.id = si.sale_id
  join public.products p on p.id = si.product_id
  where s.status = 'completed'
    and (p_date_from is null or s.sale_date >= p_date_from)
    and (p_date_to is null or s.sale_date <= p_date_to)
    and (p_company_id is null or s.company_id = p_company_id);

  select coalesce(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
  into v_rows
  from (
    select
      p.id as product_id,
      p.name as product_name,
      p.sku,
      c.name as company_name,
      coalesce(sum(si.quantity), 0) as quantity_sold,
      coalesce(sum(si.line_total), 0) as revenue,
      coalesce(sum(si.cogs), 0) as total_cogs,
      coalesce(sum(si.line_profit), 0) as total_profit
    from public.sale_items si
    join public.sales s on s.id = si.sale_id
    join public.products p on p.id = si.product_id
    left join public.companies c on c.id = p.company_id
    where s.status = 'completed'
      and (p_date_from is null or s.sale_date >= p_date_from)
      and (p_date_to is null or s.sale_date <= p_date_to)
      and (p_company_id is null or s.company_id = p_company_id)
    group by p.id, p.name, p.sku, c.name
    order by coalesce(sum(si.line_profit), 0) desc, p.name
    limit 500
  ) t;

  return jsonb_build_object(
    'summary', coalesce(v_summary, jsonb_build_object(
      'quantity_sold', 0, 'revenue', 0, 'total_cogs', 0, 'total_profit', 0, 'product_count', 0
    )),
    'rows', coalesce(v_rows, '[]'::jsonb)
  );
end;
$$;

revoke all on function public.get_product_report(date, date, uuid) from public;
grant execute on function public.get_product_report(date, date, uuid) to authenticated;

-- Company-wise sales, purchases, profit, product count.
create or replace function public.get_company_report(
  p_date_from date default null,
  p_date_to date default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_summary jsonb;
  v_rows jsonb;
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;
  if p_date_from is not null and p_date_to is not null and p_date_to < p_date_from then
    raise exception 'End date must be on or after start date.';
  end if;

  select coalesce(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
  into v_rows
  from (
    select
      c.id as company_id,
      c.name as company_name,
      c.code,
      coalesce((
        select sum(s.total_amount)
        from public.sales s
        where s.company_id = c.id
          and s.status = 'completed'
          and (p_date_from is null or s.sale_date >= p_date_from)
          and (p_date_to is null or s.sale_date <= p_date_to)
      ), 0) as sales_total,
      coalesce((
        select sum(s.total_profit)
        from public.sales s
        where s.company_id = c.id
          and s.status = 'completed'
          and (p_date_from is null or s.sale_date >= p_date_from)
          and (p_date_to is null or s.sale_date <= p_date_to)
      ), 0) as profit_total,
      coalesce((
        select sum(p.total_amount)
        from public.purchases p
        where p.company_id = c.id
          and p.status = 'completed'
          and (p_date_from is null or p.purchase_date >= p_date_from)
          and (p_date_to is null or p.purchase_date <= p_date_to)
      ), 0) as purchases_total,
      (
        select count(*)::int from public.products pr
        where pr.company_id = c.id and pr.is_active = true
      ) as product_count
    from public.companies c
    where c.is_active = true
    order by c.name
  ) t;

  select jsonb_build_object(
    'company_count', coalesce(jsonb_array_length(v_rows), 0),
    'sales_total', coalesce((
      select sum((r->>'sales_total')::numeric) from jsonb_array_elements(v_rows) r
    ), 0),
    'purchases_total', coalesce((
      select sum((r->>'purchases_total')::numeric) from jsonb_array_elements(v_rows) r
    ), 0),
    'profit_total', coalesce((
      select sum((r->>'profit_total')::numeric) from jsonb_array_elements(v_rows) r
    ), 0)
  )
  into v_summary;

  return jsonb_build_object(
    'summary', coalesce(v_summary, jsonb_build_object(
      'company_count', 0, 'sales_total', 0, 'purchases_total', 0, 'profit_total', 0
    )),
    'rows', coalesce(v_rows, '[]'::jsonb)
  );
end;
$$;

revoke all on function public.get_company_report(date, date) from public;
grant execute on function public.get_company_report(date, date) to authenticated;
