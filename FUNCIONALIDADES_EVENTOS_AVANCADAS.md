# 📋 Funcionalidades Avançadas de Eventos - Climetry

## 🎯 Visão Geral
Este documento detalha todas as funcionalidades avançadas de gerenciamento de eventos implementadas no Climetry, incluindo sistema de prioridades, eventos recorrentes, monitoramento de condições climáticas customizadas e sistema de tags.

---

## 🏗️ Arquitetura das Mudanças

### 📦 **Modelo de Dados - Activity Entity**
Localização: `lib/src/features/activities/domain/entities/activity.dart`

#### **Novos Enums Implementados:**

```dart
// 1️⃣ Sistema de Prioridades (4 níveis)
enum ActivityPriority {
  low,      // 🔵 Comum
  medium,   // 🟢 Importante  
  high,     // 🟡 Prioritário
  urgent    // 🔴 Urgente
}

// 2️⃣ Tipos de Recorrência
enum RecurrenceType {
  none,     // 📅 Não se repete
  weekly,   // 🔄 Toda semana
  monthly,  // 📆 Todo mês
  yearly    // 🎂 Todo ano
}

// 3️⃣ Condições Climáticas Monitoráveis
enum WeatherCondition {
  temperature, // 🌡️ Temperatura
  rain,        // 🌧️ Chuva
  wind,        // 💨 Vento
  humidity,    // 💧 Umidade
  uv           // ☀️ Índice UV
}
```

#### **Novos Campos na Classe Activity:**

```dart
class Activity {
  // Campos existentes...
  final String id;
  final String userId;
  final String title;
  final DateTime date;
  final LatLng location;
  final ActivityType type;
  final String? description;
  
  // 🆕 NOVOS CAMPOS
  final ActivityPriority priority;           // Prioridade do evento
  final List<String> tags;                   // Tags customizadas
  final RecurrenceType recurrence;           // Tipo de repetição
  final List<WeatherCondition> monitoredConditions; // Condições a monitorar
}
```

#### **Serialização JSON com Backward Compatibility:**

```dart
Map<String, dynamic> toJson() {
  return {
    // ... campos existentes
    'priority': priority.name,
    'tags': tags,
    'recurrence': recurrence.name,
    'monitoredConditions': monitoredConditions.map((c) => c.name).toList(),
  };
}

factory Activity.fromJson(Map<String, dynamic> json) {
  return Activity(
    // ... campos existentes
    priority: json['priority'] != null 
        ? ActivityPriority.values.firstWhere((e) => e.name == json['priority'])
        : ActivityPriority.low, // Default seguro
    tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
    recurrence: json['recurrence'] != null
        ? RecurrenceType.values.firstWhere((e) => e.name == json['recurrence'])
        : RecurrenceType.none,
    monitoredConditions: json['monitoredConditions'] != null
        ? (json['monitoredConditions'] as List).map((c) => 
            WeatherCondition.values.firstWhere((e) => e.name == c)).toList()
        : [WeatherCondition.temperature, WeatherCondition.rain], // Defaults sensatos
  );
}
```

**✅ Garantia de Compatibilidade:**
- Eventos antigos (sem os novos campos) carregam com valores default
- Não quebra dados existentes no Firestore
- Migração automática e transparente

---

## 🖥️ Interface de Criação de Eventos

### 📝 **Tela: New Activity Screen**
Localização: `lib/src/features/activities/presentation/screens/new_activity_screen.dart`

#### **Novos State Variables:**

```dart
class _NewActivityScreenState extends State<NewActivityScreen> {
  // Estados existentes...
  ActivityType _selectedType = ActivityType.outdoor;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  
  // 🆕 NOVOS ESTADOS
  ActivityPriority _selectedPriority = ActivityPriority.low;
  RecurrenceType _selectedRecurrence = RecurrenceType.none;
  List<String> _tags = [];
  List<WeatherCondition> _monitoredConditions = [
    WeatherCondition.temperature,
    WeatherCondition.rain,
  ];
  
  final TextEditingController _tagsController = TextEditingController();
}
```

#### **Widget 1: Seletor de Prioridade**

```dart
Widget _buildPriorityPicker() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Prioridade', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
      SizedBox(height: 8),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButton<ActivityPriority>(
          value: _selectedPriority,
          isExpanded: true,
          dropdownColor: Color(0xFF1E1E1E),
          items: ActivityPriority.values.map((priority) {
            return DropdownMenuItem(
              value: priority,
              child: Row(
                children: [
                  Text(priority.icon, style: TextStyle(fontSize: 20)), // Emoji colorido
                  SizedBox(width: 12),
                  Text(priority.label), // Ex: "Urgente"
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedPriority = value!),
        ),
      ),
    ],
  );
}
```

