# 🚀 Plano de Implementação - Melhorias Climetry

## 📋 Funcionalidades Solicitadas

### ✅ **PRIORIDADE ALTA** (Implementar primeiro)

#### 1. **Sincronização Home ↔ Eventos**
- [x] EventRefreshNotifier criado
- [x] Provider configurado no main.dart
- [x] HomeScreen escutando mudanças
- [ ] NewActivityScreen notificando após criar
- [ ] EditActivityScreen notificando após editar
- [ ] ActivitiesScreen notificando após deletar

#### 2. **Tela de Edição de Eventos**
- [ ] Criar `edit_activity_screen.dart`
- [ ] Botão de edição (✏️) no header de `event_details_screen.dart`
- [ ] Pré-preencher todos os campos
- [ ] Salvar mudanças no Firestore
- [ ] Notificar mudanças via EventRefreshNotifier

#### 3. **Contador Din

âmico de Tempo**
- [ ] Implementar `_buildTimeCountdown()` em `event_details_screen.dart`
- [ ] Usar Timer para atualizar a cada segundo
- [ ] Formato: "3 semanas, 2 dias, 5 horas, 30 minutos, 15 segundos"
- [ ] Dispose do timer corretamente

---

### ⚠️ **PRIORIDADE MÉDIA**

#### 4. **Sistema de Notificações**
**Packages necessários:**
```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
  timezone: ^0.9.0
```

**Campos a adicionar no Activity:**
```dart
final List<NotificationTiming> notificationTimings; // 1h antes, 1 dia antes, etc
```

**Enum NotificationTiming:**
```dart
enum NotificationTiming {
  fifteenMinutes,  // 15min antes
  thirtyMinutes,   // 30min antes
  oneHour,         // 1h antes
  twoHours,        // 2h antes
  oneDay,          // 1 dia antes
  twoDays,         // 2 dias antes
  oneWeek,         // 1 semana antes
}
```

#### 5. **Integração com Calendários**
**Package necessário:**
```yaml
dependencies:
  add_2_calendar: ^3.0.1
```

**Botão em event_details_screen:**
- "📅 Adicionar ao Calendário"
- Menu com opções: Google Calendar / Apple Calendar

#### 6. **Customização de Cards de Previsão**
- [ ] Redesenhar `_buildWeatherSection()` em `event_details_screen.dart`
- [ ] Usar apenas `monitoredConditions` do evento
- [ ] Layout moderno com gradientes e sombras
- [ ] Ícones animados (opcional)

---

### 📱 **PRIORIDADE BAIXA** (Melhorias de UX)

#### 7. **Melhorar Cards de Resumo na Home**
Redesenhar `_buildInlineStat()`:

**Antes:**
```
✅ 5 Seguros  ⚠️ 2 Atenção  🚨 1 Crítico
```

**Depois:**
```
┌────────────┐ ┌────────────┐ ┌────────────┐
│ ✓ Seguros  │ │ ⚠ Atenção │ │ ⚡ Críticos │
│     5      │ │     2      │ │      1     │
└────────────┘ └────────────┘ └────────────┘
 Verde          Amarelo        Vermelho
```

#### 8. **Melhorar Filtros na Home**
Mover filtros para abaixo de "Seus Eventos", similar à aba Eventos:

**Layout:**
```
Seus Eventos                    8 eventos
───────────────────────────────────────────

[🕐 Tempo] [📍 Distância] [⚠️ Prioridade]

┌─────────────────────────────────────────┐
│ Card Evento 1                           │
└─────────────────────────────────────────┘
```

#### 9. **Sistema de Foto de Perfil**
**Packages necessários:**
```yaml
dependencies:
  image_picker: ^1.0.7
  firebase_storage: ^11.6.0
  cached_network_image: ^3.3.1
```

**Implementação:**
1. Adicionar campo `photoURL` no User (Firestore)
2. Tela de edição de perfil
3. Upload para Firebase Storage
4. Exibir foto no header de Settings

---

## 🛠️ **Implementação Passo a Passo**

### **Fase 1: Sincronização e Edição** (1-2 horas)
1. ✅ Criar EventRefreshNotifier
2. ✅ Configurar Provider
3. ✅ HomeScreen escutando
4. ⏳ Notificar em NewActivityScreen após criar
5. ⏳ Criar EditActivityScreen
6. ⏳ Adicionar botão de edição em EventDetailsScreen

### **Fase 2: Contador e Notificações** (2-3 horas)
1. Implementar contador dinâmico
2. Adicionar flutter_local_notifications
3. Criar NotificationService
4. UI para selecionar timings de notificação
5. Agendar notificações ao criar/editar evento

### **Fase 3: Integrações e Melhorias** (2-3 horas)
1. Integrar add_2_calendar
2. Redesenhar cards de resumo
3. Melhorar filtros na Home
4. Customizar cards de previsão nos detalhes

### **Fase 4: Foto de Perfil** (1-2 horas)
1. Adicionar image_picker
2. Criar tela de edição de perfil
3. Upload para Firebase Storage
4. Exibir foto no app

---

## 📝 **Código de Exemplo - Contador Dinâmico**

