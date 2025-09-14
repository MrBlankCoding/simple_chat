import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';
import '../services/typing_service.dart';
import '../services/error_service.dart';
import '../services/cache_service.dart';
import '../services/notification_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final FirestoreService _firestoreService = FirestoreService();
  final TypingService _typingService = TypingService();
  final ErrorService _errorService = ErrorService();
  final CacheService _cacheService = CacheService();
  final NotificationService _notificationService = NotificationService();

  List<Chat> _chats = [];
  final Map<String, List<Message>> _chatMessages = {};
  final Map<String, UserModel> _users = {};
  final Map<String, List<String>> _typingUsers = {};
  bool _isLoading = false;
  String? _error;
  final Map<String, StreamSubscription> _messageSubscriptions = {};
  final Map<String, StreamSubscription> _typingSubscriptions = {};
  StreamSubscription? _chatsSubscription;
  
  // Pagination state
  final Map<String, bool> _isLoadingMoreMessages = {};
  final Map<String, bool> _hasMoreMessages = {};
  final Map<String, int> _currentPage = {};
  final Map<String, DocumentSnapshot?> _lastDocument = {};
  static const int _messagesPerPage = 20;

  // Optimization: Connection pooling and request deduplication
  final Map<String, Future<UserModel?>> _pendingUserRequests = {};
  final Map<String, Timer> _subscriptionTimers = {};
  final Set<String> _activeSubscriptions = {};
  Timer? _batchUserLoadTimer;
  final Set<String> _pendingUserIds = {};
  
  // Optimization: Reduced subscription limits
  static const int _realtimeMessageLimit = 10; // Reduced from 50
  static const int _maxActiveSubscriptions = 3; // Limit concurrent subscriptions

  ChatProvider() {
    _initializeChats();
  }

  void _initializeChats() {
    // Load cached chats first
    _loadCachedChats();
    
    // Subscribe to real-time chats
    _subscribeToChats();
  }

  void _subscribeToChats() {
    _chatsSubscription?.cancel(); // Cancel existing subscription if any
    _chatsSubscription = _chatService.getUserChats().listen(
      (chats) async {
        try {
          // Check if provider is disposed
          if (_chatsSubscription == null) return;
          
          // Filter out any null or invalid chats
          final validChats = chats.where((chat) => chat.id.isNotEmpty).toList();
          _chats = validChats;
          
          // Cache chats (with error handling)
          try {
            await _cacheService.cacheChats(validChats);
          } catch (e) {
            // Silent cache failure - not critical
            _errorService.logError('Failed to cache chats', error: e);
          }
          
          // Optimization: Batch load user data instead of individual requests
          final allParticipantIds = <String>{};
          for (final chat in validChats) {
            allParticipantIds.addAll(chat.participants);
          }
          
          // Remove already loaded users
          final usersToLoad = allParticipantIds.where((id) => !_users.containsKey(id)).toList();
          if (usersToLoad.isNotEmpty) {
            await _batchLoadUsers(usersToLoad);
          }
          
          // Only notify listeners if still subscribed
          if (_chatsSubscription != null) {
            _clearError(); // Clear any previous errors on successful load
            notifyListeners();
          }
        } catch (e) {
          // Log error but don't crash the subscription
          _errorService.logError('Error processing chats subscription', error: e);
          // Don't set UI error for data processing issues
        }
      },
      onError: (error) {
        // Handle subscription errors gracefully
        _errorService.logError('Chat subscription error', error: error);
        // Only set UI error for critical subscription failures
        if (error.toString().contains('permission-denied') || 
            error.toString().contains('unauthenticated')) {
          _setError('Unable to load chats. Please check your connection.');
        }
        // For other errors, try to continue with cached data
      },
    );
  }

  Future<void> _loadCachedChats() async {
    try {
      final cachedChats = await _cacheService.getCachedChats();
      if (cachedChats.isNotEmpty) {
        _chats = cachedChats;
        notifyListeners();
      }
    } catch (e) {
      _errorService.logError('Failed to load cached chats', error: e);
    }
  }

  Future<void> _loadCachedMessages(String chatId) async {
    try {
      final cachedMessages = await _cacheService.getCachedMessages(chatId);
      if (cachedMessages.isNotEmpty) {
        _chatMessages[chatId] = cachedMessages;
        notifyListeners();
      }
    } catch (e) {
      _errorService.logError('Failed to load cached messages for chat $chatId', error: e);
    }
  }

  Future<void> _cacheMessages(String chatId, List<Message> messages) async {
    try {
      // Cache all messages (legacy support)
      await _cacheService.cacheMessages(chatId, messages);
      
      // Also cache by pages for better pagination support
      const pageSize = _messagesPerPage;
      for (int i = 0; i < messages.length; i += pageSize) {
        final pageMessages = messages.skip(i).take(pageSize).toList();
        final pageNumber = (i / pageSize).floor();
        await _cacheService.cacheMessages(chatId, pageMessages, page: pageNumber);
      }
    } catch (e) {
      // Silent cache failure - not critical
      _errorService.logError('Failed to cache messages for chat $chatId', error: e);
    }
  }

  Future<void> _loadUserWithCache(String userId) async {
    // Deduplication: Check if request is already pending
    if (_pendingUserRequests.containsKey(userId)) {
      await _pendingUserRequests[userId];
      return;
    }
    
    try {
      // Create pending request
      _pendingUserRequests[userId] = _loadUserWithCacheInternal(userId);
      await _pendingUserRequests[userId];
    } finally {
      // Clean up pending request
      _pendingUserRequests.remove(userId);
    }
  }
  
  Future<UserModel?> _loadUserWithCacheInternal(String userId) async {
    try {
      // Try to load from cache first
      final cachedUser = await _cacheService.getCachedUser(userId);
      if (cachedUser != null) {
        // Apply short-lived cached presence if available
        bool? cachedOnline = await _cacheService.getCachedUserOnline(userId);
        DateTime? cachedLastSeen = await _cacheService.getCachedUserLastSeen(userId);
        final withPresence = (cachedOnline != null || cachedLastSeen != null)
            ? cachedUser.copyWith(
                isOnline: cachedOnline ?? cachedUser.isOnline,
                lastSeen: cachedLastSeen ?? cachedUser.lastSeen,
              )
            : cachedUser;
        _users[userId] = withPresence;
        notifyListeners();
        
        // Load fresh data in background if cache is old
        final lastSync = await _cacheService.getLastSyncTime('user_$userId');
        if (lastSync == null || DateTime.now().difference(lastSync).inHours > 1) {
          _loadUserFromServer(userId);
        }
        return withPresence;
      } else {
        // No cache, load from server
        return await _loadUserFromServer(userId);
      }
    } catch (e) {
      _errorService.logError('Failed to load user with cache $userId', error: e);
      return null;
    }
  }

  Future<UserModel?> _loadUserFromServer(String userId) async {
    try {
      final user = await _firestoreService.getUserById(userId);
      if (user != null) {
        _users[userId] = user;
        
        // Cache the user data
        await _cacheService.cacheUser(user);
        await _cacheService.setLastSyncTime('user_$userId', DateTime.now());
        
        // Cache online status if available
        await _cacheService.cacheUserOnlineStatus(userId, user.isOnline, user.lastSeen);
        
        notifyListeners();
        return user;
      }
      return null;
    } catch (e) {
      _errorService.logError('Failed to load user from server $userId', error: e);
      return null;
    }
  }

  List<Message> getChatMessages(String chatId) {
    return _chatMessages[chatId] ?? [];
  }

  void subscribeToChat(String chatId) {
    // Optimization: Limit concurrent subscriptions
    if (_activeSubscriptions.length >= _maxActiveSubscriptions && !_activeSubscriptions.contains(chatId)) {
      // Unsubscribe from oldest chat if at limit
      final oldestChatId = _activeSubscriptions.first;
      unsubscribeFromChat(oldestChatId);
    }
    
    if (_messageSubscriptions.containsKey(chatId)) return;

    // Initialize pagination state
    _currentPage[chatId] = 0;
    _hasMoreMessages[chatId] = true;
    _isLoadingMoreMessages[chatId] = false;
    _activeSubscriptions.add(chatId);

    // Load cached messages first
    _loadCachedMessages(chatId);

    // Load initial messages with pagination
    _loadInitialMessages(chatId);

    // Subscribe to real-time updates for new messages only (with reduced limit)
    _subscribeToNewMessages(chatId);
  }

  Future<void> _loadInitialMessages(String chatId) async {
    try {
      // Check if we have cached messages
      final cachedMessages = await _cacheService.getCachedMessages(chatId, limit: _messagesPerPage);
      
      if (cachedMessages.isNotEmpty) {
        _chatMessages[chatId] = cachedMessages;
        notifyListeners();
        
        // Load newer messages from server if available
        final lastCachedTime = await _cacheService.getLastMessageTime(chatId);
        if (lastCachedTime != null) {
          _loadNewerMessages(chatId, lastCachedTime);
        }
      } else {
        // No cache, load from server
        await loadMoreMessages(chatId);
      }
    } catch (e) {
      _errorService.logError('Failed to load initial messages for chat $chatId', error: e);
    }
  }

  Future<void> _loadNewerMessages(String chatId, DateTime after) async {
    try {
      final newerMessages = await _firestoreService.getMessagesAfter(chatId, after);
      if (newerMessages.isNotEmpty) {
        final existingMessages = _chatMessages[chatId] ?? [];
        final allMessages = [...newerMessages, ...existingMessages];
        
        // Remove duplicates and sort
        final uniqueMessages = <String, Message>{};
        for (final message in allMessages) {
          uniqueMessages[message.id] = message;
        }
        
        final sortedMessages = uniqueMessages.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        _chatMessages[chatId] = sortedMessages;
        
        // Cache the updated messages
        await _cacheMessages(chatId, sortedMessages);
        notifyListeners();
      }
    } catch (e) {
      _errorService.logError('Failed to load newer messages for chat $chatId', error: e);
    }
  }

  void _subscribeToNewMessages(String chatId) {
    // Optimization: Reduced real-time subscription limit and smarter filtering
    _messageSubscriptions[chatId] = _firestoreService
        .getChatMessages(chatId, limit: _realtimeMessageLimit) // Reduced from 50 to 10
        .listen(
      (updatedMessages) {
        if (updatedMessages.isEmpty) return;
        
        final existingMessages = _chatMessages[chatId] ?? [];
        
        // Optimization: Only process truly new messages
        final existingMessageIds = existingMessages.map((m) => m.id).toSet();
        final newMessages = updatedMessages.where((m) => !existingMessageIds.contains(m.id)).toList();
        
        if (newMessages.isEmpty && existingMessages.isNotEmpty) {
          // Check for updates to existing messages (read status, edits, etc.)
          bool hasUpdates = false;
          final updatedMessagesMap = {for (var m in updatedMessages) m.id: m};
          
          for (int i = 0; i < existingMessages.length && i < _realtimeMessageLimit; i++) {
            final existingMsg = existingMessages[i];
            final updatedMsg = updatedMessagesMap[existingMsg.id];
            
            if (updatedMsg != null && _hasMessageChanged(existingMsg, updatedMsg)) {
              existingMessages[i] = updatedMsg;
              hasUpdates = true;
            }
          }
          
          if (hasUpdates) {
            _chatMessages[chatId] = existingMessages;
            _cacheMessages(chatId, existingMessages);
            notifyListeners();
          }
          return;
        }
        
        // Add new messages
        if (newMessages.isNotEmpty) {
          final allMessages = [...newMessages, ...existingMessages];
          allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          _chatMessages[chatId] = allMessages;
          _cacheMessages(chatId, allMessages);
          
          // Send push notifications for new messages from other users
          _handleNewMessageNotifications(chatId, newMessages);
          
          notifyListeners();
        }
      },
      onError: (error) {
        _errorService.logError('Message subscription error for chat $chatId', error: error);
        // Don't set UI error for message subscription issues - continue with cached data
      },
    );
  }

  bool _hasMessageChanged(Message oldMsg, Message newMsg) {
    return oldMsg.text != newMsg.text ||
           oldMsg.isEdited != newMsg.isEdited ||
           oldMsg.isDeleted != newMsg.isDeleted ||
           !_listEquals(oldMsg.readBy, newMsg.readBy) ||
           oldMsg.reactions.toString() != newMsg.reactions.toString();
  }

  bool _listEquals(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  Future<void> loadMoreMessages(String chatId) async {
    if (_isLoadingMoreMessages[chatId] == true || _hasMoreMessages[chatId] == false) {
      return;
    }

    try {
      _isLoadingMoreMessages[chatId] = true;
      notifyListeners();

      final currentPage = _currentPage[chatId] ?? 0;
      final nextPage = currentPage + 1;

      // Try to load from cache first
      final cachedMessages = await _cacheService.getCachedMessages(chatId, page: nextPage);
      
      List<Message> newMessages;
      if (cachedMessages.isNotEmpty) {
        newMessages = cachedMessages;
      } else {
        // Load from server
        newMessages = await _firestoreService.getChatMessagesPaginated(
          chatId,
          limit: _messagesPerPage,
          lastDocument: _lastDocument[chatId],
        );
        
        // Cache the new page
        if (newMessages.isNotEmpty) {
          await _cacheService.cacheMessages(chatId, newMessages, page: nextPage);
        }
      }

      if (newMessages.isNotEmpty) {
        final existingMessages = _chatMessages[chatId] ?? [];
        final allMessages = [...existingMessages, ...newMessages];
        
        // Remove duplicates
        final uniqueMessages = <String, Message>{};
        for (final message in allMessages) {
          uniqueMessages[message.id] = message;
        }
        
        final sortedMessages = uniqueMessages.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        _chatMessages[chatId] = sortedMessages;
        _currentPage[chatId] = nextPage;
        
        // Check if there are more messages
        _hasMoreMessages[chatId] = newMessages.length == _messagesPerPage;
      } else {
        _hasMoreMessages[chatId] = false;
      }

      notifyListeners();
    } catch (e) {
      _errorService.logError('Failed to load more messages for chat $chatId', error: e);
      _setError('Failed to load more messages');
    } finally {
      _isLoadingMoreMessages[chatId] = false;
      notifyListeners();
    }
  }

  void unsubscribeFromChat(String chatId) {
    _messageSubscriptions[chatId]?.cancel();
    _messageSubscriptions.remove(chatId);
    _activeSubscriptions.remove(chatId);
    
    // Optimization: Don't immediately remove messages, keep them cached
    // _chatMessages.remove(chatId); // Commented out to maintain cache
    
    // Clean up pagination state
    _isLoadingMoreMessages.remove(chatId);
    _hasMoreMessages.remove(chatId);
    _currentPage.remove(chatId);
    _lastDocument.remove(chatId);
    
    // Cancel any pending timers
    _subscriptionTimers[chatId]?.cancel();
    _subscriptionTimers.remove(chatId);
  }

  Future<String> getOrCreateDirectChat(String otherUserId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final chatId = await _chatService.getOrCreateDirectChat(otherUserId);
      
      // Load user data if not already loaded
      if (!_users.containsKey(otherUserId)) {
        await _loadUserWithCache(otherUserId);
      }
      
      return chatId;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<String> createGroupChat(List<String> participantIds, String groupName) async {
    try {
      _setLoading(true);
      _clearError();
      
      final chatId = await _chatService.createGroupChat(participantIds, groupName);
      
      // Load user data for participants with caching
      for (final participantId in participantIds) {
        if (!_users.containsKey(participantId)) {
          await _loadUserWithCache(participantId);
        }
      }
      
      return chatId;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendTextMessage(String chatId, String text, {String? replyToMessageId}) async {
    try {
      // Don't set loading state for message sending to avoid UI freeze
      await _chatService.sendTextMessage(chatId, text, replyToMessageId: replyToMessageId);
      
      // Optimistically ensure unread count is zero for the sender while in chat
      final currentUserId = _chatService.currentUserId;
      if (currentUserId != null) {
        final chatIndex = _chats.indexWhere((c) => c.id == chatId);
        if (chatIndex != -1) {
          final chat = _chats[chatIndex];
          if ((chat.unreadCount[currentUserId] ?? 0) != 0) {
            _chats[chatIndex] = chat.resetUnreadCount(currentUserId);
            notifyListeners();
          }
        }
      }
      
      // Stop typing indicator when message is sent
      await stopTyping(chatId);
      
      _clearError();
    } catch (e) {
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to send message', error: e);
    }
  }

  Future<void> editMessage(String messageId, String newText) async {
    try {
      // Update local state immediately for better UX
      _updateMessageLocally(messageId, (message) => message.copyWith(
        text: newText,
        isEdited: true,
        editedAt: DateTime.now(),
      ));
      
      await _chatService.editMessage(messageId, newText);
      _clearError();
    } catch (e) {
      // Revert local changes on error
      _revertMessageEdit(messageId);
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to edit message', error: e);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      // Update local state immediately for better UX
      _updateMessageLocally(messageId, (message) => message.copyWith(
        isDeleted: true,
        text: 'This message was deleted',
      ));
      
      await _chatService.deleteMessage(messageId);
      _clearError();
    } catch (e) {
      // Revert local changes on error
      _revertMessageEdit(messageId);
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to delete message', error: e);
    }
  }

  void _updateMessageLocally(String messageId, Message Function(Message) updateFunction) {
    for (final chatId in _chatMessages.keys) {
      final messages = _chatMessages[chatId]!;
      final messageIndex = messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        final originalMessage = messages[messageIndex];
        final updatedMessage = updateFunction(originalMessage);
        messages[messageIndex] = updatedMessage;
        notifyListeners();
        break;
      }
    }
  }

  void _revertMessageEdit(String messageId) {
    // For now, we'll let the real-time stream handle reverting
    // In a more sophisticated implementation, we could store original states
    // But the stream subscription will update with the correct server state
  }

  Future<void> addReaction(String messageId, String emoji) async {
    try {
      await _chatService.addReaction(messageId, emoji);
      _clearError();
    } catch (e) {
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to add reaction', error: e);
    }
  }

  Future<void> removeReaction(String messageId, String emoji) async {
    try {
      await _chatService.removeReaction(messageId, emoji);
      _clearError();
    } catch (e) {
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to remove reaction', error: e);
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      _setLoading(true);
      await _chatService.deleteChat(chatId);
      
      // Remove from local state
      _chats.removeWhere((chat) => chat.id == chatId);
      _chatMessages.remove(chatId);
      
      // Unsubscribe from chat
      unsubscribeFromChat(chatId);
      
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to delete chat', error: e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> pinChat(String chatId) async {
    try {
      await _chatService.pinChat(chatId);
      _clearError();
    } catch (e) {
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to pin chat', error: e);
    }
  }

  Future<void> markChatAsRead(String chatId) async {
    try {
      // Optimistically reset unread count locally
      final currentUserId = _chatService.currentUserId;
      if (currentUserId != null) {
        final chatIndex = _chats.indexWhere((c) => c.id == chatId);
        if (chatIndex != -1) {
          final chat = _chats[chatIndex];
          if ((chat.unreadCount[currentUserId] ?? 0) != 0) {
            _chats[chatIndex] = chat.resetUnreadCount(currentUserId);
            notifyListeners();
          }
        }
      }

      await _chatService.markChatAsRead(chatId);
      _clearError();
    } catch (e) {
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to mark chat as read', error: e);
    }
  }

  Future<void> startTyping(String chatId) async {
    try {
      final userId = _chatService.currentUserId;
      if (userId != null) {
        await _typingService.startTyping(chatId, userId);
      }
    } catch (e) {
      _errorService.logError('Failed to start typing', error: e);
    }
  }

  Future<void> stopTyping(String chatId) async {
    try {
      final userId = _chatService.currentUserId;
      if (userId != null) {
        await _typingService.stopTyping(chatId, userId);
      }
    } catch (e) {
      _errorService.logError('Failed to stop typing', error: e);
    }
  }

  void subscribeToTyping(String chatId) {
    final userId = _chatService.currentUserId;
    if (userId == null) return;

    _typingSubscriptions[chatId]?.cancel();
    _typingSubscriptions[chatId] = _typingService.getTypingUsers(chatId, userId).listen(
      (typingUserIds) {
        _typingUsers[chatId] = typingUserIds;
        notifyListeners();
      },
      onError: (e) {
        _errorService.logError('Error in typing subscription', error: e);
      },
    );
  }

  Future<void> markMessagesAsRead(String chatId) async {
    try {
      // Optimistically reset unread count locally for immediate UI feedback
      final currentUserId = _chatService.currentUserId;
      if (currentUserId != null) {
        final chatIndex = _chats.indexWhere((c) => c.id == chatId);
        if (chatIndex != -1) {
          final chat = _chats[chatIndex];
          if ((chat.unreadCount[currentUserId] ?? 0) != 0) {
            _chats[chatIndex] = chat.resetUnreadCount(currentUserId);
            notifyListeners();
          }
        }
      }

      await _chatService.markMessagesAsRead(chatId);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> markMessageAsRead(String messageId, String chatId) async {
    try {
      final currentUserId = _chatService.currentUserId;
      if (currentUserId == null) return;
       
      // Check if message is already marked as read locally to avoid duplicate calls
      if (_chatMessages.containsKey(chatId)) {
        final messages = _chatMessages[chatId]!;
        final messageIndex = messages.indexWhere((msg) => msg.id == messageId);
        if (messageIndex != -1) {
          final message = messages[messageIndex];
          if (message.readBy.contains(currentUserId)) {
            return; // Already marked as read, no need to update
          }
          
          // Update local state immediately for better UX
          final updatedMessage = message.markAsRead(currentUserId);
          messages[messageIndex] = updatedMessage;
          notifyListeners();
        }
      }
       
      // Use the more efficient single message update
      await _firestoreService.markSingleMessageAsRead(messageId, currentUserId);
    } catch (e) {
      // Silently fail - not critical for UX
      _errorService.logError('Failed to mark message as read', error: e);
    }
  }

  String getChatTitle(Chat chat, String currentUserId) {
    if (chat.isGroup) {
      return chat.groupName ?? 'Group Chat';
    } else {
      final otherUserId = chat.getOtherParticipant(currentUserId);
      if (otherUserId != null && _users.containsKey(otherUserId)) {
        return _users[otherUserId]!.name;
      }
      return 'Unknown User';
    }
  }

  String? getChatImageUrl(Chat chat, String currentUserId) {
    if (chat.isGroup) {
      return chat.groupImageUrl;
    } else {
      final otherUserId = chat.getOtherParticipant(currentUserId);
      if (otherUserId != null && _users.containsKey(otherUserId)) {
        return _users[otherUserId]!.profileImageUrl;
      }
      return null;
    }
  }

  bool isUserOnline(String userId) {
    return _users[userId]?.isOnline ?? false;
  }

  DateTime? getUserLastSeen(String userId) {
    return _users[userId]?.lastSeen;
  }

  int getTotalUnreadCount(String currentUserId) {
    int total = 0;
    for (final chat in _chats) {
      total += chat.getUnreadCount(currentUserId);
    }
    return total;
  }

  // Public getters for UI consumption
  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool hasMoreMessages(String chatId) => _hasMoreMessages[chatId] ?? true;
  bool isLoadingMoreMessages(String chatId) => _isLoadingMoreMessages[chatId] ?? false;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Refresh user data (force reload from server)
  Future<void> refreshUser(String userId) async {
    try {
      await _loadUserFromServer(userId);
    } catch (e) {
      _errorService.logError('Failed to refresh user $userId', error: e);
    }
  }

  // Get user with cache fallback
  UserModel? getUser(String userId) {
    return _users[userId];
  }

  // Preload users for better performance
  Future<void> preloadUsers(List<String> userIds) async {
    final futures = <Future>[];
    for (final userId in userIds) {
      if (!_users.containsKey(userId)) {
        futures.add(_loadUserWithCache(userId));
      }
    }
    await Future.wait(futures);
  }

  // Optimization: Batch load user data instead of individual requests
  Future<void> _batchLoadUsers(List<String> userIds) async {
    if (userIds.isEmpty) return;
    
    try {
      // Check cache first for all users
      final Map<String, UserModel> cachedUsers = {};
      final List<String> usersToFetch = [];
      
      for (final userId in userIds) {
        final cachedUser = await _cacheService.getCachedUser(userId);
        if (cachedUser != null) {
          // Apply presence overrides from short-lived status cache
          bool? cachedOnline = await _cacheService.getCachedUserOnline(userId);
          DateTime? cachedLastSeen = await _cacheService.getCachedUserLastSeen(userId);
          final withPresence = (cachedOnline != null || cachedLastSeen != null)
              ? cachedUser.copyWith(
                  isOnline: cachedOnline ?? cachedUser.isOnline,
                  lastSeen: cachedLastSeen ?? cachedUser.lastSeen,
                )
              : cachedUser;
          cachedUsers[userId] = withPresence;
          _users[userId] = withPresence;
        } else {
          usersToFetch.add(userId);
        }
      }
      
      // Batch fetch remaining users from server
      if (usersToFetch.isNotEmpty) {
        final fetchedUsers = await _firestoreService.getUsersMap(usersToFetch);
        
        // Update local state and cache
        for (final entry in fetchedUsers.entries) {
          _users[entry.key] = entry.value;
          await _cacheService.cacheUser(entry.value);
          await _cacheService.setLastSyncTime('user_${entry.key}', DateTime.now());
        }
      }
      
      if (cachedUsers.isNotEmpty || usersToFetch.isNotEmpty) {
        notifyListeners();
      }
    } catch (e) {
      _errorService.logError('Failed to batch load users', error: e);
    }
  }

  // Group management: refresh a single chat from server
  Future<void> refreshChat(String chatId) async {
    try {
      final chat = await _chatService.getChatById(chatId);
      if (chat != null) {
        final idx = _chats.indexWhere((c) => c.id == chatId);
        if (idx != -1) {
          _chats[idx] = chat;
        } else {
          _chats.add(chat);
        }
        // Preload users for participants
        await preloadUsers(chat.participants);
        notifyListeners();
      }
    } catch (e) {
      _errorService.logError('Failed to refresh chat $chatId', error: e);
    }
  }

  // Group management: update group name/image (admin only)
  Future<void> updateGroupInfo(
    String chatId, {
    String? newGroupName,
    dynamic newImageFile, // XFile? but keep dynamic to avoid import cycle here
  }) async {
    try {
      // Optimistically update local state
      final idx = _chats.indexWhere((c) => c.id == chatId);
      if (idx != -1) {
        final chat = _chats[idx];
        _chats[idx] = chat.copyWith(
          groupName: newGroupName ?? chat.groupName,
          // Keep existing image URL locally; server refresh will update if image changes
          groupImageUrl: chat.groupImageUrl,
        );
        notifyListeners();
      }

      await _chatService.updateGroupInfo(
        chatId,
        newGroupName: newGroupName,
        newImageFile: newImageFile,
      );

      // Refresh from server to ensure consistency (e.g., receive image URL)
      await refreshChat(chatId);
      _clearError();
    } catch (e) {
      // Revert optimistic update if needed
      final idx = _chats.indexWhere((c) => c.id == chatId);
      if (idx != -1) {
        // Fetch latest from server to revert
        await refreshChat(chatId);
      }
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to update group info', error: e);
    }
  }

  // Group management: remove member (admin only)
  Future<void> removeGroupMember(String chatId, String memberUserId) async {
    try {
      // Optimistically update chat participants locally
      final idx = _chats.indexWhere((c) => c.id == chatId);
      if (idx != -1) {
        final chat = _chats[idx];
        if (chat.participants.contains(memberUserId)) {
          final updatedParticipants = List<String>.from(chat.participants)..remove(memberUserId);
          final updatedUnread = Map<String, int>.from(chat.unreadCount)..remove(memberUserId);
          _chats[idx] = chat.copyWith(participants: updatedParticipants, unreadCount: updatedUnread);
          notifyListeners();
        }
      }

      await _chatService.removeGroupMember(chatId, memberUserId);

      // Ensure consistency
      await refreshChat(chatId);
      _clearError();
    } catch (e) {
      // Revert via refresh
      await refreshChat(chatId);
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to remove group member', error: e);
    }
  }

  // Group management: add members (admin only)
  Future<void> addGroupMembers(String chatId, List<String> userIds) async {
    if (userIds.isEmpty) return;
    try {
      // Optimistic: append unique members
      final idx = _chats.indexWhere((c) => c.id == chatId);
      if (idx != -1) {
        final chat = _chats[idx];
        final updatedParticipants = {...chat.participants, ...userIds}.toList();
        _chats[idx] = chat.copyWith(participants: updatedParticipants);
        notifyListeners();
      }

      await _chatService.addGroupMembers(chatId, userIds);
      await refreshChat(chatId);
      _clearError();
    } catch (e) {
      await refreshChat(chatId);
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to add group members', error: e);
    }
  }

  // Group management: leave group (non-admin)
  Future<void> leaveGroup(String chatId) async {
    try {
      final uid = _chatService.currentUserId;
      if (uid == null) return;

      // Optimistic: remove current user
      final idx = _chats.indexWhere((c) => c.id == chatId);
      if (idx != -1) {
        final chat = _chats[idx];
        final updatedParticipants = List<String>.from(chat.participants)..remove(uid);
        final updatedUnread = Map<String, int>.from(chat.unreadCount)..remove(uid);
        _chats[idx] = chat.copyWith(participants: updatedParticipants, unreadCount: updatedUnread);
        notifyListeners();
      }

      await _chatService.leaveGroup(chatId);

      // Remove chat locally since user is no longer participant
      _chats.removeWhere((c) => c.id == chatId);
      _chatMessages.remove(chatId);
      unsubscribeFromChat(chatId);
      notifyListeners();
    } catch (e) {
      await refreshChat(chatId);
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to leave group', error: e);
    }
  }

  // Group management: transfer admin (admin only)
  Future<void> transferGroupAdmin(String chatId, String newAdminUserId) async {
    try {
      await _chatService.transferGroupAdmin(chatId, newAdminUserId);
      await refreshChat(chatId);
      _clearError();
    } catch (e) {
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to transfer admin', error: e);
    }
  }

  // Expose users map for UI selection helpers
  Map<String, UserModel> get usersMap => _users;

  // Helpers
  String? get currentUserId => _chatService.currentUserId;
  bool isAdmin(Chat chat) => _chatService.currentUserId != null && chat.createdBy == _chatService.currentUserId;

  // Handle push notifications for new messages
  Future<void> _handleNewMessageNotifications(String chatId, List<Message> newMessages) async {
    try {
      final currentUserId = _chatService.currentUserId;
      if (currentUserId == null) return;

      final chat = _chats.firstWhere((c) => c.id == chatId, orElse: () => Chat(
        id: chatId,
        participants: [],
        createdAt: DateTime.now(),
        createdBy: currentUserId,
        lastMessage: null,
        lastMessageTime: DateTime.now(),
      ));

      // Filter messages not sent by current user
      final messagesFromOthers = newMessages.where((msg) => msg.senderId != currentUserId).toList();
      
      for (final message in messagesFromOthers) {
        // Get sender info for notification
        final sender = await _loadUserWithCacheInternal(message.senderId);
        if (sender == null) continue;

        String notificationTitle;
        String notificationBody;

        if (chat.isGroup) {
          notificationTitle = chat.groupName ?? 'Group Chat';
          notificationBody = '${sender.name}: ${_getMessagePreview(message)}';
        } else {
          notificationTitle = sender.name;
          notificationBody = _getMessagePreview(message);
        }

        // Send notification to current user (this would typically be handled server-side)
        // For now, we'll create a notification request that can be processed by a cloud function
        await _notificationService.sendNotificationToUser(
          recipientUserId: currentUserId,
          title: notificationTitle,
          body: notificationBody,
          data: {
            'chatId': chatId,
            'messageId': message.id,
            'senderId': message.senderId,
            'type': 'new_message',
          },
        );
      }
    } catch (e) {
      _errorService.logError('Error handling new message notifications', error: e);
    }
  }

  // Get message preview for notifications
  String _getMessagePreview(Message message) {
    switch (message.type) {
      case MessageType.text:
        return message.text.length > 50 
            ? '${message.text.substring(0, 50)}...' 
            : message.text;
      case MessageType.image:
        return '📷 Photo';
      case MessageType.system:
        return '🔔 System message';
    }
  }

  @override
  void dispose() {
    // Cancel all subscriptions safely
    _chatsSubscription?.cancel();
    _chatsSubscription = null;
    
    // Cancel message subscriptions
    for (final subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();
    
    // Cancel typing subscriptions
    for (final subscription in _typingSubscriptions.values) {
      subscription.cancel();
    }
    _typingSubscriptions.clear();
    
    // Dispose typing service
    _typingService.dispose();
    
    // Clean up optimization timers and pending requests
    _batchUserLoadTimer?.cancel();
    for (final timer in _subscriptionTimers.values) {
      timer.cancel();
    }
    _subscriptionTimers.clear();
    _pendingUserRequests.clear();
    _activeSubscriptions.clear();
    _pendingUserIds.clear();
    
    // Clean up pagination state
    _isLoadingMoreMessages.clear();
    _hasMoreMessages.clear();
    _currentPage.clear();
    _lastDocument.clear();
    
    super.dispose();
  }
}