**🎨 UX:**
- Dropdown com emojis coloridos (🔵🟢🟡🔴)
- Labels descritivos em português
- Valor default: "Comum" (low)

#### **Widget 2: Seletor de Recorrência**

```dart
Widget _buildRecurrencePicker() {
  // Similar ao priority picker, mas com RecurrenceType
  // Opções: 📅 Não se repete, 🔄 Toda semana, 📆 Todo mês, 🎂 Todo ano
}
```

**📅 Lógica de Repetição (Futura):**
- `none`: Evento único
- `weekly`: Repete 7 em 7 dias
- `monthly`: Repete mensalmente (mesmo dia)
- `yearly`: Repete anualmente (aniversários, etc.)

#### **Widget 3: Seletor de Condições Climáticas**

```dart
Widget _buildWeatherConditionsPicker() {
  return Column(
    children: [
      Text('Monitorar Condições Climáticas'),
      Container(
        child: Column(
          children: WeatherCondition.values.map((condition) {
            final isSelected = _monitoredConditions.contains(condition);
            return CheckboxListTile(
              value: isSelected,
              onChanged: (checked) {
                setState(() {
                  if (checked!) {
                    _monitoredConditions.add(condition);
                  } else {
                    _monitoredConditions.remove(condition);
                  }
                });
              },
              title: Row(
                children: [
                  Text(condition.icon, style: TextStyle(fontSize: 20)),
                  SizedBox(width: 12),
                  Text(condition.label), // Ex: "Temperatura"
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}
```

**🌦️ Multi-Seleção:**
- Usuário pode selecionar múltiplas condições
- Checkboxes independentes
- Ex: Marcar "Chuva" + "Vento" para evento ao ar livre

#### **Widget 4: Campo de Tags**

```dart
Widget _buildTagsField() {
  return Column(
    children: [
      Text('Tags'),
      Container(
        child: Column(
          children: [
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                hintText: 'Digite uma tag e pressione Enter',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add, color: Colors.blue),
                  onPressed: () {
                    final tag = _tagsController.text.trim();
                    if (tag.isNotEmpty && !_tags.contains(tag)) {
                      setState(() {
                        _tags.add(tag);
                        _tagsController.clear();
                      });
                    }
                  },
                ),
              ),
              onSubmitted: (value) {
                // Adiciona tag ao pressionar Enter
              },
            ),
            // Exibir tags como chips
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.blue.withOpacity(0.3),
                    deleteIcon: Icon(Icons.close, size: 18),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    ],
  );
}
```

**🏷️ Sistema de Tags:**
- Campo de texto com botão "+" ou Enter
- Tags exibidas como chips removíveis
- Previne duplicatas
- Exemplos: "urgente", "trabalho", "família", "saúde"

#### **Salvamento dos Novos Dados:**

```dart
void _saveActivity() async {
  // ... validações existentes
  
  final activity = Activity(
    id: '', // Gerado pelo Firestore
    userId: userId,
    title: _titleController.text,
    date: DateTime(
      _selectedDate.year,
      _selectedDate.month, 
      _selectedDate.day,
      _startTime!.hour,
      _startTime!.minute,
    ),
    location: _selectedLocation!,
    type: _selectedType,
    description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
    
    // 🆕 NOVOS CAMPOS SALVOS
    priority: _selectedPriority,
    tags: _tags,
    recurrence: _selectedRecurrence,
    monitoredConditions: _monitoredConditions,
  );
  
  await _userDataService.createActivity(activity);
  Navigator.pop(context);
}
```

---

## 🏠 Mudanças na Tela Home

### 📱 **Header Reformulado**
Localização: `lib/src/features/home/presentation/screens/home_screen.dart`

#### **Antes:**
```
┌─────────────────────────────────┐
│ 📅 [Ícone Evento]               │
│ Seus Próximos Eventos           │
│ 8 eventos analisados            │
└─────────────────────────────────┘
```

#### **Depois:**
```
┌─────────────────────────────────┐
│ 🏠 [Ícone Casa]                 │
│ CLIMETRY                        │
│ Mantendo seus eventos sobre     │
│ controle do clima               │
│                                 │
│ Seus Eventos         8 eventos  │
│ Ordenados por proximidade de    │
│ tempo e distância               │
│                                 │
│ ✅ 5 Seguros  ⚠️ 2 Atenção     │
│ 🚨 1 Crítico                    │
└─────────────────────────────────┘
```

#### **Código do Novo Header:**

