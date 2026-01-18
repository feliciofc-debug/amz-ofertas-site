/*
  # Criar Tabelas de Campanhas Faltantes

  1. Novas Tabelas
    - `campanhas_recorrentes`
      - Campanhas recorrentes para o sistema principal
      - Configurações de agendamento (frequência, horários, dias)
      - Rastreamento de execuções e status
    
    - `afiliado_campanhas` 
      - Campanhas recorrentes específicas para afiliados
      - Similar a campanhas_recorrentes mas para módulo de afiliados
      - Configurações de agendamento e rastreamento
  
  2. Segurança
    - RLS ativo em ambas tabelas
    - Políticas para usuários autenticados
*/

-- Tabela campanhas_recorrentes
CREATE TABLE IF NOT EXISTS public.campanhas_recorrentes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  vendedor_id uuid,
  produto_id uuid,
  mensagem_template text NOT NULL,
  frequencia text NOT NULL,
  horarios text[] NOT NULL,
  dias_semana integer[],
  data_inicio timestamptz NOT NULL,
  data_fim timestamptz,
  listas_ids text[] NOT NULL,
  categorias text[],
  ativa boolean DEFAULT true,
  proxima_execucao timestamptz,
  ultima_execucao timestamptz,
  total_enviados integer DEFAULT 0,
  status text DEFAULT 'ativa',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabela afiliado_campanhas
CREATE TABLE IF NOT EXISTS public.afiliado_campanhas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  produto_id uuid,
  mensagem_template text NOT NULL,
  frequencia text NOT NULL,
  horarios text[] NOT NULL,
  dias_semana integer[],
  data_inicio timestamptz NOT NULL,
  data_fim timestamptz,
  listas_ids text[],
  categorias text[],
  ativa boolean DEFAULT true,
  proxima_execucao timestamptz,
  ultima_execucao timestamptz,
  total_enviados integer DEFAULT 0,
  status text DEFAULT 'ativa',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE campanhas_recorrentes ENABLE ROW LEVEL SECURITY;
ALTER TABLE afiliado_campanhas ENABLE ROW LEVEL SECURITY;

-- Políticas para campanhas_recorrentes
CREATE POLICY "Usuários podem ver suas próprias campanhas"
  ON campanhas_recorrentes FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem criar suas próprias campanhas"
  ON campanhas_recorrentes FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar suas próprias campanhas"
  ON campanhas_recorrentes FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem deletar suas próprias campanhas"
  ON campanhas_recorrentes FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Políticas para afiliado_campanhas
CREATE POLICY "Afiliados podem ver suas próprias campanhas"
  ON afiliado_campanhas FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Afiliados podem criar suas próprias campanhas"
  ON afiliado_campanhas FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Afiliados podem atualizar suas próprias campanhas"
  ON afiliado_campanhas FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Afiliados podem deletar suas próprias campanhas"
  ON afiliado_campanhas FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);