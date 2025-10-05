# 🧪 Guia de Testes - Event Collaboration System

## 📱 Dispositivos de Teste
- **Dispositivo A (iPhone físico)**: Usuário criador/admin
- **Dispositivo B (Simulador)**: Usuário convidado/participante

---

## ✅ Checklist de Testes

### **Teste 1: Criar Evento com Participantes**

**No Dispositivo A (iPhone):**
1. ✅ Abrir o app
2. ✅ Fazer login (se necessário)
3. ✅ Ir para a aba "Atividades"
4. ✅ Tocar no botão "+" (Nova Atividade)
5. ✅ Preencher os dados:
   - Título: "Churrasco na Praia"
   - Local: Escolher localização
   - Data: Amanhã
   - Horário: 15:00
   - Tipo: 🎉 Festa
6. ✅ Rolar até o final e tocar em "Selecionar Participantes"
7. ✅ Selecionar um amigo (usuário do Simulador)
8. ✅ Atribuir papel: **Admin** 👑
9. ✅ Salvar participantes
10. ✅ Salvar evento
11. ✅ **Resultado Esperado**: 
    - Mensagem "✅ Evento criado!"
    - Evento aparece na lista com badge "🏆 Dono"

---

### **Teste 2: Receber Notificação Push**

**No Dispositivo B (Simulador):**
1. ✅ App deve estar aberto/logado
2. ✅ Aguardar ~10 segundos
3. ✅ **Resultado Esperado**:
   - Notificação push aparece:
   - Título: "🎉 Convite para Evento"
   - Corpo: "Você foi convidado como administrador para 'Churrasco na Praia'"
4. ✅ Se não receber, verificar:
   - Console do Firebase Functions (logs)
   - Firestore collection `eventInvitations` (deve ter 1 documento)
   - Firestore collection `fcmMessages` (deve ter 1 documento com `sent: true`)

**Comandos de debug (terminal):**
```bash
# Ver logs das Cloud Functions
firebase functions:log --only notifyEventInvitation

# Verificar Firestore (via Firebase Console)
https://console.firebase.google.com/project/nasa-climetry/firestore
```

---

### **Teste 3: Ver Evento com Badge de Papel**

**No Dispositivo B (Simulador):**
1. ✅ Abrir o app (se fechou)
2. ✅ Ir para aba "Atividades"
3. ✅ **Resultado Esperado**:
   - Evento "Churrasco na Praia" aparece na lista
   - Badge exibido: **👑 Admin** (cor vermelha)
   - Badge aparece entre a data e o contador "Em X dias"

**Verificação visual:**
- Badge tem fundo semi-transparente vermelho
- Borda vermelha
- Emoji 👑 + texto "Admin"
- Tamanho pequeno (10px)

---

### **Teste 4: Configurar Alertas Personalizados**

**No Dispositivo B (Simulador):**
1. ✅ Tocar no card do evento "Churrasco na Praia"
2. ✅ Rolar até encontrar o botão azul "Configurar Alertas Personalizados"
3. ✅ Tocar no botão
4. ✅ **Resultado Esperado**: Modal aparece (75% da tela)
5. ✅ Ajustar configurações:
   - **Temperatura**:
     - Ativar toggle
     - Min: 15°C
     - Max: 30°C
   - **Chuva**:
     - Ativar toggle
     - Limite: 40%
   - **Vento**:
     - Ativar toggle
     - Limite: 25 km/h
   - **Umidade**:
     - Desativar toggle
6. ✅ Como admin, deve ver opção "Aplicar para Todos" (badge dourado)
7. ✅ Ativar "Aplicar para Todos"
8. ✅ Tocar em "Salvar Configurações"
9. ✅ **Resultado Esperado**:
   - Mensagem: "Configurações aplicadas para todos os participantes"
   - Modal fecha

**Verificação:**
- Abrir novamente os alertas
- Valores devem estar salvos (15°C, 30°C, 40%, 25km/h)

---

### **Teste 5: Admin Pode Editar Evento**

**No Dispositivo B (Simulador):**
1. ✅ No detalhe do evento, tocar no ícone de editar (✏️ no topo)
2. ✅ **Resultado Esperado**: 
   - Tela de edição abre
   - Como admin, pode editar título, data, local
3. ✅ Mudar o título para "Churrasco na Praia - CANCELADO"
4. ✅ Salvar
5. ✅ **Resultado Esperado**:
   - Volta para detalhes
   - Título atualizado exibido

---

### **Teste 6: Sair do Evento (Participante)**

**Criar outro teste:**
**No Dispositivo A (iPhone):**
1. ✅ Criar um segundo evento
2. ✅ Convidar o mesmo usuário como **Participante** 👤 (não admin)

