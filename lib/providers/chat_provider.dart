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

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final FirestoreService _firestoreService = FirestoreService();
  final TypingService _typingService = TypingService();
  final ErrorService _errorService = ErrorService();
  final CacheService _cacheService = CacheService();

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

  List<Chat> get chats => _chats;
  Map<String, List<Message>> get chatMessages => _chatMessages;
  Map<String, UserModel> get users => _users;
  Map<String, List<String>> get typingUsers => _typingUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Pagination getters
  bool isLoadingMoreMessages(String chatId) => _isLoadingMoreMessages[chatId] ?? false;
  bool hasMoreMessages(String chatId) => _hasMoreMessages[chatId] ?? true;
  int getCurrentPage(String chatId) => _currentPage[chatId] ?? 0;

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
          
          // Load user data for each chat (with improved error handling)
          for (final chat in validChats) {
            // Check if still subscribed before continuing
            if (_chatsSubscription == null) return;
            
            await _loadChatParticipants(chat);
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
    try {
      // Try to load from cache first
      final cachedUser = await _cacheService.getCachedUser(userId);
      if (cachedUser != null) {
        _users[userId] = cachedUser;
        notifyListeners();
        
        // Load fresh data in background if cache is old
        final lastSync = await _cacheService.getLastSyncTime('user_$userId');
        if (lastSync == null || DateTime.now().difference(lastSync).inHours > 1) {
          _loadUserFromServer(userId);
        }
      } else {
        // No cache, load from server
        await _loadUserFromServer(userId);
      }
    } catch (e) {
      _errorService.logError('Failed to load user with cache $userId', error: e);
    }
  }

  Future<void> _loadUserFromServer(String userId) async {
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
      }
    } catch (e) {
      _errorService.logError('Failed to load user from server $userId', error: e);
    }
  }

  Future<void> _loadChatParticipants(Chat chat) async {
    try {
      for (final participantId in chat.participants) {
        if (participantId.isNotEmpty && !_users.containsKey(participantId)) {
          // Load user with cache-first approach
          await _loadUserWithCache(participantId);
        }
      }
    } catch (e) {
      _errorService.logError('Failed to load chat participants for ${chat.id}', error: e);
    }
  }

  List<Message> getChatMessages(String chatId) {
    return _chatMessages[chatId] ?? [];
  }

  void subscribeToChat(String chatId) {
    if (_messageSubscriptions.containsKey(chatId)) return;

    // Initialize pagination state
    _currentPage[chatId] = 0;
    _hasMoreMessages[chatId] = true;
    _isLoadingMoreMessages[chatId] = false;

    // Load cached messages first
    _loadCachedMessages(chatId);

    // Load initial messages with pagination
    _loadInitialMessages(chatId);

    // Subscribe to real-time updates for new messages only
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
    // Subscribe to real-time updates for very recent messages only
    _messageSubscriptions[chatId] = _firestoreService
        .getChatMessages(chatId, limit: 5)
        .listen(
      (recentMessages) {
        if (recentMessages.isEmpty) return;
        
        final existingMessages = _chatMessages[chatId] ?? [];
        final existingIds = existingMessages.map((m) => m.id).toSet();
        
        // Only add truly new messages
        final newMessages = recentMessages.where((m) => !existingIds.contains(m.id)).toList();
        
        if (newMessages.isNotEmpty) {
          final allMessages = [...newMessages, ...existingMessages];
          allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          _chatMessages[chatId] = allMessages;
          
          // Cache the updated messages
          _cacheMessages(chatId, allMessages);
          notifyListeners();
        }
      },
      onError: (error) {
        _errorService.logError('Message subscription error for chat $chatId', error: error);
        // Don't set UI error for message subscription issues - continue with cached data
      },
    );
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
    _chatMessages.remove(chatId);
    
    // Clean up pagination state
    _isLoadingMoreMessages.remove(chatId);
    _hasMoreMessages.remove(chatId);
    _currentPage.remove(chatId);
    _lastDocument.remove(chatId);
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
      await _chatService.editMessage(messageId, newText);
      _clearError();
    } catch (e) {
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to edit message', error: e);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
      _clearError();
    } catch (e) {
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to delete message', error: e);
    }
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
      await _chatService.markMessagesAsRead(chatId);
    } catch (e) {
      // Silently fail - not critical
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
    
    // Clean up pagination state
    _isLoadingMoreMessages.clear();
    _hasMoreMessages.clear();
    _currentPage.clear();
    _lastDocument.clear();
    
    super.dispose();
  }
}
