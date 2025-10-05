# 🔥 URGENTE: Ativar Firebase Storage

## ⚠️ Storage não está ativo ainda!

Você precisa ativar o Firebase Storage no console primeiro.

## 📝 Passo a Passo (2 minutos)

### 1. Abrir Firebase Console
```
https://console.firebase.google.com/project/nasa-climetry/storage
```

### 2. Clicar em "Get Started"
- Você verá uma tela de boas-vindas
- Clique no botão **"Get Started"** ou **"Começar"**

### 3. Configurar Storage
**Tela 1: Security Rules**
- Selecione: **"Start in test mode"** (vamos aplicar regras corretas depois)
- Clique **"Next"**

**Tela 2: Cloud Storage location**
- Selecione: **"us-central1"** (mesma região das Functions)
- Clique **"Done"**

### 4. Aguardar Criação
- Firebase vai criar o bucket automaticamente
- Leva ~30 segundos
- Você verá a tela do Storage vazia

### 5. Aplicar Regras de Segurança
Depois que o Storage estiver ativo, volte aqui no terminal e execute:

```bash
firebase deploy --only storage
```

Isso aplicará as regras que eu criei em `storage.rules`.

---

## 📄 Regras Criadas

O arquivo `storage.rules` já está pronto com:

### ✅ O que está configurado:

**Fotos de Perfil** (`/profile_photos/{userId}.jpg`)
- ✅ Qualquer usuário autenticado pode VER fotos de perfil
- ✅ Apenas o PRÓPRIO usuário pode fazer upload/atualizar sua foto
- ✅ Máximo 5MB por foto
- ✅ Apenas imagens (JPEG, PNG, etc)

**Fotos de Eventos** (`/activity_photos/{activityId}/{fileName}`)
- ✅ Usuários autenticados podem ver e fazer upload
- ✅ Limite de 5MB

**Fotos de Desastres** (`/disaster_photos/{disasterId}/{fileName}`)
- ✅ Todos podem ver (dados públicos)
- ✅ Apenas autenticados podem fazer upload

**Uploads Temporários** (`/temp_uploads/{userId}/{fileName}`)
- ✅ Apenas o próprio usuário acessa

---

## 🔍 Verificar se Funcionou

Depois de aplicar as regras:

1. **No Firebase Console**
   - Storage → Rules
   - Deve mostrar as regras aplicadas
   - Status: "Published"

2. **Testar Upload de Foto**
   - No app, vá em Configurações
   - Clique no ícone de lápis
   - Selecione "Alterar Foto"
   - Escolha uma foto
   - ✅ Deve funcionar sem erro!

---

## ⚡ Depois de Ativar

Execute este comando para aplicar as regras:

```bash
firebase deploy --only storage
```

Resultado esperado:
```
✔  Deploy complete!
Storage Rules:
- Published successfully
```

---

## 🆘 Se Der Erro

### Erro: "object-not-found"
**Solução**: Storage não está ativado ainda
- Siga os passos acima para ativar

### Erro: "Permission denied"
**Solução**: Rules não foram aplicadas
- Execute: `firebase deploy --only storage`

### Erro: "File too large"
**Solução**: Foto maior que 5MB
- As regras limitam a 5MB
- Comprima a foto ou escolha outra

---

## 📊 Monitorar Uso do Storage

### Ver Arquivos Enviados
Firebase Console → Storage → Files
- Você verá as pastas:
  - `profile_photos/` - Fotos de perfil dos usuários
  - `activity_photos/` - Fotos de eventos
  - etc.

### Ver Estatísticas
Storage → Usage
- Total de arquivos
- Espaço usado
- Transferência de dados
- **Plano gratuito**: 5GB storage + 1GB/dia download

---

## ✅ Checklist

Antes de testar a foto de perfil:
- [ ] Storage ativado no Firebase Console
- [ ] Região selecionada: us-central1
- [ ] Rules aplicadas: `firebase deploy --only storage`
- [ ] App atualizado no dispositivo

---

**⚡ ATIVE AGORA: https://console.firebase.google.com/project/nasa-climetry/storage**

Depois volte aqui e me avise que ativou para eu continuar com os outros ajustes!
