# 🌤️ Climetry - NASA Space Apps Challenge# Climetry



**Monitoramento Climático Inteligente com IA para Eventos**Discover the science of perfect weather. Analyze climate probabilities powered by NASA data — anywhere, anytime.



Climetry é uma aplicação Flutter que utiliza dados meteorológicos em tempo real da API Meteomatics e inteligência artificial da OpenAI para fornecer insights climáticos precisos e recomendações personalizadas para eventos.## Getting Started



[![Flutter](https://img.shields.io/badge/Flutter-3.24.5-blue.svg)](https://flutter.dev)This project is a starting point for a Flutter application.

[![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg)](https://firebase.google.com)

[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)A few resources to get you started if this is your first Flutter project:



## 🌟 Funcionalidades- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)

- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

### 📊 Monitoramento Climático

- Previsão meteorológica detalhada até 180 diasFor help getting started with Flutter development, view the

- Dados em tempo real: temperatura, precipitação, vento, UV, umidade[online documentation](https://docs.flutter.dev/), which offers tutorials,

- Alertas automáticos (ondas de calor, chuvas intensas, granizo, ventania)samples, guidance on mobile development, and a full API reference.

- Comparação com médias históricas de 10 anos

### 🤖 Inteligência Artificial
- Insights personalizados gerados por GPT-4o-mini
- Recomendações específicas por tipo de evento
- Análise de impacto climático em tempo real
- Atualização automática de insights quando clima muda

### 🔔 Sistema de Notificações
- Monitoramento contínuo até o dia do evento
- Alertas push quando clima muda significativamente (>3°C, >20% chuva)
- Notificação matinal no dia do evento
- Integração com Firebase Cloud Messaging

### 📈 Visualização de Dados
- Gráficos interativos (temperatura, precipitação, vento, UV)
- Cards expansíveis com detalhes completos
- Rating de condições climáticas (0-10)
- Interface responsiva dark/light

### 👥 Colaboração
- Sistema de eventos compartilhados
- Gestão de participantes com roles (owner, admin, moderator)
- Convites via email
- Sincronização em tempo real via Firestore

---

## 📋 Requisitos do Sistema

### Desenvolvimento
- **Flutter SDK**: 3.24.5 ou superior
- **Dart SDK**: 3.5.4 ou superior
- **Node.js**: 16.x ou superior (para Firebase)
- **CocoaPods**: 1.11.0+ (para iOS)
- **Xcode**: 15.0+ (para iOS)
- **Android Studio**: Latest (para Android)

### Contas Necessárias
- **Firebase**: Projeto configurado com Authentication, Firestore, Storage, Hosting, Cloud Messaging
- **Meteomatics**: Conta com credenciais (username/password)
- **OpenAI**: API Key com acesso ao GPT-4o-mini
- **Google Maps**: API Key (opcional para mapas)
- **Apple Developer**: Conta paga para distribuição iOS ($99/ano)

---

## 🚀 Configuração do Projeto

### 1. Clone o Repositório

```bash
git clone https://github.com/VLab-Software/Climetry.git
cd Climetry
```

### 2. Instale Dependências

```bash
flutter pub get
```

### 3. Configure Variáveis de Ambiente

Crie o arquivo `.env` na raiz do projeto:

```bash
cp .env.example .env
```

Edite `.env` com suas credenciais reais:

```env
OPENAI_API_KEY=sk-proj-YOUR_OPENAI_KEY_HERE
METEOMATICS_USERNAME=your_meteomatics_username
METEOMATICS_PASSWORD=your_meteomatics_password
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_KEY_HERE
```

⚠️ **IMPORTANTE**: O arquivo `.env` está no `.gitignore` e nunca será commitado. Use `.env.example` como template.

---

## 🔥 Configuração do Firebase

### Passo 1: Criar Projeto Firebase

1. Acesse [Firebase Console](https://console.firebase.google.com)
2. Clique em "Adicionar projeto"
3. Nome: `nasa-climetry` (ou seu nome preferido)
4. Habilite Google Analytics (opcional)
5. Clique em "Criar projeto"

### Passo 2: Configurar Authentication

1. No painel lateral, vá em **Authentication**
2. Clique em "Começar"
3. Habilite os provedores:
   - ✅ **E-mail/Senha**
   - ✅ **Google** (opcional)
4. Em "Settings" > "Authorized domains", adicione:
   - `localhost`
   - `nasa-climetry.web.app`
   - `nasa-climetry.firebaseapp.com`
   - Seu domínio customizado (se tiver)

### Passo 3: Configurar Firestore Database

1. No painel lateral, vá em **Firestore Database**
2. Clique em "Criar banco de dados"
3. Escolha **Modo de produção**
4. Selecione localização: `us-central1` (ou mais próxima)
5. Copie as regras de segurança de `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    match /users/{userId} {
      allow read: if isSignedIn();
      allow write: if isOwner(userId);
    }

    match /activities/{activityId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update, delete: if isSignedIn() && 
        (resource.data.ownerId == request.auth.uid || 
         request.auth.uid in resource.data.participants);
    }

    match /weather_monitoring/{docId} {
      allow read, write: if isSignedIn();
    }

    match /weather_insights/{docId} {
      allow read: if isSignedIn();
      allow write: if false;
    }

    match /notifications/{notificationId} {
      allow read: if isSignedIn() && resource.data.userId == request.auth.uid;
      allow write: if isSignedIn();
    }
  }
}
```

### Passo 4: Configurar Storage

1. No painel lateral, vá em **Storage**
2. Clique em "Começar"
3. Escolha **Modo de produção**
4. Copie as regras de `storage.rules`:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /activities/{activityId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Passo 5: Configurar Cloud Messaging (Notificações Push)

1. No painel lateral, vá em **Cloud Messaging**
2. Clique em "Começar"
3. **Android**:
   - O FCM é configurado automaticamente com o `google-services.json`
4. **iOS**:
   - Faça upload do certificado APNs (veremos na seção iOS)
5. **Web**:
   - Copie o "Server Key" e "Sender ID" (salvos automaticamente)

### Passo 6: Configurar Hosting (Web)

1. No painel lateral, vá em **Hosting**
2. Clique em "Começar"
3. Instale Firebase CLI:

```bash
npm install -g firebase-tools
```

4. Faça login:

```bash
firebase login
```

5. Inicialize o projeto:

```bash
firebase init hosting
```

Selecione:
- ✅ Use an existing project: `nasa-climetry`
- Public directory: `build/web`
- Configure as single-page app: **Yes**
- Set up automatic builds: **No**

6. Deploy:

```bash
flutter build web --release
firebase deploy --only hosting
```

Sua aplicação estará disponível em: `https://nasa-climetry.web.app`

---

## 📱 Configuração iOS

### Passo 1: Pré-requisitos

1. **Mac com macOS** (necessário para desenvolvimento iOS)
2. **Xcode 15.0+** instalado via App Store
3. **CocoaPods** instalado:

```bash
sudo gem install cocoapods
```

4. **Conta Apple Developer** ($99/ano) em [developer.apple.com](https://developer.apple.com)

### Passo 2: Configurar Bundle Identifier

1. Abra `ios/Runner.xcworkspace` no Xcode
2. Selecione o projeto **Runner** no navegador
3. Em "General" > "Identity":
   - **Bundle Identifier**: `com.vlabsoftware.climetry`
   - **Display Name**: `Climetry`
   - **Version**: `1.0.0`
   - **Build**: `1`

### Passo 3: Adicionar Firebase ao iOS

1. No Firebase Console, clique no ícone **iOS** para adicionar app
2. Bundle ID: `com.vlabsoftware.climetry`
3. App nickname: `Climetry iOS`
4. Baixe `GoogleService-Info.plist`
5. Arraste o arquivo para `ios/Runner/` no Xcode
6. ✅ Marque "Copy items if needed"
7. ✅ Selecione target "Runner"

### Passo 4: Configurar Certificados e Provisioning

1. No Xcode, vá em **Signing & Capabilities**
2. Marque **Automatically manage signing**
3. Selecione seu **Team** (Apple Developer Account)
4. O Xcode criará automaticamente:
   - Development Certificate
   - Provisioning Profile
   - App ID

### Passo 5: Adicionar Capabilities

No Xcode, vá em **Signing & Capabilities** e adicione:

1. **Push Notifications**:
   - Clique em "+ Capability"
   - Busque e adicione "Push Notifications"

2. **Background Modes**:
   - Clique em "+ Capability"
   - Busque e adicione "Background Modes"
   - ✅ Marque "Remote notifications"

### Passo 6: Configurar APNs (Apple Push Notification service)

1. Acesse [Apple Developer Portal](https://developer.apple.com/account/)
2. Vá em **Certificates, Identifiers & Profiles**
3. Clique em **Keys** (chaves)
4. Clique no **+** para criar nova chave
5. Nome: `Climetry APNs Key`
6. ✅ Marque **Apple Push Notifications service (APNs)**
7. Clique em "Continue" e "Register"
8. **Baixe o arquivo .p8** (só pode baixar uma vez!)
9. Anote o **Key ID**

10. No Firebase Console:
    - Vá em **Project Settings** > **Cloud Messaging**
    - Na seção **Apple app configuration**
    - Clique em "Upload" em **APNs Authentication Key**
    - Faça upload do arquivo .p8
    - Insira:
      - **Key ID**: (anotado no passo 9)
      - **Team ID**: (encontre em Account Settings no Apple Developer)

### Passo 7: Instalar Dependências iOS

```bash
cd ios
pod install
cd ..
```

### Passo 8: Build para Dispositivo Físico

1. Conecte seu iPhone via USB
2. Confie no computador no iPhone (popup)
3. No Xcode, selecione seu dispositivo no topo
4. Pressione **Cmd + R** ou clique no botão ▶️ Play

**Ou via terminal:**

```bash
flutter build ios --release
```

**Para instalar no dispositivo:**

```bash
flutter install --device-id=YOUR_DEVICE_ID
```

Para ver device ID:

```bash
flutter devices
```

### Passo 9: Distribuição (TestFlight ou App Store)

1. No Xcode, vá em **Product** > **Archive**
2. Aguarde o build finalizar
3. Na janela Archives, clique em "Distribute App"
4. Escolha:
   - **TestFlight & App Store** (para testar com beta testers)
   - **Ad Hoc** (para distribuição limitada)
5. Siga o wizard para fazer upload para App Store Connect

---

## 🤖 Configuração Android

### Passo 1: Adicionar Firebase ao Android

1. No Firebase Console, clique no ícone **Android** para adicionar app
2. Package name: `com.vlabsoftware.climetry`
3. App nickname: `Climetry Android`
4. Baixe `google-services.json`
5. Coloque em `android/app/google-services.json`

### Passo 2: Configurar Signing (Release)

1. Crie keystore para assinatura:

```bash
keytool -genkey -v -keystore ~/climetry-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias climetry
```

2. Crie `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=climetry
storeFile=/Users/SEU_USUARIO/climetry-release-key.jks
```

3. Em `android/app/build.gradle`, o signing já está configurado para ler do `key.properties`

### Passo 3: Build para Android

**Debug (para teste):**

```bash
flutter build apk --debug
```

**Release (para produção):**

```bash
flutter build apk --release
```

**App Bundle (para Play Store):**

```bash
flutter build appbundle --release
```

**Instalar no dispositivo conectado:**

```bash
flutter install
```

### Passo 4: Publicar na Google Play Store

1. Acesse [Google Play Console](https://play.google.com/console)
2. Crie uma conta de desenvolvedor ($25 taxa única)
3. Clique em "Criar app"
4. Preencha informações do app
5. Faça upload do `app-release.aab`
6. Configure:
   - Classificação de conteúdo
   - Preço e distribuição (Gratuito)
   - Política de privacidade
7. Envie para revisão

---

## 🔑 Configuração das APIs

### OpenAI API

1. Acesse [platform.openai.com](https://platform.openai.com)
2. Crie uma conta (requer cartão de crédito)
3. Vá em **API Keys**
4. Clique em "Create new secret key"
5. Copie a chave (só aparece uma vez!)
6. Cole no `.env`:

```env
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxx
```

**Custos estimados:**
- GPT-4o-mini: ~$0.15 por 1M tokens de entrada
- Uso médio: <$5/mês para uso moderado

### Meteomatics API

1. Acesse [meteomatics.com](https://www.meteomatics.com)
2. Entre em contato para criar conta
3. Após aprovação, você receberá:
   - Username
   - Password
4. Cole no `.env`:

```env
METEOMATICS_USERNAME=seu_usuario
METEOMATICS_PASSWORD=sua_senha
```

**Plano recomendado:**
- Weather API Professional
- Máximo 10 parâmetros por requisição
- Previsões até 180 dias

### Google Maps API (Opcional)

1. Acesse [Google Cloud Console](https://console.cloud.google.com)
2. Crie um novo projeto ou use existente
3. Habilite **Maps SDK for Android** e **Maps SDK for iOS**
4. Vá em **Credenciais**
5. Crie **API Key**
6. Restrinja a chave:
   - Android: adicione SHA-1 do seu app
   - iOS: adicione Bundle ID `com.vlabsoftware.climetry`
7. Cole no `.env`:

```env
GOOGLE_MAPS_API_KEY=AIzaSyxxxxxxxxxxxxx
```

**Tier Gratuito:**
- $200 de crédito mensal
- ~28.000 visualizações de mapa por mês

---

## 🏗️ Estrutura do Projeto

```
lib/
├── main.dart                           
├── src/
│   ├── app.dart                        
│   ├── core/
│   │   ├── auth/                       
│   │   ├── network/                    
│   │   ├── services/                   
│   │   ├── theme/                      
│   │   └── widgets/                    
│   └── features/
│       ├── activities/                 
│       │   ├── data/                   
│       │   ├── domain/                 
│       │   └── presentation/           
│       ├── auth/                       
│       ├── climate/                    
│       ├── disasters/                  
│       ├── friends/                    
│       ├── home/                       
│       ├── settings/                   
│       └── weather/                    
│           ├── data/                   
│           │   └── services/
│           │       ├── meteomatics_service.dart           
│           │       └── weather_monitoring_service.dart    
│           ├── domain/
│           │   ├── entities/           
│           │   └── models/             
│           └── presentation/
│               └── widgets/            
```

---

## 🧪 Executando o Projeto

### Web

```bash
flutter run -d chrome
```

### iOS (Simulator)

```bash
flutter run -d "iPhone 15 Pro"
```

### iOS (Device)

```bash
flutter devices
flutter run -d YOUR_DEVICE_ID
```

### Android (Emulator)

```bash
flutter emulators --launch Pixel_7_API_34
flutter run
```

### Android (Device)

```bash
flutter run -d YOUR_DEVICE_ID
```

---

## 📦 Build de Produção

### Web

```bash
flutter build web --release
firebase deploy --only hosting
```

### iOS

```bash
flutter build ios --release
```

Depois, use Xcode para Archive e distribuir.

### Android

```bash
flutter build appbundle --release
```

Upload do `build/app/outputs/bundle/release/app-release.aab` para Play Console.

---

## 🐛 Troubleshooting

### Erro: "GoogleService-Info.plist not found"
**Solução**: Certifique-se de que o arquivo está em `ios/Runner/` e foi adicionado ao target Runner no Xcode.

### Erro: "CocoaPods not installed"
**Solução**: 
```bash
sudo gem install cocoapods
cd ios && pod install
```

### Erro: "API key inválida"
**Solução**: Verifique se o `.env` foi criado e contém as chaves corretas. Execute:
```bash
flutter clean
flutter pub get
```

### Erro de certificado iOS
**Solução**: 
1. Abra Xcode
2. Vá em Preferences > Accounts
3. Adicione sua conta Apple Developer
4. Em Signing & Capabilities, clique em "Download Manual Profiles"

### Build iOS falha com "No profiles found"
**Solução**:
1. No Xcode, desmarque "Automatically manage signing"
2. Marque novamente
3. Selecione seu team
4. Clean Build Folder (Cmd + Shift + K)

### Notificações push não funcionam
**Solução**:
1. Verifique se APNs key foi carregado no Firebase
2. Confirme que Push Notifications capability está ativa
3. Teste com dispositivo físico (simulador não recebe push)

---

## 🔄 Sistema de Monitoramento Climático

O Climetry possui um sistema inteligente de monitoramento contínuo:

### Como Funciona

1. **Ao criar um evento**:
   - Sistema salva previsão inicial no Firestore
   - Inicia monitoramento automático

2. **Verificação Diária**:
   - Firebase Cloud Function roda a cada 24h
   - Compara previsão atual com última salva
   - Detecta mudanças significativas:
     - Temperatura: >3°C
     - Chuva: >20% probabilidade
     - Vento: >15 km/h

3. **Quando detecta mudança**:
   - Atualiza previsão no Firestore
   - Gera novos insights com OpenAI
   - Envia notificação push para participantes

4. **No dia do evento**:
   - Notificação matinal com resumo completo
   - Recomendações finais
   - Alertas críticos (se houver)

### Configurar Cloud Function (Opcional)

Para ativar verificação automática, crie Cloud Function:

```bash
cd functions
npm install
firebase deploy --only functions
```

A função `checkWeatherChanges` rodará diariamente às 8h (horário configurável).

---

## 📊 Métricas e Analytics

### Firebase Analytics

Já configurado! Métricas automáticas:
- Usuários ativos
- Sessões
- Eventos criados
- Tempo de uso

### Eventos Personalizados

Para adicionar tracking:

```dart
FirebaseAnalytics.instance.logEvent(
  name: 'event_created',
  parameters: {
    'event_type': activity.type.label,
    'days_until': daysUntil,
  },
);
```

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👥 Autores

**VLab Software**
- Website: [vlabsoftware.com](https://vlabsoftware.com)
- Email: contact@vlabsoftware.com
- GitHub: [@VLab-Software](https://github.com/VLab-Software)

---

## 🙏 Agradecimentos

- **NASA Space Apps Challenge** - Inspiração e dados
- **Meteomatics** - API meteorológica de alta qualidade
- **OpenAI** - Inteligência artificial para insights
- **Firebase** - Backend e hosting
- **Flutter Team** - Framework incrível

---

## 📞 Suporte

Para suporte, envie email para: roosoars@icloud.com

Ou abra uma issue no GitHub: [github.com/VLab-Software/Climetry/issues](https://github.com/VLab-Software/Climetry/issues)

---

**Desenvolvido com ❤️ para o NASA Space Apps Challenge 2025**
