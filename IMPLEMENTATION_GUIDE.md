# Climetry - Guia de Implementação Completa

## ✅ O que já foi implementado:

### 1. Estrutura de Dados (Models/Entities)
- ✅ `Activity` - Representa eventos/atividades do usuário
- ✅ `DisasterAlert` - Alertas de desastres  
- ✅ `WeatherAlert` - Alertas climáticos calculados
- ✅ `CurrentWeather` - Clima atual
- ✅ `DailyWeather` - Previsão diária
- ✅ `HourlyWeather` - Previsão por hora
- ✅ `NotificationSettings` - Configurações de notificação

### 2. Serviços
- ✅ `MeteomaticsService` - Integração completa com API Meteomatics
  - getCurrentWeather() - Clima atual
  - getHourlyForecast() - Próximas 24h
  - getWeeklyForecast() - 7 dias
  - getMonthlyForecast() - 30 dias
  - getSixMonthsForecast() - 6 meses
  - calculateWeatherAlerts() - Calcula todos os 9 alertas climáticos

### 3. Cálculos de Alertas Implementados
- ✅ Alerta 1: Onda de Calor (temp ≥35°C por 3+ dias)
- ✅ Alerta 2: Desconforto Térmico (temp ≥30°C + umidade ≥60%)
- ✅ Alerta 3: Frio Intenso (temp ≤5°C)
- ✅ Alerta 4: Risco de Geada (temp ≤3°C)
- ✅ Alerta 5: Chuva Intensa (precip >30mm)
- ✅ Alerta 6: Risco de Enchente (precip >50mm)
- ✅ Alerta 7: Tempestade Severa (CAPE >2000 J/kg)
- ✅ Alerta 8: Risco de Granizo (hail >0cm)
- ✅ Alerta 9: Ventania Forte (vento ≥60 km/h)

## 📋 O que precisa ser implementado:

### 1. Instalar Dependências
```bash
cd /Users/roosoars/Desktop/Climetry
flutter pub get
```

### 2. Criar Tela de Atividades/Agenda

Arquivo: `lib/src/features/activities/presentation/screens/activities_screen.dart`

**Funcionalidades:**
- Lista de atividades futuras
- Botão flutuante para criar nova atividade
- Cards mostrando: título, localização, data/hora, ícone do tipo
- Ao clicar, navega para detalhes da atividade com previsão do tempo

### 3. Criar Tela de Nova Atividade

Arquivo: `lib/src/features/activities/presentation/screens/new_activity_screen.dart`

**Campos do formulário:**
- Nome da atividade (TextField)
- Localização (TextField com botão para abrir mapa)
- Data (DatePicker)
- Hora inicial (TimePicker)
- Hora final (TimePicker - opcional)
- Tipo de atividade (Dropdown: Esporte, Ao Ar Livre, Social, Trabalho, Viagem, Outro)
- Descrição (TextField multilinha - opcional)

**Botão "Salvar Atividade":**
- Valida dados
- Consulta previsão do tempo para a data/hora
- Mostra preview do clima esperado
- Salva no repositório local (SharedPreferences)

### 4. Criar Tela de Detalhes da Atividade

Arquivo: `lib/src/features/activities/presentation/screens/activity_details_screen.dart`

**Elementos:**
- Header com título, data, hora, localização
- Card "Tempo para o evento" (countdown)
- Card "Chance de chuva" com % e status (Baixa/Média/Alta)
- Seção "Possível condição climática para a hora do evento"
  - 3 cards horizontais mostrando horários próximos
  - Temperatura, ícone do clima
- Seção "Recomendações"
  - Cards coloridos com ícones e dicas baseadas no clima previsto
  - Ex: "Leve protetor solar", "Hidrate-se bem", "Cancele se houver tempestade"
- Botão "Ver mais detalhes"
- Botões de ação:
  - Compartilhar no WhatsApp
  - Adicionar ao Google Calendar / Apple Calendar
  - Editar atividade
  - Excluir atividade

### 5. Criar Tela de Alertas de Desastres

Arquivo: `lib/src/features/disasters/presentation/screens/disasters_screen.dart`

**Seções:**
- Header "Alertas de Desastres" com botão "+" para adicionar localização
- Seção "Tipos de Eventos" com toggles:
  - 🌊 Inundações
  - ⛈️ Tempestades Severas
  - ❄️ Geada
  - 🔥 Incêndios Florestais
- Seção "Raio de Monitoramento"
  - Slider de 5km a 100km (padrão: 30km)
- Seção "Preferência de Notificação"
  - Toggle "Notificação Push"
  - Toggle "Notificação por Email"
  - Toggle "Notificação por SMS"
- Card de alerta (quando há alerta ativo):
  - Fundo amarelo/laranja/vermelho (conforme severidade)
  - Ícone de alerta
  - Título do alerta
  - Mensagem descritiva
  - Timestamp

### 6. Criar Tela de Configurações/Ajustes

Arquivo: `lib/src/features/settings/presentation/screens/settings_screen.dart`

**Seções:**
- Perfil do Usuário
  - Nome
  - Email
  - Foto (opcional)
