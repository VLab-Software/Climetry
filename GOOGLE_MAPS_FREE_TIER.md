# 🆓 Google Maps - Limites do Plano Gratuito

## 💰 Crédito Mensal Gratuito
- **$200 USD de crédito gratuito por mês**
- Renovado automaticamente todo mês
- Não acumula para o próximo mês

## 📊 Uso Estimado do Climetry

### Maps JavaScript API (Web)
- **Preço:** $7 por 1.000 carregamentos
- **Incluído Grátis:** ~28.571 carregamentos/mês
- **Uso Estimado:** 
  - 1 carregamento por sessão de usuário
  - ~100 sessões/dia = 3.000 carregamentos/mês
  - **Custo:** ~$21/mês → **COBERTO pelo crédito gratuito**

### Maps SDK for Android
- **Preço:** $7 por 1.000 carregamentos
- **Incluído Grátis:** ~28.571 carregamentos/mês
- **Uso Estimado:** Similar à Web

### Maps SDK for iOS
- **Preço:** $7 por 1.000 carregamentos
- **Incluído Grátis:** ~28.571 carregamentos/mês
- **Uso Estimado:** Similar à Web

### Dynamic Maps (Interação)
- **Preço:** $7 por 1.000 solicitações
- **O que conta:**
  - Pan (arrastar mapa)
  - Zoom
  - Trocar tipo de mapa
- **Uso Estimado:**
  - ~5 interações por sessão
  - 100 sessões/dia = 500 interações/dia = 15.000/mês
  - **Custo:** ~$105/mês → **COBERTO pelo crédito gratuito**

## ⚠️ Total Estimado
- **Web + Android + iOS:** ~$150/mês
- **Crédito Gratuito:** $200/mês
- **Margem de Segurança:** $50/mês restante ✅

## 🛡️ Como Configurar Limites (Proteção Extra)

### 1. Configurar Quotas no Google Cloud Console

1. Acesse [console.cloud.google.com](https://console.cloud.google.com/)
2. Vá em **APIs & Services** > **Quotas**
3. Busque por "Maps JavaScript API"
4. Configure limites:

#### Limites Recomendados para Desenvolvimento/Teste:
```
Maps JavaScript API:
- Map loads per day: 1,000
- Map loads per 100 seconds per user: 10

Maps SDK for Android:
- Map loads per day: 1,000

Maps SDK for iOS:
- Map loads per day: 1,000
```

#### Limites para Produção (Uso Moderado):
```
Maps JavaScript API:
- Map loads per day: 5,000
- Map loads per 100 seconds per user: 50

Maps SDK for Android:
- Map loads per day: 5,000

Maps SDK for iOS:
- Map loads per day: 5,000
```

### 2. Configurar Alertas de Billing

1. Vá em **Billing** > **Budgets & alerts**
2. Clique em **CREATE BUDGET**
3. Configure:
   - **Budget Name:** Google Maps Usage Alert
   - **Target Amount:** $150 (75% do crédito)
   - **Alert Thresholds:** 50%, 75%, 90%, 100%
   - **Email:** Seu email

### 3. Configurar Billing Cap (Limite de Gastos)

⚠️ **IMPORTANTE:** Por padrão, Google Maps pode cobrar acima do crédito gratuito!

1. Vá em **Billing** > **Account Management**
2. Configure limite de gastos:
   - **Monthly Spend Cap:** $200 (ou $0 se não quiser pagar nada)
3. Ative **Automatic Billing Cap**

## 🎯 Estratégias para Economizar

### 1. Cache de Mapas
```dart
// No GoogleMap widget, use:
liteModeEnabled: true,  // Reduz chamadas à API
```

### 2. Limitar Interações
```dart
GoogleMap(
  zoomControlsEnabled: false,  // Usuário usa pinch to zoom
  myLocationButtonEnabled: false,
  mapToolbarEnabled: false,
)
```

### 3. Carregar Mapa Apenas Quando Necessário
```dart
// Só carregar quando usuário abrir tela de mapa
// Não carregar em background
```

### 4. Usar Static Maps quando possível
```dart
// Para exibir localização sem interação:
// Use Image.network com Static Maps API
// Preço: $2 por 1.000 requests (mais barato!)
```

## 📈 Monitorar Uso em Tempo Real

1. Acesse [console.cloud.google.com](https://console.cloud.google.com/)
2. Vá em **APIs & Services** > **Dashboard**
3. Veja gráficos de uso:
   - Requests por dia
   - Custo estimado
   - Quotas utilizadas

## 🚨 Alertas Configurados

Você receberá email quando:
- ✅ Uso chegar a 50% do budget ($100)
- ✅ Uso chegar a 75% do budget ($150)
- ⚠️ Uso chegar a 90% do budget ($180)
- 🔴 Uso chegar a 100% do budget ($200)

## 💡 Recomendações

1. **Para Desenvolvimento:**
   - Use limites conservadores (1.000 loads/day)
   - Teste localmente o máximo possível
   - Use emulador ao invés de device real quando possível

2. **Para Produção (100 usuários/dia):**
   - Libere até 5.000 loads/day
   - Configure alertas em $150
   - Monitore semanalmente

3. **Para Escala (1.000+ usuários/dia):**
   - Considere upgrade para plano pago
   - Otimize todas as chamadas à API
   - Implemente cache agressivo

## 🔗 Links Úteis

- [Preços do Google Maps](https://mapsplatform.google.com/pricing/)
- [Calculadora de Custos](https://mapsplatform.google.com/pricing/calculator/)
- [Otimizar Custos](https://developers.google.com/maps/billing/gmp-billing)
- [Free Tier Details](https://cloud.google.com/maps-platform/pricing/sheet/)

## ✅ Checklist de Segurança

- [x] API Key configurada
- [ ] Restrições de API Key ativadas (HTTP referrers, Android/iOS apps)
- [ ] Quotas configuradas
- [ ] Alertas de billing configurados
- [ ] Billing cap ativado (opcional mas recomendado)
- [ ] Monitoramento semanal agendado

---

**Última atualização:** 5 de outubro de 2025
**Crédito Gratuito Atual:** $200/mês
**Uso Estimado Climetry:** ~$150/mês (dentro do free tier ✅)
