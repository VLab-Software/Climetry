# Correção: Erro 403 Identity Toolkit API

## ❌ Problema
```
Failed to load resource: the server responded with a status of 403 ()
identitytoolkit.googleapis.com/v1/accounts:signUp
```

## ✅ Solução

### 1. Habilitar Identity Toolkit API no Google Cloud Console

1. Acesse: https://console.cloud.google.com/
2. Selecione o projeto: **climetry-app**
3. No menu lateral, vá em: **APIs & Services** > **Library**
4. Pesquise por: **Identity Toolkit API**
5. Clique em **ENABLE** (Habilitar)

### 2. Verificar Configuração do Firebase Authentication

1. Acesse: https://console.firebase.google.com/
2. Selecione: **climetry-app**
3. Vá em: **Authentication** > **Sign-in method**
4. Verifique se **Email/Password** está **Habilitado**
5. Se não estiver, clique em **Email/Password** e habilite

### 3. Verificar Domínios Autorizados

1. No Firebase Console, em **Authentication** > **Settings** > **Authorized domains**
2. Adicione: `localhost` (se não estiver na lista)
3. Adicione: seu domínio de produção quando fizer deploy

## 🔧 Correções Já Aplicadas no Código

✅ **web/index.html**
- Corrigido `appId` do Firebase (antes estava como `YOUR_WEB_APP_ID`)
- Corrigido `measurementId` (antes estava como `G-XXXXXXXXXX`)
- Adicionado `loading=async` no Google Maps API

✅ **lib/main.dart**
- Firebase Web configurado com FirebaseOptions corretos
- API Key: `AIzaSyDYHDKJUcQEOMpi-h8QQ7afHuZtMYopb6Q`
- App ID: `1:537476913348:web:bd37e5edc50b2e57c3b6ac`
- Measurement ID: `G-5MQSWRYL5Q`

## 🧪 Testar

Após habilitar a Identity Toolkit API:

1. Recarregue a página: http://localhost:8080
2. Abra o DevTools (F12) e vá em Console
3. Tente criar uma conta nova
4. O erro 403 deve desaparecer

## 📝 Observações

- O erro 403 acontece porque a **Identity Toolkit API** não está habilitada no projeto do Google Cloud
- Esta API é necessária para autenticação no Firebase (signUp, signIn, etc)
- É diferente da **Firebase Authentication** que já está configurada
- Após habilitar, pode demorar 1-2 minutos para propagar
