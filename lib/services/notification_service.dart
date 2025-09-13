import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AuthService _authService = AuthService();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request notification permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure Firebase Messaging
    await _configureFCM();

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await Permission.notification.request();
    }

    // Request FCM permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      throw Exception('Notification permissions denied');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _configureFCM() async {
    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null && _authService.currentUser != null) {
      await _authService.updateFCMToken(_authService.currentUser!.uid, token);
    }

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((String token) async {
      if (_authService.currentUser != null) {
        await _authService.updateFCMToken(_authService.currentUser!.uid, token);
      }
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background message
    print('Handling background message: ${message.messageId}');
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navigate to appropriate screen based on notification data
    final data = message.data;
    if (data.containsKey('chatId')) {
      // Navigate to chat screen
      // This would need to be implemented with a navigation service
    } else if (data.containsKey('friendRequestId')) {
      // Navigate to friends screen
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle local notification tap
    final payload = response.payload;
    if (payload != null) {
      // Parse payload and navigate accordingly
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? 'You have a new message',
      platformDetails,
      payload: message.data.toString(),
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> updateFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null && _authService.currentUser != null) {
      await _authService.updateFCMToken(_authService.currentUser!.uid, token);
    }
  }

  void dispose() {
    // Clean up resources if needed
  }
}
