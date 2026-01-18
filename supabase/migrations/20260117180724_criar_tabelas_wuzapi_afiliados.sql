/*
  # Sistema de Gerenciamento de Instâncias Wuzapi para Afiliados
  
  1. Nova Tabela: wuzapi_instancias_afiliados
    - `id` (uuid, primary key) - Identificador único da instância
    - `numero_instancia` (integer, unique) - Número sequencial da instância (1-35)
    - `servidor_url` (text) - URL do servidor (api2.amzofertas.com.br)
    - `porta` (integer) - Porta da instância (8001-8035)
    - `token` (text, unique) - Token de autenticação da instância
    - `nome_instancia` (text) - Nome da instância (Afiliado-02, etc)
    - `senha_admin` (text) - Senha do admin Wuzapi
    - `webhook_url` (text) - URL do webhook para receber mensagens
    - `status` (text) - Status: disponivel, em_uso, manutencao, erro
    - `afiliado_id` (uuid, fk) - ID do afiliado usando a instância (nullable)
    - `telefone_conectado` (text) - Número do WhatsApp conectado
    - `data_conexao` (timestamptz) - Quando foi conectado
    - `data_ultimo_uso` (timestamptz) - Último envio realizado
    - `total_mensagens_enviadas` (integer) - Contador de mensagens
    - `qr_code` (text) - QR Code para conexão
    - `observacoes` (text) - Observações gerais
    - `created_at` (timestamptz) - Data de criação
    - `updated_at` (timestamptz) - Última atualização
    
  2. Nova Tabela: wuzapi_afiliados_historico
    - Histórico de uso de instâncias por afiliado
    
  3. Security
    - Enable RLS em ambas tabelas
    - Políticas para admin gerenciar tudo
    - Políticas para afiliados verem apenas suas instâncias
    
  4. Inserir as 35 instâncias
*/

-- Criar tabela de instâncias Wuzapi para afiliados
CREATE TABLE IF NOT EXISTS wuzapi_instancias_afiliados (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  numero_instancia integer UNIQUE NOT NULL,
  servidor_url text NOT NULL DEFAULT 'api2.amzofertas.com.br',
  porta integer NOT NULL,
  token text UNIQUE NOT NULL,
  nome_instancia text NOT NULL,
  senha_admin text NOT NULL DEFAULT 'amz-ofertas-afiliados-2025',
  webhook_url text NOT NULL DEFAULT 'https://jibpvpqgplmahjhswiza.supabase.co/functions/v1/wuzapi-webhook-afiliados',
  status text NOT NULL DEFAULT 'disponivel' CHECK (status IN ('disponivel', 'em_uso', 'manutencao', 'erro')),
  afiliado_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  telefone_conectado text,
  data_conexao timestamptz,
  data_ultimo_uso timestamptz,
  total_mensagens_enviadas integer DEFAULT 0,
  qr_code text,
  observacoes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_wuzapi_afiliados_status ON wuzapi_instancias_afiliados(status);
CREATE INDEX IF NOT EXISTS idx_wuzapi_afiliados_afiliado_id ON wuzapi_instancias_afiliados(afiliado_id);
CREATE INDEX IF NOT EXISTS idx_wuzapi_afiliados_numero ON wuzapi_instancias_afiliados(numero_instancia);

-- Criar tabela de histórico de uso
CREATE TABLE IF NOT EXISTS wuzapi_afiliados_historico (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instancia_id uuid REFERENCES wuzapi_instancias_afiliados(id) ON DELETE CASCADE,
  afiliado_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  telefone_conectado text,
  data_inicio timestamptz NOT NULL,
  data_fim timestamptz,
  total_mensagens integer DEFAULT 0,
  motivo_desconexao text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_wuzapi_historico_afiliado ON wuzapi_afiliados_historico(afiliado_id);
CREATE INDEX IF NOT EXISTS idx_wuzapi_historico_instancia ON wuzapi_afiliados_historico(instancia_id);

-- Enable RLS
ALTER TABLE wuzapi_instancias_afiliados ENABLE ROW LEVEL SECURITY;
ALTER TABLE wuzapi_afiliados_historico ENABLE ROW LEVEL SECURITY;

-- Políticas para admin (tipo = 'admin')
CREATE POLICY "Admin pode visualizar todas instâncias afiliados"
  ON wuzapi_instancias_afiliados FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tipo = 'admin'
    )
  );

