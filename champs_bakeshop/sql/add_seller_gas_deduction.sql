alter table public.seller_remittances
  add column if not exists gas_deduction numeric not null default 0;
