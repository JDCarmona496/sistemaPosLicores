-- ============================================================================
-- MIGRACIÓN: Tablas de conteo de billetes y monedas
-- Fecha: 2026-08-08
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA: CASH_COUNTS
-- ----------------------------------------------------------------------------
create table if not exists public.cash_counts (
  id uuid primary key default uuid_generate_v4(),
  shift_id uuid not null references public.shifts(id) on delete restrict,
  responsible_user_id uuid not null references public.profiles(id) on delete restrict,
  responsible_name text,
  total numeric(12,2) not null default 0,
  total_bills numeric(12,2) not null default 0,
  total_coins numeric(12,2) not null default 0,
  notes text,
  created_at timestamptz not null default now()
);

comment on table public.cash_counts is 'Conteos físicos de efectivo por turno';

create index if not exists idx_cash_counts_shift on public.cash_counts(shift_id);
create index if not exists idx_cash_counts_user on public.cash_counts(responsible_user_id);
create index if not exists idx_cash_counts_date on public.cash_counts(created_at desc);

-- ----------------------------------------------------------------------------
-- TABLA: CASH_COUNT_DENOMINATIONS
-- ----------------------------------------------------------------------------
create table if not exists public.cash_count_denominations (
  id uuid primary key default uuid_generate_v4(),
  cash_count_id uuid not null references public.cash_counts(id) on delete cascade,
  value integer not null,
  type text not null check (type in ('bill', 'coin')),
  quantity integer not null default 0,
  subtotal numeric(12,2) not null default 0
);

comment on table public.cash_count_denominations is 'Detalle de cantidad por denominación';

create index if not exists idx_cash_count_denominations_count on public.cash_count_denominations(cash_count_id);

-- ----------------------------------------------------------------------------
-- RLS
-- ----------------------------------------------------------------------------
alter table public.cash_counts enable row level security;
alter table public.cash_count_denominations enable row level security;

drop policy if exists "Usuarios ven sus propios conteos, admins ven todos" on public.cash_counts;
create policy "Usuarios ven sus propios conteos, admins ven todos" on public.cash_counts
  for select using (
    private.is_admin() or auth.uid() = responsible_user_id
  );

drop policy if exists "Usuarios crean sus propios conteos" on public.cash_counts;
create policy "Usuarios crean sus propios conteos" on public.cash_counts
  for insert with check (
    auth.uid() = responsible_user_id
  );

drop policy if exists "Solo admins editan/eliminan conteos" on public.cash_counts;
create policy "Solo admins editan/eliminan conteos" on public.cash_counts
  for update using (private.is_admin());

drop policy if exists "Detalle visible si el conteo es visible" on public.cash_count_denominations;
create policy "Detalle visible si el conteo es visible" on public.cash_count_denominations
  for select using (
    exists (
      select 1 from public.cash_counts c
      where c.id = cash_count_id
      and (private.is_admin() or auth.uid() = c.responsible_user_id)
    )
  );

drop policy if exists "Cualquier usuario inserta detalle de sus conteos" on public.cash_count_denominations;
create policy "Cualquier usuario inserta detalle de sus conteos" on public.cash_count_denominations
  for insert with check (
    exists (
      select 1 from public.cash_counts c
      where c.id = cash_count_id
      and auth.uid() = c.responsible_user_id
    )
  );
