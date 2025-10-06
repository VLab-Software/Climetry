# 🌤️ Climetry - Intelligent Weather Analysis for Your Events# 🌤️ Climetry - NASA Space Apps Challenge# Climetry



> **NASA Space Apps Challenge 2024 Project**  

> Empowering users with AI-driven weather insights and disaster tracking powered by NASA data

**Monitoramento Climático Inteligente com IA para Eventos**Discover the science of perfect weather. Analyze climate probabilities powered by NASA data — anywhere, anytime.

[![Flutter](https://img.shields.io/badge/Flutter-3.24.5-02569B?logo=flutter)](https://flutter.dev)

[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase)](https://firebase.google.com)

[![NASA](https://img.shields.io/badge/NASA-EONET-0B3D91?logo=nasa)](https://eonet.gsfc.nasa.gov/)

[![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4o--mini-412991?logo=openai)](https://openai.com)Climetry é uma aplicação Flutter que utiliza dados meteorológicos em tempo real da API Meteomatics e inteligência artificial da OpenAI para fornecer insights climáticos precisos e recomendações personalizadas para eventos.## Getting Started



🌐 **Live Demo**: [https://nasa-climetry.web.app](https://nasa-climetry.web.app)



---[![Flutter](https://img.shields.io/badge/Flutter-3.24.5-blue.svg)](https://flutter.dev)This project is a starting point for a Flutter application.



## 📋 Table of Contents[![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg)](https://firebase.google.com)



- [Overview](#overview)[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)A few resources to get you started if this is your first Flutter project:

- [Key Features](#key-features)

- [Technology Stack](#technology-stack)

- [Getting Started](#getting-started)

- [Complete Feature Guide](#complete-feature-guide)## 🌟 Funcionalidades- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)

- [Architecture](#architecture)

- [API Documentation](#api-documentation)- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

- [Deployment Guide](#deployment-guide)

### 📊 Monitoramento Climático

---

- Previsão meteorológica detalhada até 180 diasFor help getting started with Flutter development, view the

## 🎯 Overview

- Dados em tempo real: temperatura, precipitação, vento, UV, umidade[online documentation](https://docs.flutter.dev/), which offers tutorials,

**Climetry** is an intelligent event planning assistant that combines real-time weather forecasting, historical climate data, and NASA's natural disaster tracking to help users make informed decisions about their outdoor activities and events.

- Alertas automáticos (ondas de calor, chuvas intensas, granizo, ventania)samples, guidance on mobile development, and a full API reference.

### The Problem We Solve

- Comparação com médias históricas de 10 anos

- ❌ Unexpected weather ruins outdoor events

- ❌ No easy way to compare forecasts with historical patterns### 🤖 Inteligência Artificial

- ❌ Natural disasters aren't factored into planning- Insights personalizados gerados por GPT-4o-mini

- ❌ Manual research across multiple sources- Recomendações específicas por tipo de evento

- Análise de impacto climático em tempo real

### Our Solution- Atualização automática de insights quando clima muda



- ✅ **AI-Powered Insights**: GPT-4o-mini analyzes weather patterns### 🔔 Sistema de Notificações

- ✅ **Historical Comparison**: 10-year climate averages- Monitoramento contínuo até o dia do evento

- ✅ **NASA Integration**: Real-time disaster tracking- Alertas push quando clima muda significativamente (>3°C, >20% chuva)

- ✅ **Smart Alerts**: Customizable weather monitoring- Notificação matinal no dia do evento

- ✅ **Collaborative Planning**: Invite friends with role-based permissions- Integração com Firebase Cloud Messaging



---### 📈 Visualização de Dados

- Gráficos interativos (temperatura, precipitação, vento, UV)

## ⭐ Key Features- Cards expansíveis com detalhes completos

- Rating de condições climáticas (0-10)

### 1. 🤖 AI-Powered Weather Analysis- Interface responsiva dark/light

OpenAI GPT-4o-mini provides contextual insights based on:

- Event type (sports, concerts, camping, etc.)### 👥 Colaboração

- Weather forecast data- Sistema de eventos compartilhados

- Historical climate comparisons- Gestão de participantes com roles (owner, admin, moderator)

- NASA disaster alerts- Convites via email

- Risk assessment (Low/Moderate/High)- Sincronização em tempo real via Firestore



### 2. 📊 Historical Climate Comparison---

Compare your event date weather with 10-year averages:

- Temperature trends## 📋 Requisitos do Sistema

- Precipitation patterns

- Wind speed variations### Desenvolvimento

- Humidity levels- **Flutter SDK**: 3.24.5 ou superior

- Visual "better/worse than average" indicators- **Dart SDK**: 3.5.4 ou superior

- **Node.js**: 16.x ou superior (para Firebase)

### 3. 🌍 NASA EONET Disaster Tracking- **CocoaPods**: 1.11.0+ (para iOS)

Real-time monitoring of:- **Xcode**: 15.0+ (para iOS)

- 🌪️ Severe Storms- **Android Studio**: Latest (para Android)

- 🔥 Wildfires

- 🌋 Volcanoes### Contas Necessárias

- 🌊 Floods- **Firebase**: Projeto configurado com Authentication, Firestore, Storage, Hosting, Cloud Messaging

- ❄️ Snow/Ice- **Meteomatics**: Conta com credenciais (username/password)

- 🌀 Tropical Cyclones- **OpenAI**: API Key com acesso ao GPT-4o-mini

- **Google Maps**: API Key (opcional para mapas)

### 4. 👥 Collaborative Event Management- **Apple Developer**: Conta paga para distribuição iOS ($99/ano)

- Invite friends via email

- Role-based permissions (Owner, Admin, Moderator, Participant)---

- Real-time Firebase sync

- Push notifications## 🚀 Configuração do Projeto



### 5. 📍 Smart Location Features### 1. Clone o Repositório

- Google Places Autocomplete

- Interactive map picker```bash

- Current location detectiongit clone https://github.com/VLab-Software/Climetry.git

- Distance-based disaster filteringcd Climetry

```

### 6. 🔔 Intelligent Alerts

- Temperature warnings### 2. Instale Dependências

- Rain alerts

- Wind speed notifications```bash

- Storm warningsflutter pub get

- Firebase Cloud Messaging```



---### 3. Configure Variáveis de Ambiente



## 🛠️ Technology StackCrie o arquivo `.env` na raiz do projeto:



- **Flutter 3.24.5** - Cross-platform framework```bash

- **Firebase** - Firestore, Auth, Cloud Messaging, Hostingcp .env.example .env

- **Meteomatics API** - Weather + Climate Normals```

- **NASA EONET API** - Natural disaster data

- **OpenAI GPT-4o-mini** - AI analysisEdite `.env` com suas credenciais reais:

- **Google Maps/Places API** - Location services

```env

---OPENAI_API_KEY=sk-proj-YOUR_OPENAI_KEY_HERE

METEOMATICS_USERNAME=your_meteomatics_username

## 🚀 Getting StartedMETEOMATICS_PASSWORD=your_meteomatics_password

GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_KEY_HERE

### Prerequisites```



```bash⚠️ **IMPORTANTE**: O arquivo `.env` está no `.gitignore` e nunca será commitado. Use `.env.example` como template.

flutter doctor

# Requires: Flutter 3.24.5+, Dart 3.5+---

```

## 🔥 Configuração do Firebase

### Installation

### Passo 1: Criar Projeto Firebase

```bash

# Clone repository1. Acesse [Firebase Console](https://console.firebase.google.com)

git clone https://github.com/VLab-Software/Climetry.git2. Clique em "Adicionar projeto"

cd Climetry3. Nome: `nasa-climetry` (ou seu nome preferido)

4. Habilite Google Analytics (opcional)

# Install dependencies5. Clique em "Criar projeto"

flutter pub get

### Passo 2: Configurar Authentication

# Set up environment variables

# Create .env file with:1. No painel lateral, vá em **Authentication**

METEOMATICS_USERNAME=your_username2. Clique em "Começar"

METEOMATICS_PASSWORD=your_password3. Habilite os provedores:

OPENAI_API_KEY=your_key   - ✅ **E-mail/Senha**

GOOGLE_MAPS_API_KEY=your_key   - ✅ **Google** (opcional)

4. Em "Settings" > "Authorized domains", adicione:

# Run app   - `localhost`

flutter run -d chrome  # Web   - `nasa-climetry.web.app`

flutter run -d ios     # iOS   - `nasa-climetry.firebaseapp.com`

flutter run -d android # Android   - Seu domínio customizado (se tiver)

```

### Passo 3: Configurar Firestore Database

### Build for Production

1. No painel lateral, vá em **Firestore Database**

```bash2. Clique em "Criar banco de dados"

# Web3. Escolha **Modo de produção**

flutter build web --release4. Selecione localização: `us-central1` (ou mais próxima)

firebase deploy --only hosting5. Copie as regras de segurança de `firestore.rules`:



# Android```javascript

flutter build apk --releaserules_version = '2';

service cloud.firestore {

# iOS  match /databases/{database}/documents {

flutter build ios --release    function isSignedIn() {

```      return request.auth != null;

    }

---    

    function isOwner(userId) {

## 📖 Complete Feature Guide      return isSignedIn() && request.auth.uid == userId;

    }

### Creating Your First Event

    match /users/{userId} {

#### Step 1: Basic Information Tab      allow read: if isSignedIn();

      allow write: if isOwner(userId);

1. **Tap the + button** (Home or Ewinds screen)    }

2. **Enter event title** (required)

   ```    match /activities/{activityId} {

   Example: "Beach BBQ with Friends"      allow read: if isSignedIn();

   ```      allow create: if isSignedIn();

3. **Enter location**:      allow update, delete: if isSignedIn() && 

   - Type to search (Google Places Autocomplete)        (resource.data.ownerId == request.auth.uid || 

   - Tap map icon to pick on map         request.auth.uid in resource.data.participants);

   - Use "Use current location"    }

4. **Select date and time**:

   - Date picker (today or future)    match /weather_monitoring/{docId} {

   - Optional start time      allow read, write: if isSignedIn();

   - Optional end time    }



#### Step 2: Event Type & Priority    match /weather_insights/{docId} {

      allow read: if isSignedIn();

**Event Types** (with icons):      allow write: if false;

- 🏃 Sports & Fitness    }

- 🎵 Outdoor Concerts

- 🏕️ Camping & Hiking    match /notifications/{notificationId} {

- 🍖 BBQ & Picnics      allow read: if isSignedIn() && resource.data.userId == request.auth.uid;

- 🚴 Cycling      allow write: if isSignedIn();

- ⛱️ Beach Activities    }

- 🎉 Festivals  }

- 📸 Photography}

- 🌳 Gardening```

- 📚 Other

### Passo 4: Configurar Storage

**Priority Levels**:

- 🔴 **Urgent**: Within 24 hours1. No painel lateral, vá em **Storage**

- 🟠 **High**: Within 3 days2. Clique em "Começar"

- 🟡 **Medium**: Within a week3. Escolha **Modo de produção**

- 🟢 **Low**: No rush4. Copie as regras de `storage.rules`:



**Recurrence Options**:```javascript

- None (single event)rules_version = '2';

- Dailyservice firebase.storage {

- Weekly  match /b/{bucket}/o {

- Monthly    match /users/{userId}/{allPaths=**} {

      allow read: if request.auth != null;

**Description** (optional):      allow write: if request.auth != null && request.auth.uid == userId;

- Add details about the event    }

- Special instructions    

- What to bring    match /activities/{activityId}/{allPaths=**} {

      allow read: if request.auth != null;

#### Step 3: Participants Tab      allow write: if request.auth != null;

    }

1. **Tap "Invite Friends"**  }

2. **Select from your friends list**}

3. **Assign roles**:```

   - **Owner** 🏆: Full control (creator)

   - **Admin** 👑: Can modify and invite### Passo 5: Configurar Cloud Messaging (Notificações Push)

   - **Moderator** 🎖️: Can edit details

   - **Participant** 👤: View-only1. No painel lateral, vá em **Cloud Messaging**

2. Clique em "Começar"

4. **Confirm selection**3. **Android**:

   - Participants receive push notification   - O FCM é configurado automaticamente com o `google-services.json`

   - Real-time sync across devices4. **iOS**:

   - Faça upload do certificado APNs (veremos na seção iOS)

#### Step 4: Notifications Tab5. **Web**:

   - Copie o "Server Key" e "Sender ID" (salvos automaticamente)

**Weather Conditions to Monitor**:

- ☀️ Temperature### Passo 6: Configurar Hosting (Web)

- 🌧️ Rain/Precipitation

- 💨 Wind Speed1. No painel lateral, vá em **Hosting**

- 🌡️ Humidity2. Clique em "Começar"

3. Instale Firebase CLI:

**Custom Alert Settings**:

``````bash

Example:npm install -g firebase-tools

- Notify if temp exceeds 95°F```

- Alert if rain probability > 50%

- Warn if wind speed > 25 mph4. Faça login:

```

```bash

#### Step 5: Advanced Settings Tabfirebase login

```

**Tags** (optional):

```5. Inicialize o projeto:

Add tags for organization:

#outdoor #summer #friends #bbq```bash

firebase init hosting

How to add:```

- Type tag name

- Press comma or enterSelecione:

- Remove by tapping X- ✅ Use an existing project: `nasa-climetry`

```- Public directory: `build/web`

- Configure as single-page app: **Yes**

**Create Event**:- Set up automatic builds: **No**

- Tap blue "Create Ewind" button (bottom)

- System automatically:6. Deploy:

  1. Saves to Firestore

  2. Fetches weather forecast```bash

  3. Gets climate normals (10-year avg)flutter build web --release

  4. Checks NASA disastersfirebase deploy --only hosting

  5. Generates AI analysis```



---Sua aplicação estará disponível em: `https://nasa-climetry.web.app`



### Understanding Your Event Analysis---



After creating an event, you'll see an analysis card with:## 📱 Configuração iOS



#### 1. Risk Assessment Badge### Passo 1: Pré-requisitos

```

🟢 LOW RISK1. **Mac com macOS** (necessário para desenvolvimento iOS)

- Weather is favorable2. **Xcode 15.0+** instalado via App Store

- No disasters nearby3. **CocoaPods** instalado:

- Better than average conditions

```bash

🟡 MODERATE RISKsudo gem install cocoapods

- Some concerning conditions```

- Monitor weather updates

- Have backup plan4. **Conta Apple Developer** ($99/ano) em [developer.apple.com](https://developer.apple.com)



🔴 HIGH RISK### Passo 2: Configurar Bundle Identifier

- Dangerous conditions

- Consider rescheduling1. Abra `ios/Runner.xcworkspace` no Xcode

- Alternative dates suggested2. Selecione o projeto **Runner** no navegador

```3. Em "General" > "Identity":

   - **Bundle Identifier**: `com.vlabsoftware.climetry`

#### 2. Weather Summary Section   - **Display Name**: `Climetry`

   - **Version**: `1.0.0`

**Current Forecast**:   - **Build**: `1`

```

Temperature: 88°F### Passo 3: Adicionar Firebase ao iOS

Conditions: Partly Cloudy

Rain Chance: 20%1. No Firebase Console, clique no ícone **iOS** para adicionar app

Wind: 12 mph ENE2. Bundle ID: `com.vlabsoftware.climetry`

Humidity: 65%3. App nickname: `Climetry iOS`

```4. Baixe `GoogleService-Info.plist`

5. Arraste o arquivo para `ios/Runner/` no Xcode

**Historical Comparison**:6. ✅ Marque "Copy items if needed"

```7. ✅ Selecione target "Runner"

📊 Forecast vs 10-Year Average

### Passo 4: Configurar Certificados e Provisioning

Temperature:

88°F current | 84°F average1. No Xcode, vá em **Signing & Capabilities**

✅ 4°F warmer than usual2. Marque **Automatically manage signing**

3. Selecione seu **Team** (Apple Developer Account)

Precipitation:4. O Xcode criará automaticamente:

0.2" forecast | 0.35" average   - Development Certificate

✅ 40% less rain than usual   - Provisioning Profile

   - App ID

Wind Speed:

12 mph forecast | 10 mph average### Passo 5: Adicionar Capabilities

⚠️ Slightly windier than normal

No Xcode, vá em **Signing & Capabilities** e adicione:

Humidity:

65% forecast | 63% average1. **Push Notifications**:

✓ Typical for this date   - Clique em "+ Capability"

```   - Busque e adicione "Push Notifications"



#### 3. AI-Generated Insights2. **Background Modes**:

   - Clique em "+ Capability"

**Example Output**:   - Busque e adicione "Background Modes"

```   - ✅ Marque "Remote notifications"

🌤️ Great day for your beach BBQ!

### Passo 6: Configurar APNs (Apple Push Notification service)

Analysis:

Temperature is perfect at 88°F with partly cloudy 1. Acesse [Apple Developer Portal](https://developer.apple.com/account/)

skies. Light winds of 12 mph will keep things 2. Vá em **Certificates, Identifiers & Profiles**

comfortable. Small chance of brief afternoon 3. Clique em **Keys** (chaves)

showers (20%), so bring a tent just in case.4. Clique no **+** para criar nova chave

5. Nome: `Climetry APNs Key`

Historical Context:6. ✅ Marque **Apple Push Notifications service (APNs)**

Conditions are better than the historical average 7. Clique em "Continue" e "Register"

for July 15th. Temperatures are 4°F warmer and 8. **Baixe o arquivo .p8** (só pode baixar uma vez!)

precipitation is 40% less than typical.9. Anote o **Key ID**



Recommendations:10. No Firebase Console:

✅ Apply sunscreen (UV index moderate)    - Vá em **Project Settings** > **Cloud Messaging**

✅ Bring shade umbrellas    - Na seção **Apple app configuration**

✅ Have rain backup plan    - Clique em "Upload" em **APNs Authentication Key**

✅ Stay hydrated    - Faça upload do arquivo .p8

    - Insira:

Data Sources:      - **Key ID**: (anotado no passo 9)

- Weather: Meteomatics API      - **Team ID**: (encontre em Account Settings no Apple Developer)

- Climate Normals: 10-year average (2014-2024)

- Disasters: NASA EONET### Passo 7: Instalar Dependências iOS



Have a great time! 🏖️```bash

```cd ios

pod install

#### 4. NASA Disaster Alertscd ..

```

**If disasters detected within 500km**:

```### Passo 8: Build para Dispositivo Físico

⚠️ ACTIVE DISASTERS NEARBY

1. Conecte seu iPhone via USB

🔥 Wildfire2. Confie no computador no iPhone (popup)

Location: 120 miles west3. No Xcode, selecione seu dispositivo no topo

Status: Active since July 104. Pressione **Cmd + R** ou clique no botão ▶️ Play

Impact: Possible smoke affecting air quality

Details: Monitor air quality index**Ou via terminal:**



🌪️ Severe Storm```bash

Location: 300 miles northeast  flutter build ios --release

Status: Active since July 14```

Impact: Minimal, moving away

```**Para instalar no dispositivo:**



**If no disasters**:```bash

```flutter install --device-id=YOUR_DEVICE_ID

✅ NO ACTIVE DISASTERS DETECTED```

All clear within 500km radius

```Para ver device ID:



#### 5. Alternative Dates```bash

flutter devices

**Shown when risk is Moderate/High**:```

```

📅 SUGGESTED ALTERNATIVES### Passo 9: Distribuição (TestFlight ou App Store)



Option 1: July 16 (Wednesday)1. No Xcode, vá em **Product** > **Archive**

Risk: LOW2. Aguarde o build finalizar

Temp: 82°F | Rain: 5%3. Na janela Archives, clique em "Distribute App"

Why better: Lower temps, no rain4. Escolha:

   - **TestFlight & App Store** (para testar com beta testers)

Option 2: July 18 (Friday)   - **Ad Hoc** (para distribuição limitada)

Risk: LOW5. Siga o wizard para fazer upload para App Store Connect

Temp: 85°F | Rain: 10%

Why better: Perfect conditions, light breeze---

```

## 🤖 Configuração Android

---

### Passo 1: Adicionar Firebase ao Android

### Viewing & Managing Events

1. No Firebase Console, clique no ícone **Android** para adicionar app

#### Home Screen2. Package name: `com.vlabsoftware.climetry`

- **Shows**: Events with AI analysis3. App nickname: `Climetry Android`

- **Sorted by**: Date (upcoming first)4. Baixe `google-services.json`

- **Filter button** (top right):5. Coloque em `android/app/google-services.json`

  - Sort by Time (chronological)

  - Sort by Distance (nearest first)### Passo 2: Configurar Signing (Release)

  - Sort by Priority (urgent first)

1. Crie keystore para assinatura:

#### Ewinds Screen

- **Shows**: All your events (past & future)```bash

- **Tabs**: All | Upcoming | Pastkeytool -genkey -v -keystore ~/climetry-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias climetry

- **Filter options**: Same as Home + recurrence filter```

- **Search**: By name or tags

2. Crie `android/key.properties`:

#### Event Details Screen

```properties

**Tap any event card to see**:storePassword=YOUR_STORE_PASSWORD

1. Full weather analysiskeyPassword=YOUR_KEY_PASSWORD

2. Hour-by-hour forecast (if available)keyAlias=climetry

3. NASA disaster mapstoreFile=/Users/SEU_USUARIO/climetry-release-key.jks

4. Historical comparison charts```

5. AI recommendations

6. Participant list3. Em `android/app/build.gradle`, o signing já está configurado para ler do `key.properties`

7. Share options

### Passo 3: Build para Android

---

**Debug (para teste):**

### Editing Events

```bash

**For Owners & Admins**:flutter build apk --debug

``````

1. Find event in Ewinds tab

2. Tap three-dot menu (⋮)**Release (para produção):**

3. Select "Edit"

4. Modify any field```bash

5. Tap "Save Changes"flutter build apk --release

```

All participants see updates in real-time via Firebase

```**App Bundle (para Play Store):**



**What you can edit**:```bash

- Title, descriptionflutter build appbundle --release

- Location, date, time```

- Event type, priority

- Recurrence settings**Instalar no dispositivo conectado:**

- Monitored conditions

- Tags```bash

flutter install

**What you cannot edit**:```

- Event ID

- Owner### Passo 4: Publicar na Google Play Store

- Creation date

1. Acesse [Google Play Console](https://play.google.com/console)

---2. Crie uma conta de desenvolvedor ($25 taxa única)

3. Clique em "Criar app"

### Deleting Events4. Preencha informações do app

5. Faça upload do `app-release.aab`

**For Owners only**:6. Configure:

```   - Classificação de conteúdo

1. Tap three-dot menu (⋮)   - Preço e distribuição (Gratuito)

2. Select "Delete"   - Política de privacidade

3. Confirm deletion7. Envie para revisão



⚠️ This removes the event for all participants---

Cannot be undone

```## 🔑 Configuração das APIs



---### OpenAI API



### Sharing Events1. Acesse [platform.openai.com](https://platform.openai.com)

2. Crie uma conta (requer cartão de crédito)

**After creating an event**:3. Vá em **API Keys**

```4. Clique em "Create new secret key"

Options available:5. Copie a chave (só aparece uma vez!)

1. ��️ Add to Calendar6. Cole no `.env`:

   - iOS/Android native calendar

   - Creates event with all details```env

OPENAI_API_KEY=sk-proj-xxxxxxxxxxxx

2. 💬 Share via WhatsApp```

   - Sends event details as message

   - Includes weather summary**Custos estimados:**

- GPT-4o-mini: ~$0.15 por 1M tokens de entrada

3. 📤 System Share- Uso médio: <$5/mês para uso moderado

   - Share via any app

   - Email, Messages, etc.### Meteomatics API

```

1. Acesse [meteomatics.com](https://www.meteomatics.com)

---2. Entre em contato para criar conta

3. Após aprovação, você receberá:

### Friend Management   - Username

   - Password

#### Adding Friends4. Cole no `.env`:



``````env

1. Go to Settings → Manage FriendsMETEOMATICS_USERNAME=seu_usuario

2. Tap "Add Friend" buttonMETEOMATICS_PASSWORD=sua_senha

3. Enter friend's email address```

   (Must have Climetry account)

4. Send friend request**Plano recomendado:**

5. Friend accepts in their app- Weather API Professional

6. Now you can invite them to events- Máximo 10 parâmetros por requisição

```- Previsões até 180 dias



#### Managing Friendships### Google Maps API (Opcional)



**In Friend List**:1. Acesse [Google Cloud Console](https://console.cloud.google.com)

- View all friends2. Crie um novo projeto ou use existente

- See mutual events3. Habilite **Maps SDK for Android** e **Maps SDK for iOS**

- Remove friends (tap X)4. Vá em **Credenciais**

- Block users (from menu)5. Crie **API Key**

6. Restrinja a chave:

**Friend Permissions in Events**:   - Android: adicione SHA-1 do seu app

```   - iOS: adicione Bundle ID `com.vlabsoftware.climetry`

You can assign roles when inviting:7. Cole no `.env`:

- Admin: Can modify event + invite others

- Moderator: Can edit event details```env

- Participant: View-only accessGOOGLE_MAPS_API_KEY=AIzaSyxxxxxxxxxxxxx

```

Owner can change roles anytime

```**Tier Gratuito:**

- $200 de crédito mensal

---- ~28.000 visualizações de mapa por mês



### Notifications---



#### Types of Notifications## 🏗️ Estrutura do Projeto



1. **Event Invitations**```

   ```lib/

   "John invited you to 'Beach BBQ'"├── main.dart                           

   Tap to accept/decline├── src/

   ```│   ├── app.dart                        

│   ├── core/

2. **Weather Alerts**│   │   ├── auth/                       

   ```│   │   ├── network/                    

   "⚠️ Rain probability increased to 80%"│   │   ├── services/                   

   For: Beach BBQ (July 15)│   │   ├── theme/                      

   ```│   │   └── widgets/                    

│   └── features/

3. **Event Reminders**│       ├── activities/                 

   ```│       │   ├── data/                   

   24 hours before: "Event tomorrow: Beach BBQ"│       │   ├── domain/                 

   1 hour before: "Event starting soon!"│       │   └── presentation/           

   ```│       ├── auth/                       

│       ├── climate/                    

4. **Role Changes**│       ├── disasters/                  

   ```│       ├── friends/                    

   "You're now an Admin for 'Beach BBQ'"│       ├── home/                       

   New permissions unlocked│       ├── settings/                   

   ```│       └── weather/                    

│           ├── data/                   

5. **Event Updates**│           │   └── services/

   ```│           │       ├── meteomatics_service.dart           

   "Beach BBQ location changed"│           │       └── weather_monitoring_service.dart    

   New location: Santa Monica Beach│           ├── domain/

   ```│           │   ├── entities/           

│           │   └── models/             

#### Notification Settings│           └── presentation/

│               └── widgets/            

**Configure in Settings → Notifications**:```

```

Master Switch:---

- Enable/Disable all notifications

## 🧪 Executando o Projeto

Weather Alerts:

- Temperature threshold: e.g., above 95°F### Web

- Rain probability: e.g., above 50%

- Wind speed: e.g., above 25 mph```bash

- Storm warnings: Always onflutter run -d chrome

```

Event Reminders:

- 24 hours before### iOS (Simulator)

- 1 hour before

- At event time```bash

flutter run -d "iPhone 15 Pro"

Social Notifications:```

- Friend requests

- Event invitations### iOS (Device)

- Role changes

- Event updates```bash

```flutter devices

flutter run -d YOUR_DEVICE_ID

---```



### User Preferences### Android (Emulator)



#### Temperature Units```bash

```flutter emulators --launch Pixel_7_API_34

Go to Settings → Temperatureflutter run

```

Options:

- Celsius (°C) - Metric### Android (Device)

- Fahrenheit (°F) - Imperial

```bash

Affects:flutter run -d YOUR_DEVICE_ID

- All temperature displays```

- API requests

- Historical comparisons---

```

## 📦 Build de Produção

#### Wind Speed Units

```### Web

Settings → Wind

```bash

Options:flutter build web --release

- km/h - Metricfirebase deploy --only hosting

- mph - Imperial```



Used in:### iOS

- Weather forecasts

- Wind alerts```bash

- Historical dataflutter build ios --release

``````



#### Precipitation UnitsDepois, use Xcode para Archive e distribuir.

```

Settings → Precipitation### Android



Options:```bash

- Millimeters (mm) - Metricflutter build appbundle --release

- Inches (in) - Imperial```



Affects:Upload do `build/app/outputs/bundle/release/app-release.aab` para Play Console.

- Rain forecasts

- Climate normals---

- Alert thresholds

```## 🐛 Troubleshooting



#### Location Preferences### Erro: "GoogleService-Info.plist not found"

```**Solução**: Certifique-se de que o arquivo está em `ios/Runner/` e foi adicionado ao target Runner no Xcode.

Settings → Location

### Erro: "CocoaPods not installed"

Toggle "Use Current Location":**Solução**: 

- ON: Auto-detects your location```bash

- OFF: Must search manuallysudo gem install cocoapods

cd ios && pod install

Permissions:```

- Requires location permission

- Works on all platforms### Erro: "API key inválida"

```**Solução**: Verifique se o `.env` foi criado e contém as chaves corretas. Execute:

```bash

---flutter clean

flutter pub get

## 🏗️ Architecture```



### Clean Architecture Structure### Erro de certificado iOS

**Solução**: 

```1. Abra Xcode

lib/2. Vá em Preferences > Accounts

├── src/3. Adicione sua conta Apple Developer

│   ├── core/                    # Core functionality4. Em Signing & Capabilities, clique em "Download Manual Profiles"

│   │   ├── services/

│   │   │   ├── event_weather_prediction_service.dart### Build iOS falha com "No profiles found"

│   │   │   ├── user_data_service.dart**Solução**:

│   │   │   └── event_sharing_service.dart1. No Xcode, desmarque "Automatically manage signing"

│   │   ├── theme/              # App theming2. Marque novamente

│   │   └── widgets/            # Shared components3. Selecione seu team

│   │4. Clean Build Folder (Cmd + Shift + K)

│   ├── features/               # Feature modules

│   │   ├── activities/         # Event CRUD### Notificações push não funcionam

│   │   ├── auth/               # Login/Register**Solução**:

│   │   ├── climate/            # Historical data1. Verifique se APNs key foi carregado no Firebase

│   │   ├── disasters/          # NASA integration2. Confirme que Push Notifications capability está ativa

│   │   ├── friends/            # Social features3. Teste com dispositivo físico (simulador não recebe push)

│   │   ├── home/               # Dashboard

│   │   ├── settings/           # Preferences---

│   │   └── weather/            # Forecasts

│   │## 🔄 Sistema de Monitoramento Climático

│   └── main.dart               # Entry point

```O Climetry possui um sistema inteligente de monitoramento contínuo:



### Data Flow### Como Funciona



```1. **Ao criar um evento**:

User Input   - Sistema salva previsão inicial no Firestore

    ↓   - Inicia monitoramento automático

UI Widget (Flutter)

    ↓2. **Verificação Diária**:

Repository (Business Logic)   - Firebase Cloud Function roda a cada 24h

    ↓   - Compara previsão atual com última salva

API Service (HTTP Client)   - Detecta mudanças significativas:

    ↓     - Temperatura: >3°C

External API (REST)     - Chuva: >20% probabilidade

    ↓     - Vento: >15 km/h

Parse JSON Response

    ↓3. **Quando detecta mudança**:

Update Firestore   - Atualiza previsão no Firestore

    ↓   - Gera novos insights com OpenAI

StreamBuilder Updates UI   - Envia notificação push para participantes

```

4. **No dia do evento**:

### State Management   - Notificação matinal com resumo completo

   - Recomendações finais

- **Provider**: Global app state   - Alertas críticos (se houver)

- **StreamBuilder**: Firebase real-time updates

- **FutureBuilder**: Async operations### Configurar Cloud Function (Opcional)

- **ValueNotifier**: Local state

- **ChangeNotifier**: Custom notifiersPara ativar verificação automática, crie Cloud Function:



---```bash

cd functions

## 🔌 API Documentationnpm install

firebase deploy --only functions

### 1. Meteomatics Weather API```



#### Weather Forecast EndpointA função `checkWeatherChanges` rodará diariamente às 8h (horário configurável).



**Request**:---

```http

GET /2024-07-15T12:00:00Z/t_2m:F,precip_1h:in,wind_speed_10m:mph,relative_humidity_2m:p/34.0522,-118.2437/json## 📊 Métricas e Analytics

Authorization: Basic <base64(username:password)>

```### Firebase Analytics



**Parameters**:Já configurado! Métricas automáticas:

- `t_2m:F` - Temperature at 2m in Fahrenheit- Usuários ativos

- `precip_1h:in` - Precipitation in inches- Sessões

- `wind_speed_10m:mph` - Wind speed at 10m in mph- Eventos criados

- `relative_humidity_2m:p` - Humidity percentage- Tempo de uso



**Response**:### Eventos Personalizados

```json

{Para adicionar tracking:

  "data": [

    {```dart

      "parameter": "t_2m:F",FirebaseAnalytics.instance.logEvent(

      "coordinates": [{"lat": 34.0522, "lon": -118.2437}],  name: 'event_created',

      "dates": [  parameters: {

        {    'event_type': activity.type.label,

          "date": "2024-07-15T12:00:00Z",    'days_until': daysUntil,

          "value": 88.0  },

        });

      ]```

    }

  ]---

}

```## 🤝 Contribuindo



#### Climate Normals Endpoint1. Fork o projeto

2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)

**Request**:3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)

```http4. Push para a branch (`git push origin feature/AmazingFeature`)

GET /07-15/climate_normals/t_2m:F,precip_1h:in,wind_speed_10m:mph,relative_humidity_2m:p/34.0522,-118.2437/json5. Abra um Pull Request

Authorization: Basic <base64(username:password)>

```---



**Returns**: 10-year historical averages for that specific date## 📄 Licença



---Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.



### 2. NASA EONET API---



**Endpoint**:## 👥 Autores

```http

GET https://eonet.gsfc.nasa.gov/api/v3/events?status=open**VLab Software**

```- Website: [vlabsoftware.com](https://vlabsoftware.com)

- Email: contact@vlabsoftware.com

**No Authentication Required** ✅- GitHub: [@VLab-Software](https://github.com/VLab-Software)



**Response**:---

```json

{## 🙏 Agradecimentos

  "title": "EONET Events",

  "events": [- **NASA Space Apps Challenge** - Inspiração e dados

    {- **Meteomatics** - API meteorológica de alta qualidade

      "id": "EONET_6234",- **OpenAI** - Inteligência artificial para insights

      "title": "Wildfire - California, United States",- **Firebase** - Backend e hosting

      "categories": [- **Flutter Team** - Framework incrível

        {

          "id": "wildfires",---

          "title": "Wildfires"

        }## 📞 Suporte

      ],

      "geometry": [Para suporte, envie email para: roosoars@icloud.com

        {

          "date": "2024-07-10T00:00:00Z",Ou abra uma issue no GitHub: [github.com/VLab-Software/Climetry/issues](https://github.com/VLab-Software/Climetry/issues)

          "type": "Point",

          "coordinates": [-122.4194, 37.7749]---

        }

      ],**Desenvolvido com ❤️ para o NASA Space Apps Challenge 2025**

      "closed": null
    }
  ]
}
```

**Event Categories**:
- volcanoes
- severeStorms
- wildfires
- floods
- drought
- dustHaze
- snow
- seaLakeIce

---

### 3. OpenAI GPT-4o-mini

**Model**: `gpt-4o-mini`

**System Prompt**:
```
You are a specialized weather advisor analyzing conditions for outdoor events.
Provide risk assessment, analysis, and recommendations based on weather data,
historical comparisons, and NASA disaster alerts.
```

**User Prompt Template**:
```
Analyze weather for: {event_type} - {title}

LOCATION: {location} ({lat}, {lon})
DATE: {date}
PRIORITY: {priority}

WEATHER FORECAST:
Temperature: {temp}°F
Conditions: {conditions}
Rain: {rain_prob}%
Wind: {wind_speed} mph {wind_dir}
Humidity: {humidity}%

HISTORICAL COMPARISON (10-year avg):
Temperature: {forecast_temp}°F vs {avg_temp}°F ({diff}°F {warmer/cooler})
Precipitation: {forecast_precip}" vs {avg_precip}" ({diff}% {more/less})
Wind: {forecast_wind} mph vs {avg_wind} mph

NASA DISASTERS (within 500km):
{disaster_list or "None detected"}

Provide:
1. Risk level (Low/Moderate/High)
2. 2-3 sentence weather analysis
3. Specific recommendations (3-5 items)
4. Alternative dates if high risk (2 suggestions)

Use emojis, be concise, cite data sources.
```

**API Request**:
```dart
final response = await http.post(
  Uri.parse('https://api.openai.com/v1/chat/completions'),
  headers: {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'model': 'gpt-4o-mini',
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ],
    'temperature': 0.7,
    'max_tokens': 500,
  }),
);
```

---

### 4. Google Places API

**Autocomplete**:
```http
GET https://maps.googleapis.com/maps/api/place/autocomplete/json
  ?input={query}
  &key={API_KEY}
  &types=geocode
```

**Place Details**:
```http
GET https://maps.googleapis.com/maps/api/place/details/json
  ?place_id={place_id}
  &key={API_KEY}
  &fields=geometry,formatted_address
```

---

## 🚀 Deployment Guide

### Web (Firebase Hosting)

**1. Build**:
```bash
flutter build web --release --no-tree-shake-icons
```

**2. Deploy**:
```bash
firebase deploy --only hosting
```

**3. Custom Domain** (optional):
```bash
firebase hosting:channel:deploy production
```

**4. Cache Configuration**:

`firebase.json`:
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "headers": [
      {
        "source": "/index.html",
        "headers": [
          {"key": "Cache-Control", "value": "no-cache, no-store, must-revalidate"},
          {"key": "Pragma", "value": "no-cache"},
          {"key": "Expires", "value": "0"}
        ]
      },
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp)",
        "headers": [{"key": "Cache-Control", "value": "max-age=604800"}]
      }
    ]
  }
}
```

**Live URL**: [https://nasa-climetry.web.app](https://nasa-climetry.web.app)

---

### Android

**1. Development Build**:
```bash
flutter build apk --debug
```

**2. Release Build**:
```bash
flutter build apk --release
```

**3. App Bundle** (for Play Store):
```bash
flutter build appbundle --release
```

**4. Signing Configuration**:

`android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=climetry
storeFile=/Users/you/keystore.jks
```

`android/app/build.gradle`:
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
```

---

### iOS

**1. Development**:
```bash
flutter build ios --debug
```

**2. Release**:
```bash
flutter build ios --release --no-codesign
```

**3. Wireless Deployment**:
```bash
# Find device
flutter devices

# Deploy to iPhone
flutter run --release -d <device-id>
```

**4. Code Signing**:
- Team ID: `C277ZT2F26`
- Bundle ID: `com.vlabsoftware.climetry`
- Provisioning Profile: Automatic (Xcode managed)

**5. App Store**:
```bash
# In Xcode:
Product → Archive → Distribute App
```

---

### macOS

**Build**:
```bash
flutter build macos --release
```

**Required Entitlements**:
```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

---

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repo
2. Create a feature branch
3. Make changes
4. Run `flutter test`
5. Submit PR

---

## 📄 License

MIT License - see [LICENSE](LICENSE)

---

## 👥 Credits

- **Developer**: Rodrigo Soares
- **Organization**: VLab Software
- **Event**: NASA Space Apps Challenge 2024

---

## 🙏 Acknowledgments

- NASA EONET for disaster data
- Meteomatics for weather API
- OpenAI for GPT-4o-mini
- Flutter team
- Firebase

---

**Made with ❤️ for NASA Space Apps Challenge 2024**

🚀 **Empowering better event planning through intelligent climate analysis** 🌍
