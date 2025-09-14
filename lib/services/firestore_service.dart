import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/friend_request_model.dart';
import '../utils/constants.dart';
import 'dart:async';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // User Operations
  Future<List<UserModel>> searchUsers(String query, String currentUserId) async {
    try {
      // Search by name (case insensitive)
      final nameQuery = await _firestore
          .collection(AppConstants.usersCollection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      // Search by email
      final emailQuery = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(20)
          .get();

      final Set<UserModel> users = {};
      
      // Add users from name search
      for (var doc in nameQuery.docs) {
        final user = UserModel.fromDocument(doc);
        if (user.uid != currentUserId) {
          users.add(user);
        }
      }
      
      // Add users from email search
      for (var doc in emailQuery.docs) {
        final user = UserModel.fromDocument(doc);
        if (user.uid != currentUserId) {
          users.add(user);
        }
      }

      return users.toList();
    } catch (e) {
      throw Exception('Failed to search users: ${e.toString()}');
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  // Friend Request Operations
  Future<void> sendFriendRequest(String senderId, String receiverId) async {
    try {
      // Check if request already exists
      final existingRequest = await _firestore
          .collection(AppConstants.friendRequestsCollection)
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw Exception('Friend request already sent');
      }

      // Check if they are already friends
      final friendship = await _firestore
          .collection(AppConstants.friendsCollection)
          .where('user1Id', whereIn: [senderId, receiverId])
          .where('user2Id', whereIn: [senderId, receiverId])
          .get();

      if (friendship.docs.isNotEmpty) {
        throw Exception('Already friends');
      }

      final request = FriendRequest(
        id: _uuid.v4(),
        senderId: senderId,
        receiverId: receiverId,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.friendRequestsCollection)
          .doc(request.id)
          .set(request.toMap());
    } catch (e) {
      throw Exception('Failed to send friend request: ${e.toString()}');
    }
  }

  Future<void> respondToFriendRequest(String requestId, bool accept) async {
    try {
      final requestDoc = await _firestore
          .collection(AppConstants.friendRequestsCollection)
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Friend request not found');
      }

      final request = FriendRequest.fromDocument(requestDoc);

      if (accept) {
        // Accept request
        await _firestore
            .collection(AppConstants.friendRequestsCollection)
            .doc(requestId)
            .update(request.accept().toMap());

        // Create friendship
        final friendship = Friendship(
          id: _uuid.v4(),
          user1Id: request.senderId,
          user2Id: request.receiverId,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.friendsCollection)
            .doc(friendship.id)
            .set(friendship.toMap());
      } else {
        // Decline request
        await _firestore
            .collection(AppConstants.friendRequestsCollection)
            .doc(requestId)
            .update(request.decline().toMap());
      }
    } catch (e) {
      throw Exception('Failed to respond to friend request: ${e.toString()}');
    }
  }

  Stream<List<FriendRequest>> getFriendRequests(String userId) {
    return _firestore
        .collection(AppConstants.friendRequestsCollection)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequest.fromDocument(doc))
            .toList());
  }

  Stream<List<Friendship>> getFriends(String userId) {
    // Merge real-time snapshots for friendships where the user is either user1Id or user2Id
    final controller = StreamController<List<Friendship>>.broadcast();

    List<Friendship> friendsAsUser1 = [];
    List<Friendship> friendsAsUser2 = [];

    StreamSubscription? sub1;
    StreamSubscription? sub2;

    void emitCombined() {
      // Combine both lists and emit
      controller.add([...friendsAsUser1, ...friendsAsUser2]);
    }

    sub1 = _firestore
        .collection(AppConstants.friendsCollection)
        .where('user1Id', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      friendsAsUser1 = snapshot.docs.map((doc) => Friendship.fromDocument(doc)).toList();
      emitCombined();
    }, onError: (error) {
      controller.addError(error);
    });

    sub2 = _firestore
        .collection(AppConstants.friendsCollection)
        .where('user2Id', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      friendsAsUser2 = snapshot.docs.map((doc) => Friendship.fromDocument(doc)).toList();
      emitCombined();
    }, onError: (error) {
      controller.addError(error);
    });

    controller.onCancel = () async {
      await sub1?.cancel();
      await sub2?.cancel();
    };

    return controller.stream;
  }

  // Remove friendship between two users (affects both perspectives)
  Future<void> deleteFriendship(String userAId, String userBId) async {
    try {
      final col = _firestore.collection(AppConstants.friendsCollection);

      // Find friendships where (user1==A && user2==B) OR (user1==B && user2==A)
      final q1 = await col
          .where('user1Id', isEqualTo: userAId)
          .where('user2Id', isEqualTo: userBId)
          .get();

      final q2 = await col
          .where('user1Id', isEqualTo: userBId)
          .where('user2Id', isEqualTo: userAId)
          .get();

      final docs = [...q1.docs, ...q2.docs];

      if (docs.isEmpty) {
        // Nothing to delete; treat as success to keep UX smooth
        return;
      }

      final batch = _firestore.batch();
      for (final d in docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove friend: ${e.toString()}');
    }
  }

  // Chat Operations
  Future<String> createChat(List<String> participants, {bool isGroup = false, String? groupName}) async {
    try {
      final chatId = _uuid.v4();
      final chat = Chat(
        id: chatId,
        participants: participants,
        isGroup: isGroup,
        groupName: groupName,
        createdAt: DateTime.now(),
        createdBy: participants.first,
      );

      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .set(chat.toMap());

      return chatId;
    } catch (e) {
      throw Exception('Failed to create chat: ${e.toString()}');
    }
  }

  Future<String?> getDirectChatId(String user1Id, String user2Id) async {
    try {
      final query = await _firestore
          .collection(AppConstants.chatsCollection)
          .where('participants', arrayContains: user1Id)
          .where('isGroup', isEqualTo: false)
          .get();

      for (var doc in query.docs) {
        final chat = Chat.fromDocument(doc);
        if (chat.participants.contains(user2Id) && chat.participants.length == 2) {
          return chat.id;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get direct chat: ${e.toString()}');
    }
  }

  Stream<List<Chat>> getUserChats(String userId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Chat.fromDocument(doc))
            .toList());
  }

  // Message Operations
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? replyToMessageId,
  }) async {
    try {
      final messageId = _uuid.v4();
      
      // Get reply information if replying to a message
      String? replyToText;
      String? replyToSenderId;
      if (replyToMessageId != null) {
        final replyDoc = await _firestore
            .collection(AppConstants.messagesCollection)
            .doc(replyToMessageId)
            .get();
        if (replyDoc.exists) {
          final replyMessage = Message.fromDocument(replyDoc);
          replyToText = replyMessage.text;
          replyToSenderId = replyMessage.senderId;
        }
      }
      
      final message = Message(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
        type: type,
        imageUrl: imageUrl,
        readBy: [senderId], // Sender has read the message
        replyToMessageId: replyToMessageId,
        replyToText: replyToText,
        replyToSenderId: replyToSenderId,
      );

      // Add message to messages collection
      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .set(message.toMap());

      // Update chat with last message info
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
      });

      // Update unread counts for other participants
      final chatDoc = await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .get();

      if (chatDoc.exists) {
        final chat = Chat.fromDocument(chatDoc);
        final Map<String, int> updatedUnreadCount = Map.from(chat.unreadCount);

        for (String participantId in chat.participants) {
          if (participantId != senderId) {
            updatedUnreadCount[participantId] = (updatedUnreadCount[participantId] ?? 0) + 1;
          }
        }

        await _firestore
            .collection(AppConstants.chatsCollection)
            .doc(chatId)
            .update({'unreadCount': updatedUnreadCount});
      }
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Stream<List<Message>> getChatMessages(String chatId, {int limit = 20}) {
    return _firestore
        .collection(AppConstants.messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromDocument(doc))
            .toList());
  }

  // Get paginated messages for a chat
  Future<List<Message>> getChatMessagesPaginated(
    String chatId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Message.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get paginated messages: ${e.toString()}');
    }
  }

  // Get messages after a specific timestamp (for real-time updates)
  Future<List<Message>> getMessagesAfter(
    String chatId,
    DateTime timestamp, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(timestamp))
          .orderBy('timestamp', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Message.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get messages after timestamp: ${e.toString()}');
    }
  }

  // Get recent messages for initial load
  Future<List<Message>> getRecentMessages(
    String chatId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Message.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get recent messages: ${e.toString()}');
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // Reset unread count for user
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .update({'unreadCount.$userId': 0});

      // Mark messages as read
      final unreadMessages = await _firestore
          .collection(AppConstants.messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('readBy', whereNotIn: [userId])
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        final message = Message.fromDocument(doc);
        if (!message.readBy.contains(userId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([userId])
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: ${e.toString()}');
    }
  }

  // Mark a single message as read (more efficient for individual messages)
  Future<void> markSingleMessageAsRead(String messageId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: ${e.toString()}');
    }
  }

  // Edit message
  Future<void> editMessage(String messageId, String newText, String userId) async {
    try {
      final messageDoc = await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final message = Message.fromDocument(messageDoc);
      
      // Check if user is the sender
      if (message.senderId != userId) {
        throw Exception('You can only edit your own messages');
      }

      // Check if message can still be edited (15 minute window)
      if (!message.canEdit(userId)) {
        throw Exception('Message can no longer be edited');
      }

      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .update({
        'text': newText,
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to edit message: ${e.toString()}');
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId, String userId) async {
    try {
      final messageDoc = await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final message = Message.fromDocument(messageDoc);
      
      // Check if user is the sender
      if (message.senderId != userId) {
        throw Exception('You can only delete your own messages');
      }

      // Mark as deleted instead of actually deleting to preserve chat history
      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .update({
        'isDeleted': true,
        'text': 'This message was deleted',
      });
    } catch (e) {
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }

  // Add reaction to message
  Future<void> addReaction(String messageId, String emoji, String userId) async {
    try {
      final messageDoc = await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final message = Message.fromDocument(messageDoc);
      final updatedMessage = message.addReaction(emoji, userId);

      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .update({'reactions': updatedMessage.reactions});
    } catch (e) {
      throw Exception('Failed to add reaction: ${e.toString()}');
    }
  }

  // Remove reaction from message
  Future<void> removeReaction(String messageId, String emoji, String userId) async {
    try {
      final messageDoc = await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final message = Message.fromDocument(messageDoc);
      final updatedMessage = message.removeReaction(emoji, userId);

      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .update({'reactions': updatedMessage.reactions});
    } catch (e) {
      throw Exception('Failed to remove reaction: ${e.toString()}');
    }
  }

  // Delete chat
  Future<void> deleteChat(String chatId, String userId) async {
    try {
      final chatDoc = await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chat = Chat.fromDocument(chatDoc);
      
      // Check if user can delete the chat
      if (!chat.canDelete(userId)) {
        throw Exception('You cannot delete this chat');
      }

      // Mark chat as deleted instead of actually deleting
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .update({'isDeleted': true});
    } catch (e) {
      throw Exception('Failed to delete chat: ${e.toString()}');
    }
  }

  // Pin/unpin chat
  Future<void> pinChat(String chatId, String userId) async {
    try {
      final chatDoc = await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chat = Chat.fromDocument(chatDoc);
      final updatedChat = chat.togglePin(userId);

      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .update({'pinnedBy': updatedChat.pinnedBy});
    } catch (e) {
      throw Exception('Failed to pin chat: ${e.toString()}');
    }
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await markMessagesAsRead(chatId, userId);
    } catch (e) {
      throw Exception('Failed to mark chat as read: ${e.toString()}');
    }
  }

  // Utility Methods
  Future<Map<String, UserModel>> getUsersMap(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return {};
      
      final Map<String, UserModel> usersMap = {};
      
      // Firestore 'in' queries are limited to 10 items
      const batchSize = 10;
      for (int i = 0; i < userIds.length; i += batchSize) {
        final batch = userIds.skip(i).take(batchSize).toList();
        
        final snapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        for (var doc in snapshot.docs) {
          final user = UserModel.fromDocument(doc);
          usersMap[user.uid] = user;
        }
      }
      
      return usersMap;
    } catch (e) {
      throw Exception('Failed to get users map: ${e.toString()}');
    }
  }

  // Get users with online status
  Future<Map<String, UserModel>> getUsersWithStatus(List<String> userIds) async {
    try {
      final usersMap = await getUsersMap(userIds);
      
      // Update with real-time online status if available
      for (final userId in userIds) {
        if (usersMap.containsKey(userId)) {
          // This could be enhanced with real-time presence detection
          // For now, we'll use the cached status from the user document
        }
      }
      
      return usersMap;
    } catch (e) {
      throw Exception('Failed to get users with status: ${e.toString()}');
    }
  }
}
