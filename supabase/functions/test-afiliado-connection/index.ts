import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Autenticar
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: 'Não autenticado' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabase.auth.getUser(token)

    if (userError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Usuário inválido', details: userError?.message }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Teste 1: Verificar perfil
    const { data: profile } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .maybeSingle()

    // Teste 2: Verificar se já tem instância
    const { data: instancia } = await supabase
      .from('wuzapi_instancias_afiliados')
      .select('*')
      .eq('afiliado_id', user.id)
      .maybeSingle()

    // Teste 3: Contar instâncias disponíveis
    const { count } = await supabase
      .from('wuzapi_instancias_afiliados')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'disponivel')

    // Teste 4: Pegar primeira instância disponível
    const { data: primeiraDisponivel } = await supabase
      .from('wuzapi_instancias_afiliados')
      .select('*')
      .eq('status', 'disponivel')
      .is('afiliado_id', null)
      .order('numero_instancia')
      .limit(1)
      .maybeSingle()

    return new Response(
      JSON.stringify({
        success: true,
        user: {
          id: user.id,
          email: user.email
        },
        profile: profile ? { id: profile.id, tipo: profile.tipo } : null,
        instancia_atual: instancia ? {
          nome: instancia.nome_instancia,
          status: instancia.status,
          porta: instancia.porta
        } : null,
        instancias_disponiveis: count,
        primeira_disponivel: primeiraDisponivel ? {
          nome: primeiraDisponivel.nome_instancia,
          porta: primeiraDisponivel.porta
        } : null
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error: any) {
    return new Response(
      JSON.stringify({ success: false, error: error.message, stack: error.stack }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