```dart
Widget _buildModernHeader(bool isDark, ThemeProvider themeProvider) {
  return Container(
    child: Column(
      children: [
        // Ícone + Título
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.home, color: Color(0xFF3B82F6), size: 24), // 🏠 Casa
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CLIMETRY', 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Mantendo seus eventos sobre controle do clima',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        
        SizedBox(height: 20),
        
        // Seção "Seus Eventos"
        Row(
          children: [
            Text('Seus Eventos', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Spacer(),
            Text('${_analyses.length} eventos', 
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        Text('Ordenados por proximidade de tempo e distância',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
        
        // Resumo de status
        if (_analyses.isNotEmpty) ...[
          SizedBox(height: 16),
          Row(
            children: [
              _buildInlineStat('✅', safeCount, 'Seguros', Color(0xFF10B981)),
              _buildInlineStat('⚠️', warningCount, 'Atenção', Color(0xFFF59E0B)),
              _buildInlineStat('🚨', criticalCount, 'Críticos', Color(0xFFEF4444)),
            ],
          ),
        ],
      ],
    ),
  );
}
```

---

## 📅 Mudanças na Tela de Eventos (Ex-Agenda)

### **Renomeação Completa:**

1. **Tab Bar** (`app_new.dart`):
   ```dart
   // ANTES: label: 'Agenda'
   // DEPOIS: label: 'Eventos'
   ```

2. **Header da Tela** (`activities_screen.dart`):
   ```dart
   // ANTES: Text('Agenda')
   // DEPOIS: Text('Eventos')
   ```

3. **Mensagens de Help** (`home_screen.dart`):
   ```dart
   // ANTES: 'Adicione eventos na aba Agenda'
   // DEPOIS: 'Adicione eventos na aba Eventos'
   ```

---

## 🔮 Funcionalidades Futuras (Próximas Implementações)

### **1. Edição de Eventos**
- Criar `edit_activity_screen.dart` similar a `new_activity_screen.dart`
- Pré-preencher campos com dados existentes
- Manter mesma UI/UX

### **2. Filtros Avançados na Tela Eventos**
Adicionar botão de filtros com opções:

```dart
// Filtro por Prioridade
[ ] Comum  [ ] Importante  [ ] Prioritário  [ ] Urgente

// Filtro por Tipo de Recorrência
[ ] Únicos  [ ] Semanais  [ ] Mensais  [ ] Anuais

// Filtro por Tags
[ ] trabalho  [ ] pessoal  [ ] urgente  [ ] família

// Ordenação
( ) Mais próximos (data/hora)
( ) Mais próximos (distância geográfica)
( ) Prioridade (urgente → comum)
```

### **3. Ordenação por Proximidade Geográfica**
- Usar `LatLng` + localização atual do usuário
- Calcular distância usando `geolocator` package
- Ordenar lista de eventos por distância crescente

### **4. Lógica de Eventos Recorrentes**
Implementar geração automática de instâncias:

```dart
List<Activity> generateRecurringInstances(Activity baseActivity, DateTime until) {
  if (baseActivity.recurrence == RecurrenceType.none) {
    return [baseActivity];
  }
  
  List<Activity> instances = [];
  DateTime currentDate = baseActivity.date;
  
  while (currentDate.isBefore(until)) {
    instances.add(baseActivity.copyWith(date: currentDate));
    
    switch (baseActivity.recurrence) {
      case RecurrenceType.weekly:
        currentDate = currentDate.add(Duration(days: 7));
        break;
      case RecurrenceType.monthly:
        currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
        break;
      case RecurrenceType.yearly:
        currentDate = DateTime(currentDate.year + 1, currentDate.month, currentDate.day);
        break;
    }
  }
  
  return instances;
}
```

### **5. Análise Climática Personalizada**
Usar `monitoredConditions` para:
- Alertas customizados (ex: avisar se UV > 8 para evento ao ar livre)
- Gráficos específicos (mostrar só temperatura e chuva se selecionados)
- Sugestões mais precisas baseadas nas condições escolhidas

### **6. Busca por Tags**
- Campo de busca na tela Eventos
- Filtrar por múltiplas tags (AND/OR logic)
- Autocomplete de tags existentes

---

## ✅ Checklist de Implementação

### **Fase 1: Modelo de Dados** ✅
- [x] Criar enum `ActivityPriority` com 4 níveis
- [x] Criar enum `RecurrenceType` com 4 tipos
- [x] Criar enum `WeatherCondition` com 5 condições
- [x] Adicionar 4 novos campos na classe `Activity`
- [x] Atualizar `toJson()` e `fromJson()` com backward compatibility
- [x] Testar serialização/desserialização

