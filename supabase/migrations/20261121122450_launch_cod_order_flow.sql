-- Launch checkout: COD-only orders, structured Indian delivery addresses,
-- manually fulfilled catalogue variants, and administrator cash collection.

alter table public.orders
  add column if not exists delivery_house text,
  add column if not exists delivery_street text,
  add column if not exists delivery_area text,
  add column if not exists delivery_landmark text,
  add column if not exists delivery_city text,
  add column if not exists delivery_state text,
  add column if not exists delivery_pincode text,
  add column if not exists delivery_instructions text,
  add column if not exists payment_method text not null default 'cod',
  add column if not exists payment_status text not null default 'pending_collection',
  add column if not exists payment_collected_at timestamptz,
  add column if not exists payment_collected_by uuid references auth.users(id) on delete set null;

alter table public.orders drop constraint if exists orders_payment_method_check;
alter table public.orders add constraint orders_payment_method_check check (payment_method = 'cod');
alter table public.orders drop constraint if exists orders_payment_status_check;
alter table public.orders add constraint orders_payment_status_check
  check (payment_status in ('pending_collection', 'collected'));

alter table public.order_events drop constraint if exists order_events_event_type_check;
alter table public.order_events add constraint order_events_event_type_check
  check (event_type in ('status_changed', 'shipping_updated', 'payment_updated'));

-- Launch inventory is manually confirmed by the administrator; checkout does not reserve stock.
update public.products
set is_active = true, updated_at = now()
where slug in (
  'chilli-powder', 'turmeric-powder', 'goda-masala', 'sambar-premix',
  'rasam-premix', 'chicken-masala', 'meat-masala', 'biryani-masala',
  'garlic-podi', 'gunpowder-podi', 'groundnut-chutney-powder'
);

update public.products
set is_active = false, is_featured = false, updated_at = now()
where slug in ('green-chilli', 'shiva', 'suchi');

update public.product_variants v
set is_active = false, track_stock = false, updated_at = now()
from public.products p
where p.id = v.product_id and p.slug in ('green-chilli', 'shiva', 'suchi');

update public.product_variants v
set is_active = false, track_stock = false, updated_at = now()
from public.products p
where p.id = v.product_id
  and p.slug in (
    'chilli-powder', 'turmeric-powder', 'goda-masala', 'sambar-premix',
    'rasam-premix', 'chicken-masala', 'meat-masala', 'biryani-masala',
    'garlic-podi', 'gunpowder-podi', 'groundnut-chutney-powder'
  );