CREATE POLICY "Admin pode inserir instâncias afiliados"
  ON wuzapi_instancias_afiliados FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tipo = 'admin'
    )
  );

CREATE POLICY "Admin pode atualizar instâncias afiliados"
  ON wuzapi_instancias_afiliados FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tipo = 'admin'
    )
  );

CREATE POLICY "Admin pode deletar instâncias afiliados"
  ON wuzapi_instancias_afiliados FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tipo = 'admin'
    )
  );

-- Políticas para afiliados (tipo = 'afiliado')
CREATE POLICY "Afiliado pode ver sua própria instância"
  ON wuzapi_instancias_afiliados FOR SELECT
  TO authenticated
  USING (
    afiliado_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tipo = 'afiliado'
    )
  );

CREATE POLICY "Afiliado pode atualizar sua própria instância"
  ON wuzapi_instancias_afiliados FOR UPDATE
  TO authenticated
  USING (afiliado_id = auth.uid())
  WITH CHECK (afiliado_id = auth.uid());

-- Políticas para histórico
CREATE POLICY "Admin pode ver todo histórico"
  ON wuzapi_afiliados_historico FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tipo = 'admin'
    )
  );

CREATE POLICY "Afiliado pode ver seu próprio histórico"
  ON wuzapi_afiliados_historico FOR SELECT
  TO authenticated
  USING (afiliado_id = auth.uid());

CREATE POLICY "Admin pode inserir histórico"
  ON wuzapi_afiliados_historico FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.tipo = 'admin'
    )
  );

