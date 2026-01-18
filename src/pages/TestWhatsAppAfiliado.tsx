import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { supabase } from '@/integrations/supabase/client'
import { toast } from 'sonner'
import { useNavigate } from 'react-router-dom'

export default function TestWhatsAppAfiliado() {
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<any>(null)
  const [user, setUser] = useState<any>(null)
  const navigate = useNavigate()

  useEffect(() => {
    checkAuth()
  }, [])

  const checkAuth = async () => {
    const { data: { session } } = await supabase.auth.getSession()
    if (session?.user) {
      setUser(session.user)
      console.log('✅ Usuário logado:', session.user.email)
    } else {
      console.log('❌ Usuário NÃO logado')
      toast.error('Você precisa fazer login primeiro!')
    }
  }

  const runTest = async () => {
    setLoading(true)
    setResult(null)
    try {
      console.log('🧪 Iniciando teste...')

      const { data, error } = await supabase.functions.invoke('test-afiliado-connection')

      console.log('📊 Resposta teste:', { data, error })

      if (error) {
        setResult({ error: error.message })
        toast.error('Erro: ' + error.message)
      } else {
        setResult(data)
        toast.success('Teste concluído!')
      }
    } catch (err: any) {
      console.error('💥 Erro:', err)
      setResult({ error: err.message })
      toast.error('Erro: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  const createInstance = async () => {
    setLoading(true)
    try {
      console.log('🔨 Criando instância...')

      const { data, error } = await supabase.functions.invoke('criar-instancia-wuzapi-afiliado', {
        body: { action: 'criar-instancia' }
      })

      console.log('📊 Resposta criar:', { data, error })

      if (error) {
        toast.error('Erro: ' + JSON.stringify(error))
      } else if (data.success) {
        toast.success('Instância criada!')
        setResult(data)
      } else {
        toast.error(data.error || 'Erro desconhecido')
        setResult(data)
      }
    } catch (err: any) {
      console.error('💥 Erro:', err)
      toast.error('Erro: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  const conectar = async () => {
    setLoading(true)
    try {
      console.log('🔌 Conectando...')

      const { data, error } = await supabase.functions.invoke('criar-instancia-wuzapi-afiliado', {
        body: { action: 'conectar' }
      })

      console.log('📊 Resposta conectar:', { data, error })

      if (error) {
        toast.error('Erro: ' + JSON.stringify(error))
      } else if (data.qrCode) {
        toast.success('QR Code recebido!')
        setResult({ ...data, qrCodePreview: data.qrCode.substring(0, 50) + '...' })
      } else {
        toast.error(data.message || 'Sem QR Code')
        setResult(data)
      }
    } catch (err: any) {
      console.error('💥 Erro:', err)
      toast.error('Erro: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="container mx-auto p-6 max-w-4xl">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            <span>🧪 Teste WhatsApp Afiliado - Debug</span>
            {user ? (
              <Badge className="bg-green-500">
                Logado: {user.email}
              </Badge>
            ) : (
              <Badge variant="destructive">
                NÃO LOGADO
              </Badge>
            )}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {!user && (
            <div className="p-4 bg-red-500/10 border border-red-500 rounded-lg">
              <p className="font-bold text-red-500">
                ⚠️ Você precisa fazer login primeiro!
              </p>
              <Button
                className="mt-2"
                onClick={() => navigate('/login')}
              >
                Ir para Login
              </Button>
            </div>
          )}
          <div className="flex gap-2">
            <Button onClick={runTest} disabled={loading || !user}>
              1. Testar Conexão e Dados
            </Button>
            <Button onClick={createInstance} disabled={loading || !user}>
              2. Criar Instância
            </Button>
            <Button onClick={conectar} disabled={loading || !user}>
              3. Conectar WhatsApp
            </Button>
          </div>

          {result && (
            <div className="mt-4 p-4 bg-muted rounded-lg">
              <h3 className="font-bold mb-2">Resultado:</h3>
              <pre className="text-xs overflow-auto max-h-96">
                {JSON.stringify(result, null, 2)}
              </pre>
            </div>
          )}

          <div className="mt-4 p-4 bg-blue-500/10 border border-blue-500/20 rounded-lg">
            <h3 className="font-bold mb-2">📋 Como usar:</h3>
            <ol className="text-sm space-y-1 list-decimal list-inside">
              <li>Clique em "1. Testar Conexão" para verificar dados</li>
              <li>Se tudo OK, clique em "2. Criar Instância"</li>
              <li>Depois clique em "3. Conectar WhatsApp"</li>
              <li>Copie e me envie o JSON do resultado</li>
            </ol>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
