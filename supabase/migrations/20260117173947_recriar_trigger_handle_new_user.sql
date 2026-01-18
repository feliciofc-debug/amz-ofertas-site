/*
  # Recriar trigger on_auth_user_created
  
  1. Alterações
    - Remove e recria o trigger na tabela auth.users
    - Garante que o trigger dispare AFTER INSERT na tabela auth.users
    - Chama a função handle_new_user que já existe
  
  2. Segurança
    - Mantém RLS existente
*/

-- Remover trigger se existir
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Recriar trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
