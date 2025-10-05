# Configuração Firebase - Climetry

## Passos para Configurar Firebase

### 1. Criar Projeto no Firebase Console
1. Acesse https://console.firebase.google.com/
2. Clique em "Adicionar projeto"
3. Nome do projeto: **Climetry**
4. Ative o Google Analytics (opcional)
5. Crie o projeto

### 2. Adicionar App iOS
1. No console, clique no ícone do iOS
2. **iOS bundle ID**: `com.vlabsoftware.climetry` (verifique em ios/Runner.xcodeproj)
3. **App nickname**: Climetry iOS
4. Baixe o arquivo `GoogleService-Info.plist`
5. Coloque em: `ios/Runner/GoogleService-Info.plist`
6. No Xcode, adicione o arquivo ao Runner (arraste e solte)

### 3. Adicionar App Android
1. No console, clique no ícone do Android
2. **Android package name**: `com.vlabsoftware.climetry`
3. **App nickname**: Climetry Android
4. Baixe o arquivo `google-services.json`
5. Coloque em: `android/app/google-services.json`

### 4. Configurar Android - build.gradle

**android/build.gradle.kts** - Adicionar no topo:
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}
```

**android/app/build.gradle.kts** - Adicionar no final:
```kotlin
apply(plugin = "com.google.gms.google-services")
```

### 5. Ativar Serviços no Firebase Console

#### Authentication
1. Vá para **Authentication** > **Sign-in method**
2. Ative **Email/Password**
3. Ative **Google**
   - Configure OAuth consent screen
   - Adicione domínios autorizados

#### Firestore Database
1. Vá para **Firestore Database**
2. Clique em **Create database**
3. Escolha localização: **southamerica-east1** (São Paulo)
4. Mode: **Start in test mode** (depois alterar para produção)

**Regras de Segurança (Security Rules)**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir leitura/escrita apenas para usuários autenticados
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /users/{userId}/activities/{activityId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /users/{userId}/preferences/{preferencesId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 6. Configurar Google Sign-In

#### iOS
1. No Firebase Console, vá para Authentication > Sign-in method > Google
2. Copie o **iOS client ID**
3. Edite `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- REVERSED_CLIENT_ID do GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.SEU-CLIENT-ID-AQUI</string>
        </array>
    </dict>
</array>
```

#### Android
O `google-services.json` já contém as configurações necessárias.

### 7. Estrutura de Dados no Firestore

```
/users/{userId}
  - email: string
  - displayName: string
  - photoURL: string
  - createdAt: timestamp
  - preferences: map
    - theme: string ('light' | 'dark' | 'system')
    - language: string ('pt_BR' | 'en_US')
    - temperatureUnit: string ('celsius' | 'fahrenheit')
    - enabledAlerts: array<string>
    - monitoringLocation: map
      - latitude: number
      - longitude: number
      - name: string

/users/{userId}/activities/{activityId}
  - id: string
  - title: string
  - description: string?
  - location: string
  - coordinates: geopoint
  - date: timestamp
  - startTime: string?
  - endTime: string?
  - type: string
  - createdAt: timestamp
  - updatedAt: timestamp
```

### 8. Testar Configuração

```bash
# Rodar app
flutter run

# Verificar logs do Firebase
flutter logs
```

## Status da Implementação

- [x] Dependências adicionadas ao pubspec.yaml
- [ ] GoogleService-Info.plist configurado (iOS)
- [ ] google-services.json configurado (Android)
- [ ] build.gradle configurado
- [ ] Authentication ativado no Firebase
- [ ] Firestore Database criado
- [ ] Google Sign-In configurado
- [ ] Regras de segurança configuradas
- [ ] Estrutura de dados criada

## Comandos Úteis

```bash
# Ver versões do Firebase
flutter pub deps | grep firebase

# Limpar e reconstruir
flutter clean && flutter pub get

# Rodar no iOS
flutter run -d ios

# Rodar no Android
flutter run -d android

# Ver logs
flutter logs

# Build para produção
flutter build ios --release
flutter build apk --release
```
