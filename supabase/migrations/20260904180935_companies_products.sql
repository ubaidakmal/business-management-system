-- Companies and products foundation for later purchases/sales/stock.

create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text,
  email text,
  phone text,
  address text,
  city text,
  country text,
  notes text,
  is_active boolean not null default true,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint companies_name_not_blank check (length(trim(name)) > 0)
);

create unique index if not exists companies_code_unique
  on public.companies (lower(code))
  where code is not null and length(trim(code)) > 0;

create index if not exists companies_name_idx on public.companies (lower(name));
create index if not exists companies_is_active_idx on public.companies (is_active);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete restrict,
  name text not null,
  sku text,
  barcode text,
  category text,
  unit text,
  description text,
  purchase_price numeric(14, 2) not null default 0,
  sale_price numeric(14, 2) not null default 0,
  opening_stock numeric(14, 3) not null default 0,
  is_active boolean not null default true,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint products_name_not_blank check (length(trim(name)) > 0),
  constraint products_purchase_price_non_negative check (purchase_price >= 0),
  constraint products_sale_price_non_negative check (sale_price >= 0),
  constraint products_opening_stock_non_negative check (opening_stock >= 0)
);

create unique index if not exists products_sku_unique
  on public.products (lower(sku))
  where sku is not null and length(trim(sku)) > 0;

create unique index if not exists products_barcode_unique
  on public.products (lower(barcode))
  where barcode is not null and length(trim(barcode)) > 0;

create index if not exists products_company_id_idx on public.products (company_id);
create index if not exists products_name_idx on public.products (lower(name));
create index if not exists products_category_idx on public.products (lower(category));
create index if not exists products_is_active_idx on public.products (is_active);

-- Shared updated_at helper
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists companies_set_updated_at on public.companies;
create trigger companies_set_updated_at
  before update on public.companies
  for each row
  execute function public.set_updated_at();

drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at
  before update on public.products
  for each row
  execute function public.set_updated_at();

alter table public.companies enable row level security;
alter table public.products enable row level security;

-- Authenticated users can manage company/product data.
-- Prefer deactivation over hard delete in the app.
create policy "companies_select_authenticated"
  on public.companies for select to authenticated
  using (true);

create policy "companies_insert_authenticated"
  on public.companies for insert to authenticated
  with check (auth.uid() is not null);

create policy "companies_update_authenticated"
  on public.companies for update to authenticated
  using (true)
  with check (true);

create policy "companies_delete_admin"
  on public.companies for delete to authenticated
  using (public.current_user_role() = 'admin');

create policy "products_select_authenticated"
  on public.products for select to authenticated
  using (true);

create policy "products_insert_authenticated"
  on public.products for insert to authenticated
  with check (auth.uid() is not null);

create policy "products_update_authenticated"
  on public.products for update to authenticated
  using (true)
  with check (true);

create policy "products_delete_admin"
  on public.products for delete to authenticated
  using (public.current_user_role() = 'admin');

grant select, insert, update, delete on table public.companies to authenticated;
grant select, insert, update, delete on table public.products to authenticated;
