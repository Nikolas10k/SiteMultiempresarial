-- Fotos da garagem do Estacionamento Rotativo (out/2026). Placas de veículos e
-- rostos de pessoas foram desfocados em todas as fotos da galeria. Idempotente.

update public.galeria_albuns
   set capa = 'assets/galeria/rotativo/garagem-h.jpg',
       descricao = 'Estacionamento rotativo coberto, com vagas preferenciais.'
 where titulo = 'Estacionamento Rotativo';

update public.galeria_fotos
   set ordem = case url when 'assets/galeria/rotativo/area-externa.jpg' then 5 else 6 end
 where url in ('assets/galeria/rotativo/area-externa.jpg', 'assets/galeria/rotativo/embarque-desembarque.jpg');

insert into public.galeria_fotos (album_id, url, legenda, ordem)
select a.id, f.url, f.legenda, f.ordem
  from (values
         ('assets/galeria/rotativo/garagem-h.jpg',         'Garagem coberta',                              1),
         ('assets/galeria/rotativo/garagem-e.jpg',         'Vagas do setor E',                             2),
         ('assets/galeria/rotativo/vagas-pcd.jpg',         'Vagas preferenciais (PcD)',                    3),
         ('assets/galeria/rotativo/garagem-corredor.jpg',  'Corredor da garagem',                          4),
         ('assets/galeria/rotativo/tabela-precos.jpg',     'Tabela de preços e horário de funcionamento',  7)
       ) as f(url, legenda, ordem)
  join public.galeria_albuns a on a.titulo = 'Estacionamento Rotativo'
 where not exists (select 1 from public.galeria_fotos g where g.url = f.url);
