import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Cache user data
  Future<void> cacheUser(UserModel user) async {
    try {
      await initialize();
      final userJson = jsonEncode(user.toJsonMap());
      await _prefs!.setString('user_${user.uid}', userJson);
    } catch (e) {
      print('Cache warning: Failed to cache user ${user.uid}: $e');
    }
  }

  Future<UserModel?> getCachedUser(String uid) async {
    await initialize();
    final userJson = _prefs!.getString('user_$uid');
    if (userJson != null) {
      return UserModel.fromJsonMap(jsonDecode(userJson));
    }
    return null;
  }

  // Cache chat messages with pagination support
  Future<void> cacheMessages(String chatId, List<Message> messages, {int? page}) async {
    try {
      await initialize();
      final messagesJson = jsonEncode(messages.map((m) => m.toJsonMap()).toList());
      
      if (page != null) {
        // Cache specific page
        await _prefs!.setString('messages_${chatId}_page_$page', messagesJson);
        
        // Update page metadata
        final existingPages = await getCachedMessagePages(chatId);
        if (!existingPages.contains(page)) {
          existingPages.add(page);
          existingPages.sort();
          await _prefs!.setStringList('message_pages_$chatId', existingPages.map((p) => p.toString()).toList());
        }
      } else {
        // Cache all messages (legacy support)
        await _prefs!.setString('messages_$chatId', messagesJson);
      }
      
      // Update last message timestamp for this chat
      if (messages.isNotEmpty) {
        final latestMessage = messages.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
        await _prefs!.setInt('last_message_time_$chatId', latestMessage.timestamp.millisecondsSinceEpoch);
      }
    } catch (e) {
      print('Cache warning: Failed to cache messages for chat $chatId: $e');
    }
  }

  Future<List<Message>> getCachedMessages(String chatId, {int? page, int? limit}) async {
    try {
      await initialize();
      
      if (page != null) {
        // Get specific page
        final messagesJson = _prefs!.getString('messages_${chatId}_page_$page');
        if (messagesJson != null) {
          final List<dynamic> messagesList = jsonDecode(messagesJson);
          return messagesList.map((m) => Message.fromJsonMap(m)).toList();
        }
        return [];
      } else {
        // Get all cached messages (legacy support or combined view)
        final messagesJson = _prefs!.getString('messages_$chatId');
        if (messagesJson != null) {
          final List<dynamic> messagesList = jsonDecode(messagesJson);
          List<Message> messages = messagesList.map((m) => Message.fromJsonMap(m)).toList();
          
          // Apply limit if specified
          if (limit != null && messages.length > limit) {
            messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            messages = messages.take(limit).toList();
          }
          
          return messages;
        }
        
        // Try to combine all pages if no legacy cache exists
        return await getCombinedCachedMessages(chatId, limit: limit);
      }
    } catch (e) {
      print('Cache warning: Failed to get cached messages for chat $chatId: $e');
      return [];
    }
  }

  Future<List<Message>> getCombinedCachedMessages(String chatId, {int? limit}) async {
    try {
      final pages = await getCachedMessagePages(chatId);
      List<Message> allMessages = [];
      
      for (final page in pages) {
        final pageMessages = await getCachedMessages(chatId, page: page);
        allMessages.addAll(pageMessages);
      }
      
      // Sort by timestamp (newest first)
      allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Apply limit if specified
      if (limit != null && allMessages.length > limit) {
        allMessages = allMessages.take(limit).toList();
      }
      
      return allMessages;
    } catch (e) {
      print('Cache warning: Failed to get combined cached messages for chat $chatId: $e');
      return [];
    }
  }

  Future<List<int>> getCachedMessagePages(String chatId) async {
    try {
      await initialize();
      final pagesJson = _prefs!.getStringList('message_pages_$chatId');
      if (pagesJson != null) {
        return pagesJson.map((p) => int.parse(p)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<DateTime?> getLastMessageTime(String chatId) async {
    try {
      await initialize();
      final timestamp = _prefs!.getInt('last_message_time_$chatId');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Cache chats
  Future<void> cacheChats(List<Chat> chats) async {
    try {
      await initialize();
      final chatsJson = jsonEncode(chats.map((c) => c.toJsonMap()).toList());
      await _prefs!.setString('chats', chatsJson);
    } catch (e) {
      print('Cache warning: Failed to cache chats: $e');
    }
  }

  Future<List<Chat>> getCachedChats() async {
    try {
      await initialize();
      final chatsJson = _prefs!.getString('chats');
      if (chatsJson != null) {
        final List<dynamic> chatsList = jsonDecode(chatsJson);
        return chatsList.map((c) => Chat.fromJsonMap(c)).toList();
      }
      return [];
    } catch (e) {
      print('Cache warning: Failed to get cached chats: $e');
      return [];
    }
  }

  // Cache last sync timestamp
  Future<void> setLastSyncTime(String key, DateTime timestamp) async {
    await initialize();
    await _prefs!.setInt('sync_$key', timestamp.millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastSyncTime(String key) async {
    await initialize();
    final timestamp = _prefs!.getInt('sync_$key');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // Clear specific cache
  Future<void> clearCache(String key) async {
    await initialize();
    await _prefs!.remove(key);
  }

  // Clear messages cache for specific chat
  Future<void> clearMessagesCache(String chatId) async {
    try {
      await initialize();
      
      // Clear legacy messages cache
      await _prefs!.remove('messages_$chatId');
      
      // Clear paginated messages cache
      final pages = await getCachedMessagePages(chatId);
      for (final page in pages) {
        await _prefs!.remove('messages_${chatId}_page_$page');
      }
      
      // Clear page metadata
      await _prefs!.remove('message_pages_$chatId');
      await _prefs!.remove('last_message_time_$chatId');
    } catch (e) {
      print('Cache warning: Failed to clear messages cache for chat $chatId: $e');
    }
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    await initialize();
    final keys = _prefs!.getKeys().where((key) => 
      key.startsWith('user_') || 
      key.startsWith('messages_') || 
      key.startsWith('chats') ||
      key.startsWith('sync_') ||
      key.startsWith('message_pages_') ||
      key.startsWith('last_message_time_') ||
      key.startsWith('friend_requests_') ||
      key.startsWith('online_status_')
    ).toList();
    
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }

  // Cache app settings
  Future<void> setSetting(String key, dynamic value) async {
    await initialize();
    if (value is String) {
      await _prefs!.setString('setting_$key', value);
    } else if (value is bool) {
      await _prefs!.setBool('setting_$key', value);
    } else if (value is int) {
      await _prefs!.setInt('setting_$key', value);
    } else if (value is double) {
      await _prefs!.setDouble('setting_$key', value);
    }
  }

  Future<T?> getSetting<T>(String key) async {
    await initialize();
    return _prefs!.get('setting_$key') as T?;
  }

  // Cache friend requests
  Future<void> cacheFriendRequests(List<Map<String, dynamic>> requests) async {
    try {
      await initialize();
      final requestsJson = jsonEncode(requests);
      await _prefs!.setString('friend_requests', requestsJson);
    } catch (e) {
      print('Cache warning: Failed to cache friend requests: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCachedFriendRequests() async {
    try {
      await initialize();
      final requestsJson = _prefs!.getString('friend_requests');
      if (requestsJson != null) {
        final List<dynamic> requestsList = jsonDecode(requestsJson);
        return requestsList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Cache warning: Failed to get cached friend requests: $e');
      return [];
    }
  }

  // Cache user online status
  Future<void> cacheUserOnlineStatus(String userId, bool isOnline, DateTime? lastSeen) async {
    try {
      await initialize();
      final statusData = {
        'isOnline': isOnline,
        'lastSeen': lastSeen?.millisecondsSinceEpoch,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      };
      await _prefs!.setString('online_status_$userId', jsonEncode(statusData));
    } catch (e) {
      print('Cache warning: Failed to cache online status for user $userId: $e');
    }
  }

  Future<Map<String, dynamic>?> getCachedUserOnlineStatus(String userId) async {
    try {
      await initialize();
      final statusJson = _prefs!.getString('online_status_$userId');
      if (statusJson != null) {
        final statusData = jsonDecode(statusJson) as Map<String, dynamic>;
        
        // Check if cache is still valid (5 minutes)
        final cachedAt = DateTime.fromMillisecondsSinceEpoch(statusData['cachedAt']);
        if (DateTime.now().difference(cachedAt).inMinutes < 5) {
          return {
            'isOnline': statusData['isOnline'],
            'lastSeen': statusData['lastSeen'] != null 
                ? DateTime.fromMillisecondsSinceEpoch(statusData['lastSeen'])
                : null,
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Cache management utilities
  Future<int> getCacheSize() async {
    try {
      await initialize();
      int totalSize = 0;
      final keys = _prefs!.getKeys();
      
      for (final key in keys) {
        final value = _prefs!.get(key);
        if (value is String) {
          totalSize += value.length;
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  Future<void> cleanupOldCache({int maxAgeHours = 24}) async {
    try {
      await initialize();
      final cutoffTime = DateTime.now().subtract(Duration(hours: maxAgeHours));
      final keysToRemove = <String>[];
      
      // Check sync timestamps and remove old entries
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('sync_')) {
          final timestamp = _prefs!.getInt(key);
          if (timestamp != null) {
            final syncTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            if (syncTime.isBefore(cutoffTime)) {
              keysToRemove.add(key);
              // Also remove associated data
              final dataKey = key.replaceFirst('sync_', '');
              if (keys.contains(dataKey)) {
                keysToRemove.add(dataKey);
              }
            }
          }
        }
      }
      
      for (final key in keysToRemove) {
        await _prefs!.remove(key);
      }
    } catch (e) {
      print('Cache warning: Failed to cleanup old cache: $e');
    }
  }
}
