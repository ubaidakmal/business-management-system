-- Keep opening FIFO layer in sync when products are created/updated
-- before any stock movements exist.

create or replace function public.products_sync_opening_cost_layer()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1 from public.stock_movements sm where sm.product_id = new.id
  ) then
    return new;
  end if;

  delete from public.inventory_cost_layers
  where product_id = new.id
    and source_type = 'opening';

  if new.opening_stock > 0 then
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
      new.id,
      'opening',
      new.id,
      null,
      new.opening_stock,
      new.opening_stock,
      coalesce(new.opening_unit_cost, 0),
      coalesce(new.created_at, now())
    );
  end if;

  return new;
end;
$$;

drop trigger if exists products_sync_opening_cost_layer on public.products;
create trigger products_sync_opening_cost_layer
  after insert or update of opening_stock, opening_unit_cost on public.products
  for each row
  execute function public.products_sync_opening_cost_layer();
