-- Phase 8: Dashboard aggregation (completed transactions only).

create or replace function public.get_dashboard_data(
  p_date_from date,
  p_date_to date,
  p_company_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_from date := coalesce(p_date_from, current_date);
  v_to date := coalesce(p_date_to, current_date);
  v_summary jsonb;
  v_recent_sales jsonb;
  v_recent_purchases jsonb;
  v_inventory jsonb;
  v_low_stock jsonb;
  v_trend jsonb;
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;
  if v_to < v_from then
    raise exception 'End date must be on or after start date.';
  end if;

  select jsonb_build_object(
    'sales_total', coalesce(sum(s.total_amount), 0),
    'purchases_total', (
      select coalesce(sum(p.total_amount), 0)
      from public.purchases p
      where p.status = 'completed'
        and p.purchase_date between v_from and v_to
        and (p_company_id is null or p.company_id = p_company_id)
    ),
    'revenue', coalesce(sum(s.total_amount), 0),
    'total_cogs', coalesce(sum(s.total_cogs), 0),
    'total_profit', coalesce(sum(s.total_profit), 0),
    'sales_count', count(s.id)::int,
    'purchases_count', (
      select count(*)::int
      from public.purchases p
      where p.status = 'completed'
        and p.purchase_date between v_from and v_to
        and (p_company_id is null or p.company_id = p_company_id)
    )
  )
  into v_summary
  from public.sales s
  where s.status = 'completed'
    and s.sale_date between v_from and v_to
    and (p_company_id is null or s.company_id = p_company_id);

  -- When no sales rows, still need purchases side of summary
  if v_summary is null then
    select jsonb_build_object(
      'sales_total', 0,
      'purchases_total', coalesce(sum(p.total_amount), 0),
      'revenue', 0,
      'total_cogs', 0,
      'total_profit', 0,
      'sales_count', 0,
      'purchases_count', count(*)::int
    )
    into v_summary
    from public.purchases p
    where p.status = 'completed'
      and p.purchase_date between v_from and v_to
      and (p_company_id is null or p.company_id = p_company_id);
  end if;

  select coalesce(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
  into v_recent_sales
  from (
    select
      s.id,
      s.invoice_number,
      s.sale_date,
      s.total_amount,
      s.total_profit,
      s.status,
      c.name as company_name
    from public.sales s
    left join public.companies c on c.id = s.company_id
    where s.status = 'completed'
      and s.sale_date between v_from and v_to
      and (p_company_id is null or s.company_id = p_company_id)
    order by s.sale_date desc, s.created_at desc
    limit 8
  ) t;

  select coalesce(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
  into v_recent_purchases
  from (
    select
      p.id,
      p.invoice_number,
      p.purchase_date,
      p.total_amount,
      p.status,
      c.name as company_name
    from public.purchases p
    left join public.companies c on c.id = p.company_id
    where p.status = 'completed'
      and p.purchase_date between v_from and v_to
      and (p_company_id is null or p.company_id = p_company_id)
    order by p.purchase_date desc, p.created_at desc
    limit 8
  ) t;

  select jsonb_build_object(
    'total_products', count(*)::int,
    'low_stock_count', count(*) filter (
      where b.is_low_stock and b.current_stock > 0
    )::int,
    'out_of_stock_count', count(*) filter (where b.current_stock <= 0)::int
  )
  into v_inventory
  from public.product_stock_balances b
  where b.is_active = true
    and (p_company_id is null or b.company_id = p_company_id);

  select coalesce(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
  into v_low_stock
  from (
    select
      b.product_id,
      b.product_name,
      b.sku,
      b.current_stock,
      b.reorder_level,
      b.company_name
    from public.product_stock_balances b
    where b.is_active = true
      and b.is_low_stock = true
      and (p_company_id is null or b.company_id = p_company_id)
    order by b.current_stock asc, b.product_name
    limit 8
  ) t;

  select coalesce(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
  into v_trend
  from (
    select
      d::date as day,
      coalesce(sum(s.total_amount), 0) as sales_total,
      coalesce(sum(s.total_profit), 0) as profit_total,
      count(s.id)::int as sales_count
    from generate_series(v_from, v_to, interval '1 day') as d
    left join public.sales s
      on s.status = 'completed'
     and s.sale_date = d::date
     and (p_company_id is null or s.company_id = p_company_id)
    group by d::date
    order by d::date
  ) t;

  return jsonb_build_object(
    'date_from', v_from,
    'date_to', v_to,
    'summary', v_summary,
    'recent_sales', v_recent_sales,
    'recent_purchases', v_recent_purchases,
    'inventory', v_inventory,
    'low_stock', v_low_stock,
    'trend', v_trend
  );
end;
$$;

revoke all on function public.get_dashboard_data(date, date, uuid) from public;
grant execute on function public.get_dashboard_data(date, date, uuid) to authenticated;
