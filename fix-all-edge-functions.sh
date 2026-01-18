#!/bin/bash

# Script para corrigir imports antigos em TODAS as edge functions

echo "🔧 Corrigindo imports antigos em edge functions..."

# Encontrar todos os arquivos index.ts
find supabase/functions -name "index.ts" -type f | while read file; do
    echo "  📝 Processando: $file"

    # 1. Remover import do edge-runtime (jsr)
    sed -i '/import "jsr:@supabase\/functions-js\/edge-runtime.d.ts";/d' "$file"

    # 2. Remover import do serve do deno.land
    sed -i '/import { serve } from "https:\/\/deno.land\/std@.*\/http\/server.ts"/d' "$file"

    # 3. Substituir import do supabase esm.sh por npm
    sed -i 's|import { createClient } from "https://esm.sh/@supabase/supabase-js@2"|import { createClient } from "npm:@supabase/supabase-js@2"|g' "$file"

    # 4. Substituir serve( por Deno.serve(
    sed -i 's/^serve(/Deno.serve(/g' "$file"
done

echo "✅ Correção concluída!"
