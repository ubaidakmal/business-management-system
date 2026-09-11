-- Phase 11: Application settings, profile active flag, admin user management.

-- ---------------------------------------------------------------------------
-- Profiles: soft-disable users
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists is_active boolean not null default true;

create index if not exists profiles_is_active_idx on public.profiles (is_active);

-- Allow admins to update any profile; users still update only themselves.
drop policy if exists "profiles_update_own" on public.profiles;

create policy "profiles_update_own_or_admin"
  on public.profiles
  for update
  to authenticated
  using (
    auth.uid() = id
    or public.current_user_role() = 'admin'
  )
  with check (
    auth.uid() = id
    or public.current_user_role() = 'admin'
  );

-- Stronger update guard: role/active changes admin-only; protect last admin.
create or replace function public.handle_profile_update()
returns trigger
language plpgsql
as $$
declare
  v_is_admin boolean := coalesce(public.current_user_role(), '') = 'admin';
  v_active_admins int;
begin
  if auth.uid() is not null and not v_is_admin then
    if new.role is distinct from old.role then
      raise exception 'Only admins can change roles';
    end if;
    if new.is_active is distinct from old.is_active then
      raise exception 'Only admins can change active status';
    end if;
    if new.email is distinct from old.email then
      raise exception 'Email cannot be changed here';
    end if;
  end if;

  if old.role = 'admin' and old.is_active = true then
    if new.role <> 'admin' or new.is_active = false then
      select count(*)::int into v_active_admins
      from public.profiles p
      where p.role = 'admin'
        and p.is_active = true
        and p.id <> old.id;
      if coalesce(v_active_admins, 0) < 1 then
        raise exception 'Cannot remove or disable the last active admin';
      end if;
    end if;
  end if;

  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Application settings (singleton row id = 1)
-- ---------------------------------------------------------------------------
create table if not exists public.app_settings (
  id integer primary key default 1 check (id = 1),
  business_name text not null default 'Business Management',
  logo_url text,
  contact_email text,
  phone text,
  address text,
  city text,
  country text,
  default_currency text not null default 'PKR',
  date_format text not null default 'yyyy-MM-dd',
  number_format text not null default '1,234.56',
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles (id)
);

insert into public.app_settings (id)
values (1)
on conflict (id) do nothing;

alter table public.app_settings enable row level security;

drop policy if exists "app_settings_select_authenticated" on public.app_settings;
create policy "app_settings_select_authenticated"
  on public.app_settings
  for select
  to authenticated
  using (true);

drop policy if exists "app_settings_update_admin" on public.app_settings;
create policy "app_settings_update_admin"
  on public.app_settings
  for update
  to authenticated
  using (public.current_user_role() = 'admin')
  with check (public.current_user_role() = 'admin');

grant select, update on table public.app_settings to authenticated;

create or replace function public.touch_app_settings()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  new.updated_by = auth.uid();
  return new;
end;
$$;

drop trigger if exists app_settings_before_update on public.app_settings;
create trigger app_settings_before_update
  before update on public.app_settings
  for each row
  execute function public.touch_app_settings();

-- ---------------------------------------------------------------------------
-- Admin overview counts (read-only)
-- ---------------------------------------------------------------------------
create or replace function public.get_admin_overview()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;
  if coalesce(public.current_user_role(), '') <> 'admin' then
    raise exception 'Only admins can view administration overview.';
  end if;

  return jsonb_build_object(
    'users_total', (select count(*)::int from public.profiles),
    'users_active', (select count(*)::int from public.profiles where is_active = true),
    'users_admins', (select count(*)::int from public.profiles where role = 'admin' and is_active = true),
    'companies_total', (select count(*)::int from public.companies),
    'companies_active', (select count(*)::int from public.companies where is_active = true),
    'products_total', (select count(*)::int from public.products),
    'products_active', (select count(*)::int from public.products where is_active = true)
  );
end;
$$;

revoke all on function public.get_admin_overview() from public;
grant execute on function public.get_admin_overview() to authenticated;

-- ---------------------------------------------------------------------------
-- Simple role → capability helper (foundation; RLS remains source of truth)
-- ---------------------------------------------------------------------------
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
      'view_settings'
    ) then true
    when p_permission in ('manage_users', 'manage_settings', 'view_admin') then false
    else false
  end;
$$;

revoke all on function public.current_user_can(text) from public;
grant execute on function public.current_user_can(text) to authenticated;
