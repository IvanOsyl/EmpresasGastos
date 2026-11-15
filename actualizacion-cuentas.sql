-- ===== ACTUALIZACIÓN: cuentas separadas por empresa =====
-- Córrelo UNA vez en tu Supabase actual (SQL Editor > New query > Run) ANTES de publicar el nuevo index.html.
-- No borra nada: los movimientos que ya existen quedan en la cuenta 'principal'.

alter table public.expenses add column if not exists cuenta text not null default 'principal'
  check (cuenta ~ '^[a-z0-9_-]{1,30}$');
drop index if exists public.expenses_user_date;
create index if not exists expenses_user_cuenta_date on public.expenses (user_id, cuenta, spent_on);

alter table public.empresas add column if not exists cuentas jsonb;

drop function if exists public.get_balance();
create or replace function public.get_balance(p_cuenta text default 'principal')
returns table (balance numeric, movimientos bigint)
language sql stable security invoker set search_path = public
as $$
  select coalesce(sum(case when kind = 'ingreso' then amount else -amount end), 0) as balance,
         count(*) as movimientos
  from public.expenses
  where user_id = (select auth.uid()) and cuenta = p_cuenta;
$$;
grant execute on function public.get_balance(text) to authenticated;