```dart
class _EventDetailsScreenState extends State<EventDetailsScreen> {
  Timer? _countdownTimer;
  String _timeRemaining = '';

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _updateTimeRemaining();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    final difference = widget.analysis.activity.date.difference(now);

    if (difference.isNegative) {
      setState(() => _timeRemaining = 'Evento já passou');
      _countdownTimer?.cancel();
      return;
    }

    final weeks = difference.inDays ~/ 7;
    final days = difference.inDays % 7;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    final parts = <String>[];
    if (weeks > 0) parts.add('$weeks sem');
    if (days > 0) parts.add('$days dias');
    if (hours > 0) parts.add('$hours h');
    if (minutes > 0) parts.add('$minutes min');
    if (seconds > 0 || parts.isEmpty) parts.add('$seconds seg');

    setState(() => _timeRemaining = parts.join(', '));
  }

  Widget _buildCountdownSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.access_time, color: Colors.white, size: 32),
          SizedBox(height: 8),
          Text(
            'Faltam',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _timeRemaining,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

---

## 📝 **Código de Exemplo - EditActivityScreen**

```dart
class EditActivityScreen extends StatefulWidget {
  final Activity activity;
  
  const EditActivityScreen({super.key, required this.activity});

  @override
  State<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userDataService = UserDataService();
  
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late DateTime _selectedDate;
  // ... outros campos
  
  @override
  void initState() {
    super.initState();
    // Pré-preencher com dados existentes
    _titleController = TextEditingController(text: widget.activity.title);
    _locationController = TextEditingController(text: widget.activity.location);
    _selectedDate = widget.activity.date;
    _selectedPriority = widget.activity.priority;
    _tags = List.from(widget.activity.tags);
    // ... etc
  }
  
  Future<void> _updateActivity() async {
    if (_formKey.currentState!.validate()) {
      final updatedActivity = widget.activity.copyWith(
        title: _titleController.text,
        location: _locationController.text,
        date: _selectedDate,
        priority: _selectedPriority,
        tags: _tags,
        // ... outros campos
      );
      
      await _userDataService.updateActivity(updatedActivity);
      
      // Notificar mudanças
      if (mounted) {
        Provider.of<EventRefreshNotifier>(context, listen: false)
            .notifyEventsChanged();
        Navigator.pop(context);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Similar a NewActivityScreen, mas com título "Editar Evento"
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Evento'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _updateActivity,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: // ... mesmo layout de NewActivityScreen
      ),
    );
  }
}
```

---

## 🎨 **Mockup - Cards de Resumo Melhorados**

```dart
Widget _buildModernStatCard({
  required IconData icon,
  required int count,
  required String label,
  required Color color,
  required bool isDark,
}) {
  return Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

// Uso:
Row(
  children: [
    _buildModernStatCard(
      icon: Icons.check_circle,
      count: safeCount,
      label: 'Seguros',
      color: Color(0xFF10B981),
      isDark: isDark,
    ),
    SizedBox(width: 12),
    _buildModernStatCard(
      icon: Icons.warning_amber_rounded,
      count: warningCount,
      label: 'Atenção',
      color: Color(0xFFF59E0B),
      isDark: isDark,
    ),
    SizedBox(width: 12),
    _buildModernStatCard(
      icon: Icons.error,
      count: criticalCount,
      label: 'Críticos',
      color: Color(0xFFEF4444),
      isDark: isDark,
    ),
  ],
)
```

---

## 📦 **Packages a Adicionar no pubspec.yaml**

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existentes
  provider: ^6.1.1
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  google_maps_flutter: ^2.5.0
  http: ^1.2.0
  intl: ^0.18.1
  uuid: ^4.3.3
  
  # NOVOS - Notificações
  flutter_local_notifications: ^17.0.0
  timezone: ^0.9.0
  
  # NOVOS - Calendário
  add_2_calendar: ^3.0.1
  
  # NOVOS - Foto de Perfil
  image_picker: ^1.0.7
  firebase_storage: ^11.6.0
  cached_network_image: ^3.3.1
```

---

## ✅ **Checklist de Implementação**

### **Fase 1: Básico** ✅ 50% Completo
- [x] EventRefreshNotifier criado
- [x] Provider configurado
- [x] HomeScreen escutando
- [ ] NewActivityScreen notificando
- [ ] EditActivityScreen completo
- [ ] Botão de edição em EventDetailsScreen

### **Fase 2: Contador e Notificações** ⏳ 0% Completo
- [ ] Contador dinâmico implementado
- [ ] flutter_local_notifications adicionado
- [ ] NotificationService criado
- [ ] UI para selecionar timings
- [ ] Agendamento funcionando

### **Fase 3: Integrações** ⏳ 0% Completo
- [ ] add_2_calendar adicionado
- [ ] Botão "Adicionar ao Calendário"
- [ ] Cards de resumo redesenhados
- [ ] Filtros da Home melhorados
- [ ] Cards de previsão customizados

### **Fase 4: Foto de Perfil** ⏳ 0% Completo
- [ ] image_picker adicionado
- [ ] Firebase Storage configurado
- [ ] Tela de edição de perfil
- [ ] Upload de foto funcionando
- [ ] Exibição de foto no app

---

## 🚀 **Próximos Passos Imediatos**

1. ✅ Finalizar sincronização Home ↔ Eventos
2. ⏳ Criar EditActivityScreen
3. ⏳ Implementar contador dinâmico
4. ⏳ Adicionar packages de notificação
5. ⏳ Implementar sistema de notificações

---

**Tempo Estimado Total:** 8-10 horas de desenvolvimento
**Prioridade Imediata:** Edição de eventos + Contador dinâmico (2-3 horas)
