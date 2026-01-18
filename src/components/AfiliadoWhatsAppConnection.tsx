import { useState, useEffect, useRef } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Loader2, Smartphone, QrCode, CheckCircle, XCircle, RefreshCw, LogOut } from 'lucide-react'
import { supabase } from '@/integrations/supabase/client'
import { toast } from 'sonner'

interface ConnectionStatus {
  connected: boolean
  jid?: string
  phone?: string
}

export default function AfiliadoWhatsAppConnection() {
  const [loading, setLoading] = useState(true)
  const [connecting, setConnecting] = useState(false)
  const [status, setStatus] = useState<ConnectionStatus>({ connected: false })
  const [qrCode, setQrCode] = useState<string | null>(null)
  const [hasInstance, setHasInstance] = useState(false)
  const [polling, setPolling] = useState(false)

  const prevConnected = useRef<boolean>(false)
  const lastDisconnectAlertAt = useRef<number>(0)

  useEffect(() => {
    checkStatus()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Polling rápido apenas enquanto o QR estiver na tela
  useEffect(() => {
    let interval: NodeJS.Timeout
    if (polling && qrCode) {
      interval = setInterval(() => {
        checkStatus()
      }, 3000)
    }
    return () => {
      if (interval) clearInterval(interval)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [polling, qrCode])

  // Monitoramento contínuo quando estiver conectado (alerta se cair)
  useEffect(() => {
    let interval: NodeJS.Timeout | undefined

    if (status.connected) {
      interval = setInterval(() => {
        checkStatus(true)
      }, 15000)
    }

    return () => {
      if (interval) clearInterval(interval)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [status.connected])

  const checkStatus = async (silent: boolean = false) => {
    try {
      console.log('🔍 [Frontend] Verificando status...')

      const { data: { session } } = await supabase.auth.getSession()
      if (!session) {
        console.error('❌ [Frontend] Sem sessão ativa')
        toast.error('Sessão expirada. Faça login novamente.')
        return
      }

      console.log('✅ [Frontend] Sessão existe:', {
        userId: session.user?.id,
        tokenExists: !!session.access_token,
        tokenPreview: session.access_token?.substring(0, 20) + '...'
      })

      const { data, error } = await supabase.functions.invoke('criar-instancia-wuzapi-afiliado', {
        body: { action: 'status' },
        headers: {
          Authorization: `Bearer ${session.access_token}`
        }
      })

      console.log('📊 [Frontend] Resposta status:', { data, error })

      if (error) {
        console.error('❌ [Frontend] Erro na função:', error)
        throw error
      }

      const isConnected = Boolean(data?.connected)

      if (isConnected) {
        setStatus({
          connected: true,
          jid: data.jid,
          phone: data.phone
        })
        setQrCode(null)
        setPolling(false)
        setHasInstance(true)
      } else {
        setStatus({ connected: false })
        // Se o erro é "Sem instância", então NÃO tem instância
        // Caso contrário (success: true mas connected: false), tem instância desconectada
        if (data?.error === 'Sem instância') {
          setHasInstance(false)
        } else if (data?.success === true) {
          setHasInstance(true)
        }
      }

      // ALERTA: caiu a conexão (evita spam)
      if (prevConnected.current && !isConnected) {
        const now = Date.now()
        if (now - lastDisconnectAlertAt.current > 20000) {
          lastDisconnectAlertAt.current = now
          if (!silent) {
            toast.error('⚠️ WhatsApp desconectou! Reconecte aqui nesta tela.')
          } else {
            toast.error('⚠️ WhatsApp desconectou! Reconecte em Conectar Celular.')
          }
        }
      }

      prevConnected.current = isConnected
    } catch (error) {
      console.error('Erro ao verificar status:', error)
    } finally {
      setLoading(false)
    }
  }

  const createInstance = async () => {
    setConnecting(true)
    try {
      console.log('🔨 [Frontend] Criando instância...')

      const { data: { session } } = await supabase.auth.getSession()
      if (!session) {
        toast.error('Sessão expirada. Faça login novamente.')
        return
      }

      const { data: { user } } = await supabase.auth.getUser()
      if (!user) {
        toast.error('Usuário não autenticado')
        return
      }

      console.log('👤 [Frontend] Usuário:', user.id)

      const payload = {
        action: 'criar-instancia',
        nome: user.user_metadata?.nome || user.email?.split('@')[0],
        email: user.email,
        telefone: ''
      }

      console.log('📤 [Frontend] Enviando payload:', payload)

      const { data, error } = await supabase.functions.invoke('criar-instancia-wuzapi-afiliado', {
        body: payload,
        headers: {
          Authorization: `Bearer ${session.access_token}`
        }
      })

      console.log('📥 [Frontend] Resposta:', { data, error })

      if (error) {
        console.error('❌ [Frontend] Erro da função:', error)
        // Mostrar erro mais detalhado
        toast.error(`Erro: ${error.message || JSON.stringify(error)}`)
        throw error
      }

      if (data.success) {
        toast.success('Instância criada! Agora conecte seu WhatsApp.')
        setHasInstance(true)
        await handleConnect()
      } else {
        console.error('❌ [Frontend] Erro no data:', data)
        toast.error(data.error || data.details || 'Erro ao criar instância')
      }
    } catch (error: any) {
      console.error('💥 [Frontend] Exception:', error)
      toast.error(error.message || 'Erro ao criar instância')
    } finally {
      setConnecting(false)
    }
  }

  const handleConnect = async () => {
    setConnecting(true)
    try {
      console.log('🔌 [Frontend] Conectando WhatsApp...')

      const { data: { session } } = await supabase.auth.getSession()
      if (!session) {
        toast.error('Sessão expirada. Faça login novamente.')
        return
      }

      const { data, error } = await supabase.functions.invoke('criar-instancia-wuzapi-afiliado', {
        body: { action: 'conectar' },
        headers: {
          Authorization: `Bearer ${session.access_token}`
        }
      })

      console.log('📥 [Frontend] Resposta conectar:', { data, error })

      if (error) {
        console.error('❌ [Frontend] Erro ao conectar:', error)
        toast.error(`Erro: ${error.message || JSON.stringify(error)}`)
        throw error
      }

      if (data.qrCode) {
        console.log('✅ [Frontend] QR Code recebido!')
        setQrCode(data.qrCode)
        setPolling(true)
        toast.info('Escaneie o QR Code com seu WhatsApp')
      } else {
        console.error('❌ [Frontend] QR Code não disponível:', data)
        toast.error(data.message || 'QR Code não disponível. Tente novamente.')
      }
    } catch (error: any) {
      console.error('💥 [Frontend] Exception ao conectar:', error)
      toast.error(error.message || 'Erro ao conectar')
    } finally {
      setConnecting(false)
    }
  }

  const handleDisconnect = async () => {
    setConnecting(true)
    try {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) {
        toast.error('Sessão expirada. Faça login novamente.')
        return
      }

      const { data, error } = await supabase.functions.invoke('criar-instancia-wuzapi-afiliado', {
        body: { action: 'desconectar' },
        headers: {
          Authorization: `Bearer ${session.access_token}`
        }
      })

      if (error) throw error

      setStatus({ connected: false })
      setQrCode(null)
      toast.success('WhatsApp desconectado')
    } catch (error: any) {
      console.error('Erro:', error)
      toast.error(error.message || 'Erro ao desconectar')
    } finally {
      setConnecting(false)
    }
  }

  const formatPhone = (phone?: string) => {
    if (!phone) return ''
    const clean = phone.replace(/\D/g, '')
    if (clean.length === 13) {
      return `+${clean.slice(0, 2)} (${clean.slice(2, 4)}) ${clean.slice(4, 9)}-${clean.slice(9)}`
    }
    return phone
  }

  if (loading) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center py-12">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="flex items-center gap-2">
              <Smartphone className="h-5 w-5" />
              WhatsApp Único - Pietro + Grupos
            </CardTitle>
            <CardDescription>
              Uma única conexão para assistente IA e grupos
            </CardDescription>
          </div>
          <Badge variant={status.connected ? 'default' : 'secondary'}>
            {status.connected ? (
              <><CheckCircle className="h-3 w-3 mr-1" /> Conectado</>
            ) : (
              <><XCircle className="h-3 w-3 mr-1" /> Desconectado</>
            )}
          </Badge>
        </div>
      </CardHeader>

      <CardContent className="space-y-4">
        {status.connected ? (
          <div className="space-y-4">
            <div className="bg-green-500/10 border border-green-500/20 rounded-lg p-4">
              <div className="flex items-center gap-3">
                <CheckCircle className="h-8 w-8 text-green-500" />
                <div>
                  <p className="font-medium text-green-700 dark:text-green-400">
                    WhatsApp Conectado
                  </p>
                  <p className="text-sm text-muted-foreground">
                    {formatPhone(status.phone)}
                  </p>
                </div>
              </div>
            </div>

            <div className="flex gap-2">
              <Button 
                variant="outline" 
                onClick={() => checkStatus(false)}
                disabled={connecting}
              >
                <RefreshCw className="h-4 w-4 mr-2" />
                Atualizar Status
              </Button>
              <Button 
                variant="destructive" 
                onClick={handleDisconnect}
                disabled={connecting}
              >
                <LogOut className="h-4 w-4 mr-2" />
                Desconectar
              </Button>
            </div>
          </div>
        ) : qrCode ? (
          <div className="space-y-4">
            <div className="flex flex-col items-center gap-4 p-4 bg-muted/50 rounded-lg">
              <p className="text-sm text-muted-foreground text-center">
                Escaneie o QR Code abaixo com seu WhatsApp
              </p>
              <div className="bg-white p-4 rounded-lg shadow-sm">
                <img 
                  src={`data:image/png;base64,${qrCode}`} 
                  alt="QR Code WhatsApp" 
                  className="w-64 h-64"
                />
              </div>
              <p className="text-xs text-muted-foreground">
                O QR Code expira em ~60 segundos
              </p>
            </div>

            <div className="flex gap-2">
              <Button 
                variant="outline" 
                onClick={handleConnect}
                disabled={connecting}
              >
                <RefreshCw className="h-4 w-4 mr-2" />
                Novo QR Code
              </Button>
              <Button 
                variant="ghost" 
                onClick={() => { setQrCode(null); setPolling(false) }}
              >
                Cancelar
              </Button>
            </div>
          </div>
        ) : !hasInstance ? (
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Você ainda não tem uma instância WhatsApp configurada. Clique abaixo para criar.
            </p>
            <Button 
              onClick={createInstance}
              disabled={connecting}
              className="w-full"
            >
              {connecting ? (
                <><Loader2 className="h-4 w-4 mr-2 animate-spin" /> Criando...</>
              ) : (
                <><QrCode className="h-4 w-4 mr-2" /> Criar Instância</>
              )}
            </Button>
          </div>
        ) : (
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Clique abaixo para conectar seu WhatsApp e começar a enviar mensagens.
            </p>
            <Button 
              onClick={handleConnect}
              disabled={connecting}
              className="w-full"
            >
              {connecting ? (
                <><Loader2 className="h-4 w-4 mr-2 animate-spin" /> Conectando...</>
              ) : (
                <><QrCode className="h-4 w-4 mr-2" /> Conectar WhatsApp</>
              )}
            </Button>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
