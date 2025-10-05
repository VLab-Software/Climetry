# 🎯 Implementação de Eventos Colaborativos - PROGRESSO

**Data:** 5 de outubro de 2025  
**Status:** 🚧 EM ANDAMENTO

---

## ✅ Implementado (50% Completo)

### 1. Modelo de Dados Atualizado ✅
**Arquivo:** `lib/src/features/friends/domain/entities/friend.dart`

**EventParticipant:**
```dart
class EventParticipant {
  final String userId;
  final String name;
  final String? photoUrl;
  final EventRole role;           // owner, admin, moderator, participant
  final DateTime joinedAt;
  final ParticipantStatus status; // pending, accepted, rejected, maybe
  final Map<String, dynamic>? customAlertSettings; // NOVO: alertas personalizados
}
```

**EventRole:**
- **Owner**: Criador do evento (pode tudo)
- **Admin**: Pode editar evento e convidar (👑)
- **Moderator**: Pode convidar mas não editar (🎖️)
- **Participant**: Apenas visualiza (👤)

**ParticipantStatus:**
- **Pending**: Convite pendente (⏳)
- **Accepted**: Confirmado (✅)
- **Rejected**: Recusou (❌)
- **Maybe**: Talvez (🤔)

---

### 2. Activity Model Atualizado ✅
**Arquivo:** `lib/src/features/activities/domain/entities/activity.dart`

**Novos Campos:**
```dart
final String ownerId;  // ID do criador
final List<EventParticipant> participants;  // Lista de convidados
```

**Novos Métodos:**
```dart
bool isOwner(String userId)
bool canEdit(String userId)
bool canInvite(String userId)
Activity addParticipant(EventParticipant participant)
Activity removeParticipant(String userId)
Activity updateParticipantStatus(String userId, ParticipantStatus status)
Activity updateParticipantRole(String userId, EventRole role)
Activity updateParticipantAlertSettings(String userId, Map<String, dynamic> settings)  // NOVO
int get confirmedParticipantsCount
```

---

### 3. Tela de Seleção de Participantes ✅
**Arquivo:** `lib/src/features/activities/presentation/widgets/event_participants_selector.dart`

**Funcionalidades:**
- ✅ Lista todos os amigos do usuário
- ✅ Checkbox para selecionar/desselecionar
- ✅ Seletor de papel (Admin/Moderator/Participant)
- ✅ Mostra badges com emoji (👑 🎖️ 👤)
- ✅ Contador de selecionados
- ✅ Interface responsiva dark/light

**UI:**
```
┌─────────────────────────────────┐
│  Convidar Amigos    [2 selecionados]
├─────────────────────────────────┤
│  👤 João Silva            ☑️    │
│     👑 Admin                    │
│     ├─ 👑 Admin ✓              │
│     ├─ 🎖️ Moderador           │
│     └─ 👤 Participante         │
├─────────────────────────────────┤
│  👤 Maria Santos          ☑️    │
│     👤 Participante             │
│     ├─ 👑 Admin                │
│     ├─ 🎖️ Moderador           │
│     └─ 👤 Participante ✓       │
├─────────────────────────────────┤
│  [Confirmar 2 convidado(s)]     │
└─────────────────────────────────┘
```

---

### 4. Integração em NewActivityScreen ✅
**Arquivo:** `lib/src/features/activities/presentation/screens/new_activity_screen.dart`

**Adicionado:**
- ✅ Campo `List<EventParticipant> _selectedParticipants`
- ✅ Método `_selectParticipants()` para abrir modal
- ✅ Widget `_buildParticipantsSelector()` com botão e chips
- ✅ Passa participants para o Activity ao salvar

**UI:**
```
┌────────────────────────────────┐
│  [Convidar amigos (opcional)]  │  ← Botão (vazio)
└────────────────────────────────┘

ou

┌────────────────────────────────┐
│  [2 convidados]                │  ← Botão (com seleção)
├────────────────────────────────┤
│  ⚪ João Silva 👑  ❌          │  ← Chips removíveis
│  ⚪ Maria Santos  ❌           │
└────────────────────────────────┘
```