with seed(slug, weight_value, price, display_order) as (
  values
    ('chilli-powder', 100::numeric, 80::numeric, 1),
    ('chilli-powder', 250::numeric, 175::numeric, 2),
    ('chilli-powder', 500::numeric, 330::numeric, 3),
    ('turmeric-powder', 100::numeric, 65::numeric, 1),
    ('turmeric-powder', 250::numeric, 150::numeric, 2),
    ('turmeric-powder', 500::numeric, 280::numeric, 3),
    ('goda-masala', 100::numeric, 110::numeric, 1),
    ('goda-masala', 250::numeric, 255::numeric, 2),
    ('goda-masala', 500::numeric, 490::numeric, 3),
    ('sambar-premix', 100::numeric, 90::numeric, 1),
    ('sambar-premix', 250::numeric, 210::numeric, 2),
    ('sambar-premix', 500::numeric, 400::numeric, 3),
    ('rasam-premix', 100::numeric, 85::numeric, 1),
    ('rasam-premix', 250::numeric, 195::numeric, 2),
    ('rasam-premix', 500::numeric, 375::numeric, 3),
    ('chicken-masala', 100::numeric, 100::numeric, 1),
    ('chicken-masala', 250::numeric, 230::numeric, 2),
    ('chicken-masala', 500::numeric, 445::numeric, 3),
    ('meat-masala', 100::numeric, 110::numeric, 1),
    ('meat-masala', 250::numeric, 255::numeric, 2),
    ('meat-masala', 500::numeric, 490::numeric, 3),
    ('biryani-masala', 100::numeric, 120::numeric, 1),
    ('biryani-masala', 250::numeric, 275::numeric, 2),
    ('biryani-masala', 500::numeric, 530::numeric, 3),
    ('garlic-podi', 100::numeric, 95::numeric, 1),
    ('garlic-podi', 250::numeric, 220::numeric, 2),
    ('garlic-podi', 500::numeric, 420::numeric, 3),
    ('gunpowder-podi', 100::numeric, 90::numeric, 1),
    ('gunpowder-podi', 250::numeric, 205::numeric, 2),
    ('gunpowder-podi', 500::numeric, 395::numeric, 3),
    ('groundnut-chutney-powder', 100::numeric, 80::numeric, 1),
    ('groundnut-chutney-powder', 250::numeric, 185::numeric, 2),
    ('groundnut-chutney-powder', 500::numeric, 350::numeric, 3)
)
insert into public.product_variants (
  product_id, weight_value, weight_unit, price, sale_price,
  track_stock, stock_quantity, is_active, is_demo, display_order
)
select p.id, s.weight_value, 'g', s.price, null, false, 0, true, false, s.display_order
from seed s
join public.products p on p.slug = s.slug
on conflict (product_id, weight_value, weight_unit) do update
set price = excluded.price,
    sale_price = null,
    track_stock = false,
    stock_quantity = 0,
    is_active = true,
    is_demo = false,
    display_order = excluded.display_order,
    updated_at = now();