- Localização Padrão
  - TextField com busca + mapa
- Unidades
  - Temperatura (Celsius/Fahrenheit)
  - Velocidade do vento (km/h, m/s, mph)
  - Precipitação (mm, inches)
- Notificações
  - Ativar/desativar notificações
  - Som
  - Vibração
- Privacidade
  - Permissões de localização
  - Compartilhamento de dados
- Sobre
  - Versão do app
  - Termos de uso
  - Política de privacidade

### 7. Criar Modal de Seleção de Localização

Arquivo: `lib/src/features/shared/widgets/location_picker_modal.dart`

**Elementos:**
- Campo de busca no topo
- Mapa interativo (Flutter Map)
- Marcador azul arrastável
- Botão "Confirmar" na parte inferior

### 8. Criar Repositório de Atividades

Arquivo: `lib/src/features/activities/data/repositories/activity_repository.dart`

**Métodos:**
```dart
class ActivityRepository {
  // Salvar no SharedPreferences
  Future<void> save(Activity activity);
  
  // Listar todas
  Future<List<Activity>> getAll();
  
  // Buscar por ID
  Future<Activity?> getById(String id);
  
  // Atualizar
  Future<void> update(Activity activity);
  
  // Deletar
  Future<void> delete(String id);
  
  // Buscar por data
  Future<List<Activity>> getByDate(DateTime date);
}
```

### 9. Implementar Compartilhamento

Arquivo: `lib/src/features/shared/services/sharing_service.dart`

**Métodos:**
```dart
class SharingService {
  // Compartilhar via WhatsApp
  Future<void> shareOnWhatsApp(Activity activity, CurrentWeather weather);
  
  // Adicionar ao Google Calendar
  Future<void> addToGoogleCalendar(Activity activity);
  
  // Adicionar ao Apple Calendar (iOS)
  Future<void> addToAppleCalendar(Activity activity);
}
```

Usar o pacote `url_launcher` para abrir URLs:
- WhatsApp: `whatsapp://send?text=...`
- Google Calendar: URL com parâmetros do evento
- Apple Calendar: Usar plugin nativo

### 10. Atualizar App Principal

Arquivo: `lib/src/app.dart`

Substituir por navegação com bottom navigation bar:
```dart
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    HomeScreen(),
    ActivitiesScreen(),
    DisastersScreen(),
    SettingsScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF1E2A3A),
        selectedItemColor: Color(0xFF4A9EFF),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Atividades'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Alertas'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
```

## 🎨 Paleta de Cores (baseada nos designs)

```dart
// Cores principais
const primaryBackground = Color(0xFF1E2A3A);  // Azul escuro
const secondaryBackground = Color(0xFF2A3A4D);  // Azul médio
const accentBlue = Color(0xFF4A9EFF);  // Azul claro
const accentCyan = Color(0xFF5DD3D3);  // Ciano

// Alertas
const alertYellow = Color(0xFFFFC107);  // Amarelo (aviso)
const alertOrange = Color(0xFFFF9800);  // Laranja (atenção)
const alertRed = Color(0xFFF44336);  // Vermelho (perigo)
const alertBlue = Color(0xFF2196F3);  // Azul (info)

// Cards de recomendação
const cardSun = Color(0xFFFFF8E1);  // Amarelo claro (protetor solar)
const cardWater = Color(0xFFE3F2FD);  // Azul claro (hidratação)
const cardStorm = Color(0xFFFFEBEE);  // Rosa claro (cancelar)
```

## 📱 Próximos Passos

1. Execute `flutter pub get` para instalar as novas dependências
2. Corrija os imports no `home_screen.dart`
3. Implemente as telas listadas acima
4. Teste a integração com a API Meteomatics
5. Implemente persistência local com SharedPreferences
6. Adicione funcionalidades de compartilhamento
7. Teste em dispositivos Android, iOS e Web

## 🔧 Comandos Úteis

```bash
# Instalar dependências
flutter pub get

# Rodar no emulador/dispositivo
flutter run

# Rodar no Chrome (web)
flutter run -d chrome

# Build para Android
flutter build apk

# Build para iOS
flutter build ios

# Análise de código
flutter analyze
```

## 📚 Documentação de Referência

- Flutter Map: https://docs.fleaflet.dev/
- URL Launcher: https://pub.dev/packages/url_launcher
- SharedPreferences: https://pub.dev/packages/shared_preferences
- Intl (formatação de datas): https://pub.dev/packages/intl
- API Meteomatics: https://www.meteomatics.com/en/api/

## 🎯 Funcionalidades Principais a Implementar

- [x] Models de dados
- [x] Serviço de API climatológica
- [x] Cálculo de alertas climáticos
- [ ] Tela Home com previsão atual
- [ ] Tela de lista de atividades
- [ ] Tela de criar/editar atividade
- [ ] Tela de detalhes da atividade
- [ ] Tela de alertas de desastres
- [ ] Tela de configurações
- [ ] Modal de seleção de localização
- [ ] Persistência local (SharedPreferences)
- [ ] Compartilhamento WhatsApp
- [ ] Integração com calendários
- [ ] Sistema de notificações
