-- Bio d’Ivoire — base des commandes (Supabase / PostgreSQL)
-- À exécuter une seule fois dans le tableau de bord Supabase : SQL Editor > New query > coller > Run.
-- Toutes les tables commencent par « bio_ » pour pouvoir cohabiter avec un autre projet dans la même base.

create table if not exists public.bio_orders (
  id           bigint generated always as identity primary key,
  ref          text not null unique check (ref ~ '^BI-[A-Z0-9]{6}$'),
  client_nom   text not null check (char_length(client_nom) between 1 and 80),
  telephone    text not null check (telephone ~ '^[0-9+ .-]{8,20}$'),
  lat          double precision not null check (lat between -90 and 90),
  lng          double precision not null check (lng between -180 and 180),
  precision_m  integer,
  distance_km  numeric(6,1),
  repere       text check (repere is null or char_length(repere) <= 300),
  articles     jsonb not null check (jsonb_typeof(articles) = 'array' and jsonb_array_length(articles) between 1 and 100),
  sous_total   integer not null check (sous_total >= 0),
  livraison    integer check (livraison is null or livraison >= 0),
  total        integer not null check (total >= 0),
  statut       text not null default 'nouvelle' check (statut in ('nouvelle', 'preparation', 'livraison', 'livree', 'annulee')),
  created_at   timestamptz not null default now()
);
create index if not exists bio_orders_created_idx on public.bio_orders (created_at desc);

-- Liste des comptes autorisés à voir et gérer les commandes.
create table if not exists public.bio_admins (
  user_id uuid primary key references auth.users (id) on delete cascade
);

alter table public.bio_orders enable row level security;
alter table public.bio_admins enable row level security;

create or replace function public.bio_is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.bio_admins where user_id = auth.uid());
$$;

-- Tout visiteur peut déposer une commande, mais ne peut ni lire ni modifier les commandes.
drop policy if exists "bio: déposer une commande" on public.bio_orders;
create policy "bio: déposer une commande" on public.bio_orders
  for insert to anon, authenticated with check (statut = 'nouvelle');

-- Seuls les administrateurs lisent et mettent à jour les commandes.
drop policy if exists "bio: admin lit" on public.bio_orders;
create policy "bio: admin lit" on public.bio_orders
  for select to authenticated using (public.bio_is_admin());

drop policy if exists "bio: admin met à jour" on public.bio_orders;
create policy "bio: admin met à jour" on public.bio_orders
  for update to authenticated using (public.bio_is_admin()) with check (public.bio_is_admin());

drop policy if exists "bio: admin se voit" on public.bio_admins;
create policy "bio: admin se voit" on public.bio_admins
  for select to authenticated using (user_id = auth.uid());

grant insert on public.bio_orders to anon, authenticated;
grant select, update on public.bio_orders to authenticated;
grant select on public.bio_admins to authenticated;

-- Suivi de commande pour le client : ne renvoie que le statut, la date et le total d'un numéro donné.
create or replace function public.bio_track(p_ref text)
returns table (ref text, statut text, created_at timestamptz, total integer)
language sql stable security definer set search_path = public as $$
  select o.ref, o.statut, o.created_at, o.total from public.bio_orders o where o.ref = upper(p_ref);
$$;
grant execute on function public.bio_track(text) to anon, authenticated;

-- Notifications en temps réel dans l'espace administrateur.
do $$ begin
  alter publication supabase_realtime add table public.bio_orders;
exception when duplicate_object then null; end $$;

-- Dernière étape, après avoir créé le compte administrateur depuis admin.html
-- (remplacer l'adresse par celle du compte) :
-- insert into public.bio_admins (user_id) select id from auth.users where email = 'ADRESSE@EXEMPLE.COM' on conflict do nothing;
