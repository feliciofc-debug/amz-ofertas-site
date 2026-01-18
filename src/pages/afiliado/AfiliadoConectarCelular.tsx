import { ArrowLeft, Smartphone } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Link } from 'react-router-dom'
import AfiliadoWhatsAppConnection from '@/components/AfiliadoWhatsAppConnection'
import { useAfiliadoTheme } from '@/hooks/useAfiliadoTheme'

export default function AfiliadoConectarCelular() {
  useAfiliadoTheme();
  return (
    <div className="container mx-auto p-6 max-w-2xl">
      <div className="mb-6">
        <Link to="/afiliado/dashboard">
          <Button variant="ghost" size="sm">
            <ArrowLeft className="mr-2 h-4 w-4" />
            Voltar ao Dashboard
          </Button>
        </Link>
      </div>

      <AfiliadoWhatsAppConnection />

      <div className="mt-6 bg-gradient-to-r from-green-500/10 to-blue-500/10 border border-green-500/20 rounded-lg p-6">
        <h3 className="font-bold text-lg mb-3 flex items-center gap-2">
          <Smartphone className="h-5 w-5 text-green-600" />
          Uma Conexão, Múltiplas Funcionalidades
        </h3>
        <p className="text-sm text-muted-foreground mb-4">
          Este único WhatsApp é usado para:
        </p>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3 mb-4">
          <div className="bg-background/50 rounded-lg p-3">
            <p className="font-semibold text-sm mb-1">🤖 Pietro Eugenio (IA)</p>
            <p className="text-xs text-muted-foreground">
              Responde mensagens automaticamente, qualifica leads e tira dúvidas sobre produtos
            </p>
          </div>
          <div className="bg-background/50 rounded-lg p-3">
            <p className="font-semibold text-sm mb-1">👥 Grupos WhatsApp</p>
            <p className="text-xs text-muted-foreground">
              Cria grupos, envia ofertas e gerencia sua comunidade de clientes
            </p>
          </div>
        </div>
      </div>

      <div className="mt-4 bg-muted/50 rounded-lg p-4 text-sm text-muted-foreground">
        <p className="font-semibold mb-2">📱 Como conectar:</p>
        <ol className="space-y-1 list-decimal list-inside">
          <li>Clique em "Conectar WhatsApp"</li>
          <li>Abra o WhatsApp no seu celular</li>
          <li>Vá em <strong>Configurações → Aparelhos conectados</strong></li>
          <li>Toque em <strong>"Conectar aparelho"</strong></li>
          <li>Escaneie o QR Code exibido</li>
        </ol>

        <p className="font-semibold mt-4 mb-2">ℹ️ Importante:</p>
        <ul className="space-y-1 list-disc list-inside">
          <li>Use um número dedicado para atendimento</li>
          <li>Mantenha o celular com bateria e internet</li>
          <li>Não desconecte o WhatsApp Web manualmente</li>
          <li>O QR Code expira em ~60 segundos</li>
        </ul>
      </div>
    </div>
  )
}