create or replace function public.create_customer_order(
  p_customer_name text,
  p_customer_phone text,
  p_address_house text,
  p_address_street text,
  p_address_area text,
  p_address_landmark text,
  p_delivery_city text,
  p_delivery_state text,
  p_delivery_pincode text,
  p_delivery_instructions text,
  p_items jsonb,
  p_submission_key uuid,
  p_expected_prices jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_existing_id uuid;
  v_order_id uuid;
  v_created jsonb;
  v_full_address text;
begin
  if p_submission_key is null then
    raise exception 'INVALID_SUBMISSION_KEY: A checkout submission key is required.';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(p_submission_key::text, 0));
  select id into v_existing_id from public.orders where submission_key = p_submission_key;

  if found then
    return public.order_response(v_existing_id) ||
      jsonb_build_object(
        'delivery_house', (select delivery_house from public.orders where id = v_existing_id),
        'delivery_street', (select delivery_street from public.orders where id = v_existing_id),
        'delivery_area', (select delivery_area from public.orders where id = v_existing_id),
        'delivery_landmark', (select delivery_landmark from public.orders where id = v_existing_id),
        'delivery_city', (select delivery_city from public.orders where id = v_existing_id),
        'delivery_state', (select delivery_state from public.orders where id = v_existing_id),
        'delivery_pincode', (select delivery_pincode from public.orders where id = v_existing_id),
        'delivery_instructions', (select delivery_instructions from public.orders where id = v_existing_id),
        'payment_method', (select payment_method from public.orders where id = v_existing_id),
        'payment_status', (select payment_status from public.orders where id = v_existing_id)
      );
  end if;

  if char_length(btrim(coalesce(p_address_house, ''))) < 1 or char_length(btrim(p_address_house)) > 120 then
    raise exception 'INVALID_ADDRESS: Enter a house or flat number.';
  end if;
  if char_length(btrim(coalesce(p_address_street, ''))) < 2 or char_length(btrim(p_address_street)) > 160 then
    raise exception 'INVALID_ADDRESS: Enter a building or street.';
  end if;
  if char_length(btrim(coalesce(p_address_area, ''))) < 2 or char_length(btrim(p_address_area)) > 160 then
    raise exception 'INVALID_ADDRESS: Enter an area or locality.';
  end if;
  if char_length(btrim(coalesce(p_delivery_city, ''))) < 2 or char_length(btrim(p_delivery_city)) > 120 then
    raise exception 'INVALID_ADDRESS: Enter a city.';
  end if;
  if char_length(btrim(coalesce(p_delivery_state, ''))) < 2 or char_length(btrim(p_delivery_state)) > 120 then
    raise exception 'INVALID_ADDRESS: Enter a state.';
  end if;
  if coalesce(p_delivery_pincode, '') !~ '^[1-9][0-9]{5}$' then
    raise exception 'INVALID_PINCODE: Enter a valid six-digit Indian PIN code.';
  end if;
  if char_length(coalesce(p_address_landmark, '')) > 160 then
    raise exception 'INVALID_ADDRESS: Landmark must be 160 characters or fewer.';
  end if;
  if char_length(coalesce(p_delivery_instructions, '')) > 500 then
    raise exception 'INVALID_ADDRESS: Delivery instructions must be 500 characters or fewer.';
  end if;

  v_full_address := concat_ws(E'\n',
    'House / flat: ' || btrim(p_address_house),
    'Building / street: ' || btrim(p_address_street),
    'Area / locality: ' || btrim(p_address_area),
    case when nullif(btrim(coalesce(p_address_landmark, '')), '') is not null then 'Landmark: ' || btrim(p_address_landmark) end,
    'City: ' || btrim(p_delivery_city),
    'State: ' || btrim(p_delivery_state),
    'PIN code: ' || btrim(p_delivery_pincode),
    case when nullif(btrim(coalesce(p_delivery_instructions, '')), '') is not null then 'Delivery instructions: ' || btrim(p_delivery_instructions) end
  );

  v_created := public.create_order(
    p_customer_name, p_customer_phone, v_full_address,
    p_items, p_submission_key, p_expected_prices
  );
  v_order_id := (v_created ->> 'order_id')::uuid;

  update public.orders
  set delivery_house = btrim(p_address_house),
      delivery_street = btrim(p_address_street),
      delivery_area = btrim(p_address_area),
      delivery_landmark = nullif(btrim(coalesce(p_address_landmark, '')), ''),
      delivery_city = btrim(p_delivery_city),
      delivery_state = btrim(p_delivery_state),
      delivery_pincode = btrim(p_delivery_pincode),
      delivery_instructions = nullif(btrim(coalesce(p_delivery_instructions, '')), ''),
      payment_method = 'cod',
      payment_status = 'pending_collection'
  where id = v_order_id;

  return v_created || jsonb_build_object(
    'delivery_house', btrim(p_address_house),
    'delivery_street', btrim(p_address_street),
    'delivery_area', btrim(p_address_area),
    'delivery_landmark', nullif(btrim(coalesce(p_address_landmark, '')), ''),
    'delivery_city', btrim(p_delivery_city),
    'delivery_state', btrim(p_delivery_state),
    'delivery_pincode', btrim(p_delivery_pincode),
    'delivery_instructions', nullif(btrim(coalesce(p_delivery_instructions, '')), ''),
    'delivery_address', v_full_address,
    'payment_method', 'cod',
    'payment_status', 'pending_collection'
  );
end;
$function$;