---

## 🚧 Próximas Etapas (50% Restante)

### 5. Atualizar Cards de Atividade 🔄
**Objetivo:** Mostrar badges de status (Dono/Admin/Convidado)

**Arquivos a modificar:**
- `lib/src/features/activities/presentation/screens/activities_screen.dart`
- `lib/src/features/home/presentation/screens/home_screen_redesigned.dart`

**UI Proposta:**
```
┌──────────────────────────────────────┐
│  🏃 Churrasco com Amigos             │
│  📍 Parque Ibirapuera     [👑 DONO] │
│  📅 10/10/2025 18:00                 │
│  👥 5 confirmados / 8 convidados     │
└──────────────────────────────────────┘

ou

┌──────────────────────────────────────┐
│  🏃 Futebol no Clube                 │
│  📍 Clube XV              [👤 CONVIDADO] │
│  📅 12/10/2025 10:00                 │
└──────────────────────────────────────┘
```

---

### 6. Adicionar Botão "Sair do Evento" 🔄
**Arquivo:** `lib/src/features/activities/presentation/screens/activity_details_screen.dart`

**Regras:**
- ✅ **Convidados** podem sair (botão vermelho)
- ❌ **Admins** não podem sair (só remover outros)
- ❌ **Dono** não pode sair (só deletar evento)

**Método a criar:**
```dart
Future<void> _leaveEvent() async {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  
  if (widget.activity.isOwner(currentUserId)) {
    // Mostrar: "Você é o dono. Apenas pode deletar o evento."
    return;
  }
  
  if (widget.activity.canEdit(currentUserId)) {
    // Mostrar: "Admins não podem sair. Transfira a administração primeiro."
    return;
  }
  
  // Confirmar e remover participante
  final updatedActivity = widget.activity.removeParticipant(currentUserId);
  await _userDataService.saveActivity(updatedActivity);
}
```

**UI:**
```
┌────────────────────────────────┐
│  DETALHES DO EVENTO            │
├────────────────────────────────┤
│  ... conteúdo ...              │
├────────────────────────────────┤
│  [🚪 Sair do Evento]          │  ← Botão vermelho (só convidados)
└────────────────────────────────┘
```

---

### 7. Alertas Personalizados por Participante 🔄
**Arquivo:** Criar `lib/src/features/activities/presentation/widgets/participant_alert_settings.dart`

**Funcionalidade:**
- ✅ **Participante**: Configura alertas **apenas para si**
- ✅ **Admin/Dono**: Pode configurar alertas **globais** (para todos)

**customAlertSettings Structure:**
```json
{
  "temperature": {"enabled": true, "min": 15, "max": 30},
  "rain": {"enabled": true, "threshold": 50},
  "wind": {"enabled": false, "maxSpeed": 40},
  "uv": {"enabled": true, "maxIndex": 8}
}
```

**UI Proposta:**
```
┌─────────────────────────────────────┐
│  ⚙️ Meus Alertas de Clima           │  ← Para participante
├─────────────────────────────────────┤
│  🌡️ Temperatura      ☑️             │
│     ├─ Mínima: [15°C]               │
│     └─ Máxima: [30°C]               │
│  🌧️ Chuva           ☑️             │
│     └─ Probabilidade > [50%]        │
│  💨 Vento           ☐              │
└─────────────────────────────────────┘

vs

┌─────────────────────────────────────┐
│  ⚙️ Alertas Globais (Admin)         │  ← Para admin
├─────────────────────────────────────┤
│  [Configurar para todos]            │
│  [Meus alertas pessoais]            │
└─────────────────────────────────────┘
```

**Método a criar:**
```dart
Future<void> _updateParticipantAlerts(
  String userId,
  Map<String, dynamic> settings,
) async {
  final updatedActivity = widget.activity
      .updateParticipantAlertSettings(userId, settings);
  
  await _userDataService.saveActivity(updatedActivity);
}
```

