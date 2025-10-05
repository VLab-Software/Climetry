# 🌐 Guia: Conectar Domínio Customizado ao Firebase Hosting

## ✅ Deploy Concluído

Sua aplicação web está no ar:
- 🔗 URL Firebase: **https://nasa-climetry.web.app**
- 🔗 URL alternativa: **https://nasa-climetry.firebaseapp.com**

## 📋 Passo a Passo: Adicionar Domínio Customizado

### 1️⃣ Acessar Firebase Console

1. Vá para: https://console.firebase.google.com/project/nasa-climetry/hosting
2. Clique em **"Add custom domain"** ou **"Adicionar domínio personalizado"**

### 2️⃣ Adicionar seu Domínio

Você pode adicionar:
- **Domínio raiz**: `seudominio.com`
- **Subdomínio**: `app.seudominio.com` ou `climetry.seudominio.com`

**Recomendação**: Use um subdomínio como `app.seudominio.com`

### 3️⃣ Verificar Propriedade do Domínio

O Firebase vai pedir para verificar que você é dono do domínio.

#### Opção A: Registro TXT (Recomendado)
```
Tipo: TXT
Nome: @
Valor: [Firebase vai fornecer um código único]
TTL: 3600
```

#### Opção B: Arquivo no servidor
- Upload de um arquivo específico no seu servidor atual

### 4️⃣ Configurar DNS no seu Provedor (Hostinger)

Após verificação, adicione os registros DNS:

#### Para Domínio Raiz (`seudominio.com`):
```
Tipo: A
Nome: @
Valor: [IPs fornecidos pelo Firebase]
TTL: 3600
```

#### Para Subdomínio (`app.seudominio.com`):
```
Tipo: CNAME
Nome: app
Valor: nasa-climetry.web.app
TTL: 3600
```

### 5️⃣ Aguardar Propagação DNS

- ⏱️ Tempo: 24-48 horas (geralmente 1-2 horas)
- 🔍 Verificar: https://www.whatsmydns.net/

### 6️⃣ SSL/HTTPS (Automático) ✅

O Firebase provisiona automaticamente um certificado SSL gratuito via **Let's Encrypt**:
- ✅ Renovação automática
- ✅ HTTPS forçado
- ✅ TLS 1.2+
- ✅ Sem custo adicional

## 🎯 Exemplo Prático

### Se seu domínio é `climetry.com`:

**Opção 1: Domínio raiz**
```bash
# No Hostinger DNS:
A     @     151.101.1.195
A     @     151.101.65.195
```
Resultado: `https://climetry.com`

**Opção 2: Subdomínio (Recomendado)**
```bash
# No Hostinger DNS:
CNAME app   nasa-climetry.web.app
```
Resultado: `https://app.climetry.com`

## 🔧 Comandos Úteis

### Ver domínios conectados:
```bash
firebase hosting:sites:list
```

### Fazer novo deploy:
```bash
flutter build web --release
firebase deploy --only hosting
```

### Ver logs:
```bash
firebase hosting:channel:list
```

## 📱 Redirecionamentos Automáticos

O Firebase Hosting já está configurado para:
- ✅ Redirecionar HTTP → HTTPS
- ✅ Redirecionar `www.seudominio.com` → `seudominio.com` (se configurado)
- ✅ SPA routing (todas as rotas vão para `/index.html`)

## 🚀 Performance

O Firebase Hosting oferece:
- 🌍 CDN Global (150+ locais)
- ⚡ Cache automático de assets (JS, CSS, imagens)
- 🗜️ Compressão gzip/brotli automática
- 📊 HTTP/2 e HTTP/3

## 🔐 Segurança

- ✅ HTTPS forçado
- ✅ Certificado SSL gratuito
- ✅ Headers de segurança (configurado em `firebase.json`)
- ✅ Proteção DDoS automática

## ❓ Troubleshooting

### Domínio não funciona após 48h:
1. Verifique DNS: `nslookup seudominio.com`
2. Limpe cache do navegador
3. Tente em modo anônimo
4. Verifique no Firebase Console se status está "Connected"

### Erro SSL:
- Aguarde até 24h após configuração DNS
- SSL é provisionado automaticamente após DNS propagar
- Não precisa fazer nada manualmente

### Deploy não atualiza:
```bash
# Limpe cache e reconstrua:
flutter clean
flutter pub get
flutter build web --release
firebase deploy --only hosting
```

## 📞 Suporte

- Firebase Console: https://console.firebase.google.com/project/nasa-climetry/hosting
- Documentação: https://firebase.google.com/docs/hosting
- Status: https://status.firebase.google.com/

---

## ✅ Checklist Final

- [x] Build de produção criado
- [x] Deploy no Firebase Hosting
- [x] App acessível em `nasa-climetry.web.app`
- [ ] Domínio customizado adicionado
- [ ] DNS configurado no Hostinger
- [ ] SSL provisionado (automático após DNS)
- [ ] Teste final: `https://seudominio.com`

**Próximo passo**: Adicione seu domínio no Firebase Console! 🚀
