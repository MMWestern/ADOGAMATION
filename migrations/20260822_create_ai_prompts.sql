create table if not exists ai_prompts (
  id integer primary key default 1,
  prompts jsonb not null default '{}',
  updated_at timestamp with time zone default now()
);

-- single row constraint
alter table ai_prompts add constraint ai_prompts_single_row check (id = 1);

-- seed default row
insert into ai_prompts (id, prompts) values (1, '{}')
  on conflict (id) do nothing;

-- RLS
alter table ai_prompts enable row level security;
create policy "anon all ai_prompts" on ai_prompts
  for all using (true) with check (true);
