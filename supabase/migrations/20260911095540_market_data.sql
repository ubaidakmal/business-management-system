-- Phase 12: Live market data cache + settings flags.

alter table public.app_settings
  add column if not exists market_enabled boolean not null default true;

alter table public.app_settings
  add column if not exists market_base_currency text not null default 'USD';

alter table public.app_settings
  add column if not exists market_quote_currencies text not null default 'PKR,EUR,GBP,AED';

create table if not exists public.market_data (
  id uuid primary key default gen_random_uuid(),
  source text not null,
  data_type text not null default 'fx_rate'
    check (data_type in ('fx_rate', 'commodity', 'product_price', 'other')),
  symbol text not null,
  base_currency text not null,
  value numeric(18, 8) not null,
  currency text not null,
  meta jsonb not null default '{}'::jsonb,
  fetched_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists market_data_symbol_fetched_idx
  on public.market_data (symbol, fetched_at desc);

create index if not exists market_data_type_fetched_idx
  on public.market_data (data_type, fetched_at desc);

create index if not exists market_data_base_currency_idx
  on public.market_data (base_currency, currency, fetched_at desc);

alter table public.market_data enable row level security;

-- Authenticated users may read market rows when market feature is enabled.
drop policy if exists "market_data_select_authenticated" on public.market_data;
create policy "market_data_select_authenticated"
  on public.market_data
  for select
  to authenticated
  using (
    exists (
      select 1 from public.app_settings s
      where s.id = 1 and s.market_enabled = true
    )
  );

-- No client insert/update/delete — Edge Function uses service role.
revoke insert, update, delete on table public.market_data from authenticated;
grant select on table public.market_data to authenticated;

-- Extend capability helper for market permissions.
create or replace function public.current_user_can(p_permission text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select case
    when auth.uid() is null then false
    when public.current_user_role() = 'admin' then true
    when p_permission in (
      'view_reports',
      'manage_products',
      'manage_purchases',
      'manage_sales',
      'manage_stock',
      'view_settings',
      'view_market'
    ) then true
    when p_permission in (
      'manage_users',
      'manage_settings',
      'view_admin',
      'manage_market_settings'
    ) then false
    else false
  end;
$$;
