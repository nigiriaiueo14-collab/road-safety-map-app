create table if not exists public.hazards (
  id text primary key default gen_random_uuid()::text,
  place text not null default '投稿された場所',
  type text not null check (type in ('凸凹', '段差', '舗装はがれ', '急な坂', '狭い道')),
  level text not null check (level in ('low', 'medium', 'high')),
  note text not null check (char_length(trim(note)) between 1 and 500),
  lat double precision not null check (lat between 34.02 and 34.58),
  lng double precision not null check (lng between 133.43 and 134.45),
  targets text[] not null default array['wheelchair']::text[],
  created_by uuid default auth.uid() references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.hazards enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'hazards' and policyname = 'hazards_select_authenticated') then
    execute 'create policy "hazards_select_authenticated" on public.hazards for select to authenticated using (true)';
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'hazards' and policyname = 'hazards_insert_authenticated') then
    execute 'create policy "hazards_insert_authenticated" on public.hazards for insert to authenticated with check (created_by = auth.uid())';
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'hazards' and policyname = 'hazards_delete_admin') then
    execute 'create policy "hazards_delete_admin" on public.hazards for delete to authenticated using ((auth.jwt() ->> ''email'') = ''nigiriaiueo14@gmail.com'')';
  end if;
end $$;

grant select, insert, delete on public.hazards to authenticated;

insert into public.hazards (id, place, type, level, note, lat, lng, targets, created_by)
values
  ('h1', '高松駅前の歩道', '段差', 'high', '駅前広場から横断歩道へ向かう部分に段差があります。', 34.3506, 134.0467, array['wheelchair', 'stroller'], null),
  ('h2', '丸亀駅周辺', '凸凹', 'medium', '歩道の一部に古い舗装の盛り上がりがあります。', 34.2919, 133.7931, array['wheelchair', 'stroller'], null),
  ('h3', '坂出駅前通り', '舗装はがれ', 'medium', '雨の日は水たまりになり、穴が見えにくいです。', 34.3129, 133.8569, array['wheelchair', 'stroller'], null),
  ('h4', '観音寺市中心部', '狭い道', 'low', '時間帯によって人通りが多く、通りにくくなります。', 34.1275, 133.6614, array['wheelchair'], null),
  ('h5', 'さぬき市志度駅付近', '急な坂', 'medium', '駅から住宅地へ向かう道に傾斜があります。', 34.3214, 134.1735, array['wheelchair'], null),
  ('h6', '土庄港周辺', '段差', 'medium', '港の近くに小さな段差が続く場所があります。', 34.4862, 134.1856, array['wheelchair', 'stroller'], null)
on conflict (id) do nothing;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'hazards'
  ) then
    alter publication supabase_realtime add table public.hazards;
  end if;
end $$;
