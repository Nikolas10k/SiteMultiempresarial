-- Painel de administração (/admin): síndico e administração gerenciam o conteúdo do site.
-- Login por usuário + senha: o painel converte "usuario" em "usuario@painel.multiempresarial.com.br"
-- (endereço interno, nunca recebe e-mail). As contas são criadas pela equipe técnica e
-- registradas em public.admins; só quem está nessa tabela pode gravar.

create table if not exists public.admins (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  usuario     text not null unique check (usuario ~ '^[a-z0-9._-]{3,30}$'),
  nome        text not null,
  created_at  timestamptz not null default now()
);
alter table public.admins enable row level security;

create schema if not exists private;
grant usage on schema private to anon, authenticated;

create or replace function private.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.admins where user_id = (select auth.uid()));
$$;
revoke all on function private.is_admin() from public;
grant execute on function private.is_admin() to anon, authenticated;

create policy "administradores veem a equipe" on public.admins
  for select to authenticated using ((select private.is_admin()));
grant select on public.admins to authenticated;

-- Conteúdo do site: administração lê tudo (inclusive não publicado) e grava.
create policy "administração gerencia avisos" on public.avisos
  for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "administração gerencia documentos" on public.documentos
  for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "administração gerencia álbuns" on public.galeria_albuns
  for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "administração gerencia fotos" on public.galeria_fotos
  for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
grant select, insert, update, delete on public.avisos, public.documentos, public.galeria_albuns, public.galeria_fotos to authenticated;

-- Mensagens do formulário: só a administração lê, marca como lida e apaga.
create policy "administração lê mensagens" on public.contatos
  for select to authenticated using ((select private.is_admin()));
create policy "administração marca mensagens" on public.contatos
  for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "administração apaga mensagens" on public.contatos
  for delete to authenticated using ((select private.is_admin()));
grant select, delete on public.contatos to authenticated;
grant update (lido) on public.contatos to authenticated;

-- Arquivos: fotos no bucket "galeria", PDFs no bucket "documentos" (ambos de leitura pública).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('documentos', 'documentos', true, 26214400,
        array['application/pdf','image/jpeg','image/png','application/msword',
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
              'application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'])
on conflict (id) do nothing;
update storage.buckets set file_size_limit = 10485760, allowed_mime_types = array['image/jpeg','image/png','image/webp']
 where id = 'galeria';

create policy "administração lista arquivos" on storage.objects
  for select to authenticated using (bucket_id in ('galeria','documentos') and (select private.is_admin()));
create policy "administração envia arquivos" on storage.objects
  for insert to authenticated with check (bucket_id in ('galeria','documentos') and (select private.is_admin()));
create policy "administração atualiza arquivos" on storage.objects
  for update to authenticated using (bucket_id in ('galeria','documentos') and (select private.is_admin()));
create policy "administração apaga arquivos" on storage.objects
  for delete to authenticated using (bucket_id in ('galeria','documentos') and (select private.is_admin()));