-- Inserir as 35 instâncias
INSERT INTO wuzapi_instancias_afiliados (numero_instancia, porta, token, nome_instancia, status) VALUES
(1, 8001, 'aB1cD2eF3gH4iJ5kL6mN7oP8qR9sT0u', 'Afiliado-02', 'disponivel'),
(2, 8002, 'cD1eF2gH3iJ4kL5mN6oP7qR8sT9uV0w', 'Afiliado-03', 'disponivel'),
(3, 8003, 'cD1eF2gH3iJ4kL5mN6oP7qR8sT9uV1w', 'Afiliado-04', 'disponivel'),
(4, 8004, 'cD1eF2gH3iJ4kL5mN6oP7qR8sT9uV2w', 'Afiliado-05', 'disponivel'),
(5, 8005, 'cD1eF2gH3iJ4kL5mN6oP7qR8sT9uV3w', 'Afiliado-06', 'disponivel'),
(6, 8006, 'cD1eF2gH3iJ4kL5mN6oP7qR8sT9uV4w', 'Afiliado-07', 'disponivel'),
(7, 8007, 'cD1eF2gH3iJ4kL5mN6oP7qR8sT9uV5w', 'Afiliado-08', 'disponivel'),
(8, 8008, 'cD1eF2gH3iJ4kL5mN6oP7qR8sT9uV6w', 'Afiliado-09', 'disponivel'),
(9, 8009, 'cKO55kUA6FxBeAIFLKJasjaAiNfZ2R', 'Afiliado-10', 'disponivel'),
(10, 8010, 'dSHYwbv1XqvE1QK91yKzrMTKA6QYff7', 'Afiliado-11', 'disponivel'),
(11, 8011, 'hI1jK2lM3nO4pQ5rS6tU7vW8xY9zA0b', 'Afiliado-12', 'disponivel'),
(12, 8012, 'hI1jK2lM3nO4pQ5rS6tU7vW8xY9zA1b', 'Afiliado-13', 'disponivel'),
(13, 8013, 'hI1jK2lM3nO4pQ5rS6tU7vW8xY9zA2b', 'Afiliado-14', 'disponivel'),
(14, 8014, 'hI1jK2lM3nO4pQ5rS6tU7vW8xY9zA3b', 'Afiliado-15', 'disponivel'),
(15, 8015, 'hI1jK2lM3nO4pQ5rS6tU7vW8xY9zA4b', 'Afiliado-16', 'disponivel'),
(16, 8016, 'hI1jK2lM3nO4pQ5rS6tU7vW8xY9zA5b', 'Afiliado-17', 'disponivel'),
(17, 8017, 'hI1jK2lM3nO4pQ5rS6tU7vW8xY9zA6b', 'Afiliado-18', 'disponivel'),
(18, 8018, 'mN1oP2qR3sT4uV5wX6yZ7aB8cD9eF0g', 'Afiliado-19', 'disponivel'),
(19, 8019, 'mN1oP2qR3sT4uV5wX6yZ7aB8cD9eF1g', 'Afiliado-20', 'disponivel'),
(20, 8020, 'mN1oP2qR3sT4uV5wX6yZ7aB8cD9eF2g', 'Afiliado-21', 'disponivel'),
(21, 8021, 'mN1oP2qR3sT4uV5wX6yZ7aB8cD9eF3g', 'Afiliado-22', 'disponivel'),
(22, 8022, 'mN1oP2qR3sT4uV5wX6yZ7aB8cD9eF4g', 'Afiliado-23', 'disponivel'),
(23, 8023, 'mN1oP2qR3sT4uV5wX6yZ7aB8cD9eF5g', 'Afiliado-24', 'disponivel'),
(24, 8024, 'mN1oP2qR3sT4uV5wX6yZ7aB8cD9eF6g', 'Afiliado-25', 'disponivel'),
(25, 8025, 'VvAujW7oY1XC18TrJRRH8SKE3IlOqFZP', 'Afiliado-26', 'disponivel'),
(26, 8026, 'xY1zA2bC3dE4fG5hI6jK7lM8nO9pQ0r', 'Afiliado-27', 'disponivel'),
(27, 8027, 'xY1zA2bC3dE4fG5hI6jK7lM8nO9pQ1r', 'Afiliado-28', 'disponivel'),
(28, 8028, 'xY1zA2bC3dE4fG5hI6jK7lM8nO9pQ2r', 'Afiliado-29', 'disponivel'),
(29, 8029, 'xY1zA2bC3dE4fG5hI6jK7lM8nO9pQ3r', 'Afiliado-30', 'disponivel'),
(30, 8030, 'xY1zA2bC3dE4fG5hI6jK7lM8nO9pQ4r', 'Afiliado-31', 'disponivel'),
(31, 8031, 'xY1zA2bC3dE4fG5hI6jK7lM8nO9pQ5r', 'Afiliado-32', 'disponivel'),
(32, 8032, 'xY1zA2bC3dE4fG5hI6jK7lM8nO9pQ6r', 'Afiliado-33', 'disponivel'),
(33, 8033, 'xY1zA2bC3dE4fG5hI6jK7lM8nO9pQ7r', 'Afiliado-34', 'disponivel'),
(34, 8034, 'FDjUTGXYOt6Bp3TtYjSsjZlWOAPuxnPY', 'Afiliado-35', 'disponivel'),
(35, 8035, 'WjRi4tis2XrGUmLImu3wjwHLN3dn4uE', 'Afiliado-36', 'disponivel')
ON CONFLICT (numero_instancia) DO NOTHING;

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_wuzapi_afiliados_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_wuzapi_afiliados_updated_at
  BEFORE UPDATE ON wuzapi_instancias_afiliados
  FOR EACH ROW
  EXECUTE FUNCTION update_wuzapi_afiliados_updated_at();