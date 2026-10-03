-- Contas + assinatura mensal (R$ 49,90) para anunciar.
-- Um anúncio só é público quando: aprovado pela administração E o dono tem assinatura ativa.
-- Até o provedor de pagamento ser integrado, a administração ativa a assinatura pelo painel
-- (status = 'ativa', periodo_fim = data de vencimento).

-- ---------- assinaturas ----------
create table public.assinaturas (
  user_id       uuid primary key references auth.users (id) on delete cascade,
  status        text        not null default 'pendente' check (status in ('pendente','ativa','atrasada','cancelada')),
  valor         numeric(10,2) not null default 49.90,
  provedor      text,
  provedor_ref  text,
  periodo_fim   timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
alter table public.assinaturas enable row level security;
create policy "usuário vê a própria assinatura" on public.assinaturas
  for select to authenticated using (user_id = (select auth.uid()));
grant select on public.assinaturas to authenticated;

-- Função interna (schema não exposto pela API) usada nas políticas de RLS.
create schema if not exists private;
grant usage on schema private to anon, authenticated;
create or replace function private.assinatura_ativa(uid uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.assinaturas a
    where a.user_id = uid and a.status = 'ativa'
      and (a.periodo_fim is null or a.periodo_fim >= now())
  );
$$;
revoke all on function private.assinatura_ativa(uuid) from public;
grant execute on function private.assinatura_ativa(uuid) to anon, authenticated;

-- Usuário logado solicita a assinatura (fica 'pendente' até o pagamento ser confirmado).
create or replace function public.solicitar_assinatura()
returns text language plpgsql security definer set search_path = '' as $$
declare uid uuid := auth.uid(); st text;
begin
  if uid is null then raise exception 'não autenticado'; end if;
  insert into public.assinaturas (user_id, status) values (uid, 'pendente')
  on conflict (user_id) do update
    set status = 'pendente', updated_at = now()
    where public.assinaturas.status in ('cancelada','atrasada');
  select status into st from public.assinaturas where user_id = uid;
  return st;
end $$;
revoke all on function public.solicitar_assinatura() from public, anon;
grant execute on function public.solicitar_assinatura() to authenticated;

-- ---------- anuncios: agora pertencem a uma conta ----------
drop policy if exists "visitantes podem enviar anúncio para aprovação" on public.anuncios;
drop policy if exists "anúncios aprovados e válidos são públicos" on public.anuncios;
revoke insert on public.anuncios from anon;

alter table public.anuncios
  add column user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  add column updated_at timestamptz not null default now(),
  alter column expira_em drop not null,
  alter column expira_em drop default;
create index anuncios_user_idx on public.anuncios (user_id);

create policy "anúncios publicados são públicos" on public.anuncios
  for select to anon, authenticated
  using (status = 'aprovado' and (expira_em is null or expira_em >= current_date) and private.assinatura_ativa(user_id));
create policy "dono vê os próprios anúncios" on public.anuncios
  for select to authenticated using (user_id = (select auth.uid()));
create policy "dono cria anúncio pendente" on public.anuncios
  for insert to authenticated with check (user_id = (select auth.uid()) and status = 'pendente');
create policy "dono edita os próprios anúncios" on public.anuncios
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "dono apaga os próprios anúncios" on public.anuncios
  for delete to authenticated using (user_id = (select auth.uid()));

grant select (status, user_id, updated_at) on public.anuncios to authenticated;
grant update (tipo, titulo, descricao, sala, area_m2, valor, contato_nome, contato_telefone, contato_email)
  on public.anuncios to authenticated;
grant delete on public.anuncios to authenticated;

-- Qualquer edição feita pelo dono volta o anúncio para nova aprovação.
create or replace function private.anuncio_reaprovar()
returns trigger language plpgsql set search_path = '' as $$
begin
  if current_user = 'authenticated' then
    new.status := 'pendente';
  end if;
  new.updated_at := now();
  return new;
end $$;
create trigger anuncios_reaprovar before update on public.anuncios
  for each row execute function private.anuncio_reaprovar();
