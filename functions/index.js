const {onDocumentCreated, onDocumentUpdated, onDocumentDeleted} = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
const {setGlobalOptions} = require('firebase-functions/v2');

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

// Enviar notificação via FCM
exports.sendFCMNotification = onDocumentCreated('fcmMessages/{messageId}', async (event) => {
  const data = event.data.data();
  
  // Verificar se já foi enviada
  if (data.sent) return null;
  
  const message = {
    token: data.token,
    notification: {
      title: data.notification.title,
      body: data.notification.body,
    },
    data: data.data || {},
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        channelId: 'climetry_channel',
      },
    },
  };
  
  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    
    // Marcar como enviada
    await event.data.ref.update({ 
      sent: true, 
      sentAt: admin.firestore.FieldValue.serverTimestamp() 
    });
    
    return null;
  } catch (error) {
    console.error('Error sending message:', error);
    await event.data.ref.update({ error: error.message });
    return null;
  }
});

// Notificar quando um pedido de amizade é criado
exports.notifyFriendRequest = onDocumentCreated('friendRequests/{requestId}', async (event) => {
  const request = event.data.data();
  
  console.log('🔔 Friend request created:', {
    requestId: event.params.requestId,
    fromUser: request.fromUserName,
    toUserId: request.toUserId,
  });
  
  // Buscar token do destinatário
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(request.toUserId)
    .get();
  
  const fcmToken = userDoc.data()?.fcmToken;
  if (!fcmToken) {
    console.log('⚠️ No FCM token found for user:', request.toUserId);
    return null;
  }
  
  console.log('📱 FCM Token found for user:', request.toUserId);
  
  // Enviar notificação
  await admin.firestore().collection('fcmMessages').add({
    token: fcmToken,
    notification: {
      title: 'Nova solicitação de amizade',
      body: `${request.fromUserName || 'Alguém'} quer ser seu amigo`,
    },
    data: {
      type: 'friend_request',
      requestId: event.params.requestId,
      fromUserId: request.fromUserId,
      fromUserName: request.fromUserName || '',
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    sent: false,
  });
  
  console.log('✅ Notification queued successfully');
  
  return null;
});

// Notificar quando é convidado para um evento
exports.notifyEventInvitation = onDocumentCreated('eventInvitations/{invitationId}', async (event) => {
  const invitation = event.data.data();
  
  // Verificar se já foi processada
  if (invitation.processed) return null;
  
  console.log('🎉 Event invitation created:', {
    invitationId: event.params.invitationId,
    activityTitle: invitation.activityTitle,
    participantUserId: invitation.participantUserId,
  });
  
  // Buscar token do participante
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(invitation.participantUserId)
    .get();
  
  const fcmToken = userDoc.data()?.fcmToken;
  if (!fcmToken) {
    console.log('⚠️ No FCM token found for user:', invitation.participantUserId);
    
    // Marcar como processada mesmo sem token
    await event.data.ref.update({ 
      processed: true, 
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      error: 'No FCM token found',
    });
    return null;
  }
  
  console.log('📱 FCM Token found for user:', invitation.participantUserId);
  
  // Determinar emoji do tipo de atividade
  const typeEmoji = {
    'beach': '🏖️',
    'hiking': '🥾',
    'camping': '⛺',
    'sports': '⚽',
    'picnic': '🧺',
    'party': '🎉',
    'concert': '🎵',
    'other': '📅',
  }[invitation.activityType] || '📅';
  
  // Determinar papel do participante
  const roleText = {
    'owner': 'dono',
    'admin': 'administrador',
    'moderator': 'moderador',
    'participant': 'participante',
  }[invitation.participantRole] || 'participante';
  
  // Enviar notificação
  await admin.firestore().collection('fcmMessages').add({
    token: fcmToken,
    notification: {
      title: `${typeEmoji} Convite para Evento`,
      body: `Você foi convidado como ${roleText} para "${invitation.activityTitle}"`,
    },
    data: {
      type: 'event_invitation',
      activityId: invitation.activityId,
      activityTitle: invitation.activityTitle,
      role: invitation.participantRole,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    sent: false,
  });
  
  // Marcar como processada
  await event.data.ref.update({ 
    processed: true, 
    processedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  console.log('✅ Event invitation notification queued successfully');
  
  return null;
});

// Notificar sobre atualizações em atividades
exports.notifyActivityUpdate = onDocumentCreated('activityUpdates/{updateId}', async (event) => {
  const update = event.data.data();
  
  // Verificar se já foi processada
  if (update.processed) return null;
  
  console.log('📢 Activity update created:', {
    updateId: event.params.updateId,
    activityTitle: update.activityTitle,
    participantUserId: update.participantUserId,
  });
  
  // Buscar token do participante
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(update.participantUserId)
    .get();
  
  const fcmToken = userDoc.data()?.fcmToken;
  if (!fcmToken) {
    console.log('⚠️ No FCM token found for user:', update.participantUserId);
    
    // Marcar como processada mesmo sem token
    await event.data.ref.update({ 
      processed: true, 
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      error: 'No FCM token found',
    });
    return null;
  }
  
  // Enviar notificação
  await admin.firestore().collection('fcmMessages').add({
    token: fcmToken,
    notification: {
      title: `📝 Atualização: ${update.activityTitle}`,
      body: update.updateMessage,
    },
    data: {
      type: 'activity_update',
      activityId: update.activityId,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    sent: false,
  });
  
  // Marcar como processada
  await event.data.ref.update({ 
    processed: true, 
    processedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  console.log('✅ Activity update notification queued successfully');
  
  return null;
});

// Notificar quando notificação genérica é criada
exports.sendNotification = onDocumentCreated('notifications/{notificationId}', async (event) => {
  const notification = event.data.data();
  
  // Verificar se já foi enviada
  if (notification.status !== 'pending') return null;
  
  console.log('📬 Notification created:', {
    notificationId: event.params.notificationId,
    type: notification.type,
    recipientId: notification.recipientId,
  });
  
  const fcmToken = notification.fcmToken;
  if (!fcmToken) {
    console.log('⚠️ No FCM token in notification');
    await event.data.ref.update({ 
      status: 'failed', 
      error: 'No FCM token',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return null;
  }
  
  // Enviar notificação
  await admin.firestore().collection('fcmMessages').add({
    token: fcmToken,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: notification.data || {},
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    sent: false,
  });
  
  // Atualizar status
  await event.data.ref.update({ 
    status: 'sent', 
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  console.log('✅ Notification queued successfully');
  
  return null;
});

// Notificar quando atividade é deletada
exports.notifyActivityDeleted = onDocumentDeleted('activities/{activityId}', async (event) => {
  const deletedActivity = event.data.data();
  
  console.log('🗑️ Activity deleted:', {
    activityId: event.params.activityId,
    activityTitle: deletedActivity.title,
    ownerId: deletedActivity.ownerId,
  });
  
  // Notificar todos os participantes (exceto o dono)
  const participantIds = deletedActivity.participantIds || [];
  
  for (const participantId of participantIds) {
    // Pular o dono (ele que deletou)
    if (participantId === deletedActivity.ownerId) continue;
    
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(participantId)
      .get();
    
    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) continue;
    
    // Enviar notificação
    await admin.firestore().collection('fcmMessages').add({
      token: fcmToken,
      notification: {
        title: '❌ Evento Cancelado',
        body: `O evento "${deletedActivity.title}" foi cancelado pelo organizador`,
      },
      data: {
        type: 'activity_deleted',
        activityId: event.params.activityId,
        activityTitle: deletedActivity.title,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      sent: false,
    });
  }
  
  console.log('✅ Deletion notifications queued for all participants');
  
  return null;
});
