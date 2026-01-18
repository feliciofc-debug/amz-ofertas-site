/*
  # Criar tabelas e colunas faltantes para sistema de afiliados
  
  1. Novas Tabelas
    - `integrations` - Integrações de redes sociais (TikTok, etc)
    - `whatsapp_grupos_afiliado` - Grupos do WhatsApp do afiliado
    - `leads_ebooks` - Leads que baixaram ebooks
    - `programacao_envio_afiliado` - Programação de envios automáticos
    
  2. Alterações
    - Adicionar coluna `nome` em `afiliado_campanhas`
    - Adicionar coluna `nome_assistente` em `clientes_afiliados`
    
  3. Segurança
    - RLS habilitado em todas as tabelas
    - Políticas de acesso baseadas em user_id
*/

-- Tabela integrations
CREATE TABLE IF NOT EXISTS integrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  platform text NOT NULL,
  access_token text,
  refresh_token text,
  token_expires_at timestamptz,
  metadata jsonb DEFAULT '{}'::jsonb,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE integrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own integrations"
  ON integrations FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own integrations"
  ON integrations FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own integrations"
  ON integrations FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own integrations"
  ON integrations FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Tabela whatsapp_grupos_afiliado
CREATE TABLE IF NOT EXISTS whatsapp_grupos_afiliado (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  group_jid text NOT NULL,
  group_name text NOT NULL,
  member_count int DEFAULT 0,
  categoria text,
  is_announce boolean DEFAULT false,
  ativo boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE whatsapp_grupos_afiliado ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own groups"
  ON whatsapp_grupos_afiliado FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own groups"
  ON whatsapp_grupos_afiliado FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own groups"
  ON whatsapp_grupos_afiliado FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own groups"
  ON whatsapp_grupos_afiliado FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Tabela leads_ebooks
CREATE TABLE IF NOT EXISTS leads_ebooks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  phone text NOT NULL,
  nome text,
  categorias text[],
  ebook_baixado text,
  origem text DEFAULT 'opt-in',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE leads_ebooks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own ebook leads"
  ON leads_ebooks FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own ebook leads"
  ON leads_ebooks FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Tabela programacao_envio_afiliado
CREATE TABLE IF NOT EXISTS programacao_envio_afiliado (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nome text NOT NULL,
  tipo_envio text NOT NULL DEFAULT 'automatico',
  intervalo_minutos int DEFAULT 60,
  horario_inicio time,
  horario_fim time,
  dias_semana int[],
  categorias text[],
  mensagem_template text,
  variar_mensagens boolean DEFAULT true,
  ativo boolean DEFAULT false,
  ultimo_envio timestamptz,
  proximo_envio timestamptz,
  total_enviados int DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE programacao_envio_afiliado ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own scheduled sends"
  ON programacao_envio_afiliado FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own scheduled sends"
  ON programacao_envio_afiliado FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own scheduled sends"
  ON programacao_envio_afiliado FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own scheduled sends"
  ON programacao_envio_afiliado FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Adicionar coluna nome em afiliado_campanhas
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'afiliado_campanhas' AND column_name = 'nome'
  ) THEN
    ALTER TABLE afiliado_campanhas ADD COLUMN nome text;
  END IF;
END $$;

-- Adicionar coluna nome_assistente em clientes_afiliados
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'clientes_afiliados' AND column_name = 'nome_assistente'
  ) THEN
    ALTER TABLE clientes_afiliados ADD COLUMN nome_assistente text DEFAULT 'Pietro';
  END IF;
END $$;

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_integrations_user_id ON integrations(user_id);
CREATE INDEX IF NOT EXISTS idx_integrations_platform ON integrations(platform);
CREATE INDEX IF NOT EXISTS idx_whatsapp_grupos_user_id ON whatsapp_grupos_afiliado(user_id);
CREATE INDEX IF NOT EXISTS idx_leads_ebooks_user_id ON leads_ebooks(user_id);
CREATE INDEX IF NOT EXISTS idx_leads_ebooks_phone ON leads_ebooks(phone);
CREATE INDEX IF NOT EXISTS idx_programacao_envio_user_id ON programacao_envio_afiliado(user_id);
CREATE INDEX IF NOT EXISTS idx_programacao_envio_ativo ON programacao_envio_afiliado(ativo);