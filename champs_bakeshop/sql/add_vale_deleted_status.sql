alter table public.vale_entries
add column if not exists is_deleted boolean not null default false;

update public.vale_entries
set is_deleted = false
where is_deleted is null;