**No Dispositivo B (Simulador):**
1. ✅ Abrir o novo evento
2. ✅ Rolar até o final da página
3. ✅ **Resultado Esperado**: Botão vermelho "Sair do Evento" aparece
4. ✅ Tocar no botão
5. ✅ **Resultado Esperado**: Dialog de confirmação
   - Título: "Sair do Evento"
   - Mensagem: "Tem certeza que deseja sair..."
   - Botões: "Cancelar" e "Sair" (vermelho)
6. ✅ Tocar em "Sair"
7. ✅ **Resultado Esperado**:
   - Mensagem: "Você saiu do evento com sucesso"
   - Volta para lista de atividades
   - Evento desaparece da lista

---

### **Teste 7: Dono NÃO Pode Sair**

**No Dispositivo A (iPhone):**
1. ✅ Abrir o evento "Churrasco na Praia"
2. ✅ Rolar até o final
3. ✅ **Resultado Esperado**: 
   - Botão "Sair do Evento" **NÃO** aparece
   - Apenas donos não podem sair
4. ✅ Se tentar implementar a saída via código, deve mostrar:
   - "Você é o dono deste evento e não pode sair. Delete o evento se necessário."

---

### **Teste 8: Participante NÃO Pode Editar**

**Criar terceiro teste:**
**No Dispositivo A (iPhone):**
1. ✅ Criar terceiro evento
2. ✅ Convidar como **Participante** 👤 (sem admin)

**No Dispositivo B (Simulador):**
1. ✅ Abrir o evento
2. ✅ **Resultado Esperado**:
   - Ícone de editar (✏️) **NÃO** aparece no topo
   - Participantes sem papel de admin/owner não podem editar

---

## 🐛 Troubleshooting

### Notificação não chega:
```bash
# 1. Verificar Cloud Function logs
firebase functions:log --only notifyEventInvitation

# 2. Verificar Firestore
# Ir para Firebase Console → Firestore Database
# Coleções: eventInvitations, fcmMessages

# 3. Verificar FCM token no device B
# No console do Flutter quando app inicia, deve mostrar:
# "🔔 FCM Token: [token]"
```

### Badge não aparece:
- Verificar se `participants` está populado no evento
- Verificar se `currentUserId` está sendo detectado
- Olhar console para erros de null safety

### Alertas não salvam:
- Verificar se `ActivityRepository.update()` está sendo chamado
- Verificar SharedPreferences (pode limpar com `flutter clean`)
- Conferir estrutura JSON do `customAlertSettings`

### App crasha ao abrir evento:
- Verificar se todos os campos obrigatórios estão preenchidos
- Checar se `analysis` não é null
- Ver stack trace no console

---

## 📊 Resultados Esperados - Resumo

| Teste | Dispositivo | Resultado |
|-------|-------------|-----------|
| 1. Criar evento | iPhone | ✅ Evento criado com badge "🏆 Dono" |
| 2. Push notification | Simulador | ✅ Notificação recebida em ~10s |
| 3. Ver badge | Simulador | ✅ Badge "👑 Admin" vermelho |
| 4. Config alertas | Simulador | ✅ Salvou com "Aplicar para Todos" |
| 5. Admin edita | Simulador | ✅ Conseguiu editar título |
| 6. Sair evento | Simulador | ✅ Saiu e evento sumiu |
| 7. Dono não sai | iPhone | ✅ Botão não aparece |
| 8. Participante não edita | Simulador | ✅ Botão editar não aparece |

---

## 📝 Notas de Teste

### Capturas de Tela:
- [ ] Lista de atividades com badges
- [ ] Modal de alertas personalizados
- [ ] Notificação push recebida
- [ ] Dialog de confirmação "Sair"
- [ ] Seletor de participantes

### Performance:
- [ ] Tempo de envio da notificação: ____ segundos
- [ ] Cloud Function execution time: ____ ms (ver Firebase Console)
- [ ] Tempo para salvar alertas: ____ ms

### Bugs Encontrados:
```
[Listar aqui qualquer bug encontrado durante os testes]

Exemplo:
- Badge não aparece em eventos antigos (motivo: ownerId null)
- Notificação demora mais de 30s (motivo: cold start da função)
```

---

## ✅ Checklist Final

Após todos os testes:
- [ ] Todas as features funcionam conforme esperado
- [ ] Notificações chegam em < 15 segundos
- [ ] UI está responsiva e sem bugs visuais
- [ ] Nenhum crash reportado
- [ ] Performance aceitável
- [ ] Pronto para produção

**Data do Teste**: _____________________
**Testado por**: _____________________
**Versão**: 1.0.0
**Build**: Release mode

---

🎉 **Parabéns! Sistema de Colaboração de Eventos testado e aprovado!**
