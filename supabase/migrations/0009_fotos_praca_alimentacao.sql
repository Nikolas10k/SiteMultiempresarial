-- Fotos internas da Praça de Alimentação (out/2026), com rostos desfocados. Idempotente.

update public.galeria_albuns set capa = 'assets/galeria/alimentacao/pilares-tempero.jpg'
 where titulo = 'Praça de Alimentação';

update public.galeria_fotos
   set ordem = case url when 'assets/galeria/alimentacao/acesso-praca.jpg' then 6
                        when 'assets/galeria/alimentacao/corredor-praca.jpg' then 7
                        when 'assets/galeria/alimentacao/galeria-lojas.jpg' then 8 else 9 end
 where url in ('assets/galeria/alimentacao/acesso-praca.jpg', 'assets/galeria/alimentacao/corredor-praca.jpg',
               'assets/galeria/alimentacao/galeria-lojas.jpg', 'assets/galeria/alimentacao/lojas-terreo.jpg');

insert into public.galeria_fotos (album_id, url, legenda, ordem)
select a.id, f.url, f.legenda, f.ordem
  from (values
         ('assets/galeria/alimentacao/pilares-tempero.jpg',  'Praça de Alimentação',   1),
         ('assets/galeria/alimentacao/salao-mesas.jpg',      'Salão de mesas',         2),
         ('assets/galeria/alimentacao/mesas-nazareth.jpg',   'Mesas e cafeteria',      3),
         ('assets/galeria/alimentacao/pilares-nazareth.jpg', 'Restaurantes da praça',  4),
         ('assets/galeria/alimentacao/corredor-acesso.jpg',  'Corredor de acesso',     5)
       ) as f(url, legenda, ordem)
  join public.galeria_albuns a on a.titulo = 'Praça de Alimentação'
 where not exists (select 1 from public.galeria_fotos g where g.url = f.url);
