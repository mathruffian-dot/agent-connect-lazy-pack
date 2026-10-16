-- 連接懶人包：端到端檢查用的資料表
-- 前端（部署在 Cloudflare Workers 的 hello 頁）用 publishable／anon key 寫入一筆再讀回。
-- anon 只能 insert 與 select，不能 update／delete。

create table if not exists public.connect_check (
  id bigint generated always as identity primary key,
  note text not null check (char_length(note) between 1 and 200),
  created_at timestamptz not null default now()
);

comment on table public.connect_check is '連接懶人包端到端檢查：前端寫入一筆再讀回';

alter table public.connect_check enable row level security;

-- 明確權限：不依賴專案預設 grant
revoke all on table public.connect_check from anon, authenticated;
grant select, insert on table public.connect_check to anon, authenticated;

drop policy if exists "connect_check_insert" on public.connect_check;
create policy "connect_check_insert"
  on public.connect_check
  for insert
  to anon, authenticated
  with check (char_length(note) between 1 and 200);

drop policy if exists "connect_check_select" on public.connect_check;
create policy "connect_check_select"
  on public.connect_check
  for select
  to anon, authenticated
  using (true);

-- 不建立 update／delete policy：在 RLS 下 anon 無法修改或刪除任何資料。
