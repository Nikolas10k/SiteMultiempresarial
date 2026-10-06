-- As duas fotos do embarque/desembarque externo (em frente à fachada) voltam para o
-- álbum Fachada; o Rotativo fica só com a garagem. Idempotente.

update public.galeria_fotos
   set album_id = (select id from public.galeria_albuns where titulo = 'Fachada'),
       url = replace(url, 'assets/galeria/rotativo/', 'assets/galeria/fachada/'),
       ordem = case when url like '%embarque%' then 5 else 6 end,
       legenda = case when url like '%embarque%' then 'Embarque e desembarque em frente à fachada'
                      else 'Área externa de embarque e desembarque' end
 where url in ('assets/galeria/rotativo/area-externa.jpg', 'assets/galeria/rotativo/embarque-desembarque.jpg');

update public.galeria_fotos set ordem = 5 where url = 'assets/galeria/rotativo/tabela-precos.jpg';
