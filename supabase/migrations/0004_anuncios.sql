-- Classificados dos condôminos.
-- Qualquer visitante pode ENVIAR um anúncio (entra como 'pendente').
-- Só anúncios 'aprovado' e dentro da validade aparecem no site.
-- A administração aprova/rejeita pelo painel do Supabase (coluna status).

create table public.anuncios (
  id                bigint generated always as identity primary key,
  tipo              text        not null check (tipo in ('Venda','Locação','Serviço','Outros')),
  titulo            text        not null check (char_length(titulo) between 3 and 120),
  descricao         text        not null check (char_length(descricao) between 10 and 2000),
  sala              text        check (char_length(sala) <= 40),
  area_m2           numeric(8,2) check (area_m2 is null or (area_m2 > 0 and area_m2 < 100000)),
  valor             numeric(12,2) check (valor is null or (valor >= 0 and valor < 1000000000)),
  contato_nome      text        not null check (char_length(contato_nome) between 2 and 120),
  contato_telefone  text        not null check (char_length(contato_telefone) between 8 and 30),
  contato_email     text        check (contato_email is null or (contato_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' and char_length(contato_email) <= 200)),
  consentimento_lgpd boolean    not null check (consentimento_lgpd),
  status            text        not null default 'pendente' check (status in ('pendente','aprovado','rejeitado')),
  expira_em         date        not null default (current_date + 60),
  created_at        timestamptz not null default now()
);
create index anuncios_publicos_idx on public.anuncios (status, expira_em, created_at desc);

alter table public.anuncios enable row level security;

create policy "anúncios aprovados e válidos são públicos" on public.anuncios
  for select to anon, authenticated
  using (status = 'aprovado' and expira_em >= current_date);

create policy "visitantes podem enviar anúncio para aprovação" on public.anuncios
  for insert to anon, authenticated
  with check (status = 'pendente' and expira_em <= current_date + 60);

-- Leitura pública só das colunas exibidas; status/consentimento ficam internos.
grant select (id, tipo, titulo, descricao, sala, area_m2, valor, contato_nome, contato_telefone, contato_email, expira_em, created_at)
  on public.anuncios to anon, authenticated;
grant insert (tipo, titulo, descricao, sala, area_m2, valor, contato_nome, contato_telefone, contato_email, consentimento_lgpd)
  on public.anuncios to anon, authenticated;
