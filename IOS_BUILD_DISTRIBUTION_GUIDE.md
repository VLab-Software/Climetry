# 📱 Guia Completo: Build e Distribuição iOS - Climetry

## 📋 Informações do App

- **Nome**: Climetry
- **Bundle ID**: `com.vlabsoftware.climetry`
- **Versão**: 1.0.0 (Build 1)
- **Projeto Firebase**: nasa-climetry
- **Team ID**: C277ZT2F26

---

## ✅ Build Atual

### Status: Em andamento
```bash
flutter build ios --release --no-codesign
```

**Tempo estimado**: 5-10 minutos (primeira vez)

---

## 🎯 Opções de Distribuição

### 1. **TestFlight** (Recomendado para testes)
- ✅ Gratuito
- ✅ Até 10.000 testadores externos
- ✅ Testadores internos ilimitados
- ✅ Builds expiram em 90 dias
- ✅ Ideal para beta testing

### 2. **App Store** (Produção)
- 💰 $99/ano (Apple Developer Program)
- 📝 Revisão da Apple (1-3 dias)
- 🌍 Distribuição global
- ⭐ Reviews e ratings públicos

### 3. **Ad Hoc** (Distribuição limitada)
- 📱 Até 100 dispositivos registrados
- 🔐 Via MDM ou instalação direta
- 🧪 Ideal para clientes específicos

### 4. **Enterprise** (Organizações)
- 💰 $299/ano
- 🏢 Distribuição interna ilimitada
- 🔒 Não aparece na App Store

---

## 🚀 Passo a Passo: TestFlight (Recomendado)

### 1️⃣ Pré-requisitos

- [ ] Apple Developer Account ($99/ano)
- [ ] Xcode instalado (✅ Versão 26.0.1)
- [ ] Certificados de distribuição configurados
- [ ] App ID registrado: `com.vlabsoftware.climetry`

### 2️⃣ Configurar no App Store Connect

1. **Acessar**: https://appstoreconnect.apple.com/
2. **Criar App**:
   - Clique em "+" → "New App"
   - **Platform**: iOS
   - **Name**: Climetry
   - **Primary Language**: Portuguese (Brazil)
   - **Bundle ID**: com.vlabsoftware.climetry
   - **SKU**: climetry-ios-001 (qualquer ID único)
   - **User Access**: Full Access

3. **Preencher Informações**:
   - **App Information**:
     - Nome: Climetry
     - Subtitle: Análise Climática Inteligente
     - Privacy Policy URL: (seu site)
   - **Pricing and Availability**:
     - Price: Free
     - Availability: All countries
   - **App Privacy**:
     - Data Types: Location, Email, Name
     - Purpose: Clima local, autenticação

### 3️⃣ Preparar Ícones e Screenshots

#### Ícones do App (já configurados)
- ✅ 1024x1024px (App Store)
- ✅ Assets configurados em `ios/Runner/Assets.xcassets/`

#### Screenshots Obrigatórios
**iPhone 6.7" (Pro Max)**:
- 1290 x 2796 pixels
- 3-10 screenshots

**iPhone 6.5" (Plus)**:
- 1242 x 2688 pixels
- 3-10 screenshots

**iPad 12.9" (Pro)**:
- 2048 x 2732 pixels
- 3-10 screenshots (se suportar iPad)

### 4️⃣ Abrir no Xcode e Archive

```bash
# Abrir workspace no Xcode
open ios/Runner.xcworkspace
```

**No Xcode**:

1. **Selecionar Device**:
   - Toolbar: "Any iOS Device (arm64)"

2. **Configurar Signing**:
   - Selecione "Runner" no Project Navigator
   - Aba "Signing & Capabilities"
   - Team: Selecione seu time
   - ✅ "Automatically manage signing"
   - Provisioning Profile: Automatic

3. **Archive**:
   - Menu: **Product** → **Archive**
   - Aguarde compilação (~10-15 min)
   - Janela "Organizer" abrirá automaticamente

4. **Distribute**:
   - Clique em **"Distribute App"**
   - Selecione: **"App Store Connect"**
   - Next → **"Upload"**
   - Configurações:
     - ✅ Include bitcode: NO (deprecated)
     - ✅ Upload your app's symbols
     - ✅ Manage Version and Build Number
   - Next → **"Upload"**
   - Aguarde upload (~5-10 min)

### 5️⃣ Configurar no TestFlight

1. **App Store Connect** → **TestFlight**
2. Aguarde processamento (~5-20 min)
3. **Internal Testing**:
   - Adicione testadores internos (equipe)
   - Eles recebem email automaticamente
4. **External Testing** (opcional):
   - Clique em "+" → "New Group"
   - Adicione testadores externos
   - Preencha "Test Information"
   - Enviar para revisão da Apple (~24h)

### 6️⃣ Testadores Instalam

- Instalar **TestFlight** da App Store
- Usar link ou código de convite
- Baixar e testar o app
- Enviar feedback via TestFlight

---

## 🚀 Passo a Passo: App Store (Produção)

### 1️⃣ Após Archive e Upload

1. **App Store Connect** → **Apps** → **Climetry**
2. **App Information** (já preenchido)
3. **Pricing and Availability** (configurado)

### 2️⃣ Preparar Versão para Revisão

