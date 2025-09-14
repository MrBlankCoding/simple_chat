import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  bool _pushNotifications = true;
  bool _messageNotifications = true;
  bool _friendRequestNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isTestingNotification = false;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final isEnabled = await _notificationService.areNotificationsEnabled();
      final token = await _notificationService.getCurrentToken();
      
      setState(() {
        _pushNotifications = isEnabled;
        _fcmToken = token;
      });
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  Future<void> _sendTestNotification() async {
    if (_isTestingNotification) return;
    
    setState(() {
      _isTestingNotification = true;
    });

    try {
      await _notificationService.sendTestNotification();
      
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to send test notification: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingNotification = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final theme = themeProvider.currentTheme;
          return CupertinoAlertDialog(
            title: Text(
              'Test Notification Sent',
              style: TextStyle(color: theme.textPrimary),
            ),
            content: Text(
              'Check your notification panel to see the test notification.',
              style: TextStyle(color: theme.textSecondary),
            ),
            actions: [
              CupertinoDialogAction(
                child: Text(
                  'OK',
                  style: TextStyle(color: theme.primaryColor),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final theme = themeProvider.currentTheme;
          return CupertinoAlertDialog(
            title: Text(
              'Error',
              style: TextStyle(color: theme.textPrimary),
            ),
            content: Text(
              message,
              style: TextStyle(color: theme.textSecondary),
            ),
            actions: [
              CupertinoDialogAction(
                child: Text(
                  'OK',
                  style: TextStyle(color: theme.primaryColor),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        
        return CupertinoPageScaffold(
          backgroundColor: theme.backgroundColor,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: theme.backgroundColor,
            middle: Text(
              'Notifications',
              style: TextStyle(color: theme.textPrimary),
            ),
          ),
          child: SafeArea(
            child: ListView(
              children: [
                CupertinoFormSection.insetGrouped(
                  backgroundColor: theme.cardColor,
                  header: Text(
                    'PUSH NOTIFICATIONS',
                    style: TextStyle(color: theme.textSecondary),
                  ),
                  children: [
                    CupertinoFormRow(
                      prefix: Text(
                        'Push Notifications',
                        style: TextStyle(color: theme.textPrimary),
                      ),
                      child: CupertinoSwitch(
                        value: _pushNotifications,
                        activeTrackColor: theme.primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _pushNotifications = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                CupertinoFormSection.insetGrouped(
                  backgroundColor: theme.cardColor,
                  header: Text(
                    'MESSAGE SETTINGS',
                    style: TextStyle(color: theme.textSecondary),
                  ),
                  children: [
                    CupertinoFormRow(
                      prefix: Text(
                        'Message Notifications',
                        style: TextStyle(color: theme.textPrimary),
                      ),
                      child: CupertinoSwitch(
                        value: _messageNotifications,
                        activeTrackColor: theme.primaryColor,
                        onChanged: _pushNotifications ? (value) {
                          setState(() {
                            _messageNotifications = value;
                          });
                        } : null,
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: Text(
                        'Friend Requests',
                        style: TextStyle(color: theme.textPrimary),
                      ),
                      child: CupertinoSwitch(
                        value: _friendRequestNotifications,
                        activeTrackColor: theme.primaryColor,
                        onChanged: _pushNotifications ? (value) {
                          setState(() {
                            _friendRequestNotifications = value;
                          });
                        } : null,
                      ),
                    ),
                  ],
                ),
                
                CupertinoFormSection.insetGrouped(
                  backgroundColor: theme.cardColor,
                  header: Text(
                    'ALERT STYLE',
                    style: TextStyle(color: theme.textSecondary),
                  ),
                  children: [
                    CupertinoFormRow(
                      prefix: Text(
                        'Sound',
                        style: TextStyle(color: theme.textPrimary),
                      ),
                      child: CupertinoSwitch(
                        value: _soundEnabled,
                        activeTrackColor: theme.primaryColor,
                        onChanged: _pushNotifications ? (value) {
                          setState(() {
                            _soundEnabled = value;
                          });
                        } : null,
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: Text(
                        'Vibration',
                        style: TextStyle(color: theme.textPrimary),
                      ),
                      child: CupertinoSwitch(
                        value: _vibrationEnabled,
                        activeTrackColor: theme.primaryColor,
                        onChanged: _pushNotifications ? (value) {
                          setState(() {
                            _vibrationEnabled = value;
                          });
                        } : null,
                      ),
                    ),
                  ],
                ),

                CupertinoFormSection.insetGrouped(
                  backgroundColor: theme.cardColor,
                  header: Text(
                    'TESTING',
                    style: TextStyle(color: theme.textSecondary),
                  ),
                  children: [
                    CupertinoFormRow(
                      prefix: Text(
                        'Test Notification',
                        style: TextStyle(color: theme.textPrimary),
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _pushNotifications && !_isTestingNotification 
                            ? _sendTestNotification 
                            : null,
                        child: _isTestingNotification
                            ? const CupertinoActivityIndicator()
                            : Text(
                                'Send Test',
                                style: TextStyle(
                                  color: _pushNotifications 
                                      ? theme.primaryColor 
                                      : theme.textSecondary,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                if (_fcmToken != null)
                  CupertinoFormSection.insetGrouped(
                    backgroundColor: theme.cardColor,
                    header: Text(
                      'DEVICE INFO',
                      style: TextStyle(color: theme.textSecondary),
                    ),
                    children: [
                      CupertinoFormRow(
                        prefix: Text(
                          'FCM Token',
                          style: TextStyle(color: theme.textPrimary),
                        ),
                        child: Expanded(
                          child: Text(
                            '${_fcmToken!.substring(0, 20)}...',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Text(
                    'Push notifications help you stay connected with your friends. You can customize which notifications you receive and how you\'re alerted. Use the test notification button to verify your settings are working correctly.',
                    style: AppConstants.caption.copyWith(
                      color: theme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
