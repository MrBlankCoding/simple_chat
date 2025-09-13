import 'dart:async';
import 'package:flutter/foundation.dart';
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

  List<Chat> get chats => _chats;
  Map<String, List<Message>> get chatMessages => _chatMessages;
  Map<String, UserModel> get users => _users;
  Map<String, List<String>> get typingUsers => _typingUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    _chatsSubscription = _chatService.getUserChats().listen(
      (chats) async {
        try {
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
            for (final participantId in chat.participants) {
              if (participantId.isNotEmpty && !_users.containsKey(participantId)) {
                try {
                  final user = await _firestoreService.getUserById(participantId);
                  if (user != null) {
                    _users[participantId] = user;
                    // Cache the user data (with error handling)
                    try {
                      await _cacheService.cacheUser(user);
                    } catch (e) {
                      // Silent cache failure - not critical
                    }
                  }
                } catch (e) {
                  // Log but don't fail the entire subscription
                  _errorService.logError('Failed to load user $participantId', error: e);
                }
              }
            }
          }
          
          _clearError(); // Clear any previous errors on successful load
          notifyListeners();
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
      await _cacheService.cacheMessages(chatId, messages);
    } catch (e) {
      // Silent cache failure - not critical
      _errorService.logError('Failed to cache messages for chat $chatId', error: e);
    }
  }

  List<Message> getChatMessages(String chatId) {
    return _chatMessages[chatId] ?? [];
  }

  void subscribeToChat(String chatId) {
    if (_messageSubscriptions.containsKey(chatId)) return;

    // Load cached messages first
    _loadCachedMessages(chatId);

    _messageSubscriptions[chatId] = _chatService.getChatMessages(chatId).listen(
      (messages) {
        _chatMessages[chatId] = messages;
        // Cache messages for offline access
        _cacheMessages(chatId, messages);
        notifyListeners();
      },
      onError: (error) {
        _errorService.logError('Message subscription error for chat $chatId', error: error);
        // Don't set UI error for message subscription issues - continue with cached data
      },
    );
  }

  void unsubscribeFromChat(String chatId) {
    _messageSubscriptions[chatId]?.cancel();
    _messageSubscriptions.remove(chatId);
    _chatMessages.remove(chatId);
  }

  Future<String> getOrCreateDirectChat(String otherUserId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final chatId = await _chatService.getOrCreateDirectChat(otherUserId);
      
      // Load user data if not already loaded
      if (!_users.containsKey(otherUserId)) {
        final user = await _firestoreService.getUserById(otherUserId);
        if (user != null) {
          _users[otherUserId] = user;
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

  Future<String> createGroupChat(List<String> participantIds, String groupName) async {
    try {
      _setLoading(true);
      _clearError();
      
      final chatId = await _chatService.createGroupChat(participantIds, groupName);
      
      // Load user data for participants
      final usersMap = await _firestoreService.getUsersMap(participantIds);
      _users.addAll(usersMap);
      
      return chatId;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendTextMessage(String chatId, String text) async {
    try {
      // Don't set loading state for message sending to avoid UI freeze
      await _chatService.sendTextMessage(chatId, text);
      
      // Stop typing indicator when message is sent
      await stopTyping(chatId);
      
      _clearError();
    } catch (e) {
      _setError(_errorService.getFirebaseErrorMessage(e));
      _errorService.logError('Failed to send message', error: e);
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

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    for (final subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }
}
