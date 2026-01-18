/*
  # Criar Tabela de Clientes Afiliados

  1. Nova Tabela
    - `clientes_afiliados`
      - Informações do cliente afiliado
      - Token Wuzapi para envio de mensagens
      - Telefone conectado (JID)
      - Configurações e status
  
  2. Segurança
    - RLS ativo
    - Políticas para usuários autenticados verem apenas seus próprios dados
*/

CREATE TABLE IF NOT EXISTS public.clientes_afiliados (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  nome text,
  email text,
  telefone text,
  wuzapi_token text,
  wuzapi_jid text,
  afiliado_codigo text,
  ativo boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE clientes_afiliados ENABLE ROW LEVEL SECURITY;

-- Políticas
CREATE POLICY "Usuários podem ver seus próprios dados"
  ON clientes_afiliados FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir seus próprios dados"
  ON clientes_afiliados FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar seus próprios dados"
  ON clientes_afiliados FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem deletar seus próprios dados"
  ON clientes_afiliados FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);