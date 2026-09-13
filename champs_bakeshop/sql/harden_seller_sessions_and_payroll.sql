-- Run after add_seller_gas_deduction.sql.
-- These constraints make seller sessions and remittances safe against
-- duplicate submissions and invalid values.

create unique index if not exists seller_sessions_one_type_per_day_idx
  on public.seller_sessions (seller_id, date, session_type);

create unique index if not exists seller_remittances_one_per_session_idx
  on public.seller_remittances (session_id);

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'seller_sessions_valid_type') then
    alter table public.seller_sessions
      add constraint seller_sessions_valid_type
      check (session_type in ('morning', 'afternoon'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'seller_sessions_nonnegative_counts') then
    alter table public.seller_sessions
      add constraint seller_sessions_nonnegative_counts
      check (plantsa_count >= 0 and subra_pieces >= 0 and plantsa_count + subra_pieces > 0);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'seller_remittances_valid_amounts') then
    alter table public.seller_remittances
      add constraint seller_remittances_valid_amounts
      check (
        return_pieces >= 0 and
        return_pieces <= total_pieces_taken and
        actual_remittance >= 0 and
        total_pieces_taken >= 0 and
        expected_remittance >= 0 and
        salary >= 0 and
        gas_deduction >= 0
      );
  end if;
end $$;

create table if not exists public.seller_payroll_payments (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  paid_at timestamptz not null default now(),
  paid_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (seller_id, date)
);

create index if not exists seller_payroll_payments_date_idx
  on public.seller_payroll_payments (date);
