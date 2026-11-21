-- =====================================================
-- AUVERA Library - Supabase (PostgreSQL) Schema
-- =====================================================

-- 8-digit member numbers (10000001, 10000002, ...)
create sequence if not exists member_no_seq start 10000001;

-- ---------- PROFILES ----------
create table profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  member_no     text unique not null default nextval('member_no_seq')::text,
  full_name     text not null,
  phone         text,
  birthday      date,
  role          text not null default 'customer' check (role in ('customer','admin')),
  tier          text not null default 'bronze'
                check (tier in ('bronze','silver','gold','platinum','vvip')),
  is_vvip       boolean not null default false,
  is_blocked    boolean not null default false,
  books_taken   int not null default 0,
  created_at    timestamptz default now()
);

-- ---------- BOOKS ----------
create table books (
  id            uuid primary key default gen_random_uuid(),
  title         text not null,
  author        text not null,
  category      text,
  language      text default 'si' check (language in ('si','en','ta')),
  description   text,
  cover_url     text,
  status        text not null default 'available'
                check (status in ('available','booked','borrowed')),
  created_at    timestamptz default now()
);
create index on books (status);
create index on books using gin (to_tsvector('simple', title || ' ' || author));

-- ---------- ORDERS ----------
create table orders (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references profiles(id),
  created_at  timestamptz default now()
);

-- ---------- LOANS ----------
create table loans (
  id           uuid primary key default gen_random_uuid(),
  order_id     uuid not null references orders(id) on delete cascade,
  user_id      uuid not null references profiles(id),
  book_id      uuid not null references books(id),
  status       text not null default 'booked'
               check (status in ('booked','picked_up','returned','cancelled')),
  booked_at    timestamptz default now(),
  picked_up_at timestamptz,
  returned_at  timestamptz
);
create index on loans (user_id, status);
create index on loans (book_id, status);

-- ---------- WISHLIST ----------
create table wishlist (
  user_id    uuid references profiles(id) on delete cascade,
  book_id    uuid references books(id) on delete cascade,
  notify_when_available boolean default false,
  primary key (user_id, book_id)
);

-- ---------- ADMIN LOGS ----------
create table admin_logs (
  id         bigserial primary key,
  admin_id   uuid references profiles(id),
  action     text not null,
  target     text,
  details    jsonb,
  created_at timestamptz default now()
);

-- =====================================================
-- FUNCTIONS
-- =====================================================

create or replace function handle_new_user() returns trigger
language plpgsql security definer as $$
begin
  insert into profiles (id, full_name, phone, birthday)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)),
    new.raw_user_meta_data->>'phone',
    nullif(new.raw_user_meta_data->>'birthday','')::date
  );
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

create or replace function calc_tier(n int) returns text
language sql immutable as $$
  select case
    when n >= 30 then 'platinum'
    when n >= 20 then 'gold'
    when n >= 10 then 'silver'
    else 'bronze' end
$$;

create or replace function book_books(p_book_ids uuid[]) returns uuid
language plpgsql security definer as $$
declare
  v_user uuid := auth.uid();
  v_active int;
  v_available int;
  v_order uuid;
begin
  if exists (select 1 from profiles where id = v_user and is_blocked) then
    raise exception 'Account blocked';
  end if;

  select count(*) into v_active from loans
   where user_id = v_user and status in ('booked','picked_up');

  if v_active + array_length(p_book_ids,1) > 5 then
    raise exception 'Limit is 5 books at a time (you hold %)', v_active;
  end if;

  select count(*) into v_available from (
    select id from books
     where id = any(p_book_ids) and status = 'available'
     for update
  ) t;

  if v_available <> array_length(p_book_ids,1) then
    raise exception 'One or more books are no longer available';
  end if;

  insert into orders (user_id) values (v_user) returning id into v_order;
  insert into loans (order_id, user_id, book_id)
    select v_order, v_user, unnest(p_book_ids);
  update books set status = 'booked' where id = any(p_book_ids);

  return v_order;
end $$;

create or replace function on_loan_update() returns trigger
language plpgsql security definer as $$
begin
  if new.status = 'picked_up' then
    update books set status = 'borrowed' where id = new.book_id;
    new.picked_up_at := now();
    update profiles set books_taken = books_taken + 1
     where id = new.user_id;
    update profiles set tier = calc_tier(books_taken)
     where id = new.user_id and not is_vvip;
  elsif new.status in ('returned','cancelled') then
    update books set status = 'available' where id = new.book_id;
    new.returned_at := now();
  end if;
  return new;
end $$;

create trigger loan_status_change
  before update of status on loans
  for each row execute function on_loan_update();

create or replace function set_vvip(p_user uuid, p_on boolean) returns void
language plpgsql security definer as $$
begin
  if not exists (select 1 from profiles where id = auth.uid() and role='admin') then
    raise exception 'Admins only';
  end if;
  update profiles set
    is_vvip = p_on,
    tier = case when p_on then 'vvip' else calc_tier(books_taken) end
  where id = p_user;
  insert into admin_logs (admin_id, action, target)
    values (auth.uid(), case when p_on then 'vvip_granted' else 'vvip_removed' end, p_user::text);
end $$;

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================
alter table profiles   enable row level security;
alter table books      enable row level security;
alter table orders     enable row level security;
alter table loans      enable row level security;
alter table wishlist   enable row level security;
alter table admin_logs enable row level security;

create or replace function is_admin() returns boolean
language sql security definer stable as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin')
$$;

create policy "books read"  on books for select using (true);
create policy "books admin" on books for all using (is_admin()) with check (is_admin());

create policy "profile own"   on profiles for select using (id = auth.uid() or is_admin());
create policy "profile edit"  on profiles for update using (id = auth.uid())
  with check (id = auth.uid() and role = 'customer');
create policy "profile admin" on profiles for all using (is_admin());

create policy "orders own" on orders for select using (user_id = auth.uid() or is_admin());
create policy "loans own"  on loans  for select using (user_id = auth.uid() or is_admin());
create policy "loans admin update" on loans for update using (is_admin());

create policy "wishlist own" on wishlist for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "logs admin" on admin_logs for all using (is_admin());

alter publication supabase_realtime add table books;