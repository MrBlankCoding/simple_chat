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

  // Optimization: Connection pooling and request deduplication
  static final Map<String, Future<UserModel?>> _pendingUserRequests = {};
  static final Map<String, Future<List<UserModel>>> _pendingSearchRequests = {};
  static final Map<String, DateTime> _lastRequestTime = {};
  static final Map<String, UserModel> _userCache = {};
  static const Duration _requestDebounceTime = Duration(milliseconds: 100);
  static const Duration _cacheValidityTime = Duration(minutes: 5);

  // User Operations
  Future<List<UserModel>> searchUsers(String query, String currentUserId) async {
    try {
      final cacheKey = 'search_${query.toLowerCase()}_$currentUserId';
      
      // Check if similar request is pending
      if (_pendingSearchRequests.containsKey(cacheKey)) {
        return await _pendingSearchRequests[cacheKey]!;
      }
      
      // Debounce rapid requests
      final lastRequest = _lastRequestTime[cacheKey];
      if (lastRequest != null && 
          DateTime.now().difference(lastRequest) < _requestDebounceTime) {
        return [];
      }
      
      // Create pending request
      _pendingSearchRequests[cacheKey] = _performUserSearch(query, currentUserId);
      _lastRequestTime[cacheKey] = DateTime.now();
      
      try {
        final result = await _pendingSearchRequests[cacheKey]!;
        return result;
      } finally {
        _pendingSearchRequests.remove(cacheKey);
      }
    } catch (e) {
      _pendingSearchRequests.remove('search_${query.toLowerCase()}_$currentUserId');
      throw Exception('Failed to search users: ${e.toString()}');
    }
  }

  Future<List<UserModel>> _performUserSearch(String query, String currentUserId) async {
    // Optimization: Reduced search limits and smarter querying
    const searchLimit = 10; // Reduced from 20
    
    // Search by name (case insensitive) with reduced limit
    final nameQuery = await _firestore
        .collection(AppConstants.usersCollection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(searchLimit)
        .get();

    // Only search by email if name search doesn't yield enough results
    QuerySnapshot? emailQuery;
    if (nameQuery.docs.length < searchLimit ~/ 2) {
      emailQuery = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(searchLimit - nameQuery.docs.length)
          .get();
    }

    final Set<UserModel> users = {};
    
    // Add users from name search
    for (var doc in nameQuery.docs) {
      final user = UserModel.fromDocument(doc);
      if (user.uid != currentUserId) {
        users.add(user);
        // Cache the user
        _userCache[user.uid] = user;
        _lastRequestTime['user_${user.uid}'] = DateTime.now();
      }
    }
    
    // Add users from email search if performed
    if (emailQuery != null) {
      for (var doc in emailQuery.docs) {
        final user = UserModel.fromDocument(doc);
        if (user.uid != currentUserId) {
          users.add(user);
          // Cache the user
          _userCache[user.uid] = user;
          _lastRequestTime['user_${user.uid}'] = DateTime.now();
        }
      }
    }

    return users.toList();
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check if request is already pending
      if (_pendingUserRequests.containsKey(userId)) {
        return await _pendingUserRequests[userId];
      }
      
      // Check cache first
      final cachedUser = _userCache[userId];
      final lastRequest = _lastRequestTime['user_$userId'];
      if (cachedUser != null && 
          lastRequest != null && 
          DateTime.now().difference(lastRequest) < _cacheValidityTime) {
        return cachedUser;
      }
      
      // Create pending request
      _pendingUserRequests[userId] = _fetchUserById(userId);
      
      try {
        final user = await _pendingUserRequests[userId];
        return user;
      } finally {
        _pendingUserRequests.remove(userId);
      }
    } catch (e) {
      _pendingUserRequests.remove(userId);
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  Future<UserModel?> _fetchUserById(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (doc.exists) {
      final user = UserModel.fromDocument(doc);
      // Cache the user
      _userCache[userId] = user;
      _lastRequestTime['user_$userId'] = DateTime.now();
      return user;
    }
    return null;
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

  // Fetch a single chat by id
  Future<Chat?> getChatById(String chatId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .get();
      if (!doc.exists) return null;
      return Chat.fromDocument(doc);
    } catch (e) {
      throw Exception('Failed to get chat: ${e.toString()}');
    }
  }

  // Update group info (admin only)
  Future<void> updateGroupInfo(
    String chatId, {
    required String requesterId,
    String? groupName,
    String? groupImageUrl,
  }) async {
    try {
      final chatRef = _firestore.collection(AppConstants.chatsCollection).doc(chatId);
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }
      final chat = Chat.fromDocument(chatDoc);
      if (!chat.isGroup) {
        throw Exception('Not a group chat');
      }
      if (chat.createdBy != requesterId) {
        throw Exception('Only the admin can update group info');
      }

      final Map<String, dynamic> updates = {};
      if (groupName != null) updates['groupName'] = groupName.trim();
      if (groupImageUrl != null) updates['groupImageUrl'] = groupImageUrl.trim();
      if (updates.isEmpty) return;

      await chatRef.update(updates);
    } catch (e) {
      throw Exception('Failed to update group info: ${e.toString()}');
    }
  }

  // Remove a member from group (admin only)
  Future<void> removeGroupMember(
    String chatId,
    String memberUserId,
    String requesterId,
  ) async {
    try {
      final chatRef = _firestore.collection(AppConstants.chatsCollection).doc(chatId);
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }
      final chat = Chat.fromDocument(chatDoc);
      if (!chat.isGroup) {
        throw Exception('Not a group chat');
      }
      if (chat.createdBy != requesterId) {
        throw Exception('Only the admin can remove members');
      }
      if (!chat.participants.contains(memberUserId)) {
        throw Exception('User is not a member of this group');
      }
      if (memberUserId == chat.createdBy) {
        throw Exception('Admin cannot be removed');
      }

      final updatedParticipants = List<String>.from(chat.participants)..remove(memberUserId);
      final updatedUnread = Map<String, int>.from(chat.unreadCount)..remove(memberUserId);

      await chatRef.update({
        'participants': updatedParticipants,
        'unreadCount': updatedUnread,
      });
    } catch (e) {
      throw Exception('Failed to remove group member: ${e.toString()}');
    }
  }

  // Add members to a group (admin only)
  Future<void> addGroupMembers(
    String chatId,
    List<String> newMemberUserIds,
    String requesterId,
  ) async {
    try {
      if (newMemberUserIds.isEmpty) return;
      final chatRef = _firestore.collection(AppConstants.chatsCollection).doc(chatId);
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) throw Exception('Chat not found');
      final chat = Chat.fromDocument(chatDoc);
      if (!chat.isGroup) throw Exception('Not a group chat');
      if (chat.createdBy != requesterId) throw Exception('Only the admin can add members');

      final updatedParticipants = {...chat.participants, ...newMemberUserIds}.toList();
      final updatedUnread = Map<String, int>.from(chat.unreadCount);
      for (final uid in newMemberUserIds) {
        updatedUnread.putIfAbsent(uid, () => 0);
      }

      await chatRef.update({
        'participants': updatedParticipants,
        'unreadCount': updatedUnread,
      });
    } catch (e) {
      throw Exception('Failed to add members: ${e.toString()}');
    }
  }

  // Leave group (non-admin only)
  Future<void> leaveGroup(String chatId, String userId) async {
    try {
      final chatRef = _firestore.collection(AppConstants.chatsCollection).doc(chatId);
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) throw Exception('Chat not found');
      final chat = Chat.fromDocument(chatDoc);
      if (!chat.isGroup) throw Exception('Not a group chat');
      if (!chat.participants.contains(userId)) throw Exception('You are not a member of this group');
      if (chat.createdBy == userId) {
        throw Exception('Admin cannot leave group. Transfer admin first.');
      }

      final updatedParticipants = List<String>.from(chat.participants)..remove(userId);
      final updatedUnread = Map<String, int>.from(chat.unreadCount)..remove(userId);

      await chatRef.update({
        'participants': updatedParticipants,
        'unreadCount': updatedUnread,
      });
    } catch (e) {
      throw Exception('Failed to leave group: ${e.toString()}');
    }
  }

  // Transfer group admin to another member (admin only)
  Future<void> transferGroupAdmin(
    String chatId,
    String newAdminUserId,
    String requesterId,
  ) async {
    try {
      final chatRef = _firestore.collection(AppConstants.chatsCollection).doc(chatId);
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) throw Exception('Chat not found');
      final chat = Chat.fromDocument(chatDoc);
      if (!chat.isGroup) throw Exception('Not a group chat');
      if (chat.createdBy != requesterId) throw Exception('Only the admin can transfer ownership');
      if (!chat.participants.contains(newAdminUserId)) throw Exception('New admin must be a group member');
      if (newAdminUserId == requesterId) return; // no-op

      await chatRef.update({'createdBy': newAdminUserId});
    } catch (e) {
      throw Exception('Failed to transfer admin: ${e.toString()}');
    }
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

  Stream<List<Message>> getChatMessages(String chatId, {int limit = 10}) { // Reduced default from 20
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

  Future<List<Message>> getMessagesAfter(
    String chatId,
    DateTime timestamp, {
    int limit = 20, // Reduced from 50
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

  Future<List<Message>> getRecentMessages(
    String chatId, {
    int limit = 15, // Reduced from 20
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

      // Optimization: Limit the number of messages to mark as read
      final unreadMessages = await _firestore
          .collection(AppConstants.messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('readBy', whereNotIn: [userId])
          .limit(50) // Limit to prevent excessive batch operations
          .get();

      if (unreadMessages.docs.isEmpty) return;

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

  // Mark a single message as read by a specific user (lightweight update)
  Future<void> markSingleMessageAsRead(String messageId, String userId) async {
    try {
      final docRef = _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId);

      await docRef.update({
        'readBy': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw Exception('Failed to mark single message as read: ${e.toString()}');
    }
  }

  // Optimization: Batch user loading with smart caching
  Future<Map<String, UserModel>> getUsersMap(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return {};
      
      final Map<String, UserModel> usersMap = {};
      final List<String> usersToFetch = [];
      final now = DateTime.now();
      
      // Check cache first
      for (final userId in userIds) {
        final cachedUser = _userCache[userId];
        final lastRequest = _lastRequestTime['user_$userId'];
        
        if (cachedUser != null && 
            lastRequest != null && 
            now.difference(lastRequest) < _cacheValidityTime) {
          usersMap[userId] = cachedUser;
        } else {
          usersToFetch.add(userId);
        }
      }
      
      if (usersToFetch.isEmpty) return usersMap;
      
      // Batch fetch remaining users with optimized queries
      const batchSize = 10; // Firestore 'in' query limit
      for (int i = 0; i < usersToFetch.length; i += batchSize) {
        final batch = usersToFetch.skip(i).take(batchSize).toList();
        
        final snapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        for (var doc in snapshot.docs) {
          final user = UserModel.fromDocument(doc);
          usersMap[user.uid] = user;
          
          // Update cache
          _userCache[user.uid] = user;
          _lastRequestTime['user_${user.uid}'] = now;
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

  // Optimization: Cache cleanup utility
  static void clearCache() {
    _userCache.clear();
    _lastRequestTime.clear();
    _pendingUserRequests.clear();
    _pendingSearchRequests.clear();
  }

  // Optimization: Preload users efficiently
  static void preloadUsers(Map<String, UserModel> users) {
    final now = DateTime.now();
    for (final entry in users.entries) {
      _userCache[entry.key] = entry.value;
      _lastRequestTime['user_${entry.key}'] = now;
    }
  }

  // Message management: delete a message (soft delete by sender only)
  Future<void> deleteMessage(String messageId, String userId) async {
    try {
      final docRef = _firestore.collection(AppConstants.messagesCollection).doc(messageId);
      final doc = await docRef.get();
      if (!doc.exists) {
        throw Exception('Message not found');
      }
      final message = Message.fromDocument(doc);
      if (message.senderId != userId) {
        throw Exception('Not authorized to delete this message');
      }

      await docRef.update({
        'isDeleted': true,
        'text': '[deleted]',
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }

  // Message management: edit a message (by sender within 15 minutes)
  Future<void> editMessage(String messageId, String newText, String userId) async {
    try {
      final docRef = _firestore.collection(AppConstants.messagesCollection).doc(messageId);
      final doc = await docRef.get();
      if (!doc.exists) {
        throw Exception('Message not found');
      }
      final message = Message.fromDocument(doc);
      if (message.senderId != userId) {
        throw Exception('Not authorized to edit this message');
      }
      if (message.isDeleted) {
        throw Exception('Cannot edit a deleted message');
      }
      // Enforce 15-minute edit window similar to model's canEdit
      final diff = DateTime.now().difference(message.timestamp);
      if (diff.inMinutes > 15) {
        throw Exception('Edit window expired');
      }

      await docRef.update({
        'text': newText,
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to edit message: ${e.toString()}');
    }
  }

  // Reactions: add emoji reaction by user
  Future<void> addReaction(String messageId, String emoji, String userId) async {
    try {
      final docRef = _firestore.collection(AppConstants.messagesCollection).doc(messageId);
      await docRef.update({
        'reactions.$emoji': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw Exception('Failed to add reaction: ${e.toString()}');
    }
  }

  // Reactions: remove emoji reaction by user
  Future<void> removeReaction(String messageId, String emoji, String userId) async {
    try {
      final docRef = _firestore.collection(AppConstants.messagesCollection).doc(messageId);
      await docRef.update({
        'reactions.$emoji': FieldValue.arrayRemove([userId])
      });
      // Optional: could clean up empty reaction arrays by reading doc and removing key
    } catch (e) {
      throw Exception('Failed to remove reaction: ${e.toString()}');
    }
  }

  // Chat management: soft delete chat (mark as deleted) – requires participant
  Future<void> deleteChat(String chatId, String userId) async {
    try {
      final chatRef = _firestore.collection(AppConstants.chatsCollection).doc(chatId);
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }
      final chat = Chat.fromDocument(chatDoc);
      if (!chat.participants.contains(userId)) {
        throw Exception('Not authorized to delete this chat');
      }

      await chatRef.update({'isDeleted': true});
    } catch (e) {
      throw Exception('Failed to delete chat: ${e.toString()}');
    }
  }

  // Chat management: toggle pin for a user
  Future<void> pinChat(String chatId, String userId) async {
    try {
      final chatRef = _firestore.collection(AppConstants.chatsCollection).doc(chatId);
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }
      final chat = Chat.fromDocument(chatDoc);
      final current = (chat.pinnedBy[userId] ?? false);
      await chatRef.update({
        'pinnedBy.$userId': !current,
      });
    } catch (e) {
      throw Exception('Failed to pin/unpin chat: ${e.toString()}');
    }
  }

  // Chat management: mark chat as read for a user (lightweight)
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .update({'unreadCount.$userId': 0});
    } catch (e) {
      throw Exception('Failed to mark chat as read: ${e.toString()}');
    }
  }

  // Update user's FCM token
  Future<void> updateUserFCMToken(String userId, String fcmToken) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': fcmToken,
        'lastTokenUpdate': Timestamp.now(),
      });
      
      // Update cache if user exists
      if (_userCache.containsKey(userId)) {
        final user = _userCache[userId]!;
        _userCache[userId] = user.copyWith(fcmToken: fcmToken);
      }
      
      print('FCM token updated for user: $userId');
    } catch (e) {
      print('Error updating FCM token: $e');
      rethrow;
    }
  }

  // Create notification request (for server-side processing)
  Future<void> createNotificationRequest(Map<String, dynamic> notificationData) async {
    try {
      await _firestore.collection('notification_requests').add({
        ...notificationData,
        'createdAt': Timestamp.now(),
        'processed': false,
      });
      print('Notification request created');
    } catch (e) {
      print('Error creating notification request: $e');
      rethrow;
    }
  }

  // Get users by FCM tokens (for batch notifications)
  Future<List<UserModel>> getUsersByFCMTokens(List<String> fcmTokens) async {
    try {
      if (fcmTokens.isEmpty) return [];
      
      // Firestore 'in' queries are limited to 10 items
      final chunks = <List<String>>[];
      for (int i = 0; i < fcmTokens.length; i += 10) {
        chunks.add(fcmTokens.sublist(i, i + 10 > fcmTokens.length ? fcmTokens.length : i + 10));
      }
      
      final List<UserModel> users = [];
      for (final chunk in chunks) {
        final querySnapshot = await _firestore
            .collection('users')
            .where('fcmToken', whereIn: chunk)
            .get();
        
        for (final doc in querySnapshot.docs) {
          try {
            users.add(UserModel.fromDocument(doc));
          } catch (e) {
            print('Error parsing user document ${doc.id}: $e');
          }
        }
      }
      
      return users;
    } catch (e) {
      print('Error getting users by FCM tokens: $e');
      return [];
    }
  }
}
