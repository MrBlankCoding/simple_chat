import 'package:flutter/cupertino.dart';
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
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Notifications'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoFormSection.insetGrouped(
              header: const Text('PUSH NOTIFICATIONS'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Push Notifications'),
                  child: CupertinoSwitch(
                    value: _pushNotifications,
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
              header: const Text('MESSAGE SETTINGS'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('New Messages'),
                  child: CupertinoSwitch(
                    value: _messageNotifications,
                    onChanged: _pushNotifications ? (value) {
                      setState(() {
                        _messageNotifications = value;
                      });
                    } : null,
                  ),
                ),
                CupertinoFormRow(
                  prefix: const Text('Friend Requests'),
                  child: CupertinoSwitch(
                    value: _friendRequestNotifications,
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
              header: const Text('ALERT STYLE'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Sound'),
                  child: CupertinoSwitch(
                    value: _soundEnabled,
                    onChanged: _pushNotifications ? (value) {
                      setState(() {
                        _soundEnabled = value;
                      });
                    } : null,
                  ),
                ),
                CupertinoFormRow(
                  prefix: const Text('Vibration'),
                  child: CupertinoSwitch(
                    value: _vibrationEnabled,
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
                  color: CupertinoColors.secondaryLabel,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
