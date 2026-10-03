-- Site Multiempresarial — schema inicial
-- Conteúdo público (avisos, documentos, galeria) é somente leitura para visitantes.
-- Escrita é feita pela administração via painel do Supabase (service role) por enquanto.
-- Mensagens de contato: visitantes só podem INSERIR; ninguém anônimo lê.

create table public.avisos (
  id          bigint generated always as identity primary key,
  data        date        not null default current_date,
  categoria   text        not null default 'Administração',
  titulo      text        not null check (char_length(titulo) between 1 and 200),
  texto       text        not null,
  urgente     boolean     not null default false,
  link        text,
  publicado   boolean     not null default true,
  created_at  timestamptz not null default now()
);
create index avisos_publicado_data_idx on public.avisos (publicado, data desc);

create table public.documentos (
  id          bigint generated always as identity primary key,
  secao       text        not null check (secao in ('condominio', 'downloads')),
  titulo      text        not null,
  descricao   text,
  href        text,
  ordem       int         not null default 0,
  publicado   boolean     not null default true,
  created_at  timestamptz not null default now()
);
create index documentos_secao_ordem_idx on public.documentos (secao, ordem);

create table public.galeria_albuns (
  id          bigint generated always as identity primary key,
  titulo      text        not null,
  descricao   text,
  ano         int,
  tags        text[]      not null default '{}',
  capa        text,
  ordem       int         not null default 0,
  publicado   boolean     not null default true,
  created_at  timestamptz not null default now()
);

create table public.galeria_fotos (
  id          bigint generated always as identity primary key,
  album_id    bigint      not null references public.galeria_albuns (id) on delete cascade,
  url         text        not null,
  legenda     text,
  ordem       int         not null default 0,
  created_at  timestamptz not null default now()
);
create index galeria_fotos_album_idx on public.galeria_fotos (album_id, ordem);

create table public.contatos (
  id                bigint generated always as identity primary key,
  nome              text        not null check (char_length(nome) between 1 and 120),
  endereco          text        check (char_length(endereco) <= 200),
  email             text        not null check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' and char_length(email) <= 200),
  telefone          text        not null check (char_length(telefone) between 8 and 30),
  assunto           text        not null default 'Outros'
                    check (assunto in ('Administração','Financeiro','Manutenção','Classificados','LGPD / Dados pessoais','Outros')),
  mensagem          text        not null check (char_length(mensagem) between 1 and 4000),
  consentimento_lgpd boolean    not null check (consentimento_lgpd),
  lido              boolean     not null default false,
  created_at        timestamptz not null default now()
);

alter table public.avisos         enable row level security;
alter table public.documentos     enable row level security;
alter table public.galeria_albuns enable row level security;
alter table public.galeria_fotos  enable row level security;
alter table public.contatos       enable row level security;

create policy "avisos publicados são públicos" on public.avisos
  for select to anon, authenticated using (publicado);
create policy "documentos publicados são públicos" on public.documentos
  for select to anon, authenticated using (publicado);
create policy "álbuns publicados são públicos" on public.galeria_albuns
  for select to anon, authenticated using (publicado);
create policy "fotos de álbuns publicados são públicas" on public.galeria_fotos
  for select to anon, authenticated
  using (exists (select 1 from public.galeria_albuns a where a.id = album_id and a.publicado));

create policy "visitantes podem enviar contato" on public.contatos
  for insert to anon, authenticated
  with check (lido = false);

-- Bucket público para as fotos da galeria (upload pela administração)
insert into storage.buckets (id, name, public)
values ('galeria', 'galeria', true)
on conflict (id) do nothing;
