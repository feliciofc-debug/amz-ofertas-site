/*
  # Atualizar URLs de Webhook - Supabase Novo

  1. Alterações
    - Atualiza webhook_url em wuzapi_instancias_afiliados
    - Muda DEFAULT da coluna para nova URL do Supabase
    - Atualiza registros existentes com URL antiga

  2. URLs
    - Antiga: https://jibpvpqgplmahjhswiza.supabase.co
    - Nova: https://qbtqjrcfseqcfmcqlnqr.supabase.co
*/

-- Atualizar registros existentes com URL antiga
UPDATE wuzapi_instancias_afiliados
SET webhook_url = 'https://qbtqjrcfseqcfmcqlnqr.supabase.co/functions/v1/wuzapi-webhook-afiliados'
WHERE webhook_url = 'https://jibpvpqgplmahjhswiza.supabase.co/functions/v1/wuzapi-webhook-afiliados';

-- Alterar o DEFAULT da coluna para nova URL
ALTER TABLE wuzapi_instancias_afiliados 
ALTER COLUMN webhook_url SET DEFAULT 'https://qbtqjrcfseqcfmcqlnqr.supabase.co/functions/v1/wuzapi-webhook-afiliados';
