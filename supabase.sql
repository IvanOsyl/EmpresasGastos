-- ===== Gastos del negocio — configuración completa =====
-- Proyecto de Supabase NUEVO (separado de la app personal).
-- Pega todo en Supabase > SQL Editor > New query y dale Run. Se puede volver a correr sin romper nada.

-- ---------- Movimientos (gastos e ingresos) ----------
create table if not exists public.expenses (
  id         bigint generated always as identity primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  kind       text not null default 'gasto' check (kind in ('gasto','ingreso')),
  amount     numeric(12,2) not null check (amount > 0),
  category   text not null check (char_length(category) between 1 and 60),
  note       text not null default '' check (char_length(note) <= 120),
  spent_on   date not null default current_date,
  created_at timestamptz not null default now()
);
create index if not exists expenses_user_date on public.expenses (user_id, spent_on);

-- Cada empresa solo ve, crea, edita y borra SUS movimientos
alter table public.expenses enable row level security;

drop policy if exists "ver mis gastos"    on public.expenses;
drop policy if exists "crear mis gastos"  on public.expenses;
drop policy if exists "editar mis gastos" on public.expenses;
drop policy if exists "borrar mis gastos" on public.expenses;
create policy "ver mis gastos" on public.expenses
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "crear mis gastos" on public.expenses
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "editar mis gastos" on public.expenses
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "borrar mis gastos" on public.expenses
  for delete to authenticated using ((select auth.uid()) = user_id);

-- Saldo de la empresa actual: ingresos - gastos (respeta la seguridad: cada uno suma lo suyo)
create or replace function public.get_balance()
returns table (balance numeric, movimientos bigint)
language sql stable security invoker set search_path = public
as $$
  select coalesce(sum(case when kind = 'ingreso' then amount else -amount end), 0) as balance,
         count(*) as movimientos
  from public.expenses
  where user_id = (select auth.uid());
$$;
grant execute on function public.get_balance() to authenticated;

-- ---------- Comentarios de los clientes (los lees en Table Editor > feedback) ----------
create table if not exists public.feedback (
  id         bigint generated always as identity primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  message    text not null check (char_length(message) between 1 and 4000),
  created_at timestamptz not null default now()
);
alter table public.feedback enable row level security;

drop policy if exists "enviar comentario"   on public.feedback;
drop policy if exists "ver mis comentarios" on public.feedback;
create policy "enviar comentario" on public.feedback
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "ver mis comentarios" on public.feedback
  for select to authenticated using ((select auth.uid()) = user_id);

-- ---------- Empresas: marca de cada cliente (1 usuario = 1 empresa) ----------
create table if not exists public.empresas (
  user_id          uuid primary key references auth.users(id) on delete cascade,
  nombre           text not null check (char_length(nombre) between 1 and 60),
  logo_url         text,                                                  -- URL pública del logo (bucket "logos")
  color_principal  text check (color_principal ~ '^#[0-9a-fA-F]{6}$'),    -- ej: #14532d
  color_acento     text check (color_acento    ~ '^#[0-9a-fA-F]{6}$'),    -- botones, ej: #f59e0b
  cat_gastos       text[],                                                -- opcional: categorías propias
  cat_ingresos     text[],                                                -- opcional: categorías propias
  created_at       timestamptz not null default now()
);

-- La empresa solo puede LEER su configuración. Crearla/editarla lo haces tú desde el panel.
alter table public.empresas enable row level security;
drop policy if exists "ver mi empresa" on public.empresas;
create policy "ver mi empresa" on public.empresas
  for select to authenticated using ((select auth.uid()) = user_id);

-- Bucket público para los logos (súbelos en Storage > logos)
insert into storage.buckets (id, name, public)
values ('logos', 'logos', true)
on conflict (id) do nothing;


-- ===== DAR DE ALTA UNA EMPRESA (repite por cada cliente) =====
-- 1) Authentication > Users > Add user: correo + contraseña (marca "Auto confirm").
-- 2) Storage > logos > Upload: el logo (PNG o SVG cuadrado, ~256x256). Copia su URL con "Get URL".
-- 3) Cambia los valores de abajo, quita los "--" y dale Run:
--
-- insert into public.empresas (user_id, nombre, logo_url, color_principal, color_acento, cat_gastos, cat_ingresos)
-- select id,
--        'Bodega Don Pepe',
--        'https://TU-PROYECTO.supabase.co/storage/v1/object/public/logos/bodega-don-pepe.png',
--        '#14532d',
--        '#f59e0b',
--        array['Mercadería','Alquiler','Luz y agua','Sueldos','Transporte','Otros'],
--        array['Ventas','Delivery','Otros']
-- from auth.users where email = 'cliente@correo.com'
-- on conflict (user_id) do update set
--   nombre = excluded.nombre, logo_url = excluded.logo_url,
--   color_principal = excluded.color_principal, color_acento = excluded.color_acento,
--   cat_gastos = excluded.cat_gastos, cat_ingresos = excluded.cat_ingresos;
--
-- Si cat_gastos / cat_ingresos van en null se usan las categorías por defecto.
-- Si un usuario no tiene fila en "empresas", ve la app genérica sin logo.
