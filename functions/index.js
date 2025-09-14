const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Process notification requests and send push notifications
exports.processNotificationRequests = functions.firestore
  .document('notification_requests/{requestId}')
  .onCreate(async (snap, context) => {
    try {
      const notificationData = snap.data();
      
      // Check if already processed
      if (notificationData.processed) {
        return null;
      }

      const {
        recipientToken,
        title,
        body,
        data = {},
        timestamp
      } = notificationData;

      if (!recipientToken) {
        console.error('No recipient token provided');
        return null;
      }

      // Prepare the message
      const message = {
        token: recipientToken,
        notification: {
          title: title || 'New Message',
          body: body || 'You have a new message',
        },
        data: {
          ...data,
          timestamp: timestamp?.toString() || Date.now().toString(),
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: title || 'New Message',
                body: body || 'You have a new message',
              },
              badge: 1,
              sound: 'default',
            },
          },
        },
        android: {
          notification: {
            title: title || 'New Message',
            body: body || 'You have a new message',
            icon: 'ic_notification',
            color: '#007AFF',
            sound: 'default',
          },
          priority: 'high',
        },
      };

      // Send the notification
      const response = await admin.messaging().send(message);
      console.log('Successfully sent message:', response);

      // Mark as processed
      await snap.ref.update({
        processed: true,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: response,
      });

      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      
      // Mark as failed
      await snap.ref.update({
        processed: true,
        failed: true,
        error: error.message,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      throw error;
    }
  });

// Send notification when a new message is created
exports.sendMessageNotification = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    try {
      const message = snap.data();
      const { chatId } = context.params;

      // Get chat information
      const chatDoc = await admin.firestore()
        .collection('chats')
        .doc(chatId)
        .get();

      if (!chatDoc.exists) {
        console.log('Chat not found:', chatId);
        return null;
      }

      const chat = chatDoc.data();
      const participants = chat.participants || [];

      // Get sender information
      const senderDoc = await admin.firestore()
        .collection('users')
        .doc(message.senderId)
        .get();

      if (!senderDoc.exists) {
        console.log('Sender not found:', message.senderId);
        return null;
      }

      const sender = senderDoc.data();

      // Get recipients (exclude sender)
      const recipients = participants.filter(id => id !== message.senderId);

      if (recipients.length === 0) {
        console.log('No recipients found for chat:', chatId);
        return null;
      }

      // Get recipient user data with FCM tokens
      const recipientDocs = await admin.firestore()
        .collection('users')
        .where(admin.firestore.FieldPath.documentId(), 'in', recipients)
        .get();

      const recipientTokens = [];
      recipientDocs.forEach(doc => {
        const userData = doc.data();
        if (userData.fcmToken && userData.isOnline === false) {
          // Only send to offline users to avoid duplicate notifications
          recipientTokens.push(userData.fcmToken);
        }
      });

      if (recipientTokens.length === 0) {
        console.log('No FCM tokens found for recipients');
        return null;
      }

      // Prepare notification content
      let notificationTitle;
      let notificationBody;

      if (chat.isGroupChat) {
        notificationTitle = chat.name || 'Group Chat';
        notificationBody = `${sender.name}: ${getMessagePreview(message)}`;
      } else {
        notificationTitle = sender.name;
        notificationBody = getMessagePreview(message);
      }

      // Send notifications to all recipients
      const promises = recipientTokens.map(token => {
        const notificationMessage = {
          token: token,
          notification: {
            title: notificationTitle,
            body: notificationBody,
          },
          data: {
            chatId: chatId,
            messageId: snap.id,
            senderId: message.senderId,
            type: 'new_message',
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title: notificationTitle,
                  body: notificationBody,
                },
                badge: 1,
                sound: 'default',
              },
            },
          },
          android: {
            notification: {
              title: notificationTitle,
              body: notificationBody,
              icon: 'ic_notification',
              color: '#007AFF',
              sound: 'default',
            },
            priority: 'high',
          },
        };

        return admin.messaging().send(notificationMessage);
      });

      const results = await Promise.allSettled(promises);
      
      // Log results
      results.forEach((result, index) => {
        if (result.status === 'fulfilled') {
          console.log(`Notification sent successfully to token ${index}:`, result.value);
        } else {
          console.error(`Failed to send notification to token ${index}:`, result.reason);
        }
      });

      return results;
    } catch (error) {
      console.error('Error in sendMessageNotification:', error);
      throw error;
    }
  });

// Helper function to get message preview
function getMessagePreview(message) {
  switch (message.type) {
    case 'text':
      return message.text && message.text.length > 50 
        ? `${message.text.substring(0, 50)}...` 
        : message.text || 'New message';
    case 'image':
      return '📷 Photo';
    case 'file':
      return '📎 File';
    default:
      return 'New message';
  }
}

// Clean up old notification requests (runs daily)
exports.cleanupNotificationRequests = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 7); // Delete requests older than 7 days

    const query = admin.firestore()
      .collection('notification_requests')
      .where('createdAt', '<', admin.firestore.Timestamp.fromDate(cutoff));

    const snapshot = await query.get();
    
    if (snapshot.empty) {
      console.log('No old notification requests to delete');
      return null;
    }

    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Deleted ${snapshot.docs.length} old notification requests`);
    
    return null;
  });
