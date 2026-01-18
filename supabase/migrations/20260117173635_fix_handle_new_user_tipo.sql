/*
  # Corrigir trigger handle_new_user para incluir campo tipo
  
  1. Alterações
    - Atualiza função handle_new_user para extrair o campo 'tipo' dos metadados do usuário
    - Garante que o tipo seja definido corretamente no cadastro (afiliado, b2b, etc)
  
  2. Segurança
    - Mantém RLS existente
    - Função SECURITY DEFINER para garantir execução
*/

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO public.profiles (
    id, 
    nome, 
    whatsapp, 
    cpf,
    tipo,
    amazon_id,
    hotmart_email,
    shopee_id,
    lomadee_id
  )
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'nome', ''),
    COALESCE(new.raw_user_meta_data->>'whatsapp', ''),
    COALESCE(new.raw_user_meta_data->>'cpf', ''),
    COALESCE(new.raw_user_meta_data->>'tipo', 'b2b'),
    COALESCE(new.raw_user_meta_data->>'amazon_id', ''),
    COALESCE(new.raw_user_meta_data->>'hotmart_email', ''),
    COALESCE(new.raw_user_meta_data->>'shopee_id', ''),
    COALESCE(new.raw_user_meta_data->>'lomadee_id', '')
  );
  RETURN new;
END;
$$;
