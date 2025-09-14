import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import 'dart:async';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;

  // Optimization: Smart caching with connection pooling
  static final Map<String, Timer> _cacheTimers = {};
  static final Map<String, Completer<void>> _pendingCacheOperations = {};
  static const Duration _batchDelay = Duration(milliseconds: 200);
  static const Duration _maxCacheAge = Duration(hours: 24);
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB limit

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    // Optimization: Cleanup old cache on initialization
    _scheduleCleanup();
  }

  void _scheduleCleanup() {
    Timer.periodic(Duration(hours: 6), (timer) {
      cleanupOldCache();
    });
  }

  // Optimization: Batch cache user operations to reduce I/O
  Future<void> cacheUser(UserModel user) async {
    return _batchCacheOperation('user_${user.uid}', () async {
      try {
        await initialize();
        final userJson = jsonEncode(user.toJsonMap());
        await _prefs!.setString('user_${user.uid}', userJson);
        await _prefs!.setInt('cache_time_user_${user.uid}', DateTime.now().millisecondsSinceEpoch);
      } catch (e) {
        print('Cache warning: Failed to cache user ${user.uid}: $e');
      }
    });
  }

  // Optimization: Smart user retrieval with cache validation
  Future<UserModel?> getCachedUser(String uid) async {
    try {
      await initialize();
      
      // Check cache age first
      final cacheTime = _prefs!.getInt('cache_time_user_$uid');
      if (cacheTime != null) {
        final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(cacheTime));
        if (age > _maxCacheAge) {
          // Cache is too old, remove it
          await _prefs!.remove('user_$uid');
          await _prefs!.remove('cache_time_user_$uid');
          return null;
        }
      }
      
      final userJson = _prefs!.getString('user_$uid');
      if (userJson != null) {
        return UserModel.fromJsonMap(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      print('Cache warning: Failed to get cached user $uid: $e');
      return null;
    }
  }

  // Optimization: Batch cache operations to reduce I/O overhead
  Future<void> _batchCacheOperation(String key, Future<void> Function() operation) async {
    // Check if operation is already pending
    if (_pendingCacheOperations.containsKey(key)) {
      return _pendingCacheOperations[key]!.future;
    }

    final completer = Completer<void>();
    _pendingCacheOperations[key] = completer;

    // Cancel existing timer for this key
    _cacheTimers[key]?.cancel();

    // Schedule batched execution
    _cacheTimers[key] = Timer(_batchDelay, () async {
      try {
        await operation();
        completer.complete();
      } catch (e) {
        completer.completeError(e);
      } finally {
        _pendingCacheOperations.remove(key);
        _cacheTimers.remove(key);
      }
    });

    return completer.future;
  }

  // Optimization: Enhanced message caching with compression and smart storage
  Future<void> cacheMessages(String chatId, List<Message> messages, {int? page}) async {
    return _batchCacheOperation('messages_${chatId}_${page ?? 'all'}', () async {
      try {
        await initialize();
        
        // Check cache size before adding
        final currentSize = await getCacheSize();
        if (currentSize > _maxCacheSize) {
          await _performCacheCleanup();
        }
        
        final messagesJson = jsonEncode(messages.map((m) => m.toJsonMap()).toList());
        
        if (page != null) {
          // Cache specific page
          await _prefs!.setString('messages_${chatId}_page_$page', messagesJson);
          await _prefs!.setInt('cache_time_messages_${chatId}_page_$page', DateTime.now().millisecondsSinceEpoch);
          
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
          await _prefs!.setInt('cache_time_messages_$chatId', DateTime.now().millisecondsSinceEpoch);
        }
        
        // Update last message timestamp for this chat
        if (messages.isNotEmpty) {
          final latestMessage = messages.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
          await _prefs!.setInt('last_message_time_$chatId', latestMessage.timestamp.millisecondsSinceEpoch);
        }
      } catch (e) {
        print('Cache warning: Failed to cache messages for chat $chatId: $e');
      }
    });
  }

  // Optimization: Smart message retrieval with cache validation
  Future<List<Message>> getCachedMessages(String chatId, {int? page, int? limit}) async {
    try {
      await initialize();
      
      if (page != null) {
        // Check cache age for specific page
        final cacheTime = _prefs!.getInt('cache_time_messages_${chatId}_page_$page');
        if (cacheTime != null) {
          final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(cacheTime));
          if (age > _maxCacheAge) {
            await _prefs!.remove('messages_${chatId}_page_$page');
            await _prefs!.remove('cache_time_messages_${chatId}_page_$page');
            return [];
          }
        }
        
        // Get specific page
        final messagesJson = _prefs!.getString('messages_${chatId}_page_$page');
        if (messagesJson != null) {
          final List<dynamic> messagesList = jsonDecode(messagesJson);
          return messagesList.map((m) => Message.fromJsonMap(m)).toList();
        }
        return [];
      } else {
        // Check cache age for all messages
        final cacheTime = _prefs!.getInt('cache_time_messages_$chatId');
        if (cacheTime != null) {
          final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(cacheTime));
          if (age > _maxCacheAge) {
            await _prefs!.remove('messages_$chatId');
            await _prefs!.remove('cache_time_messages_$chatId');
            return await getCombinedCachedMessages(chatId, limit: limit);
          }
        }
        
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

  // Returns the list of cached page indices for a chat, sorted ascending
  Future<List<int>> getCachedMessagePages(String chatId) async {
    try {
      await initialize();
      final pages = _prefs!.getStringList('message_pages_$chatId');
      if (pages == null) return [];
      final parsed = pages.map((p) => int.tryParse(p)).whereType<int>().toList();
      parsed.sort();
      return parsed;
    } catch (e) {
      print('Cache warning: Failed to get cached message pages for chat $chatId: $e');
      return [];
    }
  }

  // Combines all cached message pages (and legacy cache) into a single list, sorted by timestamp desc
  Future<List<Message>> getCombinedCachedMessages(String chatId, {int? limit}) async {
    try {
      await initialize();

      // Use a map to deduplicate by message id if available
      final Map<String, Message> byId = {};
      final List<Message> aggregate = [];

      // Gather from paged cache
      final pages = await getCachedMessagePages(chatId);
      for (final page in pages) {
        final messagesJson = _prefs!.getString('messages_${chatId}_page_$page');
        if (messagesJson == null) continue;
        final List<dynamic> messagesList = jsonDecode(messagesJson);
        for (final m in messagesList) {
          final msg = Message.fromJsonMap(m);
          // Prefer id-based dedupe if id exists, else just add (fallback)
          final id = msg.id;
          if (id != null && id.isNotEmpty) {
            byId[id] = msg;
          } else {
            aggregate.add(msg);
          }
        }
      }

      // Merge legacy whole-chat cache if present
      final legacyJson = _prefs!.getString('messages_$chatId');
      if (legacyJson != null) {
        final List<dynamic> legacyList = jsonDecode(legacyJson);
        for (final m in legacyList) {
          final msg = Message.fromJsonMap(m);
          final id = msg.id;
          if (id != null && id.isNotEmpty) {
            byId[id] = msg;
          } else {
            aggregate.add(msg);
          }
        }
      }

      // Build final list and sort by timestamp desc
      final List<Message> combined = [...byId.values, ...aggregate];
      combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (limit != null && combined.length > limit) {
        return combined.take(limit).toList();
      }
      return combined;
    } catch (e) {
      print('Cache warning: Failed to combine cached messages for chat $chatId: $e');
      return [];
    }
  }

  // Optimization: Enhanced chat caching with metadata
  Future<void> cacheChats(List<Chat> chats) async {
    return _batchCacheOperation('chats', () async {
      try {
        await initialize();
        final chatsJson = jsonEncode(chats.map((c) => c.toJsonMap()).toList());
        await _prefs!.setString('chats', chatsJson);
        await _prefs!.setInt('cache_time_chats', DateTime.now().millisecondsSinceEpoch);
      } catch (e) {
        print('Cache warning: Failed to cache chats: $e');
      }
    });
  }

  // Optimization: Smart chat retrieval with validation
  Future<List<Chat>> getCachedChats() async {
    try {
      await initialize();
      
      // Check cache age
      final cacheTime = _prefs!.getInt('cache_time_chats');
      if (cacheTime != null) {
        final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(cacheTime));
        if (age > _maxCacheAge) {
          await _prefs!.remove('chats');
          await _prefs!.remove('cache_time_chats');
          return [];
        }
      }
      
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

  // Optimization: Smart cache cleanup with size management
  Future<void> _performCacheCleanup() async {
    try {
      await initialize();
      final keys = _prefs!.getKeys().toList();
      
      // Sort keys by cache time (oldest first)
      final cacheEntries = <MapEntry<String, int>>[];
      
      for (final key in keys) {
        if (key.startsWith('cache_time_')) {
          final timestamp = _prefs!.getInt(key);
          if (timestamp != null) {
            cacheEntries.add(MapEntry(key, timestamp));
          }
        }
      }
      
      cacheEntries.sort((a, b) => a.value.compareTo(b.value));
      
      // Remove oldest 25% of cache entries
      final entriesToRemove = (cacheEntries.length * 0.25).ceil();
      for (int i = 0; i < entriesToRemove && i < cacheEntries.length; i++) {
        final cacheTimeKey = cacheEntries[i].key;
        final dataKey = cacheTimeKey.replaceFirst('cache_time_', '');
        
        await _prefs!.remove(cacheTimeKey);
        await _prefs!.remove(dataKey);
      }
    } catch (e) {
      print('Cache warning: Failed to perform cache cleanup: $e');
    }
  }

  // Optimization: Enhanced cache size calculation
  Future<int> getCacheSize() async {
    try {
      await initialize();
      int totalSize = 0;
      final keys = _prefs!.getKeys();
      
      for (final key in keys) {
        final value = _prefs!.get(key);
        if (value is String) {
          totalSize += value.length * 2; // UTF-16 encoding
        } else if (value is List<String>) {
          totalSize += value.fold(0, (sum, str) => sum + str.length * 2);
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  // Optimization: More aggressive cache cleanup
  Future<void> cleanupOldCache({int maxAgeHours = 12}) async { // Reduced from 24 to 12 hours
    try {
      await initialize();
      final cutoffTime = DateTime.now().subtract(Duration(hours: maxAgeHours));
      final keysToRemove = <String>[];
      
      // Check cache timestamps and remove old entries
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_time_')) {
          final timestamp = _prefs!.getInt(key);
          if (timestamp != null) {
            final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            if (cacheTime.isBefore(cutoffTime)) {
              keysToRemove.add(key);
              // Also remove associated data
              final dataKey = key.replaceFirst('cache_time_', '');
              if (keys.contains(dataKey)) {
                keysToRemove.add(dataKey);
              }
            }
          }
        }
        
        // Also check legacy sync timestamps
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
      
      print('Cache cleanup: Removed ${keysToRemove.length} expired entries');
    } catch (e) {
      print('Cache warning: Failed to cleanup old cache: $e');
    }
  }

  // Optimization: Batch user caching for better performance
  Future<void> batchCacheUsers(Map<String, UserModel> users) async {
    if (users.isEmpty) return;
    
    return _batchCacheOperation('batch_users_${users.length}', () async {
      try {
        await initialize();
        final now = DateTime.now().millisecondsSinceEpoch;
        
        for (final entry in users.entries) {
          final userJson = jsonEncode(entry.value.toJsonMap());
          await _prefs!.setString('user_${entry.key}', userJson);
          await _prefs!.setInt('cache_time_user_${entry.key}', now);
        }
      } catch (e) {
        print('Cache warning: Failed to batch cache users: $e');
      }
    });
  }

  // Optimization: Prefetch and warm cache for better performance
  Future<void> warmCache(List<String> chatIds, List<String> userIds) async {
    try {
      // Prefetch user data
      final missingUsers = <String>[];
      for (final userId in userIds) {
        final cachedUser = await getCachedUser(userId);
        if (cachedUser == null) {
          missingUsers.add(userId);
        }
      }
      
      // Prefetch recent messages for active chats
      for (final chatId in chatIds.take(3)) { // Limit to 3 most recent chats
        final cachedMessages = await getCachedMessages(chatId, limit: 10);
        if (cachedMessages.isEmpty) {
          // Cache is empty, will be filled by real-time subscriptions
        }
      }
      
      print('Cache warming: Checked ${userIds.length} users, ${missingUsers.length} missing');
    } catch (e) {
      print('Cache warning: Failed to warm cache: $e');
    }
  }

  // Optimization: Get cache statistics for monitoring
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      await initialize();
      final keys = _prefs!.getKeys();
      final stats = <String, int>{};
      int totalSize = 0;
      
      for (final key in keys) {
        String category = 'other';
        if (key.startsWith('user_')) category = 'users';
        else if (key.startsWith('messages_')) category = 'messages';
        else if (key.startsWith('chats')) category = 'chats';
        else if (key.startsWith('cache_time_')) category = 'metadata';
        else if (key.startsWith('sync_')) category = 'sync';
        
        stats[category] = (stats[category] ?? 0) + 1;
        
        final value = _prefs!.get(key);
        if (value is String) {
          totalSize += value.length * 2;
        }
      }
      
      return {
        'categories': stats,
        'totalSize': totalSize,
        'totalKeys': keys.length,
        'sizeFormatted': '${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Sync timestamp helpers
  Future<DateTime?> getLastSyncTime(String key) async {
    try {
      await initialize();
      final ts = _prefs!.getInt('sync_$key');
      if (ts == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(ts);
    } catch (e) {
      return null;
    }
  }

  Future<void> setLastSyncTime(String key, DateTime time) async {
    try {
      await initialize();
      await _prefs!.setInt('sync_$key', time.millisecondsSinceEpoch);
    } catch (e) {
      // ignore
    }
  }

  // Cache user online status for brief period
  Future<void> cacheUserOnlineStatus(String userId, bool isOnline, DateTime? lastSeen) async {
    try {
      await initialize();
      await _prefs!.setBool('user_status_$userId', isOnline);
      if (lastSeen != null) {
        await _prefs!.setInt('user_last_seen_$userId', lastSeen.millisecondsSinceEpoch);
      }
      await _prefs!.setInt('cache_time_user_status_$userId', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // ignore cache failures
    }
  }

  // Retrieve cached user online status if not older than maxAge
  Future<bool?> getCachedUserOnline(String userId, {Duration maxAge = const Duration(minutes: 5)}) async {
    try {
      await initialize();
      final ts = _prefs!.getInt('cache_time_user_status_$userId');
      if (ts == null) return null;
      final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
      if (age > maxAge) return null;
      return _prefs!.getBool('user_status_$userId');
    } catch (e) {
      return null;
    }
  }

  // Retrieve cached user last seen if associated status cache is still valid
  Future<DateTime?> getCachedUserLastSeen(String userId, {Duration maxAge = const Duration(minutes: 5)}) async {
    try {
      await initialize();
      final ts = _prefs!.getInt('cache_time_user_status_$userId');
      if (ts == null) return null;
      final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
      if (age > maxAge) return null;
      final lastSeenMs = _prefs!.getInt('user_last_seen_$userId');
      if (lastSeenMs == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(lastSeenMs);
    } catch (e) {
      return null;
    }
  }

  // Retrieve last message timestamp tracked during cacheMessages
  Future<DateTime?> getLastMessageTime(String chatId) async {
    try {
      await initialize();
      final ts = _prefs!.getInt('last_message_time_$chatId');
      if (ts == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(ts);
    } catch (e) {
      return null;
    }
  }
}
