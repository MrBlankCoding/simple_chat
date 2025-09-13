import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class TypingService {
  static final TypingService _instance = TypingService._internal();
  factory TypingService() => _instance;
  TypingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Timer> _typingTimers = {};
  final Map<String, StreamSubscription> _typingSubscriptions = {};

  // Start typing indicator for a chat
  Future<void> startTyping(String chatId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .collection('typing')
          .doc(userId)
          .set({
        'isTyping': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Auto-stop typing after 3 seconds
      _typingTimers[chatId]?.cancel();
      _typingTimers[chatId] = Timer(const Duration(seconds: 3), () {
        stopTyping(chatId, userId);
      });
    } catch (e) {
      // Silently fail - typing indicators are not critical
    }
  }

  // Stop typing indicator for a chat
  Future<void> stopTyping(String chatId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .collection('typing')
          .doc(userId)
          .delete();

      _typingTimers[chatId]?.cancel();
      _typingTimers.remove(chatId);
    } catch (e) {
      // Silently fail - typing indicators are not critical
    }
  }

  // Listen to typing indicators for a chat
  Stream<List<String>> getTypingUsers(String chatId, String currentUserId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection('typing')
        .where('isTyping', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => doc.id)
          .toList();
    });
  }

  // Clean up typing indicators when user leaves chat
  Future<void> cleanupTyping(String chatId, String userId) async {
    await stopTyping(chatId, userId);
    _typingSubscriptions[chatId]?.cancel();
    _typingSubscriptions.remove(chatId);
  }

  void dispose() {
    for (var timer in _typingTimers.values) {
      timer.cancel();
    }
    for (var subscription in _typingSubscriptions.values) {
      subscription.cancel();
    }
    _typingTimers.clear();
    _typingSubscriptions.clear();
  }
}
