-- Projetos novos não concedem privilégios automáticos ao anon/authenticated; RLS continua filtrando as linhas.
grant usage on schema public to anon, authenticated;
grant select on public.avisos, public.documentos, public.galeria_albuns, public.galeria_fotos to anon, authenticated;
grant insert (nome, endereco, email, telefone, assunto, mensagem, consentimento_lgpd) on public.contatos to anon, authenticated;
