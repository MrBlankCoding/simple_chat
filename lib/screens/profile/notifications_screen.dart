import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _messageNotifications = true;
  bool _friendRequestNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

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
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Text(
                'Push notifications help you stay connected with your friends. You can customize which notifications you receive and how you\'re alerted.',
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
