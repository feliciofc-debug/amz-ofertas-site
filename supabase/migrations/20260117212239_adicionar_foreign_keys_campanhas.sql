/*
  # Adicionar foreign keys para relacionamentos de campanhas
  
  1. Alterações
    - Adicionar FK entre campanhas_recorrentes.produto_id e afiliado_produtos.id
    - Adicionar FK entre afiliado_campanhas.produto_id e afiliado_produtos.id
*/

-- FK para campanhas_recorrentes
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'campanhas_recorrentes_produto_id_fkey'
  ) THEN
    ALTER TABLE campanhas_recorrentes
    ADD CONSTRAINT campanhas_recorrentes_produto_id_fkey
    FOREIGN KEY (produto_id) REFERENCES afiliado_produtos(id) ON DELETE SET NULL;
  END IF;
END $$;

-- FK para afiliado_campanhas
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'afiliado_campanhas_produto_id_fkey'
  ) THEN
    ALTER TABLE afiliado_campanhas
    ADD CONSTRAINT afiliado_campanhas_produto_id_fkey
    FOREIGN KEY (produto_id) REFERENCES afiliado_produtos(id) ON DELETE SET NULL;
  END IF;
END $$;