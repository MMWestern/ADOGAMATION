create table if not exists inspector_options (
  id integer primary key default 1,
  options jsonb not null default '{}',
  updated_at timestamp with time zone default now()
);

-- single row constraint
alter table inspector_options add constraint inspector_options_single_row check (id = 1);

-- seed default row
insert into inspector_options (id, options) values (1, '{}')
  on conflict (id) do nothing;

-- RLS
alter table inspector_options enable row level security;
create policy "anon all inspector_options" on inspector_options
  for all using (true) with check (true);