---

### 8. Cloud Function para Notificações 🔄
**Arquivo:** `functions/index.js`

**Adicionar:**
```javascript
// Notificar quando é convidado para evento
exports.notifyEventInvitation = onDocumentUpdated(
  'users/{userId}/activities/{activityId}',
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    
    // Novos participantes
    const newParticipants = after.participants.filter(p => 
      !before.participants.some(bp => bp.userId === p.userId)
    );
    
    for (const participant of newParticipants) {
      // Buscar FCM token
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(participant.userId)
        .get();
      
      const fcmToken = userDoc.data()?.fcmToken;
      if (!fcmToken) continue;
      
      // Enviar notificação
      await admin.firestore().collection('fcmMessages').add({
        token: fcmToken,
        notification: {
          title: 'Convite para evento',
          body: `${after.ownerName} convidou você para "${after.title}"`,
        },
        data: {
          type: 'event_invitation',
          activityId: event.params.activityId,
          role: participant.role,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        sent: false,
      });
    }
  }
);
```

---

### 9. Atualizar Firestore Security Rules 🔄
**Arquivo:** `firestore.rules`

**Adicionar regras para participantes:**
```javascript
match /users/{userId}/activities/{activityId} {
  // Dono pode fazer tudo
  allow read, write: if request.auth.uid == userId;
  
  // Participantes podem ler
  allow read: if isParticipant(request.auth.uid, resource.data.participants);
  
  // Admins podem editar
  allow update: if canEdit(request.auth.uid, resource.data);
  
  // Participantes podem atualizar seus alertas
  allow update: if canUpdateOwnAlerts(request.auth.uid, resource.data);
}

function isParticipant(uid, participants) {
  return participants.hasAny([uid]);
}

function canEdit(uid, data) {
  return data.ownerId == uid || 
         data.participants[uid].role in ['owner', 'admin'];
}

function canUpdateOwnAlerts(uid, data) {
  return data.participants[uid] != null;
}
```

---

### 10. Teste Completo 🧪

**Cenário 1: Criar Evento com Convites**
1. ✅ Usuário A cria evento "Churrasco"
2. ✅ Convida Usuário B como **Admin** 👑
3. ✅ Convida Usuário C como **Participante** 👤
4. ✅ Salva evento
5. ✅ B e C recebem push notification
6. ✅ B e C veem evento na lista

**Cenário 2: Permissões**
1. ✅ B (admin) pode editar evento
2. ✅ B (admin) pode convidar mais pessoas
3. ❌ C (participante) NÃO pode editar
4. ❌ C (participante) NÃO pode convidar
5. ✅ C (participante) pode sair do evento

**Cenário 3: Alertas Personalizados**
1. ✅ A (dono) configura alertas globais: Chuva > 60%
2. ✅ C (participante) configura **seus** alertas: Temperatura < 20°C
3. ✅ Sistema envia alerta de chuva para todos
4. ✅ Sistema envia alerta de temperatura **apenas** para C
5. ✅ B (admin) pode ver alertas de todos

---

## 📊 Status Geral

| Tarefa | Status | % |
|--------|--------|---|
| Modelo de dados | ✅ Completo | 100% |
| Seletor de participantes | ✅ Completo | 100% |
| Integração NewActivity | ✅ Completo | 100% |
| **Cards com badges** | 🔄 Pendente | 0% |
| **Botão Sair do Evento** | 🔄 Pendente | 0% |
| **Alertas personalizados** | 🔄 Pendente | 0% |
| **Cloud Function** | 🔄 Pendente | 0% |
| **Security Rules** | 🔄 Pendente | 0% |
| **Teste completo** | 🔄 Pendente | 0% |

**PROGRESSO TOTAL: 50% ✅**

---

## 🚀 Próximo Passo

Continuar com implementação das **badges nos cards de atividade** para mostrar visualmente o status do usuário no evento.

---

**Nota:** App está rodando no iPhone. Próximas implementações serão testadas incrementalmente com hot reload.
