-- Fotos novas do álbum "Fachada" (enviadas pela administração em out/2026).
-- Os arquivos ficam no próprio site, em assets/galeria/fachada/.
-- Idempotente: troca a foto antiga pela vista frontal e só insere o que falta.

update public.galeria_albuns
   set capa = 'assets/galeria/fachada/fachada-frontal.jpg'
 where titulo = 'Fachada';

update public.galeria_fotos
   set url = 'assets/galeria/fachada/fachada-frontal.jpg', legenda = 'Vista frontal do edifício', ordem = 1
 where album_id = (select id from public.galeria_albuns where titulo = 'Fachada')
   and url = 'assets/hero/fachada.jpg';

insert into public.galeria_fotos (album_id, url, legenda, ordem)
select a.id, f.url, f.legenda, f.ordem
  from public.galeria_albuns a,
       (values
         ('assets/galeria/fachada/fachada-frontal.jpg',       'Vista frontal do edifício',                 1),
         ('assets/galeria/fachada/fachada-arvores.jpg',       'Fachada vista do canteiro',                 2),
         ('assets/galeria/fachada/placa-bloco-o.jpg',         'Placa de identificação — Bloco O',          3),
         ('assets/galeria/fachada/entrada-acesso.jpg',        'Acesso de veículos e marquise de entrada',  4),
         ('assets/galeria/fachada/embarque-desembarque.jpg',  'Área de embarque e desembarque',            5),
         ('assets/galeria/fachada/area-externa.jpg',          'Área externa em frente à entrada',          6)
       ) as f(url, legenda, ordem)
 where a.titulo = 'Fachada'
   and not exists (select 1 from public.galeria_fotos g where g.album_id = a.id and g.url = f.url);