create or replace function public.admin_update_order_status(
  p_order_id uuid,
  p_status text,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_order public.orders%rowtype;
  v_old_status text;
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
begin
  if not public.is_admin() then raise exception 'NOT_AUTHORISED: Administrator access is required.'; end if;
  if p_status is null or p_status not in ('pending_confirmation', 'confirmed', 'processing', 'dispatched', 'delivered', 'cancelled') then
    raise exception 'INVALID_STATUS: Select a valid order status.';
  end if;
  if p_note is not null and char_length(p_note) > 1000 then raise exception 'INVALID_NOTE: Notes must be 1,000 characters or fewer.'; end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND: The order could not be found.'; end if;
  v_old_status := v_order.status;
  if v_old_status = p_status then return public.order_response(v_order.id); end if;

  if v_old_status = 'pending_confirmation' and p_status = 'confirmed'
     and (v_order.shipping_charge is null or v_order.final_total is null) then
    raise exception 'SHIPPING_REQUIRED: Set the delivery charge (including ₹0 if free) before confirming this order.';
  end if;

  if not (
    (v_old_status = 'pending_confirmation' and p_status in ('confirmed', 'cancelled'))
    or (v_old_status = 'confirmed' and p_status in ('processing', 'cancelled'))
    or (v_old_status = 'processing' and p_status in ('dispatched', 'cancelled'))
    or (v_old_status = 'dispatched' and p_status in ('delivered', 'cancelled'))
  ) then
    raise exception 'INVALID_STATUS_TRANSITION: The order cannot move from % to %.', v_old_status, p_status;
  end if;

  if p_status = 'cancelled' and v_order.stock_restored_at is null then
    update public.product_variants v
    set stock_quantity = v.stock_quantity + oi.quantity
    from public.order_items oi
    where oi.order_id = v_order.id and oi.variant_id = v.id and oi.stock_tracked = true;
    update public.orders set stock_restored_at = now() where id = v_order.id;
  end if;

  update public.orders set status = p_status, admin_note = coalesce(v_note, admin_note) where id = v_order.id;
  insert into public.order_events (order_id, admin_user_id, event_type, old_status, new_status, note)
  values (v_order.id, auth.uid(), 'status_changed', v_old_status, p_status, v_note);
  return public.order_response(v_order.id);
end;
$function$;

create or replace function public.admin_update_payment_status(
  p_order_id uuid,
  p_payment_status text,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_order public.orders%rowtype;
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
begin
  if not public.is_admin() then raise exception 'NOT_AUTHORISED: Administrator access is required.'; end if;
  if p_payment_status <> 'collected' then
    raise exception 'INVALID_PAYMENT_STATUS: Cash collection can only be marked as collected.';
  end if;
  if p_note is not null and char_length(p_note) > 1000 then
    raise exception 'INVALID_NOTE: Notes must be 1,000 characters or fewer.';
  end if;
  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND: The order could not be found.'; end if;
  if v_order.payment_method <> 'cod' then raise exception 'INVALID_PAYMENT_METHOD: This order is not a COD order.'; end if;
  if v_order.status <> 'delivered' then raise exception 'PAYMENT_NOT_DUE: Mark cash as collected only after delivery.'; end if;
  if v_order.payment_status = 'collected' then return public.order_response(v_order.id); end if;

  update public.orders
  set payment_status = 'collected',
      payment_collected_at = now(),
      payment_collected_by = auth.uid(),
      admin_note = coalesce(v_note, admin_note)
  where id = v_order.id;

  insert into public.order_events (order_id, admin_user_id, event_type, old_status, new_status, note)
  values (v_order.id, auth.uid(), 'payment_updated', v_order.status, v_order.status,
    coalesce(v_note, 'Cash on delivery collected.'));
  return public.order_response(v_order.id);
end;
$function$;

revoke all on function public.create_order(text, text, text, jsonb, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.create_customer_order(text, text, text, text, text, text, text, text, text, text, jsonb, uuid, jsonb) from public, anon, authenticated;
grant execute on function public.create_customer_order(text, text, text, text, text, text, text, text, text, text, jsonb, uuid, jsonb) to anon, authenticated;
revoke all on function public.admin_update_order_status(uuid, text, text) from public, anon, authenticated;
grant execute on function public.admin_update_order_status(uuid, text, text) to authenticated;
revoke all on function public.admin_update_payment_status(uuid, text, text) from public, anon, authenticated;
grant execute on function public.admin_update_payment_status(uuid, text, text) to authenticated;
