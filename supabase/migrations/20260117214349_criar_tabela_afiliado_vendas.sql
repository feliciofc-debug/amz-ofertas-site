/*
  # Criar tabela afiliado_vendas

  1. Nova Tabela
    - `afiliado_vendas`
      - `id` (uuid, primary key)
      - `user_id` (uuid, referência auth.users)
      - `produto_id` (uuid, referência afiliado_produtos, nullable)
      - `valor` (numeric, valor da venda)
      - `comissao` (numeric, valor da comissão, nullable)
      - `marketplace` (text, nome do marketplace)
      - `status` (text, status da venda: pendente, aprovada, cancelada)
      - `data_venda` (timestamptz, data da venda)
      - `data_pagamento` (timestamptz, data do pagamento, nullable)
      - `dados_venda` (jsonb, dados adicionais da venda, nullable)
      - `created_at` (timestamptz, default now())
      - `updated_at` (timestamptz, default now())

  2. Segurança
    - Habilitar RLS
    - Usuários podem ver apenas suas próprias vendas
    - Usuários podem criar vendas
    - Usuários podem atualizar suas próprias vendas
*/

CREATE TABLE IF NOT EXISTS afiliado_vendas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  produto_id uuid REFERENCES afiliado_produtos(id) ON DELETE SET NULL,
  valor numeric NOT NULL DEFAULT 0,
  comissao numeric DEFAULT 0,
  marketplace text NOT NULL,
  status text DEFAULT 'pendente',
  data_venda timestamptz NOT NULL DEFAULT now(),
  data_pagamento timestamptz,
  dados_venda jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE afiliado_vendas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Afiliados podem ver próprias vendas"
  ON afiliado_vendas
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Afiliados podem criar vendas"
  ON afiliado_vendas
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Afiliados podem atualizar próprias vendas"
  ON afiliado_vendas
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_afiliado_vendas_user_id ON afiliado_vendas(user_id);
CREATE INDEX IF NOT EXISTS idx_afiliado_vendas_data_venda ON afiliado_vendas(data_venda);
CREATE INDEX IF NOT EXISTS idx_afiliado_vendas_status ON afiliado_vendas(status);
