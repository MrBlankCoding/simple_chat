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
    await initialize();
    await _prefs!.setString('user_${user.uid}', jsonEncode(user.toMap()));
  }

  Future<UserModel?> getCachedUser(String uid) async {
    await initialize();
    final userJson = _prefs!.getString('user_$uid');
    if (userJson != null) {
      return UserModel.fromMap(jsonDecode(userJson));
    }
    return null;
  }

  // Cache chat messages
  Future<void> cacheMessages(String chatId, List<Message> messages) async {
    await initialize();
    final messagesJson = messages.map((m) => m.toMap()).toList();
    await _prefs!.setString('messages_$chatId', jsonEncode(messagesJson));
  }

  Future<List<Message>> getCachedMessages(String chatId) async {
    await initialize();
    final messagesJson = _prefs!.getString('messages_$chatId');
    if (messagesJson != null) {
      final List<dynamic> messagesList = jsonDecode(messagesJson);
      return messagesList.map((m) => Message.fromMap(m)).toList();
    }
    return [];
  }

  // Cache chats
  Future<void> cacheChats(List<Chat> chats) async {
    await initialize();
    final chatsJson = chats.map((c) => c.toMap()).toList();
    await _prefs!.setString('chats', jsonEncode(chatsJson));
  }

  Future<List<Chat>> getCachedChats() async {
    await initialize();
    final chatsJson = _prefs!.getString('chats');
    if (chatsJson != null) {
      final List<dynamic> chatsList = jsonDecode(chatsJson);
      return chatsList.map((c) => Chat.fromMap(c)).toList();
    }
    return [];
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
