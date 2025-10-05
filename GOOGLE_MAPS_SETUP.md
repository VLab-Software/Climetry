# 🗺️ Configuração do Google Maps API

## 📋 Passo a Passo

### 1. Obter API Key do Google Cloud

1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Crie um novo projeto ou selecione um existente
3. Vá em **APIs & Services** > **Library**
4. Ative as seguintes APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Maps JavaScript API**
5. Vá em **APIs & Services** > **Credentials**
6. Clique em **+ CREATE CREDENTIALS** > **API Key**
7. Copie a API Key gerada

### 2. Configurar Restrições (Recomendado)

#### Para a API Key:
1. Clique na API Key criada
2. Em **Application restrictions**, selecione:
   - **HTTP referrers** para Web
   - **Android apps** para Android
   - **iOS apps** para iOS
3. Adicione as restrições apropriadas:
   - **Android**: `com.example.climetry`
   - **iOS**: `com.example.climetry`
   - **Web**: `localhost:*` (para desenvolvimento)
4. Em **API restrictions**, selecione as APIs ativadas acima
5. Clique em **SAVE**

### 3. Configurar no Projeto

#### 🌐 Web (`web/index.html`)
Substitua `YOUR_GOOGLE_MAPS_API_KEY` pela sua API Key:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=SUA_API_KEY_AQUI"></script>
```

#### 🤖 Android (`android/app/src/main/AndroidManifest.xml`)
Substitua `YOUR_GOOGLE_MAPS_API_KEY` pela sua API Key:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="SUA_API_KEY_AQUI" />
```

#### 🍎 iOS (`ios/Runner/AppDelegate.swift`)
Substitua `YOUR_GOOGLE_MAPS_API_KEY` pela sua API Key:
```swift
GMSServices.provideAPIKey("SUA_API_KEY_AQUI")
```

### 4. Testar

#### Web:
```bash
flutter run -d chrome
```

#### iOS:
```bash
flutter run -d ios
```
Ou abra `ios/Runner.xcworkspace` no Xcode e execute.

#### Android:
```bash
flutter run -d android
```

## ⚠️ Importante

- **NUNCA** commite sua API Key no Git
- Use variáveis de ambiente para produção
- Configure billing no Google Cloud (é necessário, mas tem free tier generoso)
- Monitore o uso da API no console do Google Cloud

## 🔒 Segurança

Para produção, considere:
1. Criar API Keys separadas para cada plataforma
2. Configurar restrições de IP/Bundle ID/Package Name
3. Implementar rate limiting no backend
4. Usar Firebase App Check para verificação adicional

## 📱 Permissões Já Configuradas

✅ **Android** - `AndroidManifest.xml`:
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `INTERNET`

✅ **iOS** - `Info.plist`:
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`

## 🚀 Próximos Passos

Após configurar as API Keys:
1. Execute `flutter clean`
2. Execute `flutter pub get`
3. Teste em cada plataforma (Web → iOS → Android)
4. Verifique se o mapa carrega corretamente
5. Teste a seleção de localização
6. Verifique se as coordenadas são capturadas

## 🆘 Troubleshooting

### Mapa não carrega na Web
- Verifique se a API Key está correta no `index.html`
- Confirme que **Maps JavaScript API** está ativada
- Verifique o console do navegador para erros

### Mapa não carrega no Android
- Execute `flutter clean && flutter pub get`
- Verifique se a API Key está no `AndroidManifest.xml`
- Confirme que **Maps SDK for Android** está ativada
- Verifique os logs: `flutter logs`

### Mapa não carrega no iOS
- Execute `cd ios && pod install`
- Verifique se a API Key está no `AppDelegate.swift`
- Confirme que **Maps SDK for iOS** está ativada
- Abra o projeto no Xcode e verifique os logs

### Erro de permissão de localização
- Android: Aceite a permissão quando solicitada
- iOS: Vá em Configurações > Privacidade > Localização > Climetry
- Web: Aceite a permissão no navegador

## 📚 Documentação Oficial

- [Google Maps Platform](https://developers.google.com/maps)
- [Maps SDK for Android](https://developers.google.com/maps/documentation/android-sdk)
- [Maps SDK for iOS](https://developers.google.com/maps/documentation/ios-sdk)
- [Maps JavaScript API](https://developers.google.com/maps/documentation/javascript)
- [google_maps_flutter Package](https://pub.dev/packages/google_maps_flutter)
