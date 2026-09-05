-- Allow SQL/service role updates when there is no authenticated JWT,
-- while still blocking non-admin users from changing roles in the app.

create or replace function public.handle_profile_update()
returns trigger
language plpgsql
as $$
begin
  if new.role is distinct from old.role
     and auth.uid() is not null
     and coalesce(public.current_user_role(), '') <> 'admin' then
    raise exception 'Only admins can change roles';
  end if;
  new.updated_at = now();
  return new;
end;
$$;
