# 🌤️ Climetry - Análise Climática para Suas Atividades

## ✅ Status da Implementação

### Concluído:

#### 📦 Estrutura de Dados
- ✅ Models completos para Activity, DisasterAlert, WeatherAlert
- ✅ Entities para clima atual, diário e por hora
- ✅ Configurações de notificação

#### 🌐 Serviços
- ✅ **MeteomaticsService** - Integração completa com API
  - Clima atual com 14 parâmetros
  - Previsão hora a hora (24h)
  - Previsão semanal (7 dias)
  - Previsão mensal (30 dias)
  - Previsão semestral (6 meses)
  - **9 Alertas climáticos calculados automaticamente**

#### 📱 Telas Implementadas
1. ✅ **Home** - Tela inicial com:
   - Temperatura atual e condições
   - Previsão por hora (24h)
   - Insights para atividades
   - Detalhes do clima (vento, umidade, UV, sensação)

2. ✅ **Atividades** - Gerenciamento de eventos:
   - Lista de atividades
   - Formulário de nova atividade
   - Detalhes da atividade com:
     - Countdown para o evento
     - Chance de chuva
     - Previsão por hora
     - Recomendações inteligentes

3. ✅ **Alertas de Desastres** - Sistema de monitoramento:
   - 4 tipos de alertas (Inundações, Tempestades, Geada, Incêndios)
   - Raio de monitoramento configurável (5-100km)
   - Preferências de notificação (Push, Email, SMS)

4. ✅ **Configurações** - Personalização:
   - Perfil do usuário
   - Localização padrão
   - Unidades de medida
   - Notificações
   - Privacidade
   - Sobre o app

#### 🔗 Integrações
- ✅ Compartilhamento via WhatsApp
- ✅ Adicionar ao Google Calendar
- ✅ Navegação com Bottom Navigation Bar

## 🚀 Como Executar

### 1. Instalar Dependências
```bash
cd /Users/roosoars/Desktop/Climetry
flutter pub get
```

### 2. Executar o App
```bash
# Android/iOS
flutter run

# Web
flutter run -d chrome

# Dispositivo específico
flutter devices
flutter run -d <device-id>
```

## 📊 Alertas Climáticos Implementados

### Relacionados ao CALOR
1. **Onda de Calor** - temp ≥35°C por 3+ dias consecutivos
2. **Desconforto Térmico** - temp ≥30°C + umidade ≥60%

### Relacionados ao FRIO
3. **Frio Intenso** - temp ≤5°C
4. **Risco de Geada** - temp ≤3°C

### Relacionados à CHUVA
5. **Chuva Intensa** - precipitação >30mm
6. **Risco de Enchente** - precipitação >50mm

### Relacionados a TEMPESTADES
7. **Tempestade Severa** - CAPE >2000 J/kg
8. **Risco de Granizo** - previsão de granizo

### Relacionados ao VENTO
9. **Ventania Forte** - ventos ≥60 km/h

## 🎨 Design System

### Cores Principais
```dart
primaryBackground = Color(0xFF1E2A3A)   // Azul escuro
secondaryBackground = Color(0xFF2A3A4D) // Azul médio
accentBlue = Color(0xFF4A9EFF)          // Azul claro
```

### Cores de Alertas
```dart
alertInfo = Colors.blue      // Informativo
alertWarning = Colors.orange // Aviso
alertSevere = Colors.red     // Severo
```

## 📁 Estrutura do Projeto

```
lib/
├── main.dart
└── src/
    ├── app_new.dart              # App principal com navegação
    ├── core/
    │   ├── network/
    │   │   └── api_client.dart
    │   └── theme/
    │       └── app_theme.dart
    └── features/
        ├── home/
        │   └── presentation/
        │       └── screens/
        │           └── home_screen.dart
        ├── activities/
        │   ├── domain/
        │   │   └── entities/
        │   │       └── activity.dart
        │   └── presentation/
        │       └── screens/
        │           ├── activities_screen.dart
        │           ├── new_activity_screen.dart
        │           └── activity_details_screen.dart
        ├── disasters/
        │   ├── domain/
        │   │   └── entities/
        │   │       └── disaster_alert.dart
        │   └── presentation/
        │       └── screens/
        │           └── disasters_screen.dart
        ├── settings/
        │   ├── domain/
        │   │   └── entities/
        │   │       └── notification_settings.dart
        │   └── presentation/
        │       └── screens/
        │           └── settings_screen.dart
        └── weather/
            ├── domain/
            │   └── entities/
            │       ├── current_weather.dart
            │       ├── daily_weather.dart
            │       ├── hourly_weather.dart
            │       └── weather_alert.dart
            └── data/
                └── services/
                    └── meteomatics_service.dart
```

## 🔧 Próximos Passos (Melhorias Futuras)

### 1. Persistência de Dados
- Implementar repositório com SharedPreferences para salvar atividades localmente
- Cache de dados climáticos para modo offline

### 2. Modal de Mapa
- Criar modal interativo com Flutter Map para seleção de localização
- Integrar com geocoding reverso

### 3. Notificações Push
- Implementar Firebase Cloud Messaging
- Agendar notificações locais para alertas de atividades

### 4. Calendário Nativo
- Integração profunda com Google Calendar (Android)
- Integração com Apple Calendar (iOS)
- Sincronização bidirecional

### 5. Testes
- Unit tests para cálculos de alertas
- Widget tests para telas principais
- Integration tests para fluxos completos

### 6. Otimizações
- Lazy loading de previsões
- Infinite scroll na lista de atividades
- Pull-to-refresh em todas as telas

## 🐛 Debug e Troubleshooting

### Erros Comuns

**1. Erro na API Meteomatics**
- Verifique as credenciais em `meteomatics_service.dart`
- Confirme conectividade com internet
- Verifique limites da API

**2. Erro de Localização**
- Adicione permissões no AndroidManifest.xml e Info.plist
- Request permissões em runtime

**3. Erro ao compartilhar**
- Verifique se `url_launcher` está configurado corretamente
- Adicione queries no AndroidManifest.xml para WhatsApp

## 📝 Comandos Úteis

```bash
# Limpar build
flutter clean

# Atualizar dependências
flutter pub upgrade

# Análise de código
flutter analyze

# Formatar código
flutter format lib/

# Build release
flutter build apk --release    # Android
flutter build ios --release    # iOS
flutter build web --release    # Web
```

## 🌐 API Endpoints Disponíveis

### Clima Atual
```
GET https://api.meteomatics.com/now/t_2m:C,t_2m:F,.../{lat},{lon}/json
```

### Previsão Hora a Hora (24h)
```
GET https://api.meteomatics.com/now--PT24H:PT1H/t_2m:C,.../{lat},{lon}/json
```

### Previsão Diária (7 dias)
```
GET https://api.meteomatics.com/{start}--{end}:P1D/t_max_2m_24h:C,.../{lat},{lon}/json
```

## 📄 Licença

Este projeto foi desenvolvido para fins educacionais e demonstrativos.

## 👥 Contribuidores

- Desenvolvido por: [Seu Nome]
- Design baseado em: Figma mockups fornecidos

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique a documentação
2. Consulte o arquivo IMPLEMENTATION_GUIDE.md
3. Abra uma issue no repositório

---

**Última atualização:** 4 de outubro de 2025
