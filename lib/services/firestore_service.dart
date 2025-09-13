import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/friend_request_model.dart';
import '../utils/constants.dart';

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
    return _firestore
        .collection(AppConstants.friendsCollection)
        .where('user1Id', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot1) async {
      final friends1 = snapshot1.docs.map((doc) => Friendship.fromDocument(doc)).toList();
      
      final snapshot2 = await _firestore
          .collection(AppConstants.friendsCollection)
          .where('user2Id', isEqualTo: userId)
          .get();
      
      final friends2 = snapshot2.docs.map((doc) => Friendship.fromDocument(doc)).toList();
      
      return [...friends1, ...friends2];
    });
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
  }) async {
    try {
      final messageId = _uuid.v4();
      final message = Message(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
        type: type,
        imageUrl: imageUrl,
        readBy: [senderId], // Sender has read the message
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

  // Utility Methods
  Future<Map<String, UserModel>> getUsersMap(List<String> userIds) async {
    try {
      final Map<String, UserModel> usersMap = {};
      
      // Firestore 'in' queries are limited to 10 items
      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .where('uid', whereIn: batch)
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
}
