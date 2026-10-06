-- Fotos das áreas comuns (enviadas pela administração em out/2026):
-- recepções, centro de convenções, estacionamento rotativo e praça de alimentação.
-- Arquivos em assets/galeria/<álbum>/. Idempotente.

-- Novo álbum: Recepções
insert into public.galeria_albuns (titulo, descricao, tags, ordem)
select 'Recepções', 'Recepção com controle de acesso e as entradas A e B do edifício.', array['Recepção','Acesso'], 2
 where not exists (select 1 from public.galeria_albuns where titulo = 'Recepções');

-- Álbuns com fotos primeiro
update public.galeria_albuns set ordem = 3 where titulo = 'Centro de Convenções';
update public.galeria_albuns set ordem = 4 where titulo = 'Estacionamento Rotativo';
update public.galeria_albuns set ordem = 5 where titulo = 'Praça de Alimentação';
update public.galeria_albuns set ordem = 6 where titulo = 'Eventos';
update public.galeria_albuns set ordem = 7 where titulo = 'Simulação de Evacuação';

update public.galeria_albuns set capa = 'assets/galeria/recepcoes/recepcao-catracas.jpg' where titulo = 'Recepções';
update public.galeria_albuns set capa = 'assets/galeria/convencoes/entrada-espaco-eventos.jpg' where titulo = 'Centro de Convenções';
update public.galeria_albuns set capa = 'assets/galeria/rotativo/area-externa.jpg' where titulo = 'Estacionamento Rotativo';
update public.galeria_albuns set capa = 'assets/galeria/alimentacao/acesso-praca.jpg',
       descricao = 'Praça de alimentação e lojas no térreo do edifício.', tags = array['Alimentação','Lojas']
 where titulo = 'Praça de Alimentação';

-- As duas fotos do estacionamento saem do álbum Fachada e vão para o Rotativo
update public.galeria_fotos g
   set album_id = (select id from public.galeria_albuns where titulo = 'Estacionamento Rotativo'),
       url = replace(g.url, 'assets/galeria/fachada/', 'assets/galeria/rotativo/'),
       ordem = case when g.url like '%area-externa%' then 1 else 2 end
 where g.url in ('assets/galeria/fachada/area-externa.jpg', 'assets/galeria/fachada/embarque-desembarque.jpg');

insert into public.galeria_fotos (album_id, url, legenda, ordem)
select a.id, f.url, f.legenda, f.ordem
  from (values
         ('Recepções',            'assets/galeria/recepcoes/recepcao-catracas.jpg',        'Recepção e controle de acesso',               1),
         ('Recepções',            'assets/galeria/recepcoes/entrada-a.jpg',                'Entrada A',                                   2),
         ('Recepções',            'assets/galeria/recepcoes/entrada-b.jpg',                'Entrada B',                                   3),
         ('Centro de Convenções', 'assets/galeria/convencoes/entrada-espaco-eventos.jpg',  'Entrada do Espaço de Eventos',                1),
         ('Praça de Alimentação', 'assets/galeria/alimentacao/acesso-praca.jpg',           'Acesso à Praça de Alimentação',               1),
         ('Praça de Alimentação', 'assets/galeria/alimentacao/corredor-praca.jpg',         'Corredor de acesso à Praça de Alimentação',   2),
         ('Praça de Alimentação', 'assets/galeria/alimentacao/galeria-lojas.jpg',          'Galeria de lojas do térreo',                  3),
         ('Praça de Alimentação', 'assets/galeria/alimentacao/lojas-terreo.jpg',           'Lojas do térreo',                             4)
       ) as f(album, url, legenda, ordem)
  join public.galeria_albuns a on a.titulo = f.album
 where not exists (select 1 from public.galeria_fotos g where g.url = f.url);