1. **App Store** → **1.0 Prepare for Submission**
2. **Preencher**:
   
   **Screenshots**:
   - Upload screenshots obrigatórios
   
   **Promotional Text** (opcional):
   ```
   Descubra a ciência do clima perfeito. Análise de probabilidades 
   climáticas com dados da NASA — qualquer lugar, qualquer hora.
   ```
   
   **Description**:
   ```
   Climetry é seu assistente inteligente para planejamento de eventos 
   com base em dados climáticos precisos da NASA.

   RECURSOS PRINCIPAIS:
   • 📊 Análise de probabilidade climática
   • 🗓️ Planejamento inteligente de eventos
   • 🤝 Colaboração em tempo real
   • 🌍 Dados globais da NASA
   • 📱 Notificações de alertas climáticos
   • 🔒 Seus dados protegidos com Firebase

   PERFEITO PARA:
   • Organizadores de eventos
   • Fotógrafos
   • Produtores rurais
   • Aventureiros e viajantes
   • Qualquer pessoa que precise planejar com o clima
   ```
   
   **Keywords** (100 caracteres max):
   ```
   clima,previsão,nasa,evento,planejamento,tempo,meteorologia
   ```
   
   **Support URL**: https://climetry.com/support
   **Marketing URL**: https://climetry.com
   
   **Version Information**:
   - What's New in This Version:
   ```
   Lançamento inicial do Climetry!
   
   • Análise climática inteligente
   • Criação e colaboração em eventos
   • Notificações de alertas
   • Interface moderna e intuitiva
   ```

3. **Build**:
   - Clique em "+" ao lado de "Build"
   - Selecione o build uploadado
   - Adicione "Export Compliance": No (se não usa criptografia)

4. **App Review Information**:
   - Nome de contato
   - Email
   - Telefone
   - **Demo Account** (importante!):
     - Username: demo@climetry.com
     - Password: Demo@123456
     - Notas: Conta de teste para revisão

5. **Version Release**:
   - Automatic: Lançar automaticamente após aprovação
   - Manual: Você escolhe quando lançar

6. **Submit for Review**:
   - Revise tudo
   - Clique em **"Add for Review"**
   - Depois **"Submit to App Review"**

### 3️⃣ Aguardar Revisão

- **Tempo**: 24h - 3 dias (média: 1-2 dias)
- **Status**:
  - Waiting for Review
  - In Review
  - Pending Developer Release (se manual)
  - Ready for Sale ✅

### 4️⃣ Após Aprovação

- App aparece na App Store
- Usuários podem baixar
- Você pode ver analytics no App Store Connect

---

## 🔧 Comandos Úteis

### Build para device conectado:
```bash
flutter run --release
```

### Build sem codesign (para testar localmente):
```bash
flutter build ios --release --no-codesign
```

### Build com codesign:
```bash
flutter build ios --release
```

### Abrir Xcode:
```bash
open ios/Runner.xcworkspace
```

### Limpar build:
```bash
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
cd ios && pod install && cd ..
```

### Ver logs do device:
```bash
flutter logs
```

---

## 📱 Informações de Build

### Capacidades Habilitadas:
- ✅ Push Notifications (Firebase)
- ✅ Background Modes (Remote notifications)
- ✅ Associated Domains (Firebase)
- ✅ App Groups (compartilhamento de dados)

### Permissões no Info.plist:
- ✅ NSLocationWhenInUseUsageDescription
- ✅ NSCameraUsageDescription
- ✅ NSPhotoLibraryUsageDescription
- ✅ NSContactsUsageDescription
- ✅ NSCalendarsUsageDescription

### Firebase Configurado:
- ✅ GoogleService-Info.plist
- ✅ Firebase Analytics
- ✅ Firebase Auth
- ✅ Cloud Firestore
- ✅ Firebase Storage
- ✅ Firebase Messaging (Push)

---

## ❓ Troubleshooting

### Erro: "No profiles found"
```bash
# Abrir Xcode Preferences
# Accounts → Download Manual Profiles
```

### Erro: "Code signing failed"
- Verificar certificados em https://developer.apple.com/account/
- Revogar e criar novos se necessário
- Xcode → Preferences → Accounts → Download Manual Profiles

### Erro: "The app ID cannot be registered"
- App ID já existe
- Usar outro bundle identifier ou verificar no Developer Portal

### Build muito lento:
```bash
# Limpar DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### Erro de pods:
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
cd ..
```

---

## 📊 Checklist Completo

### Antes do Archive:
- [ ] Bundle ID correto: `com.vlabsoftware.climetry`
- [ ] Versão atualizada: `1.0.0+1`
- [ ] Ícone configurado (1024x1024)
- [ ] GoogleService-Info.plist presente
- [ ] Capabilities habilitadas
- [ ] Permissões no Info.plist
- [ ] Testado em device físico
- [ ] Sem warnings ou errors

### Para TestFlight:
- [ ] Apple Developer Account ativo
- [ ] App criado no App Store Connect
- [ ] Archive feito com sucesso
- [ ] Upload concluído
- [ ] Build processado
- [ ] Testadores adicionados
- [ ] Link de convite enviado

### Para App Store:
- [ ] Screenshots (3+ para cada tamanho)
- [ ] Descrição completa
- [ ] Keywords definidas
- [ ] URLs de suporte e marketing
- [ ] Conta demo criada
- [ ] Privacy Policy pronta
- [ ] App Review Information preenchida
- [ ] Build selecionado
- [ ] Submetido para revisão

---

## 🎉 Status Atual

- [x] Flutter configurado
- [x] Xcode instalado (26.0.1)
- [x] CocoaPods atualizado
- [x] Firebase configurado
- [x] Build em andamento
- [ ] Archive no Xcode
- [ ] Upload para TestFlight
- [ ] Distribuição

---

## 📞 Próximos Passos

1. ⏳ **Aguardar build finalizar** (~5-10 min)
2. 🔧 **Abrir no Xcode**: `open ios/Runner.xcworkspace`
3. 📦 **Archive**: Product → Archive
4. ⬆️ **Upload**: Distribute → App Store Connect
5. 🧪 **TestFlight**: Adicionar testadores
6. 🚀 **App Store**: Submit for Review

**Precisa de ajuda em algum passo? Me avise!** 🙂
