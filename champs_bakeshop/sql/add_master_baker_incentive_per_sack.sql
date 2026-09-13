alter table public.products
  add column if not exists master_baker_incentive_per_sack numeric not null default 0;
