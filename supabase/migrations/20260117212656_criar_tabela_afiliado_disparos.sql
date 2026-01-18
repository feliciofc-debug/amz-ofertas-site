/*
  # Criar tabela afiliado_disparos e adicionar coluna status
  
  1. Novas Tabelas
    - `afiliado_disparos` - Disparos/envios agendados de afiliados
    
  2. Alterações
    - Adicionar coluna `status` em `clientes_afiliados`
    
  3. Segurança
    - RLS habilitado
    - Políticas de acesso baseadas em user_id
*/

-- Tabela afiliado_disparos
CREATE TABLE IF NOT EXISTS afiliado_disparos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  campanha_id uuid,
  produto_id uuid REFERENCES afiliado_produtos(id) ON DELETE SET NULL,
  titulo text NOT NULL,
  mensagem text NOT NULL,
  grupos_ids text[],
  data_agendamento timestamptz NOT NULL,
  status text DEFAULT 'agendado',
  total_grupos int DEFAULT 0,
  total_enviados int DEFAULT 0,
  total_erros int DEFAULT 0,
  data_execucao timestamptz,
  log_execucao jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE afiliado_disparos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own disparos"
  ON afiliado_disparos FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own disparos"
  ON afiliado_disparos FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own disparos"
  ON afiliado_disparos FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own disparos"
  ON afiliado_disparos FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Adicionar coluna status em clientes_afiliados
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'clientes_afiliados' AND column_name = 'status'
  ) THEN
    ALTER TABLE clientes_afiliados ADD COLUMN status text DEFAULT 'ativo';
  END IF;
END $$;

-- Índices
CREATE INDEX IF NOT EXISTS idx_afiliado_disparos_user_id ON afiliado_disparos(user_id);
CREATE INDEX IF NOT EXISTS idx_afiliado_disparos_status ON afiliado_disparos(status);
CREATE INDEX IF NOT EXISTS idx_afiliado_disparos_data_agendamento ON afiliado_disparos(data_agendamento);