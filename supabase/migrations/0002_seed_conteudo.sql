-- Conteúdo inicial com os títulos do site atual. hrefs/capas a preencher pela administração.
insert into public.documentos (secao, titulo, descricao, ordem) values
  ('condominio', 'Atas e Relatórios',              'Atas de assembleias e relatórios da gestão.',             1),
  ('condominio', 'Financeiro',                     'Prestação de contas e informações financeiras.',          2),
  ('condominio', 'Administração',                  'Síndico, conselho e equipe administrativa.',              3),
  ('condominio', 'Informações',                    'Horários, normas de uso e orientações gerais.',           4),
  ('condominio', 'PGRS e PGRSS',                   'Planos de gerenciamento de resíduos sólidos e de saúde.', 5),
  ('condominio', 'Lei Geral de Proteção de Dados', 'Como o condomínio trata seus dados pessoais (LGPD).',     6),
  ('condominio', 'Convenção e Regimento',          'Convenção do condomínio e regimento interno.',            7);

insert into public.galeria_albuns (titulo, descricao, ano, tags, capa, ordem) values
  ('Fachada',                 'O Edifício Novo Centro Multiempresarial, no Setor de Rádio e TV Sul.', null, '{Edifício,SRTVS}',     'assets/hero/fachada.jpg', 1),
  ('Centro de Convenções',    'Espaço para eventos, reuniões e convenções.',                           null, '{Eventos,Convenções}', null, 2),
  ('Eventos',                 'Registros dos eventos realizados no condomínio.',                        null, '{Eventos}',            null, 3),
  ('Estacionamento Rotativo', 'Estacionamento rotativo para condôminos e visitantes.',                 null, '{Estacionamento}',     null, 4),
  ('Praça de Alimentação',    'Opções de alimentação dentro do edifício.',                             null, '{Alimentação}',        null, 5),
  ('Simulação de Evacuação',  'Simulado de evacuação realizado com a brigada do edifício.',            2023, '{Segurança,Brigada}',  null, 6);

insert into public.galeria_fotos (album_id, url, ordem)
select id, 'assets/hero/fachada.jpg', 1 from public.galeria_albuns where titulo = 'Fachada';
