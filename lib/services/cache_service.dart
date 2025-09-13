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

  // Cache chat messages
  Future<void> cacheMessages(String chatId, List<Message> messages) async {
    try {
      await initialize();
      final messagesJson = jsonEncode(messages.map((m) => m.toJsonMap()).toList());
      await _prefs!.setString('messages_$chatId', messagesJson);
    } catch (e) {
      print('Cache warning: Failed to cache messages for chat $chatId: $e');
    }
  }

  Future<List<Message>> getCachedMessages(String chatId) async {
    try {
      await initialize();
      final messagesJson = _prefs!.getString('messages_$chatId');
      if (messagesJson != null) {
        final List<dynamic> messagesList = jsonDecode(messagesJson);
        return messagesList.map((m) => Message.fromJsonMap(m)).toList();
      }
      return [];
    } catch (e) {
      print('Cache warning: Failed to get cached messages for chat $chatId: $e');
      return [];
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

  // Clear all cache
  Future<void> clearAllCache() async {
    await initialize();
    final keys = _prefs!.getKeys().where((key) => 
      key.startsWith('user_') || 
      key.startsWith('messages_') || 
      key.startsWith('chats') ||
      key.startsWith('sync_')
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
}