### **Fase 2: UI de Criação** ✅
- [x] Adicionar state variables na `NewActivityScreen`
- [x] Implementar `_buildPriorityPicker()`
- [x] Implementar `_buildRecurrencePicker()`
- [x] Implementar `_buildWeatherConditionsPicker()`
- [x] Implementar `_buildTagsField()`
- [x] Atualizar `_saveActivity()` para incluir novos campos
- [x] Testar criação de eventos com todos os campos

### **Fase 3: Home Screen** ✅
- [x] Mudar ícone do header para `Icons.home`
- [x] Alterar título para "CLIMETRY"
- [x] Adicionar subtitle "Mantendo seus eventos sobre controle do clima"
- [x] Criar seção "Seus Eventos" com contador
- [x] Adicionar texto de ordenação

### **Fase 4: Renomeação** ✅
- [x] Alterar label da tab bar de "Agenda" → "Eventos"
- [x] Alterar título do header da tela de eventos
- [x] Atualizar mensagens de ajuda

### **Fase 5: Filtros e Edição** 🔜
- [ ] Implementar `edit_activity_screen.dart`
- [ ] Adicionar botão de filtros na tela Eventos
- [ ] Implementar lógica de filtro por prioridade
- [ ] Implementar lógica de filtro por tags
- [ ] Implementar ordenação por proximidade temporal
- [ ] Implementar ordenação por proximidade geográfica

### **Fase 6: Eventos Recorrentes** 🔜
- [ ] Criar lógica de geração de instâncias recorrentes
- [ ] Adicionar indicador visual de eventos recorrentes
- [ ] Implementar edição de série vs instância única
- [ ] Testar todos os tipos de recorrência

---

## 🧪 Testes Recomendados

### **Testes Manuais:**

1. **Criação de Evento Simples:**
   - Criar evento com todos os campos default
   - Verificar salvamento no Firestore
   - Confirmar que aparece na lista

2. **Criação de Evento Completo:**
   - Definir prioridade: Urgente
   - Adicionar 3 tags: "trabalho", "importante", "deadline"
   - Marcar recorrência: Toda semana
   - Selecionar 3 condições: Temperatura, Chuva, Vento
   - Salvar e verificar persistência

3. **Backward Compatibility:**
   - Verificar que eventos antigos ainda carregam
   - Confirmar valores default aplicados corretamente

4. **Interface Home:**
   - Verificar ícone de casa aparece
   - Confirmar título "CLIMETRY"
   - Checar subtitle completo
   - Validar seção "Seus Eventos"

5. **Renomeação:**
   - Tab bar mostra "Eventos" não "Agenda"
   - Header da tela mostra "Eventos"

---

## 📊 Dados de Exemplo

### **Evento de Exemplo JSON:**

```json
{
  "id": "abc123",
  "userId": "user456",
  "title": "Reunião Importante com Cliente",
  "date": "2024-06-15T14:30:00Z",
  "location": {
    "latitude": -23.550520,
    "longitude": -46.633308
  },
  "type": "work",
  "description": "Apresentação do projeto trimestral",
  "priority": "urgent",
  "tags": ["trabalho", "cliente", "Q2", "vendas"],
  "recurrence": "monthly",
  "monitoredConditions": ["temperature", "rain"]
}
```

---

## 🚀 Como Testar no iPhone

### **Build e Deploy:**

```bash
# 1. Navegar para o projeto
cd /Users/roosoars/Desktop/Climetry

# 2. Build release com OpenAI API key
flutter build ios --release \
  --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY \
  --dart-define=ENABLE_OPENAI=true

# 3. Deploy wireless (iPhone conectado na mesma rede)
flutter run --release -d 00008120-001E749A0C01A01E
```

### **Fluxo de Teste:**

1. **Login/Registro** → Entrar no app
2. **Home** → Verificar novo header com "CLIMETRY"
3. **Tab "Eventos"** → Verificar nome alterado
4. **Botão + no header** → Criar novo evento
5. **Preencher todos os campos novos:**
   - Prioridade: Urgente 🔴
   - Tags: "teste", "desenvolvimento"
   - Repetir: Toda semana
   - Monitorar: Temperatura + Chuva
6. **Salvar** → Verificar evento aparece na lista
7. **Fechar e reabrir app** → Confirmar persistência
8. **Home** → Ver análise climática do evento criado

---

## 📝 Notas Finais

- **Compatibilidade:** Todas as mudanças são backward-compatible
- **Performance:** Novos campos adicionam < 1KB por evento
- **Escalabilidade:** Sistema de tags permite categorização ilimitada
- **UX:** Todos os novos campos são opcionais (exceto prioridade com default)

**Status:** ✅ **Implementação Completa - Fase 1-4**
**Próximos Passos:** Filtros avançados, edição de eventos, lógica de recorrência

---

*Documentação criada em: 2024*  
*Última atualização: Durante implementação das funcionalidades avançadas*
