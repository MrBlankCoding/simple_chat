import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  // Handle background message here if needed
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool _isInitialized = false;
  String? _currentToken;

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission for notifications
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up Firebase messaging
      await _setupFirebaseMessaging();

      // Get and store FCM token
      await _handleTokenRefresh();

      _isInitialized = true;
      print('NotificationService initialized successfully');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  // Request notification permissions
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final chatId = data['chatId'] as String?;
        
        if (chatId != null) {
          // Navigate to chat screen
          // This will be handled by the app's navigation system
          _navigateToChat(chatId);
        }
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Navigate to chat (to be implemented with navigation context)
  void _navigateToChat(String chatId) {
    // This will be called from the main app with proper navigation context
    print('Should navigate to chat: $chatId');
  }

  // Set up Firebase messaging handlers
  Future<void> _setupFirebaseMessaging() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification opened app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  // Handle message that opened the app
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.messageId}');
    
    final chatId = message.data['chatId'] as String?;
    if (chatId != null) {
      _navigateToChat(chatId);
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = jsonEncode(message.data);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? 'You have a new message',
      notificationDetails,
      payload: payload,
    );
  }

  // Handle token refresh
  Future<void> _handleTokenRefresh() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _onTokenRefresh(token);
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  // Update token in Firestore
  Future<void> _onTokenRefresh(String token) async {
    print('FCM Token refreshed: $token');
    _currentToken = token;

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _firestoreService.updateUserFCMToken(currentUser.uid, token);
        
        // Store token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Get current FCM token
  Future<String?> getCurrentToken() async {
    if (_currentToken != null) return _currentToken;
    
    try {
      _currentToken = await _firebaseMessaging.getToken();
      return _currentToken;
    } catch (e) {
      print('Error getting current FCM token: $e');
      return null;
    }
  }

  // Send notification to specific user
  Future<void> sendNotificationToUser({
    required String recipientUserId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Get recipient's FCM token
      final recipientUser = await _firestoreService.getUser(recipientUserId);
      if (recipientUser?.fcmToken == null) {
        print('Recipient has no FCM token');
        return;
      }

      // Send notification via FCM (this would typically be done server-side)
      // For now, we'll create a cloud function trigger or use a server endpoint
      await _firestoreService.createNotificationRequest({
        'recipientToken': recipientUser!.fcmToken!,
        'title': title,
        'body': body,
        'data': data ?? {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Send test notification
  Future<void> sendTestNotification() async {
    const title = 'Test Notification';
    const body = 'This is a test notification from SimpleChat!';
    
    await _showLocalNotification(
      RemoteMessage(
        notification: const RemoteNotification(
          title: title,
          body: body,
        ),
        data: {'type': 'test'},
      ),
    );
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  // Subscribe to topic (for group notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  // Set navigation callback for handling notification taps
  void Function(String chatId)? _navigationCallback;
  
  void setNavigationCallback(void Function(String chatId) callback) {
    _navigationCallback = callback;
  }

  void _navigateToChat(String chatId) {
    _navigationCallback?.call(chatId);
  }
}
