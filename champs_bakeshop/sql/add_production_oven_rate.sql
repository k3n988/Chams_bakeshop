alter table public.productions
  add column if not exists oven_rate numeric not null default 15;
