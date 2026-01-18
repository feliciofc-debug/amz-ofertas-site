# 🚨 GUIA DE DEPLOY SEGURO - HOSTINGER

## ⚠️ IMPORTANTE - SEGURANÇA CRÍTICA

### 1. NUNCA FAÇA UPLOAD DO ARQUIVO `.env`

O arquivo `.env` contém suas chaves secretas e **NUNCA** deve ser enviado para o servidor.

### 2. O QUE FAZER AGORA (URGENTE)

Se você já fez upload do arquivo `.env` para a Hostinger:

1. **DELETAR IMEDIATAMENTE** o arquivo `.env` do servidor via FTP/File Manager
2. **TROCAR TODAS AS CHAVES DE API** que estavam nele
3. Seguir os passos abaixo corretamente

---

## 📋 PASSO A PASSO CORRETO

### Passo 1: Fazer Build Local

```bash
npm run build
```

Isso cria a pasta `dist/` com seu site pronto.

### Passo 2: Verificar o que será enviado

A pasta `dist/` deve conter APENAS:
- ✅ index.html
- ✅ assets/ (CSS e JS compilados)
- ✅ public/ (imagens, favicons, etc)
- ✅ .htaccess (arquivo de segurança)
- ❌ NÃO deve conter .env
- ❌ NÃO deve conter package.json
- ❌ NÃO deve conter src/

### Passo 3: Upload via FTP/File Manager

**OPÇÃO A - Via FTP:**
1. Conecte ao FTP da Hostinger
2. Navegue até `public_html/` (ou pasta do seu domínio)
3. **DELETE TUDO** que está lá (faça backup antes)
4. Envie **APENAS** o conteúdo da pasta `dist/`
5. Certifique-se que o `.htaccess` foi enviado

**OPÇÃO B - Via File Manager da Hostinger:**
1. Acesse o File Manager no painel da Hostinger
2. Navegue até `public_html/`
3. Delete tudo (exceto se houver outros sites)
4. Faça upload do conteúdo da pasta `dist/`

### Passo 4: Configurar Variáveis no Servidor

**As variáveis de ambiente devem ser configuradas NO PAINEL DA HOSTINGER, não em arquivo!**

Mas como este é um projeto frontend (React/Vite), as variáveis já estão compiladas no build.

---

## 🔒 VERIFICAÇÃO DE SEGURANÇA

Após o upload, teste se está protegido:

1. Acesse: `https://seusite.com/.env`
   - ✅ Deve dar erro 403 ou 404
   - ❌ Se abrir o arquivo, há um problema!

2. Acesse: `https://seusite.com/`
   - ✅ Deve abrir seu site normalmente

---

## 📁 ESTRUTURA CORRETA NO SERVIDOR

```
public_html/
├── index.html
├── .htaccess (proteção)
├── favicon.ico
├── assets/
│   ├── index-xxxxx.js
│   └── index-xxxxx.css
└── ... (outros arquivos públicos)
```

**NÃO DEVE EXISTIR:**
- ❌ .env
- ❌ .env.local
- ❌ package.json
- ❌ src/
- ❌ node_modules/

---

## 🆘 SE AS CHAVES AINDA APARECEM

Se após seguir esses passos as chaves ainda aparecem:

1. **Limpe o cache do navegador** (Ctrl+Shift+Delete)
2. Verifique se deletou TODOS os arquivos antigos do servidor
3. Confirme que está fazendo upload da pasta `dist/` e não da raiz do projeto
4. Entre em contato com o suporte da Hostinger para verificar configurações

---

## 🔐 ARQUIVOS DE PROTEÇÃO

O arquivo `.htaccess` criado bloqueia:
- Arquivos .env
- Arquivos de configuração
- Listagem de diretórios
- Arquivos ocultos

---

## ✅ CHECKLIST FINAL

Antes de considerar o deploy concluído:

- [ ] Arquivo .env foi DELETADO do servidor
- [ ] Testei acessar seusite.com/.env e deu erro
- [ ] Site principal está funcionando
- [ ] Troquei todas as chaves de API comprometidas
- [ ] .htaccess está no servidor
- [ ] Não há arquivos de código-fonte no servidor (src/, package.json, etc)

---

## 🚀 PARA PRÓXIMAS ATUALIZAÇÕES

Sempre que atualizar o site:

1. `npm run build` localmente
2. Delete o conteúdo de `public_html/`
3. Envie o novo conteúdo de `dist/`
4. Teste se está funcionando

---

**DÚVIDAS?** Verifique os logs de erro no painel da Hostinger ou entre em contato com o suporte técnico.
