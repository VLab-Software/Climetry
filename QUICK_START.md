# 🚀 Quick Start - Climetry

## ⚡ Início Rápido em 3 Passos

### 1️⃣ Instalar Dependências
```bash
cd /Users/roosoars/Desktop/Climetry
flutter pub get
```

### 2️⃣ Executar o App
```bash
# Ver dispositivos disponíveis
flutter devices

# Executar (escolha um dispositivo da lista acima)
flutter run

# Ou executar direto no Chrome
flutter run -d chrome
```

### 3️⃣ Explorar as Funcionalidades!
- 🏠 **Home**: Veja o clima atual e previsão por hora
- 📅 **Agenda**: Crie e gerencie suas atividades
- ⚠️ **Alertas**: Configure alertas de desastres
- ⚙️ **Ajustes**: Personalize o app

---

## 📱 Principais Funcionalidades

### Na Tela Home:
1. Veja a temperatura atual da sua localização
2. Scroll horizontal para ver previsão das próximas 24 horas
3. Confira insights para suas atividades agendadas

### Na Tela de Atividades:
1. Toque no **+** para criar uma nova atividade
2. Preencha: nome, localização, data, hora e tipo
3. Toque em qualquer atividade para ver detalhes completos
4. Compartilhe no WhatsApp ou adicione ao Google Calendar

### Na Tela de Alertas:
1. Ative os tipos de alertas que deseja monitorar
2. Ajuste o raio de monitoramento (5-100km)
3. Configure preferências de notificação

### Na Tela de Configurações:
1. Configure seu perfil
2. Escolha unidades de medida
3. Gerencie permissões e privacidade

---

## 🎯 O que Testar Primeiro

1. **Criar uma Atividade**
   - Agenda → ➕ → Preencher formulário → Salvar
   
2. **Ver Previsão Detalhada**
   - Toque na atividade criada
   - Veja countdown, chance de chuva e recomendações
   
3. **Compartilhar**
   - Na tela de detalhes, toque no ícone de compartilhar (canto superior)
   - Escolha WhatsApp ou Google Calendar

4. **Configurar Alertas**
   - Vá em Alertas
   - Ative "Tempestades Severas" e "Inundações"
   - Ajuste o raio para 30km

---

## 🔧 Troubleshooting

### Erro de Conexão com API?
- Verifique sua conexão com internet
- A API Meteomatics tem credenciais válidas embutidas no código

### App não inicia?
```bash
# Limpe e reinstale
flutter clean
flutter pub get
flutter run
```

### Erro no iOS?
```bash
cd ios
pod install
cd ..
flutter run
```

---

## 📖 Documentação Completa

- `SUMMARY.md` - Resumo técnico completo
- `README_FINAL.md` - Guia detalhado do projeto  
- `IMPLEMENTATION_GUIDE.md` - Guia de implementação

---

## 💡 Dicas

- **Pull to Refresh**: Puxe para baixo na tela Home para atualizar o clima
- **Dark Mode**: O app já vem com tema escuro bonito
- **Ícones**: Cada tipo de atividade tem um emoji único
- **Alertas**: São calculados automaticamente baseados nas regras meteorológicas

---

## 🎨 Personalize

Quer mudar as cores? Edite:
```dart
lib/src/core/theme/app_theme.dart
```

Quer adicionar mais tipos de atividade? Edite:
```dart
lib/src/features/activities/domain/entities/activity.dart
```

---

## ✅ Checklist de Testes

- [ ] App abre sem erros
- [ ] Tela Home carrega clima atual
- [ ] Previsão hora a hora aparece
- [ ] Consigo criar nova atividade
- [ ] Detalhes da atividade mostram previsão
- [ ] Compartilhar no WhatsApp funciona
- [ ] Bottom navigation funciona em todas as tabs
- [ ] Configurações abrem corretamente
- [ ] Alertas podem ser ativados/desativados

---

## 🆘 Precisa de Ajuda?

1. Leia `SUMMARY.md` para entender a arquitetura
2. Verifique `IMPLEMENTATION_GUIDE.md` para detalhes técnicos
3. Rode `flutter doctor` para verificar seu ambiente

---

**Pronto para começar? Execute `flutter run` e divirta-se! 🎉**
