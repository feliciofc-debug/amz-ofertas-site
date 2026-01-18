import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  console.log('🚀 [INICIO] criar-instancia-wuzapi-afiliado');

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

    const authHeader = req.headers.get('Authorization') ?? '';
    console.log('🔑 [AUTH] Header presente:', authHeader ? 'SIM' : 'NÃO');

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    });

    console.log('🔍 [AUTH] Verificando usuário...');
    const { data: userData, error: userError } = await supabase.auth.getUser();
    const user = userData?.user;

    if (userError || !user) {
      console.error('❌ [AUTH] Erro ao validar usuário:', userError);
      console.error('❌ [AUTH] User data:', userData);
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Usuário inválido',
          details: userError?.message || 'Sem usuário autenticado'
        }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log('✅ Usuário autenticado:', user.id);

    const body = await req.json();
    const { action } = body;

    console.log('📡 Ação solicitada:', action);

    // ==================== STATUS ====================
    if (action === 'status') {
      console.log('�� Verificando status da instância...');

      const { data: instancia } = await supabase
        .from('wuzapi_instancias_afiliados')
        .select('*')
        .eq('afiliado_id', user.id)
        .maybeSingle();

      if (!instancia) {
        console.log('⚠️ Afiliado não tem instância alocada');
        return new Response(
          JSON.stringify({
            success: true,
            hasInstance: false,
            connected: false
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      console.log('📡 Instância encontrada:', instancia.nome_instancia);

      // Verificar conexão no Wuzapi
      try {
        const WUZAPI_URL = 'https://api2.amzofertas.com.br';
        console.log('🌐 Verificando status em:', WUZAPI_URL);

        const statusRes = await fetch(`${WUZAPI_URL}/session/status`, {
          method: 'GET',
          headers: {
            'Token': instancia.token
          }
        });

        if (!statusRes.ok) {
          console.log('⚠️ Wuzapi retornou erro:', statusRes.status);
          throw new Error(`HTTP ${statusRes.status}`);
        }

        const statusData = await statusRes.json();
        console.log('📊 Status Wuzapi:', statusData);

        const connected = statusData.connected || false;
        const phone = statusData.phone || null;

        return new Response(
          JSON.stringify({
            success: true,
            hasInstance: true,
            connected,
            phone,
            instancia: {
              nome: instancia.nome_instancia,
              token: instancia.token
            }
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );

      } catch (err) {
        console.error('❌ Erro ao verificar status Wuzapi:', err);
        return new Response(
          JSON.stringify({
            success: true,
            hasInstance: true,
            connected: false,
            error: 'Erro ao verificar status',
            instancia: {
              nome: instancia.nome_instancia,
              token: instancia.token
            }
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // ==================== CRIAR INSTÂNCIA ====================
    if (action === 'criar-instancia') {
      console.log('🏗️ Criando/alocando instância...');

      // Verificar se já tem instância
      const { data: existing } = await supabase
        .from('wuzapi_instancias_afiliados')
        .select('*')
        .eq('afiliado_id', user.id)
        .maybeSingle();

      if (existing) {
        console.log('✅ Instância já existe:', existing.nome_instancia);
        return new Response(
          JSON.stringify({
            success: true,
            message: 'Instância já alocada',
            instancia: existing
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Buscar instância disponível
      console.log('🔍 Buscando instância disponível...');
      const { data: available, error: availError } = await supabase
        .from('wuzapi_instancias_afiliados')
        .select('*')
        .eq('status', 'disponivel')
        .is('afiliado_id', null)
        .order('numero_instancia')
        .limit(1)
        .maybeSingle();

      if (availError || !available) {
        console.error('❌ Nenhuma instância disponível');
        return new Response(
          JSON.stringify({
            success: false,
            error: 'Todas as instâncias estão em uso. Tente novamente em alguns minutos.'
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      console.log('🎯 Alocando instância:', available.nome_instancia);

      // Alocar instância
      const { data: allocated, error: allocError } = await supabase
        .from('wuzapi_instancias_afiliados')
        .update({
          afiliado_id: user.id,
          status: 'em_uso',
          data_conexao: new Date().toISOString()
        })
        .eq('id', available.id)
        .select()
        .single();

      if (allocError) {
        console.error('❌ Erro ao alocar instância:', allocError);
        return new Response(
          JSON.stringify({ success: false, error: 'Erro ao alocar instância' }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Registrar no histórico
      await supabase
        .from('wuzapi_afiliados_historico')
        .insert({
          instancia_id: allocated.id,
          afiliado_id: user.id,
          data_inicio: new Date().toISOString()
        });

      console.log('✅ Instância alocada com sucesso!');

      return new Response(
        JSON.stringify({
          success: true,
          message: 'Instância alocada com sucesso!',
          instancia: allocated
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ==================== CONECTAR (Gerar QR Code) ====================
    if (action === 'conectar') {
      console.log('🔌 Gerando QR Code...');

      const { data: instancia } = await supabase
        .from('wuzapi_instancias_afiliados')
        .select('*')
        .eq('afiliado_id', user.id)
        .maybeSingle();

      if (!instancia) {
        console.error('❌ Afiliado não tem instância');
        return new Response(
          JSON.stringify({ success: false, error: 'Você não tem uma instância alocada' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      const WUZAPI_URL = 'https://api2.amzofertas.com.br';
      console.log('🌐 Wuzapi URL:', WUZAPI_URL);

      try {
        // 1. Forçar logout
        console.log('🔄 Forçando logout...');
        try {
          await fetch(`${WUZAPI_URL}/session/logout`, {
            method: 'GET',
            headers: {
              'Token': instancia.token
            }
          });
        } catch (e) {
          console.log('⚠️ Logout falhou (normal se não estava conectado)');
        }

        // Aguardar um pouco
        await new Promise(resolve => setTimeout(resolve, 1000));

        // 2. Gerar QR Code
        console.log('📷 Gerando QR Code...');
        const qrRes = await fetch(`${WUZAPI_URL}/session/qr/image`, {
          method: 'GET',
          headers: {
            'Token': instancia.token
          }
        });

        if (!qrRes.ok) {
          console.error('❌ Erro HTTP:', qrRes.status);
          throw new Error(`HTTP ${qrRes.status}: ${await qrRes.text()}`);
        }

        const qrBlob = await qrRes.blob();
        const arrayBuffer = await qrBlob.arrayBuffer();
        const bytes = new Uint8Array(arrayBuffer);

        let binary = '';
        for (let i = 0; i < bytes.length; i++) {
          binary += String.fromCharCode(bytes[i]);
        }

        const qrBase64 = btoa(binary);

        console.log('✅ QR Code gerado! Tamanho:', qrBase64.length);

        return new Response(
          JSON.stringify({
            success: true,
            qrCode: qrBase64,
            message: 'Escaneie o QR Code com o WhatsApp'
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );

      } catch (err) {
        console.error('❌ Erro ao gerar QR:', err);
        return new Response(
          JSON.stringify({
            success: false,
            error: 'Erro ao conectar com servidor WhatsApp',
            details: err instanceof Error ? err.message : String(err)
          }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // ==================== DESCONECTAR ====================
    if (action === 'desconectar') {
      console.log('🔌 Desconectando WhatsApp...');

      const { data: instancia } = await supabase
        .from('wuzapi_instancias_afiliados')
        .select('*')
        .eq('afiliado_id', user.id)
        .maybeSingle();

      if (!instancia) {
        return new Response(
          JSON.stringify({ success: false, error: 'Instância não encontrada' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      const WUZAPI_URL = 'https://api2.amzofertas.com.br';

      try {
        await fetch(`${WUZAPI_URL}/session/logout`, {
          method: 'GET',
          headers: {
            'Token': instancia.token
          }
        });

        await supabase
          .from('wuzapi_instancias_afiliados')
          .update({ telefone_conectado: null })
          .eq('id', instancia.id);

        console.log('✅ WhatsApp desconectado');

        return new Response(
          JSON.stringify({ success: true, message: 'WhatsApp desconectado com sucesso' }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );

      } catch (err) {
        console.error('❌ Erro ao desconectar:', err);
        return new Response(
          JSON.stringify({ success: false, error: 'Erro ao desconectar' }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // Ação inválida
    return new Response(
      JSON.stringify({ success: false, error: 'Ação inválida' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error('💥 ERRO CRÍTICO:', err);
    return new Response(
      JSON.stringify({
        success: false,
        error: 'Erro interno do servidor',
        details: err instanceof Error ? err.message : String(err)
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
